param(
  # App API keys (param > env > throw)
  [string]$CustomAppKey   = 'app-CzdjFhacdnhKZ9z3vGZdL9DL',
  [string]$StandardAppKey = 'app-ZiyaCPCjqiTaN8YEAsMTZU8e',

  # Endpoints
  [string]$CustomApiUrl   = 'https://dify.91app.biz/v1/chat-messages',
  [string]$StandardApiUrl = 'https://dify.91app.biz/v1/chat-messages',

  # Misc
  [string]$User = 'copilot-code-review-request',
  [int]$TimeoutSec    = 60,
  [int]$RetryCount    = 2,
  [int]$RetryDelaySec = 2,

  # Optional conversation ids
  [string]$CustomConversationId,
  [string]$StandardConversationId,

  # Baseline ref for incremental review (passthrough to diff helpers).
  # When provided, only changes since this ref are included in the Dify payload.
  [string]$Baseline
)

$ErrorActionPreference = 'Stop'

function Get-ValueOrEnv {
  param(
    [string]$Value,
    [string]$EnvName,
    [string]$NameForError
  )
  if (-not [string]::IsNullOrWhiteSpace($Value)) { return $Value.Trim() }

  # Try to get environment variable from Process/User/Machine
  $envVal = [Environment]::GetEnvironmentVariable($EnvName)
  if ([string]::IsNullOrWhiteSpace($envVal)) {
    $envVal = [Environment]::GetEnvironmentVariable($EnvName, 'User')
    if ([string]::IsNullOrWhiteSpace($envVal)) {
      $envVal = [Environment]::GetEnvironmentVariable($EnvName, 'Machine')
    }
  }
  if ([string]::IsNullOrWhiteSpace($envVal)) {
    throw "Missing $NameForError. Provide -$NameForError or set env:$EnvName."
  }
  return $envVal.Trim()
}

# Resolve keys from param/env
$CustomAppKey   = Get-ValueOrEnv -Value $CustomAppKey   -EnvName 'DIFY_APP_KEY_CUSTOM'   -NameForError 'CustomAppKey'
$StandardAppKey = Get-ValueOrEnv -Value $StandardAppKey -EnvName 'DIFY_APP_KEY_STANDARD' -NameForError 'StandardAppKey'

