param(
  [switch]$AsJson,

  # Optional baseline ref (e.g. a stash SHA from `git stash create`).
  # When provided, unstaged diff is calculated as `git diff <Baseline>` instead
  # of `git diff` (which compares against the index / HEAD).
  # This enables incremental review: only changes since the baseline are included.
  [string]$Baseline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
  git --version *> $null
} catch {
  throw "Git is not available in PATH. Please install Git for Windows and ensure 'git' is in PATH."
}

# Validate baseline ref if provided
if (-not [string]::IsNullOrWhiteSpace($Baseline)) {
  try {
    git cat-file -t $Baseline *> $null
  } catch {
    throw "Invalid baseline ref '$Baseline'. Ensure it is a valid git object (e.g. from 'git stash create')."
  }
}

$useBaseline = -not [string]::IsNullOrWhiteSpace($Baseline)

if ($useBaseline) {
  # Baseline mode: compare working tree against the snapshot ref.
  # This captures everything changed SINCE that snapshot, regardless of
  # staging status, which is exactly what we want for incremental review.
  $unstagedDiffFiles = @(
    git diff $Baseline --name-only |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
  # Staged files that were staged AFTER the baseline was created are
  # already included in the above diff. We still collect staged-vs-HEAD
  # separately so callers that need the split can use it, but
  # IncludedDiffFiles is the authoritative set.
  $stagedDiffFiles = @(
    git diff --name-only --cached |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
} else {
  # Original behavior: full working-tree diff against HEAD/index.
  $unstagedDiffFiles = @(
    git diff --name-only |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
  $stagedDiffFiles = @(
    git diff --name-only --cached |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
}

$includedDiffFiles = @(
  $unstagedDiffFiles + $stagedDiffFiles |
  Sort-Object -Unique
)

$result = [pscustomobject]@{
  ReviewMode         = 'working-tree'
  IncludedDiffs      = if ($useBaseline) { "incremental (baseline: $Baseline)" } else { 'unstaged + staged' }
  Baseline           = if ($useBaseline) { $Baseline } else { $null }
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
