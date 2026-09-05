param(
  [switch]$AsJson,
  [switch]$RequireAll
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-FromPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutableName
  )

  $cmd = Get-Command -Name $ExecutableName -CommandType Application -ErrorAction SilentlyContinue
  if ($null -ne $cmd) {
    return $cmd.Source
  }

  return $null
}

function Get-VswherePath {
  $candidates = @(
    'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe',
    'C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe'
  )

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  return $null
}

function Resolve-FromVisualStudio {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $vswherePath = Get-VswherePath
  if ([string]::IsNullOrWhiteSpace($vswherePath)) {
    return $null
  }

  $installJson = & $vswherePath -products * -prerelease -all -format json
  if ([string]::IsNullOrWhiteSpace($installJson)) {
    return $null
  }

  $installations = $installJson | ConvertFrom-Json
  if ($null -eq $installations) {
    return $null
  }

  $orderedInstallations = @($installations | Sort-Object { [version]$_.installationVersion } -Descending)

  foreach ($installation in $orderedInstallations) {
    $basePath = $installation.installationPath
    if ([string]::IsNullOrWhiteSpace($basePath)) {
      continue
    }

    $fullPath = Join-Path -Path $basePath -ChildPath $RelativePath
    if (Test-Path -LiteralPath $fullPath) {
      return $fullPath
    }
  }

  return $null
}

function Resolve-MSBuildPath {
  $fromPath = Resolve-FromPath -ExecutableName 'MSBuild.exe'
  if (-not [string]::IsNullOrWhiteSpace($fromPath)) {
    return [pscustomobject]@{
      Path     = $fromPath
      Resolved = 'PATH'
    }
  }

  $fromVsCurrent = Resolve-FromVisualStudio -RelativePath 'MSBuild\Current\Bin\MSBuild.exe'
  if (-not [string]::IsNullOrWhiteSpace($fromVsCurrent)) {
    return [pscustomobject]@{
      Path     = $fromVsCurrent
      Resolved = 'VisualStudio'
    }
  }

  $fromVs15 = Resolve-FromVisualStudio -RelativePath 'MSBuild\15.0\Bin\MSBuild.exe'
  if (-not [string]::IsNullOrWhiteSpace($fromVs15)) {
    return [pscustomobject]@{
      Path     = $fromVs15
      Resolved = 'VisualStudio'
    }
  }

  return [pscustomobject]@{
    Path     = $null
    Resolved = 'NotFound'
  }
}

function Resolve-VSTestConsolePath {
  $fromPath = Resolve-FromPath -ExecutableName 'vstest.console.exe'
  if (-not [string]::IsNullOrWhiteSpace($fromPath)) {
    return [pscustomobject]@{
      Path     = $fromPath
      Resolved = 'PATH'
    }
  }

  $fromVs = Resolve-FromVisualStudio -RelativePath 'Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe'
  if (-not [string]::IsNullOrWhiteSpace($fromVs)) {
    return [pscustomobject]@{
      Path     = $fromVs
      Resolved = 'VisualStudio'
    }
  }

  return [pscustomobject]@{
    Path     = $null
    Resolved = 'NotFound'
  }
}

$msbuild = Resolve-MSBuildPath
$vstest = Resolve-VSTestConsolePath

$result = [pscustomobject]@{
  Profile               = 'net-framework'
  MSBuildPath           = $msbuild.Path
  VSTestConsolePath     = $vstest.Path
  MSBuildResolvedFrom   = $msbuild.Resolved
  VSTestResolvedFrom    = $vstest.Resolved
  MSBuildFound          = -not [string]::IsNullOrWhiteSpace($msbuild.Path)
  VSTestConsoleFound    = -not [string]::IsNullOrWhiteSpace($vstest.Path)
}

if ($RequireAll) {
  if (-not $result.MSBuildFound) {
    throw 'MSBuild.exe was not found. Install Visual Studio Build Tools or add MSBuild.exe to PATH.'
  }

  if (-not $result.VSTestConsoleFound) {
    throw 'vstest.console.exe was not found. Install Visual Studio Test Platform or add vstest.console.exe to PATH.'
  }
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 5
  exit 0
}

$result
