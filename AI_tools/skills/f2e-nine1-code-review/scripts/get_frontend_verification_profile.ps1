param(
  [switch]$AsJson,
  [switch]$RequireProject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepositoryRoot {
  try {
    $gitRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel 2>$null | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($gitRoot) -eq $false) {
      return $gitRoot.Trim()
    }
  } catch {
  }

  $currentDirectory = Get-Item -LiteralPath $PSScriptRoot
  while ($null -ne $currentDirectory) {
    if (Test-Path -LiteralPath (Join-Path -Path $currentDirectory.FullName -ChildPath '.git')) {
      return $currentDirectory.FullName
    }

    $currentDirectory = $currentDirectory.Parent
  }

  throw 'Repository root could not be determined from the current script location.'
}

function Get-PackageJsonCandidates {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
  )

  return @(Get-ChildItem -Path $RepositoryRoot -Filter 'package.json' -File -Recurse | Where-Object {
    $_.FullName -notmatch '[\\/](node_modules|bin|obj|dist|build|coverage|cypress/screenshots|cypress/videos)[\\/]'
  })
}

function Get-CandidateScore {
  param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileInfo]$PackageJsonFile,
    [psobject]$PackageJson
  )

  $score = 0
  $path = $PackageJsonFile.FullName.ToLowerInvariant()
  $scripts = if ($null -ne $PackageJson) { $PackageJson.scripts } else { $null }
  $dependencies = if ($null -ne $PackageJson) { $PackageJson.dependencies } else { $null }
  $devDependencies = if ($null -ne $PackageJson) { $PackageJson.devDependencies } else { $null }

  if ($path.Contains([string]([IO.Path]::DirectorySeparatorChar) + 'clientapp' + [IO.Path]::DirectorySeparatorChar)) { $score += 120 }
  if ($path.Contains([string]([IO.Path]::DirectorySeparatorChar) + 'integration' + [IO.Path]::DirectorySeparatorChar)) { $score -= 40 }

  if ($null -ne $scripts) {
    if ($null -ne $scripts.PSObject.Properties['build']) { $score += 20 }
    if ($null -ne $scripts.PSObject.Properties['lint']) { $score += 10 }
    if ($null -ne $scripts.PSObject.Properties['test:unit'] -or $null -ne $scripts.PSObject.Properties['test']) { $score += 10 }
    if ($null -ne $scripts.PSObject.Properties['dev']) { $score += 5 }
  }

  if (($null -ne $dependencies -and ($null -ne $dependencies.PSObject.Properties['react'] -or $null -ne $dependencies.PSObject.Properties['react-dom'])) -or
      ($null -ne $devDependencies -and ($null -ne $devDependencies.PSObject.Properties['webpack'] -or $null -ne $devDependencies.PSObject.Properties['vite'] -or $null -ne $devDependencies.PSObject.Properties['vitest']))) {
    $score += 25
  }

  return $score
}

function Resolve-FrontendProject {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
  )

  $candidates = Get-PackageJsonCandidates -RepositoryRoot $RepositoryRoot
  if (@($candidates).Count -eq 0) {
    return $null
  }

  $rankedCandidates = foreach ($candidate in $candidates) {
    $packageJson = $null
    try {
      $packageJson = Get-Content -LiteralPath $candidate.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
    }

    [pscustomobject]@{
      PackageJsonFile = $candidate
      PackageJson     = $packageJson
      Score           = Get-CandidateScore -PackageJsonFile $candidate -PackageJson $packageJson
    }
  }

  return @($rankedCandidates | Sort-Object -Property @{ Expression = 'Score'; Descending = $true }, @{ Expression = { $_.PackageJsonFile.FullName }; Descending = $false })[0]
}

function Get-PackageManager {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory,
    [psobject]$PackageJson
  )

  if ($null -ne $PackageJson -and $null -ne $PackageJson.packageManager -and [string]::IsNullOrWhiteSpace([string]$PackageJson.packageManager) -eq $false) {
    $packageManagerText = [string]$PackageJson.packageManager
    if ($packageManagerText.StartsWith('pnpm@')) { return 'pnpm' }
    if ($packageManagerText.StartsWith('yarn@')) { return 'yarn' }
    if ($packageManagerText.StartsWith('npm@')) { return 'npm' }
  }

  if (Test-Path -LiteralPath (Join-Path -Path $WorkingDirectory -ChildPath 'pnpm-lock.yaml')) { return 'pnpm' }
  if (Test-Path -LiteralPath (Join-Path -Path $WorkingDirectory -ChildPath 'yarn.lock')) { return 'yarn' }
  if (Test-Path -LiteralPath (Join-Path -Path $WorkingDirectory -ChildPath 'package-lock.json')) { return 'npm' }

  return 'npm'
}

function Get-ScriptCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$PackageManager,
    [Parameter(Mandatory = $true)]
    [string[]]$Candidates,
    [psobject]$Scripts
  )

  if ($null -eq $Scripts) {
    return $null
  }

  foreach ($candidate in $Candidates) {
    $scriptValue = $Scripts.PSObject.Properties[$candidate]
    if ($null -ne $scriptValue -and [string]::IsNullOrWhiteSpace([string]$scriptValue.Value) -eq $false) {
      switch ($PackageManager) {
        'yarn' { return "yarn $candidate" }
        'pnpm' { return "pnpm $candidate" }
        default { return "npm run $candidate" }
      }
    }
  }

  return $null
}

$repositoryRoot = Resolve-RepositoryRoot
$frontendProject = Resolve-FrontendProject -RepositoryRoot $repositoryRoot
$packageJson = if ($null -ne $frontendProject) { $frontendProject.PackageJson } else { $null }
$packageJsonPath = if ($null -ne $frontendProject) { $frontendProject.PackageJsonFile.FullName } else { $null }
$workingDirectory = if ($null -ne $frontendProject) { $frontendProject.PackageJsonFile.Directory.FullName } else { $null }

$packageManager = Get-PackageManager -WorkingDirectory $workingDirectory -PackageJson $packageJson
$scripts = if ($null -ne $packageJson) { $packageJson.scripts } else { $null }
$lintCommand = Get-ScriptCommand -PackageManager $packageManager -Candidates @('lint', 'lint:prettier', 'lint:watch') -Scripts $scripts
$testCommand = Get-ScriptCommand -PackageManager $packageManager -Candidates @('test:unit', 'test', 'test:unit:coverage') -Scripts $scripts
$buildCommand = Get-ScriptCommand -PackageManager $packageManager -Candidates @('build') -Scripts $scripts

$result = [pscustomobject]@{
  Profile          = 'frontend-package-scripts'
  RepositoryRoot   = $repositoryRoot
  WorkingDirectory = $workingDirectory
  PackageJsonPath  = $packageJsonPath
  PackageManager   = $packageManager
  LintCommand      = $lintCommand
  TestCommand      = $testCommand
  BuildCommand     = $buildCommand
  AvailableScripts = if ($null -ne $scripts) { @($scripts.PSObject.Properties.Name) } else { @() }
  ProjectFound     = $null -ne $frontendProject -and (Test-Path -LiteralPath $workingDirectory)
  PackageJsonFound = Test-Path -LiteralPath $packageJsonPath
}

if ($RequireProject -and -not $result.ProjectFound) {
  throw "A frontend project working directory could not be resolved from repository: $repositoryRoot"
}

if ($RequireProject -and -not $result.PackageJsonFound) {
  throw "package.json was not found: $packageJsonPath"
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 5
  exit 0
}

$result