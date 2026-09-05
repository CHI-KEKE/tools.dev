<#
.SYNOPSIS
    Query Grafana Loki logs via the /api/ds/query REST endpoint, or edit dashboard expressions.

.DESCRIPTION
    Parses a Grafana dashboard URL, extracts variables, fetches panel queries,
    and executes Loki log queries. Works with any Grafana Loki dashboard.
    Also supports editing dashboard panel expressions via REST API (SaveDashboard mode).

.PARAMETER DashboardUrl
    Full Grafana dashboard URL with query parameters (orgId, var-*, from, to).

.PARAMETER Token
    Grafana Bearer token for authentication.

.PARAMETER CredentialTarget
    Windows Credential Manager target name for Grafana token. Used when -Token and
    $env:GRAFANA_TOKEN are both empty.

.PARAMETER Expr
    (Optional) Custom LogQL expression. If omitted, auto-discovers from dashboard panels.

.PARAMETER MaxLines
    (Optional) Maximum log lines to return. Default: 50.

.PARAMETER PanelIndex
    (Optional) Which panel's query to use (0-based). Default: 0 (first panel with targets).

.PARAMETER SaveDashboard
    (Optional) Switch to enable dashboard editing mode. When set, applies SearchReplace
    to all panel expressions and saves the dashboard.

.PARAMETER SearchPattern
    (Optional) Literal string to find in panel expressions. Required with -SaveDashboard.

.PARAMETER ReplacePattern
    (Optional) Replacement string. Required with -SaveDashboard.

.PARAMETER CommitMessage
    (Optional) Commit message for the dashboard save. Default: auto-generated.

.EXAMPLE
    .\Query-GrafanaLoki.ps1 -DashboardUrl "https://<grafana-host>/d/<uid>/slug?orgId=<orgId>&var-Loki=<lokiUid>&var-Service=my-svc" -Token "glsa_xxx"

.EXAMPLE
    .\Query-GrafanaLoki.ps1 -DashboardUrl "https://<grafana-host>/d/<uid>/slug?orgId=<orgId>&var-Loki=<lokiUid>" -Token "glsa_xxx" -Expr '{service="my-svc"}' -MaxLines 100

.EXAMPLE
    .\Query-GrafanaLoki.ps1 -DashboardUrl "https://<grafana-host>/d/<uid>/slug?orgId=<orgId>" -Token "glsa_xxx" -SaveDashboard -SearchPattern '.*${RequestPath}.*' -ReplacePattern '(.*${RequestPath}.*)?'
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$DashboardUrl,

    # Bearer token — priority: -Token > $env:GRAFANA_TOKEN > Windows Credential Manager
    [string]$Token = "",

    # Windows Credential Manager target name (Generic Credential)
    [string]$CredentialTarget = "GRAFANA_TOKEN",

    [string]$Expr,

    [int]$MaxLines = 50,

    [int]$PanelIndex = 0,

    [switch]$SaveDashboard,

    [string]$SearchPattern,

    [string]$ReplacePattern,

    [string]$CommitMessage,

    # Inspection mode: list all panels with ID / Type / Title / Queries / Transformations
    [switch]$InspectDashboard
)

$ErrorActionPreference = "Stop"

