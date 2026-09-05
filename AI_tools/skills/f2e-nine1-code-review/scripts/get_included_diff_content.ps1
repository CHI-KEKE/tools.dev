param(
  [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
  git --version *> $null
} catch {
  throw "Git is not available in PATH. Please install Git for Windows and ensure 'git' is in PATH."
}

$diffScopeScript = Join-Path -Path $PSScriptRoot -ChildPath 'get_included_diffs.ps1'
if (-not (Test-Path -LiteralPath $diffScopeScript)) {
  throw "Diff scope helper script not found: $diffScopeScript"
}

$diffScope = & $diffScopeScript
$unstagedDiffFiles = @($diffScope.UnstagedDiffFiles)
$stagedDiffFiles = @($diffScope.StagedDiffFiles)
$includedDiffFiles = @($diffScope.IncludedDiffFiles)
$unstagedCount = [int]$diffScope.UnstagedCount
$stagedCount = [int]$diffScope.StagedCount
$includedCount = [int]$diffScope.IncludedFilesCount

$stagedDiffText = ''
$unstagedDiffText = ''
$queryParts = @()

if ($stagedCount -gt 0) {
  $stagedDiffText = (git diff --cached | Out-String).Trim()
  if (-not [string]::IsNullOrWhiteSpace($stagedDiffText)) {
    $queryParts += "=== STAGED DIFF (ALL FILE TYPES) ==="
    $queryParts += $stagedDiffText
  }
}

if ($unstagedCount -gt 0) {
  $unstagedDiffText = (git diff | Out-String).Trim()
  if (-not [string]::IsNullOrWhiteSpace($unstagedDiffText)) {
    $queryParts += "=== UNSTAGED DIFF (ALL FILE TYPES) ==="
    $queryParts += $unstagedDiffText
  }
}

$queryText = ($queryParts -join "`r`n`r`n").Trim()

$result = [pscustomobject]@{
  ReviewMode         = 'working-tree'
  IncludedDiffs      = 'unstaged + staged'
  UnstagedDiffFiles  = $unstagedDiffFiles
  StagedDiffFiles    = $stagedDiffFiles
  IncludedDiffFiles  = $includedDiffFiles
  UnstagedCount      = $unstagedCount
  StagedCount        = $stagedCount
  IncludedFilesCount = $includedCount
  StagedDiffText     = $stagedDiffText
  UnstagedDiffText   = $unstagedDiffText
  QueryText          = $queryText
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 6
  exit 0
}

$result
