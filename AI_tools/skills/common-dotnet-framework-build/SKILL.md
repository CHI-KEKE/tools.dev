---
name: common-dotnet-framework-build
description: >
  Executes MSBuild to build .NET Framework projects and solutions on Windows.
  Use this skill whenever the user wants to build, compile, or rebuild a .NET Framework
  project (.csproj, .vbproj) or solution (.sln) using MSBuild — even if they just say
  "build my project", "compile this", "run msbuild", or "why won't my project build".
  Handles finding the correct MSBuild.exe path across Visual Studio versions, selecting
  build configuration (Debug/Release), passing MSBuild properties, and surfacing build
  errors clearly. Trigger this skill any time .NET Framework build commands or MSBuild
  invocations are involved.
---

# .NET Framework Build Skill

This skill helps you locate MSBuild and build .NET Framework projects and solutions on
Windows using PowerShell or cmd.

---

## Step 1 — Find MSBuild.exe

MSBuild ships with Visual Studio. The path depends on the installed VS version and edition.

### Preferred: use vswhere.exe (works for VS 2017+)

```powershell
$msbuild = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
    -latest -requires Microsoft.Component.MSBuild `
    -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1

if (-not $msbuild) { Write-Error "MSBuild not found via vswhere." }
else { Write-Host "Found: $msbuild" }
```

### Fallback: well-known paths

Check in this order until one resolves:

| VS Version | Typical Path |
|---|---|
| VS 2022 (any edition) | `C:\Program Files\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe` |
| VS 2019 | `C:\Program Files (x86)\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe` |
| VS 2017 | `C:\Program Files (x86)\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe` |
| Standalone MSBuild 14 | `C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe` |

Use `Resolve-Path` with a wildcard to handle unknown editions (Community / Professional / Enterprise):

```powershell
$msbuild = Resolve-Path "C:\Program Files\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe" `
           -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path
```

Tell the user which path was found, or ask them to confirm if you can't resolve it automatically.

---

## Step 2 — Determine build target

**Target file**: path to `.sln` or `.csproj` / `.vbproj`. If the user didn't specify, scan
the current directory for `.sln` files first, then project files. If multiple are found, ask.

**Platform**: usually `"Any CPU"` for managed code; use `x86` or `x64` only if the user
explicitly requests it or the project requires it.

## Step 3 — Determine build configuration

Check whether the user has **explicitly specified** a configuration (e.g. "build with Release",
"use Staging", "Release 組態"):

- **User specified a configuration**: use it and proceed to Step 3b to detect region variants.
- **No configuration specified**: default to `Debug`, inform the user briefly, then skip
  Step 3b entirely and proceed directly to Step 4.

```
Using configuration: Debug (default)
```

---

## Step 3b — Detect region/environment variants

> **Only execute this step if the user explicitly specified a configuration in Step 3.**
> If the default Debug path was taken, skip this step entirely and go to Step 4.

Some projects use region- or environment-specific config files with a three-part naming
pattern: `<BaseName>.<Configuration>.<Region>.config`
(e.g. `AppSettings.Debug.HK.config`, `ConnectionStrings.PP.MY.config`).

After the user specifies a configuration, scan the project root (and sub-directories one level
deep) for config files matching that pattern:

```powershell
$projectDir = Split-Path $targetFile
$regionFiles = Get-ChildItem $projectDir -Recurse -Depth 1 -Filter "*.config" |
    Where-Object { $_.Name -match "^.+\.$([regex]::Escape($config))\.[A-Z]{2,4}\.config$" }

$regions = $regionFiles |
    ForEach-Object { ($_.Name -split '\.') | Select-Object -Last 2 | Select-Object -First 1 } |
    Sort-Object -Unique
```

The regex `^.+\.<Config>\.[A-Z]{2,4}\.config$` matches filenames where the second-to-last
segment (before `.config`) is a short uppercase region code (2–4 letters: HK, MY, PX, TW, SG…).

**If regions are found**, present a second selection menu:

```
Region-specific configs detected for 'Debug':
  [1] HK
  [2] MY
  [3] PX
  [N] No region (build without region override)

Which region do you want to target? (default: N — no region)
```

Wait for the user's choice, then pass the region as an MSBuild property:
- If a region is selected: add `/p:Region=HK` (or whichever region) to the MSBuild call
- If no region is selected: omit the `/p:Region` property entirely

