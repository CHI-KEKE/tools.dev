param(
  # Changed file paths (typically from get_included_diffs.ps1 IncludedDiffFiles).
  [Parameter(Mandatory = $true)]
  [string[]]$ChangedFiles,

  # Path to the .sln file. If omitted, searches the repo root for a single .sln.
  [string]$SolutionPath,

  # Output as JSON instead of PSCustomObject.
  [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve solution file ────────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($SolutionPath)) {
  $repoRoot = (git rev-parse --show-toplevel).Trim()
  $slnFiles = @(Get-ChildItem -Path $repoRoot -Filter '*.sln' -Depth 0)
  if ($slnFiles.Count -eq 0) {
    throw 'No .sln file found in repo root. Provide -SolutionPath explicitly.'
  }
  if ($slnFiles.Count -gt 1) {
    Write-Warning "Multiple .sln files found. Using first: $($slnFiles[0].FullName)"
  }
  $SolutionPath = $slnFiles[0].FullName
} else {
  $repoRoot = (git rev-parse --show-toplevel).Trim()
}

if (-not (Test-Path -LiteralPath $SolutionPath)) {
  throw "Solution file not found: $SolutionPath"
}

# ── Parse .sln to get project entries ────────────────────────────────────────
$slnContent = Get-Content -LiteralPath $SolutionPath -Raw
$projectPattern = 'Project\("\{[^}]+\}"\)\s*=\s*"([^"]+)"\s*,\s*"([^"]+)"'
$slnProjects = [ordered]@{}

foreach ($match in [regex]::Matches($slnContent, $projectPattern)) {
  $projName = $match.Groups[1].Value
  $projRelPath = $match.Groups[2].Value -replace '\\', '/'

  # Skip solution folders (they don't have .csproj/.vbproj extensions)
  if ($projRelPath -notmatch '\.(csproj|vbproj|fsproj)$') { continue }

  $projFullPath = [System.IO.Path]::GetFullPath(
    (Join-Path -Path (Split-Path $SolutionPath -Parent) -ChildPath $projRelPath)
  ) -replace '\\', '/'

  if (-not (Test-Path -LiteralPath $projFullPath)) { continue }

  $projDir = (Split-Path $projFullPath -Parent) -replace '\\', '/'
  $projDirRel = $projDir
  if ($projDir.StartsWith($repoRoot -replace '\\', '/')) {
    $projDirRel = $projDir.Substring(($repoRoot -replace '\\', '/').Length).TrimStart('/')
  }

  $slnProjects[$projRelPath] = @{
    Name          = $projName
    RelativePath  = $projRelPath
    FullPath      = $projFullPath
    Directory     = $projDirRel
    IsTestProject = $false
    References    = @()
  }
}

# ── Detect test projects and collect ProjectReference ────────────────────────
foreach ($key in @($slnProjects.Keys)) {
  $proj = $slnProjects[$key]
  $csprojContent = Get-Content -LiteralPath $proj.FullPath -Raw -ErrorAction SilentlyContinue
  if ([string]::IsNullOrWhiteSpace($csprojContent)) { continue }

  # Detect test project by common conventions
  $isTest = ($proj.Name -match '(?i)(\.Tests?|\.Spec|\.IntegrationTest|\.UnitTest)$') -or
            ($csprojContent -match '(?i)<PackageReference\s+Include="(Microsoft\.NET\.Test\.Sdk|xunit|NUnit|MSTest\.TestFramework|MSTest\.TestAdapter)') -or
            ($csprojContent -match '(?i)<IsTestProject\s*>\s*true\s*</IsTestProject>')
  $proj.IsTestProject = $isTest

  # Collect ProjectReference Include paths (normalized to full paths)
  $refPattern = '<ProjectReference\s+Include="([^"]+)"'
  $refs = @()
  foreach ($refMatch in [regex]::Matches($csprojContent, $refPattern)) {
    $refRel = $refMatch.Groups[1].Value -replace '\\', '/'
    $refFull = [System.IO.Path]::GetFullPath(
      (Join-Path -Path (Split-Path $proj.FullPath -Parent) -ChildPath $refRel)
    ) -replace '\\', '/'
    $refs += $refFull
  }
  $proj.References = $refs
}

# ── Map changed files to directly affected projects ──────────────────────────
$affectedProjectPaths = [System.Collections.Generic.HashSet[string]]::new()

foreach ($file in $ChangedFiles) {
  $fileNorm = ($file -replace '\\', '/').TrimStart('/')

  # If the changed file IS a project file, it is directly affected
  if ($fileNorm -match '\.(csproj|vbproj|fsproj)$') {
    foreach ($key in $slnProjects.Keys) {
      $proj = $slnProjects[$key]
      $projRelNorm = ($proj.RelativePath -replace '\\', '/').TrimStart('/')
      if ($projRelNorm -eq $fileNorm -or ($proj.FullPath -replace '\\', '/') -eq $fileNorm) {
        [void]$affectedProjectPaths.Add($proj.FullPath)
      }
    }
    continue
  }

  # Otherwise, find which project directory contains this file
  foreach ($key in $slnProjects.Keys) {
    $proj = $slnProjects[$key]
    $dirPrefix = $proj.Directory
    if (-not $dirPrefix.EndsWith('/')) { $dirPrefix += '/' }
    $dirPrefixNorm = $dirPrefix.TrimStart('/')
    if ($fileNorm.StartsWith($dirPrefixNorm)) {
      [void]$affectedProjectPaths.Add($proj.FullPath)
    }
  }
}

# ── Find dependent test projects ─────────────────────────────────────────────
$affectedTestProjects = [System.Collections.Generic.List[object]]::new()
$affectedSourceProjects = [System.Collections.Generic.List[object]]::new()

foreach ($key in $slnProjects.Keys) {
  $proj = $slnProjects[$key]

  if ($affectedProjectPaths.Contains($proj.FullPath)) {
    if ($proj.IsTestProject) {
      $affectedTestProjects.Add($proj)
    } else {
      $affectedSourceProjects.Add($proj)
    }
    continue
  }

  # If this is a test project that references any affected source project, include it
  if ($proj.IsTestProject -and $proj.References.Count -gt 0) {
    foreach ($refFull in $proj.References) {
      $refNorm = $refFull -replace '\\', '/'
      if ($affectedProjectPaths.Contains($refNorm)) {
        $affectedTestProjects.Add($proj)
        [void]$affectedProjectPaths.Add($proj.FullPath)  # mark as affected
        break
      }
    }
  }
}

# De-duplicate (by FullPath)
$seenSource = @{}
$uniqueSource = @()
foreach ($p in $affectedSourceProjects) {
  if (-not $seenSource.ContainsKey($p.FullPath)) {
    $seenSource[$p.FullPath] = $true
    $uniqueSource += $p
  }
}
$affectedSourceProjects = $uniqueSource

$seenTest = @{}
$uniqueTest = @()
foreach ($p in $affectedTestProjects) {
  if (-not $seenTest.ContainsKey($p.FullPath)) {
    $seenTest[$p.FullPath] = $true
    $uniqueTest += $p
  }
}
$affectedTestProjects = $uniqueTest

$allAffected = @($affectedSourceProjects) + @($affectedTestProjects)

# ── Determine if scoped build is worthwhile ──────────────────────────────────
$totalProjects = $slnProjects.Count
$affectedCount = $allAffected.Count
$scopeRatio = if ($totalProjects -gt 0) { $affectedCount / $totalProjects } else { 1.0 }

# ── Build output ─────────────────────────────────────────────────────────────
$result = [pscustomobject]@{
  SolutionPath           = $SolutionPath
  TotalSolutionProjects  = $totalProjects
  ChangedFilesCount      = $ChangedFiles.Count
  AffectedProjectsCount  = $affectedCount
  AffectedSourceProjects = @($affectedSourceProjects | ForEach-Object { $_.RelativePath })
  AffectedTestProjects   = @($affectedTestProjects | ForEach-Object { $_.RelativePath })
  BuildTargets           = @($allAffected | ForEach-Object { $_.FullPath })
  TestTargets            = @($affectedTestProjects | ForEach-Object { $_.FullPath })
  IsScopedBuild          = ($affectedCount -gt 0 -and $scopeRatio -le 0.8)
  FallbackToFullBuild    = ($affectedCount -eq 0 -and $ChangedFiles.Count -gt 0) -or ($scopeRatio -gt 0.8)
  ScopeRatio             = [math]::Round($scopeRatio, 2)
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 5
  exit 0
}

$result