# Network defaults
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
try { [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials } catch {}

# Ensure git is available
try {
  git --version *> $null
} catch {
  throw "Git is not available in PATH. Please install Git for Windows and ensure 'git' is in PATH."
}

# Get staged/unstaged diff files + content via shared helper
$stagedDiffFiles = @()
$unstagedDiffFiles = @()
$includedDiffFiles = @()
$stagedReviewFiles = @()
$unstagedReviewFiles = @()
$reviewFiles = @()
$queryText = ''
$diffScope = $null
try {
  $diffContentScript = Join-Path -Path $PSScriptRoot -ChildPath 'get_included_diff_content.ps1'
  if (-not (Test-Path -LiteralPath $diffContentScript)) {
    throw "Diff content helper script not found: $diffContentScript"
  }

  # Forward -Baseline if provided
  $diffContentArgs = @{}
  if (-not [string]::IsNullOrWhiteSpace($Baseline)) {
    $diffContentArgs['Baseline'] = $Baseline
  }

  $diffScope = & $diffContentScript @diffContentArgs
  $unstagedDiffFiles = @($diffScope.UnstagedDiffFiles)
  $stagedDiffFiles = @($diffScope.StagedDiffFiles)
  $includedDiffFiles = @($diffScope.IncludedDiffFiles)
  $stagedDiff = [string]$diffScope.StagedDiffText
  $unstagedDiff = [string]$diffScope.UnstagedDiffText
  $queryText = [string]$diffScope.QueryText
} catch {
  throw "Failed to get included diff data from helper script: $($_.Exception.Message)"
}

$stagedCount = if ($null -ne $diffScope -and $null -ne $diffScope.StagedCount) { [int]$diffScope.StagedCount } else { ($stagedDiffFiles | Measure-Object).Count }
$unstagedCount = if ($null -ne $diffScope -and $null -ne $diffScope.UnstagedCount) { [int]$diffScope.UnstagedCount } else { ($unstagedDiffFiles | Measure-Object).Count }
$allCount = if ($null -ne $diffScope -and $null -ne $diffScope.IncludedFilesCount) { [int]$diffScope.IncludedFilesCount } else { ($includedDiffFiles | Measure-Object).Count }

$diffModeLabel = if (-not [string]::IsNullOrWhiteSpace($Baseline)) { "incremental (baseline: $Baseline)" } else { 'unstaged + staged' }
Write-Host "Included Diffs: $diffModeLabel"
Write-Host "Staged diff files: $stagedCount"
if ($stagedCount -gt 0) {
  Write-Host "Staged files:`n$($stagedDiffFiles -join "`n")"
}

Write-Host "Unstaged diff files: $unstagedCount"
if ($unstagedCount -gt 0) {
  Write-Host "Unstaged files:`n$($unstagedDiffFiles -join "`n")"
}

Write-Host "Total unique diff files: $allCount"

# If no code changes, output empty JSON and exit 0 (CI friendly)
if ($allCount -eq 0) {
  Write-Host "No staged/unstaged changes found. Skipping API calls."
  @{ answers = @() } | ConvertTo-Json -Compress | Write-Output
  exit 0
}

# Build C#-focused review scope
$csharpRelatedPattern = '\.(cs|csproj|props|targets|sln|config)$|(^|[\\/])appsettings(\..+)?\.json$|(^|[\\/])Directory\.Build\.(props|targets)$|(^|[\\/])global\.json$|(^|[\\/])nuget\.config$'
$stagedReviewFiles = @($stagedDiffFiles | Where-Object { $_ -match $csharpRelatedPattern })
$unstagedReviewFiles = @($unstagedDiffFiles | Where-Object { $_ -match $csharpRelatedPattern })
$reviewFiles = @($stagedReviewFiles + $unstagedReviewFiles | Sort-Object -Unique)

Write-Host "C#-related staged files: $(@($stagedReviewFiles).Count)"
Write-Host "C#-related unstaged files: $(@($unstagedReviewFiles).Count)"
Write-Host "C#-related total unique files: $(@($reviewFiles).Count)"

$useBaseline = -not [string]::IsNullOrWhiteSpace($Baseline)

if ($useBaseline) {
  # Baseline mode: single diff against snapshot, filtered to C# files
  $queryParts = @()
  if (@($reviewFiles).Count -gt 0) {
    $baselineArgs = @('diff', $Baseline, '--') + $reviewFiles
    $baselineReviewDiff = (& git @baselineArgs | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($baselineReviewDiff)) {
      $queryParts += "=== INCREMENTAL DIFF (C# RELATED, since baseline $Baseline) ==="
      $queryParts += $baselineReviewDiff
    }
  }
  $queryText = ($queryParts -join "`r`n`r`n").Trim()
} else {
  # Original behavior: staged + unstaged C# diffs
  $queryParts = @()
  if (@($stagedReviewFiles).Count -gt 0) {
    $stagedArgs = @('diff', '--cached', '--') + $stagedReviewFiles
    $stagedReviewDiff = (& git @stagedArgs | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($stagedReviewDiff)) {
      $queryParts += "=== STAGED DIFF (C# RELATED) ==="
      $queryParts += $stagedReviewDiff
    }
  }

  if (@($unstagedReviewFiles).Count -gt 0) {
    $unstagedArgs = @('diff', '--') + $unstagedReviewFiles
    $unstagedReviewDiff = (& git @unstagedArgs | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($unstagedReviewDiff)) {
      $queryParts += "=== UNSTAGED DIFF (C# RELATED) ==="
      $queryParts += $unstagedReviewDiff
    }
  }
  $queryText = ($queryParts -join "`r`n`r`n").Trim()
}

# If no C#-related diff text, fallback to helper-provided full diff text
if ([string]::IsNullOrWhiteSpace($queryText)) {
  $queryText = [string]$diffScope.QueryText
  if (-not [string]::IsNullOrWhiteSpace($queryText)) {
    Write-Host "No C#-related diff content found. Fallback to full diff content."
  }
}

if ([string]::IsNullOrWhiteSpace($queryText)) {
  Write-Host "Staged/unstaged diff file list is non-empty but diff content is empty."
  @{ answers = @() } | ConvertTo-Json -Compress | Write-Output
  exit 0
}

# ---------------------------------------------------------------------------
# Parallel Dify API requests via Start-Job (PS 5.1 / PS 7 compatible)
# ---------------------------------------------------------------------------
# Start-Job is used instead of Start-ThreadJob to ensure compatibility with
# both Windows PowerShell 5.1 and PowerShell 7+. While Start-ThreadJob
# (thread-pool based, same process) is faster, Start-Job (new process) is
# universally available and avoids dependency on the ThreadJob module.
#
# The two Dify endpoints (Custom Rules / Standard Rules) are independent,
# so we fire both simultaneously and wait for whichever finishes last.
# ---------------------------------------------------------------------------

$difyRequestBlock = {
  param(
    [string]$AppKey,
    [string]$ApiUrl,
    [string]$Query,
    [string]$User,
    [int]$TimeoutSec,
    [string]$ConversationId,
    [int]$RetryCount,
    [int]$RetryDelaySec
  )

  $body = [ordered]@{
    query         = $Query
    user          = $User
    inputs        = @{}
    response_mode = 'blocking'
  }
  if (-not [string]::IsNullOrWhiteSpace($ConversationId)) {
    $body['conversation_id'] = $ConversationId
  }

  $json    = $body | ConvertTo-Json -Depth 10
  $headers = @{ Authorization = "Bearer $AppKey" }

  for ($i = 0; $i -le $RetryCount; $i++) {
    try {
      $resp = Invoke-RestMethod -Uri $ApiUrl -Method POST -Headers $headers `
              -ContentType 'application/json; charset=utf-8' -Body $json -TimeoutSec $TimeoutSec

      if ($resp -and ($resp.PSObject.Properties.Name -contains 'answer')) {
        return [string]$resp.answer
      } else {
        return ($resp | ConvertTo-Json -Compress)
      }
    } catch {
      if ($i -lt $RetryCount) {
        Start-Sleep -Seconds $RetryDelaySec
      } else {
        return "[ERROR] $($_.Exception.Message)"
      }
    }
  }
}

Write-Host "Sending Dify requests in parallel (Custom + Standard)..."

$customJob = Start-Job -ScriptBlock $difyRequestBlock -ArgumentList @(
  $CustomAppKey, $CustomApiUrl, $queryText, $User, $TimeoutSec,
  $CustomConversationId, $RetryCount, $RetryDelaySec
)

$standardJob = Start-Job -ScriptBlock $difyRequestBlock -ArgumentList @(
  $StandardAppKey, $StandardApiUrl, $queryText, $User, $TimeoutSec,
  $StandardConversationId, $RetryCount, $RetryDelaySec
)

# Wait for both with a generous upper bound:
#   (TimeoutSec + RetryDelaySec) * (RetryCount + 1) covers the worst-case
#   retry cycle for one request; +30s headroom for thread scheduling.
$jobTimeoutSec = ($TimeoutSec + $RetryDelaySec) * ($RetryCount + 1) + 30
$null = Wait-Job -Job $customJob, $standardJob -Timeout $jobTimeoutSec

# Collect results
$customAnswer   = (Receive-Job -Job $customJob   2>&1 | Out-String).Trim()
$standardAnswer = (Receive-Job -Job $standardJob 2>&1 | Out-String).Trim()

# Clean up thread jobs
Remove-Job -Job $customJob, $standardJob -Force -ErrorAction SilentlyContinue

# Guard against empty results from timeout or unexpected failure
if ([string]::IsNullOrWhiteSpace($customAnswer)) {
  $customAnswer = '[ERROR] Custom Dify request timed out or returned empty.'
}
if ([string]::IsNullOrWhiteSpace($standardAnswer)) {
  $standardAnswer = '[ERROR] Standard Dify request timed out or returned empty.'
}

# Human-readable output
"Code Reviewer (Custom Rules): $customAnswer"
"Code Reviewer (Standard Rules): $standardAnswer"

# Output JSON for further processing
@{ answers = @(
    @{ reviewer = 'Code Reviewer (Custom Rules)';   answer = $customAnswer },
    @{ reviewer = 'Code Reviewer (Standard Rules)'; answer = $standardAnswer }
  )
} | ConvertTo-Json -Compress | Write-Output