**If no region-specific configs are found**, skip this step silently and proceed to Step 4.

---

## Step 4 — Run MSBuild

Basic invocation (no region):

```powershell
& $msbuild $targetFile `
    /p:Configuration=Release `
    /p:Platform="Any CPU" `
    /m `
    /nologo `
    /verbosity:minimal
```

With region override:

```powershell
& $msbuild $targetFile `
    /p:Configuration=Debug `
    /p:Platform="Any CPU" `
    /p:Region=HK `
    /m `
    /nologo `
    /verbosity:minimal
```

Key flags:
- `/m` — parallel build (uses all CPU cores); safe to always include
- `/verbosity:minimal` — clean output showing only warnings and errors; use `detailed` if
  you need to diagnose a tricky failure
- `/t:Rebuild` — add only if the user asks for a full clean rebuild
- `/p:OutputPath=...` — add only if the user wants a custom output folder

Run with `2>&1` to capture both stdout and stderr:

```powershell
$regionProp = if ($region) { "/p:Region=$region" } else { $null }
$output = & $msbuild $targetFile /p:Configuration=$config /p:Platform=$platform $regionProp /m /nologo /verbosity:minimal 2>&1
$exitCode = $LASTEXITCODE
```

**IMPORTANT: always capture `$LASTEXITCODE` immediately after the MSBuild call** (the next
PowerShell statement resets it). Never infer success or failure from text parsing alone —
MSBuild installed with a non-English Visual Studio (Chinese, Japanese, etc.) does NOT output
"Build succeeded" in English; the summary line is localised or may be absent entirely
when piped to a variable. `$exitCode -eq 0` is the single reliable indicator.

---

## Step 5 — Report results

**Determine success/failure using `$exitCode` only:**

```powershell
if ($exitCode -eq 0) {
    # SUCCESS
    $warnings = @($output | Where-Object { $_ -match ': warning ' })
    Write-Host "✅ Build succeeded"
    Write-Host "Warnings: $($warnings.Count)"
    # Show output binaries (lines containing " -> ")
    $output | Where-Object { $_ -match ' -> ' } | ForEach-Object { Write-Host $_ }
} else {
    # FAILURE
    $errors = @($output | Where-Object { $_ -match ': error ' -or $_ -match '^MSBUILD : error' })
    Write-Host "❌ Build failed  (exit code $exitCode)"
    Write-Host "Errors: $($errors.Count)"
    $errors | ForEach-Object { Write-Host $_ }
}
```

Do **not** use `Select-String "Build succeeded"` or `Select-String "建置成功"` for success
detection — these are unreliable across locales and verbosity levels.

**On success** (`$exitCode -eq 0`):
- Confirm the build succeeded
- Show binary output lines (the `->` lines from MSBuild output)
- State the default output path: `bin\<Configuration>\`
- Summarise warning count; if > 500 warnings, note the most common warning code

**On failure** (`$exitCode -ne 0`):
- Show only lines matching `: error ` or `^MSBUILD : error`
- Group errors by project if building a solution
- Offer the most likely fix based on the error code:

| Common error | Likely cause & fix |
|---|---|
| `MSB3644` | Target framework not installed — install the matching .NET Framework targeting pack |
| `MSB3821` | File is locked or path too long — check for open handles or enable long paths |
| `CS0246` / `BC30002` | Missing type — check NuGet packages are restored (`nuget restore` or add `/restore` flag) |
| `MSB4019` | Missing SDK or import target — reinstall Visual Studio workload |
| `The system cannot find the path` | Wrong project path — double-check the path passed in |

If the user didn't run NuGet restore and errors look package-related, suggest:

```powershell
nuget restore $solutionFile
# or use MSBuild's built-in restore:
& $msbuild $solutionFile /t:Restore /p:Configuration=$config
```

---

## Tips

- If the user is in VS Developer PowerShell or Developer Command Prompt, MSBuild is already
  on `$PATH` — you can just call `msbuild` directly without resolving the path.
- For SDK-style projects (newer format with `<Project Sdk="Microsoft.NET.Sdk">`), prefer
  `dotnet build` instead — this skill is optimised for classic `.csproj` / `packages.config`
  style .NET Framework projects.
- When building on a CI agent (Azure Pipelines, GitHub Actions), the `MSBuild` task or
  `dotnet` CLI is usually pre-configured; MSBuild path resolution is typically not needed.
