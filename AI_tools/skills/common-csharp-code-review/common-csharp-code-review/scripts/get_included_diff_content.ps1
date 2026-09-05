param(
  [switch]$AsJson,

  # Passthrough to get_included_diffs.ps1 for incremental review.
  [string]$Baseline
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

# Forward -Baseline if provided
$diffScopeArgs = @{}
if (-not [string]::IsNullOrWhiteSpace($Baseline)) {
  $diffScopeArgs['Baseline'] = $Baseline
}

$diffScope = & $diffScopeScript @diffScopeArgs
$unstagedDiffFiles = @($diffScope.UnstagedDiffFiles)
$stagedDiffFiles = @($diffScope.StagedDiffFiles)
$includedDiffFiles = @($diffScope.IncludedDiffFiles)
$unstagedCount = [int]$diffScope.UnstagedCount
$stagedCount = [int]$diffScope.StagedCount
$includedCount = [int]$diffScope.IncludedFilesCount
$useBaseline = -not [string]::IsNullOrWhiteSpace($Baseline)

$stagedDiffText = ''
$unstagedDiffText = ''
$queryParts = @()

if ($useBaseline) {
  # Baseline mode: single diff against the snapshot ref captures all changes.
  # No need to split staged/unstaged — the baseline diff is the complete delta.
  if ($includedCount -gt 0) {
    $baselineDiffText = (git diff $Baseline | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($baselineDiffText)) {
      $queryParts += "=== INCREMENTAL DIFF (since baseline $Baseline) ==="
      $queryParts += $baselineDiffText
      # Store in unstaged field for backward compatibility
      $unstagedDiffText = $baselineDiffText
    }
  }
} else {
  # Original behavior
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
}

$queryText = ($queryParts -join "`r`n`r`n").Trim()

$result = [pscustomobject]@{
  ReviewMode         = 'working-tree'
  IncludedDiffs      = if ($useBaseline) { "incremental (baseline: $Baseline)" } else { 'unstaged + staged' }
  Baseline           = if ($useBaseline) { $Baseline } else { $null }
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
