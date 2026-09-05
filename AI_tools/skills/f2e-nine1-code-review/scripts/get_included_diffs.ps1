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

$unstagedDiffFiles = @(
  git diff --name-only |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)

$stagedDiffFiles = @(
  git diff --name-only --cached |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)

$includedDiffFiles = @(
  $unstagedDiffFiles + $stagedDiffFiles |
  Sort-Object -Unique
)

$result = [pscustomobject]@{
  ReviewMode         = 'working-tree'
  IncludedDiffs      = 'unstaged + staged'
  UnstagedDiffFiles  = @($unstagedDiffFiles)
  StagedDiffFiles    = @($stagedDiffFiles)
  IncludedDiffFiles  = @($includedDiffFiles)
  UnstagedCount      = (@($unstagedDiffFiles) | Measure-Object).Count
  StagedCount        = (@($stagedDiffFiles) | Measure-Object).Count
  IncludedFilesCount = (@($includedDiffFiles) | Measure-Object).Count
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 5
  exit 0
}

$result