# Read Grafana token from Windows Credential Manager (Generic Credential, Type=1)
function Get-WindowsCredentialSecret {
    param(
        [string[]]$TargetNames
    )

    if (-not $TargetNames -or $TargetNames.Count -eq 0) {
        return $null
    }

    if (-not ("WinCred.NativeMethods" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace WinCred
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL
    {
        public UInt32 Flags;
        public UInt32 Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public UInt32 CredentialBlobSize;
        public IntPtr CredentialBlob;
        public UInt32 Persist;
        public UInt32 AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static class NativeMethods
    {
        [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

        [DllImport("Advapi32.dll", SetLastError = true)]
        public static extern void CredFree(IntPtr cred);
    }
}
"@
    }

    foreach ($targetName in ($TargetNames | Where-Object { $_ } | Select-Object -Unique)) {
        $credPtr = [IntPtr]::Zero
        $isRead = [WinCred.NativeMethods]::CredRead($targetName, 1, 0, [ref]$credPtr)
        if (-not $isRead -or $credPtr -eq [IntPtr]::Zero) {
            continue
        }

        try {
            $credential = [Runtime.InteropServices.Marshal]::PtrToStructure($credPtr, [type][WinCred.CREDENTIAL])
            if ($credential.CredentialBlobSize -le 0 -or $credential.CredentialBlob -eq [IntPtr]::Zero) {
                continue
            }

            $secret = [Runtime.InteropServices.Marshal]::PtrToStringUni(
                $credential.CredentialBlob,
                [int]($credential.CredentialBlobSize / 2)
            )

            if ($secret) {
                return $secret
            }
        }
        finally {
            [WinCred.NativeMethods]::CredFree($credPtr)
        }
    }

    return $null
}

# Resolve Token
if (-not $Token -and $env:GRAFANA_TOKEN) {
    $Token = $env:GRAFANA_TOKEN
}

if (-not $Token) {
    $targetCandidates = @($CredentialTarget, "GRAFANA_TOKEN", "GrafanaToken")
    $Token = Get-WindowsCredentialSecret -TargetNames $targetCandidates
}

# Validate Token — must be provided via parameter, env var, or Windows Credential Manager
if (-not $Token) {
    throw "Grafana Bearer token is required. Pass -Token '<glsa_...>', set `$env:GRAFANA_TOKEN, or store it as a Windows Credential Manager Generic Credential (target: '$CredentialTarget')."
}

# ============================================================
# Step 1: Parse Dashboard URL
# ============================================================
Write-Host "=== Step 1: Parsing Dashboard URL ===" -ForegroundColor Cyan

$uri = [System.Uri]::new($DashboardUrl)
$grafanaHost = "$($uri.Scheme)://$($uri.Host)"
if ($uri.Port -ne 80 -and $uri.Port -ne 443) {
    $grafanaHost += ":$($uri.Port)"
}

# Extract dashboard UID from path: /d/<uid>/<slug>
$pathSegments = $uri.AbsolutePath.TrimStart('/').Split('/')
$dashboardUid = if ($pathSegments.Length -ge 2 -and $pathSegments[0] -eq 'd') {
    $pathSegments[1]
} else {
    throw "Cannot parse dashboard UID from URL path: $($uri.AbsolutePath)"
}

# Parse query parameters
$queryParams = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
$orgId = $queryParams["orgId"]
if (-not $orgId) { $orgId = "1" }

$fromTime = $queryParams["from"]
if (-not $fromTime) { $fromTime = "now-1h" }

$toTime = $queryParams["to"]
if (-not $toTime) { $toTime = "now" }

# Extract all var-* parameters
$variables = @{}
foreach ($key in $queryParams.AllKeys) {
    if ($key -and $key.StartsWith("var-")) {
        $varName = $key.Substring(4)
        $variables[$varName] = $queryParams[$key]
    }
}

$lokiUid = $variables["Loki"]
if (-not $lokiUid -and -not $SaveDashboard) {
    throw "Cannot find Loki datasource UID. Ensure 'var-Loki' is in the URL."
}

Write-Host "  Host:          $grafanaHost"
Write-Host "  Dashboard UID: $dashboardUid"
Write-Host "  Org ID:        $orgId"
Write-Host "  Loki UID:      $lokiUid"
Write-Host "  Time Range:    $fromTime -> $toTime"
Write-Host "  Variables:"
foreach ($kv in $variables.GetEnumerator()) {
    $val = if ($kv.Value) { $kv.Value } else { "(empty)" }
    Write-Host "    $($kv.Key) = $val"
}
Write-Host ""

# ============================================================
# Step 2: Build or Discover LogQL Expression
# ============================================================
$headers = @{
    "Authorization"    = "Bearer $Token"
    "X-Grafana-Org-Id" = $orgId
}

# ============================================================
# Dashboard Inspection Mode (when -InspectDashboard is specified)
# ============================================================
if ($InspectDashboard) {
    Write-Host "=== Dashboard Inspection Mode ===" -ForegroundColor Magenta

    $dashResp = Invoke-WebRequest -Uri "$grafanaHost/api/dashboards/uid/$dashboardUid" `
        -Headers ($headers + @{ "Content-Type" = "application/json" }) -Method Get
    $obj = $dashResp.Content | ConvertFrom-Json -Depth 50

    Write-Host "  Title:   $($obj.dashboard.title)"
    Write-Host "  UID:     $($obj.dashboard.uid)"
    Write-Host "  Version: $($obj.dashboard.version)"
    Write-Host "  Folder:  $($obj.meta.folderTitle) ($($obj.meta.folderUid))"
    Write-Host "  canSave: $($obj.meta.canSave)"
    Write-Host ""

    # Flatten panels including those nested inside collapsed rows
    function Get-FlatPanels($panels) {
        $result = [System.Collections.Generic.List[object]]::new()
        foreach ($p in $panels) {
            $result.Add($p)
            # Collapsed rows keep child panels inside their own 'panels' array
            if ($p.PSObject.Properties['panels'] -and $p.panels.Count -gt 0) {
                foreach ($child in (Get-FlatPanels $p.panels)) {
                    $result.Add($child)
                }
            }
        }
        return $result
    }

    $allPanels = Get-FlatPanels $obj.dashboard.panels
    $rows = @()
    foreach ($p in $allPanels) {
        $queryCount  = if ($p.PSObject.Properties['targets'] -and $p.targets) { $p.targets.Count } else { 0 }
        $xfrmCount   = if ($p.PSObject.Properties['transformations'] -and $p.transformations) { $p.transformations.Count } else { 0 }
        $xfrmNames   = if ($xfrmCount -gt 0) { ($p.transformations | ForEach-Object { $_.id }) -join ", " } else { "" }
        $indent      = if ($p.type -ne "row") { "  " } else { "" }
        $rows += [PSCustomObject]@{
            ID              = $p.id
            Type            = $p.type
            Title           = "$indent$($p.title)"
            Queries         = $queryCount
            Transformations = $xfrmCount
            TransformNames  = $xfrmNames
        }
    }

    Write-Host "=== Panels ($($rows.Count) total) ===" -ForegroundColor Cyan
    $rows | Format-Table -AutoSize

    return
}

# ============================================================
# Dashboard Edit Mode (when -SaveDashboard is specified)
# ============================================================
if ($SaveDashboard) {
    if (-not $SearchPattern -or -not $ReplacePattern) {
        throw "When using -SaveDashboard, both -SearchPattern and -ReplacePattern are required."
    }

    Write-Host "=== Dashboard Edit Mode ===" -ForegroundColor Magenta
    Write-Host "  Search:  $SearchPattern"
    Write-Host "  Replace: $ReplacePattern"
    Write-Host ""

    # Fetch current dashboard
    Write-Host "  Fetching dashboard..." -ForegroundColor Cyan
    $dashResp = Invoke-WebRequest -Uri "$grafanaHost/api/dashboards/uid/$dashboardUid" `
        -Headers ($headers + @{ "Content-Type" = "application/json" }) -Method Get -UseBasicParsing
    $dashContent = $dashResp.Content

    # Check permissions
    Add-Type -AssemblyName System.Text.Json
    $permDoc = [System.Text.Json.JsonDocument]::Parse($dashContent)
    $canSave = $permDoc.RootElement.GetProperty("meta").GetProperty("canSave").GetBoolean()
    $version = $permDoc.RootElement.GetProperty("dashboard").GetProperty("version").GetInt32()
    $permDoc.Dispose()

    if (-not $canSave) {
        throw "Token does not have save permission on this dashboard. Ensure the service account has Edit permission on both the dashboard AND its parent folder."
    }
    Write-Host "  Permission: canSave=True, current version=$version" -ForegroundColor Green

    # Apply replacement with idempotency check
    # If ReplacePattern already exists and SearchPattern only appears as a substring of it,
    # the fix has already been applied — skip to avoid double-wrapping.
    $replaceAlreadyExists = $dashContent.Contains($ReplacePattern)
    $searchOnlyInReplace = $ReplacePattern.Contains($SearchPattern)

    if ($replaceAlreadyExists -and $searchOnlyInReplace) {
        Write-Host "  SKIPPED: Fix already applied (ReplacePattern already present in dashboard)." -ForegroundColor Yellow
        Write-Host "  The pattern '$ReplacePattern' already exists. Re-applying would cause double-wrapping." -ForegroundColor Yellow
        return
    }

    $matchCount = [regex]::Matches($dashContent, [regex]::Escape($SearchPattern)).Count
    if ($matchCount -eq 0) {
        Write-Host "  WARNING: Pattern not found in dashboard JSON. No changes to save." -ForegroundColor Yellow
        return
    }

    $updatedContent = $dashContent.Replace($SearchPattern, $ReplacePattern)
    $newCount = [regex]::Matches($updatedContent, [regex]::Escape($ReplacePattern)).Count
    Write-Host "  Replacements: $matchCount occurrence(s) found and replaced." -ForegroundColor Green

    # Extract dashboard JSON and folder UID
    $editDoc = [System.Text.Json.JsonDocument]::Parse($updatedContent)
    $dashboardJson = $editDoc.RootElement.GetProperty("dashboard").GetRawText()
    $folderUid = $editDoc.RootElement.GetProperty("meta").GetProperty("folderUid").GetString()
    $editDoc.Dispose()

    # Build save payload
    $saveMessage = if ($CommitMessage) { $CommitMessage } else {
        "Auto-fix: replace '$SearchPattern' with '$ReplacePattern'"
    }
    $payload = "{`"dashboard`":$dashboardJson,`"folderUid`":`"$folderUid`",`"overwrite`":true,`"message`":`"$saveMessage`"}"

    # Save
    Write-Host "  Saving dashboard..." -ForegroundColor Cyan
    try {
        $saveHeaders = $headers + @{ "Content-Type" = "application/json" }
        $saveResp = Invoke-RestMethod -Uri "$grafanaHost/api/dashboards/db" `
            -Headers $saveHeaders -Method Post `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($payload))
        Write-Host ""
        Write-Host "  === SUCCESS ===" -ForegroundColor Green
        Write-Host "  Dashboard UID: $($saveResp.uid)"
        Write-Host "  New Version:   $($saveResp.version)"
        Write-Host "  URL:           $grafanaHost$($saveResp.url)"
        Write-Host "  Status:        $($saveResp.status)"
    }
    catch {
        $errMsg = if ($_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        Write-Host ""
        Write-Host "  === FAILED ===" -ForegroundColor Red
        Write-Host "  Error: $errMsg" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "    1. Ensure SA has Edit permission on the PARENT FOLDER (not just the dashboard)"
        Write-Host "    2. Dashboard-level Edit alone is NOT sufficient for API saves"
        Write-Host "    3. Check: Dashboards > [FolderName] > Settings > Permissions"
        throw "Dashboard save failed: $errMsg"
    }
    return
}

if (-not $Expr) {
    Write-Host "=== Step 2: Discovering LogQL from Dashboard Panels ===" -ForegroundColor Cyan

    $dashResponse = Invoke-WebRequest -Uri "$grafanaHost/api/dashboards/uid/$dashboardUid" `
        -Headers $headers -Method Get
    $dashContent = $dashResponse.Content

    # Extract all expr fields using regex (avoids JSON case-sensitivity issues)
    $exprMatches = [regex]::Matches($dashContent, '"expr"\s*:\s*"((?:[^"\\]|\\.)*)"')

    if ($exprMatches.Count -eq 0) {
        throw "No LogQL expressions found in dashboard panels."
    }

    # Select the panel expression
    $selectedIdx = [Math]::Min($PanelIndex, $exprMatches.Count - 1)
    $rawExpr = $exprMatches[$selectedIdx].Groups[1].Value

    # Unescape JSON string
    $rawExpr = $rawExpr -replace '\\n', "`n" -replace '\\"', '"' -replace '\\\\', '\'

    Write-Host "  Found $($exprMatches.Count) panel(s) with queries. Using panel index $selectedIdx."
    Write-Host "  Raw LogQL template:" -ForegroundColor DarkGray
    Write-Host "  $($rawExpr.Substring(0, [Math]::Min(200, $rawExpr.Length)))..." -ForegroundColor DarkGray
    Write-Host ""

    # Substitute variables into expression
    foreach ($kv in $variables.GetEnumerator()) {
        $varName = $kv.Key
        $varValue = $kv.Value

        # Handle $__all → match everything (remove the filter line)
        if ($varValue -eq '$__all' -or $varValue -eq '${__all}') {
            $varValue = ""
        }

        # Replace ${VarName} and $VarName patterns
        $rawExpr = $rawExpr -replace "\`$\{$varName\}", $varValue
        $rawExpr = $rawExpr -replace "\`$$varName(?![a-zA-Z0-9_])", $varValue
    }

    # Remove filter lines with empty values: |~ `` or |= ``
    $lines = $rawExpr -split "`n"
    $filteredLines = @($lines | Where-Object {
        $_ -notmatch '^\s*\|[~=]\s*``\s*$'
    })

    # Fix: When a |~ line filter already matches a value in the raw log text,
    # make the corresponding label filter (e.g. | _props_RequestPath =~ `.*value.*`)
    # also accept empty field values by wrapping in optional group `(.*value.*)?`.
    # This fixes queries returning zero results for services whose logs lack a
    # specific parsed field (e.g., _props_RequestPath vs request_path) while
    # preserving exact filtering for services that DO have the field.
    $lineFilterValues = @()
    foreach ($fl in $filteredLines) {
        if ($fl -match '^\s*\|~\s*`(.+)`\s*$') {
            $lineFilterValues += $Matches[1]
        }
    }
    if ($lineFilterValues.Count -gt 0) {
        $filteredLines = @($filteredLines | ForEach-Object {
            $line = $_
            foreach ($val in $lineFilterValues) {
                $search = '=~ `.*' + $val + '.*`'
                $replace = '=~ `(.*' + $val + '.*)?`'
                if ($line.Contains($search)) {
                    $line = $line.Replace($search, $replace)
                    break
                }
            }
            $line
        })
    }

    $Expr = ($filteredLines -join "`n").Trim()

    Write-Host "  Resolved LogQL:" -ForegroundColor Green
    Write-Host "  $Expr"
    Write-Host ""
}
else {
    Write-Host "=== Step 2: Using provided LogQL expression ===" -ForegroundColor Cyan
    Write-Host "  $Expr"
    Write-Host ""
}

# ============================================================
# Step 3: Execute Loki Query
# ============================================================
Write-Host "=== Step 3: Querying Loki ===" -ForegroundColor Cyan

$queryHeaders = @{
    "Authorization"    = "Bearer $Token"
    "Content-Type"     = "application/json"
    "X-Grafana-Org-Id" = $orgId
}

$body = @{
    queries = @(
        @{
            refId      = "A"
            datasource = @{ type = "loki"; uid = $lokiUid }
            expr       = $Expr
            maxLines   = $MaxLines
            queryType  = "range"
        }
    )
    from = $fromTime
    to   = $toTime
} | ConvertTo-Json -Depth 5

$queryResponse = Invoke-WebRequest -Uri "$grafanaHost/api/ds/query" `
    -Headers $queryHeaders -Method Post -Body $body

Write-Host "  Status: $($queryResponse.StatusCode)"
Write-Host "  Response size: $($queryResponse.Content.Length) bytes"
Write-Host ""

# ============================================================
# Step 4: Parse and Display Results
# ============================================================
Write-Host "=== Step 4: Parsing Results ===" -ForegroundColor Cyan

Add-Type -AssemblyName System.Text.Json

$doc = [System.Text.Json.JsonDocument]::Parse($queryResponse.Content)
$root = $doc.RootElement

# Check if results exist
$resultsA = $root.GetProperty("results").GetProperty("A")
$status = $resultsA.GetProperty("status").GetInt32()

if ($status -ne 200) {
    $errorMsg = if ($resultsA.TryGetProperty("error", [ref]$null)) {
        $resultsA.GetProperty("error").GetString()
    } else { "Unknown error" }
    throw "Loki query failed with status $status : $errorMsg"
}

$frames = $resultsA.GetProperty("frames")
if ($frames.GetArrayLength() -eq 0) {
    Write-Host "  No results found." -ForegroundColor Yellow
    return
}

$frame = $frames[0]
$values = $frame.GetProperty("data").GetProperty("values")

if ($values.GetArrayLength() -lt 3) {
    Write-Host "  No log lines in response." -ForegroundColor Yellow
    return
}

$labels = $values[0]
$times = $values[1]
$lines = $values[2]
$count = $times.GetArrayLength()

Write-Host "  Total log lines: $count" -ForegroundColor Green
Write-Host ""

# Collect stats
$levelStats = @{}
$sourceStats = @{}

# Output results
$output = @()
for ($i = 0; $i -lt $count; $i++) {
    $ts = ([DateTimeOffset]::FromUnixTimeMilliseconds($times[$i].GetInt64())).ToOffset([TimeSpan]::FromHours(8)).ToString("yyyy-MM-dd HH:mm:ss")
    $lineText = $lines[$i].GetString()

    # Extract structured fields - supports multiple log formats:
    # Format 1 (Serilog Compact): _msg, _lvl, _srctx, _tid
    # Format 2 (Standard Serilog): message, log-level/level, source-context/SourceContext, trace-id
    $msg = if ($lineText -match '"_msg"\s*:\s*"((?:[^"\\]|\\.)*)"') { $Matches[1] }
           elseif ($lineText -match '"(?:message|msg)"\s*:\s*"((?:[^"\\]|\\.)*)"') { $Matches[1] }
           else { "" }
    $lvl = if ($lineText -match '"_lvl"\s*:\s*"([^"]*)"') { $Matches[1] }
           elseif ($lineText -match '"(?:log-level|level|Level)"\s*:\s*"([^"]*)"') { $Matches[1] }
           else { "Unknown" }
    $src = if ($lineText -match '"_srctx"\s*:\s*"([^"]*)"') { $Matches[1] }
           elseif ($lineText -match '"(?:source-context|SourceContext)"\s*:\s*"([^"]*)"') { $Matches[1] }
           else { "" }
    $tid = if ($lineText -match '"_tid"\s*:\s*"([^"]*)"') { $Matches[1] }
           elseif ($lineText -match '"(?:trace-id|TraceId|request-id)"\s*:\s*"([^"]*)"') { $Matches[1] }
           else { "" }

    # Stats
    if (-not $levelStats.ContainsKey($lvl)) { $levelStats[$lvl] = 0 }
    $levelStats[$lvl]++
    if ($src) {
        if (-not $sourceStats.ContainsKey($src)) { $sourceStats[$src] = 0 }
        $sourceStats[$src]++
    }

    # Truncate message for display
    $displayMsg = if ($msg.Length -gt 120) { $msg.Substring(0, 120) + "..." } else { $msg }

    $output += [PSCustomObject]@{
        Time    = $ts
        Level   = $lvl
        Message = $displayMsg
        Source  = $src.Split('.')[-1]  # Short class name
    }
}

# Display summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Log Levels:"
$levelStats.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    $color = switch ($_.Key) {
        "Error"       { "Red" }
        "Warning"     { "Yellow" }
        "Information" { "Green" }
        default       { "White" }
    }
    Write-Host "    $($_.Key): $($_.Value)" -ForegroundColor $color
}
Write-Host ""
Write-Host "  Top Sources:"
$sourceStats.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host "    $($_.Key): $($_.Value)"
}
Write-Host ""

# Display log table
Write-Host "=== Log Entries ===" -ForegroundColor Cyan
$output | Format-Table -AutoSize -Wrap

# Cleanup
$doc.Dispose()
