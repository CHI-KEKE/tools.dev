param(
  # App API key (param > env > throw)
  [string]$AppKey = 'app-8QE3RFleNCDBl42rQwyMFhif',

  # Endpoint
  [string]$ApiUrl = 'https://dify.91app.biz/v1/chat-messages',

  # Misc
  [string]$User = 'copilot-cli-code-review-request',
  [int]$TimeoutSec    = 60,
  [int]$RetryCount    = 2,
  [int]$RetryDelaySec = 2,

  # Optional conversation id
  [string]$ConversationId
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

# Resolve key from param/env
$AppKey = Get-ValueOrEnv -Value $AppKey -EnvName 'DIFY_APP_KEY' -NameForError 'AppKey'

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

  $diffScope = & $diffContentScript
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

Write-Host "Included Diffs: unstaged + staged"
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

# Build frontend-focused review scope
$frontendRelatedPattern = '(^|[\\/])ClientApp([\\/]|$)|\.(ts|tsx|js|jsx|css|scss|sass|less|json|html|mjml|mts|cts|mjs|cjs)$|(^|[\\/])package\.json$|(^|[\\/])yarn\.lock$|(^|[\\/])tsconfig(\..+)?\.json$|(^|[\\/])webpack(\..+)?\.js$|(^|[\\/])vitest\.config\..+$|(^|[\\/])tailwind\.config\.js$|(^|[\\/])postcss\.config\.js$|(^|[\\/])\.eslintrc(\..+)?$|(^|[\\/])\.prettierrc(\..+)?$|(^|[\\/])locales[\\/].+\.json$'
$stagedReviewFiles = @($stagedDiffFiles | Where-Object { $_ -match $frontendRelatedPattern })
$unstagedReviewFiles = @($unstagedDiffFiles | Where-Object { $_ -match $frontendRelatedPattern })
$reviewFiles = @($stagedReviewFiles + $unstagedReviewFiles | Sort-Object -Unique)

Write-Host "Frontend-related staged files: $(@($stagedReviewFiles).Count)"
Write-Host "Frontend-related unstaged files: $(@($unstagedReviewFiles).Count)"
Write-Host "Frontend-related total unique files: $(@($reviewFiles).Count)"

$queryParts = @()
if (@($stagedReviewFiles).Count -gt 0) {
  $stagedArgs = @('diff', '--cached', '--') + $stagedReviewFiles
  $stagedReviewDiff = (& git @stagedArgs | Out-String).Trim()
  if (-not [string]::IsNullOrWhiteSpace($stagedReviewDiff)) {
    $queryParts += "=== STAGED DIFF (FRONTEND RELATED) ==="
    $queryParts += $stagedReviewDiff
  }
}

if (@($unstagedReviewFiles).Count -gt 0) {
  $unstagedArgs = @('diff', '--') + $unstagedReviewFiles
  $unstagedReviewDiff = (& git @unstagedArgs | Out-String).Trim()
  if (-not [string]::IsNullOrWhiteSpace($unstagedReviewDiff)) {
    $queryParts += "=== UNSTAGED DIFF (FRONTEND RELATED) ==="
    $queryParts += $unstagedReviewDiff
  }
}

$queryText = ($queryParts -join "`r`n`r`n").Trim()

# If no frontend-related diff text, fallback to helper-provided full diff text
if ([string]::IsNullOrWhiteSpace($queryText)) {
  $queryText = [string]$diffScope.QueryText
  if (-not [string]::IsNullOrWhiteSpace($queryText)) {
    Write-Host "No frontend-related diff content found. Fallback to full diff content."
  }
}

if ([string]::IsNullOrWhiteSpace($queryText)) {
  Write-Host "Staged/unstaged diff file list is non-empty but diff content is empty."
  @{ answers = @() } | ConvertTo-Json -Compress | Write-Output
  exit 0
}

function Invoke-DifyRequest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$AppKey,
    [Parameter(Mandatory)][string]$ApiUrl,
    [Parameter(Mandatory)][string]$Query,
    [Parameter(Mandatory)][string]$User,
    [int]$TimeoutSec = 60,
    [string]$ConversationId,
    [int]$RetryCount = 2,
    [int]$RetryDelaySec = 2
  )

  $body = [ordered]@{
    query         = $Query
    user          = $User
    inputs        = @{}
    response_mode = 'streaming'
  }
  if ($ConversationId) { $body['conversation_id'] = $ConversationId }

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

# Call API
$answer = Invoke-DifyRequest -AppKey $AppKey -ApiUrl $ApiUrl -Query $queryText -User $User -TimeoutSec $TimeoutSec -ConversationId $ConversationId -RetryCount $RetryCount -RetryDelaySec $RetryDelaySec

# Human-readable output
"Code Reviewer: $answer"

# Output JSON for further processing
@{ answers = @(
    @{ reviewer = 'Code Reviewer'; answer = $answer }
  )
} | ConvertTo-Json -Compress | Write-Output
