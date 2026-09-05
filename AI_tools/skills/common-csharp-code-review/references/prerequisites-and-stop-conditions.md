# Prerequisites, Scope, and Stop Conditions

## Required Inputs

- Task description source: Azure DevOps work item `Description` (preferred) or user-provided requirement text if Azure DevOps is unavailable.
- Git working tree code changes for the current task in the current repository.
- Repository baseline instructions: `.github/instructions/repo_code_base.instructions.md`
- Checklist file: `.github/checklists/code-implementation-checklist.md`
- Dify script: `.github/skills/common-csharp-code-review/scripts/dify_code_review_request.ps1` (required for `full` depth only)
- For auto-remediation: latest iteration evidence for post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run (required for `full` depth only)
- Optional: `reviewDepth` parameter (`full` or `review-only`, default: `full`)
- Optional: baseline ref from a previous task review (for incremental diff mode)
- Optional: cached repo context from a previous review in the same session (for skipping redundant file reads)

Stop and ask for scope or implementation completion if there are no relevant code changes to review.

## Review Depth Parameter

### Behavior

**CRITICAL: Dify (Stage 2) and Consolidation (Stage 3) run in BOTH modes.** The ONLY difference is Stage 4.

| Step | `review-only` | `full` |
|------|--------------|--------|
| Stage 1: Requirements + Checklist | ✅ RUN | ✅ RUN |
| Stage 2: Dify code review | **✅ RUN** | ✅ RUN |
| Stage 3: Consolidate findings | **✅ RUN** | ✅ RUN |
| Stage 4: Build + Test + Auto-fix | ❌ SKIP | ✅ RUN |

### Rules

- When `reviewDepth` is `review-only`:
  - Run Stage 1 completely (requirements, checklist, scope creep).
  - **Run Stage 2 (Dify external code review). This is MANDATORY, not optional.**
  - **Run Stage 3 (consolidation of Stage 1 + Dify findings). This is MANDATORY, not optional.**
  - Format and output the consolidated report.
  - Stop. Do NOT load Stage 4 reference files.
  - Do NOT run build or test commands.
  - Do NOT attempt auto-remediation.
  - Report `Review Depth: review-only` in the output header.
- When `reviewDepth` is `full` or omitted:
  - Run the complete pipeline (original behavior).
  - Report `Review Depth: full` in the output header.
- The `reviewDepth` parameter does not affect diff scope collection, requirements extraction, checklist validation, Dify invocation, or findings consolidation. These ALWAYS run in both modes. Only Stage 4 (build/test/auto-remediation) is controlled by `reviewDepth`.

## Repository Context Cache (Optional, Recommended for Multi-Task Sessions)

### Problem

The following inputs are read and evaluated at the start of every review cycle (Stage 1 Step 0), but their results never change within the same repository session:

1. `.github/instructions/repo_code_base.instructions.md` → verification profile (`net-framework` or `dotnet-cli`)
2. `.github/checklists/code-implementation-checklist.md` → checklist content
3. `get_netfx_tool_paths.ps1 -RequireAll` → resolved MSBuild/VSTest paths (net-framework profile only)

In a multi-task execution with Stage 4 re-runs, these can be re-read 15-20 times with identical results, wasting tool calls and context tokens.

### Solution

When the caller (e.g. executor agent) provides a `repoContext` object, the review skill skips the corresponding file reads and uses the cached values directly.

### Repo Context Object Schema

```
repoContext = {
  verificationProfile: 'net-framework' | 'dotnet-cli',
  checklistContent: '<full text of code-implementation-checklist.md>',
  msbuildPath: '<resolved path or null>',       # only for net-framework
  vstestConsolePath: '<resolved path or null>',  # only for net-framework
  solutionPath: '<resolved .sln path or null>',  # for scoped verification
}
```

### How to Populate (Executor Agent Responsibility)

Before the first task review, the executor agent should:

```
1. Read `.github/instructions/repo_code_base.instructions.md`
2. Determine verificationProfile using the standard rules (below)
3. Read `.github/checklists/code-implementation-checklist.md` → store as checklistContent
4. If verificationProfile is 'net-framework':
   - Run get_netfx_tool_paths.ps1 -RequireAll
   - Store msbuildPath and vstestConsolePath
5. Resolve the primary .sln path in the repo root → store as solutionPath
6. Package all values into a repoContext object
7. Pass repoContext to every subsequent code review invocation (per-task and Final Gate)
```

### How to Consume (Code Review Skill)

In Stage 1 Step 0 ("Initialize Repository Runtime Context"):

- If `repoContext` is provided and complete:
  - Use `repoContext.verificationProfile` directly (skip reading repo_code_base.instructions.md)
  - Use `repoContext.checklistContent` directly in Stage 1 Step 2 (skip reading checklist file)
  - Use `repoContext.msbuildPath` / `repoContext.vstestConsolePath` in Stage 4 verification (skip running get_netfx_tool_paths.ps1)
  - Use `repoContext.solutionPath` in Stage 4 scoped verification (skip .sln discovery)
  - Report in output: `Repo Context: cached (from executor)`
- If `repoContext` is not provided or incomplete:
  - Fall back to reading files and determining profile from scratch (original behavior)
  - Report in output: `Repo Context: fresh`

### Safety Rules

- The repo context cache is valid only within the same repository and the same session. Do not persist or reuse across different repositories or different working sessions.
- If any cached value is missing or suspected invalid, fall back to reading from scratch for that specific value.
- The executor agent must re-populate the cache if the repository is switched or if repo configuration files are modified during the session (which is extremely rare).

## Verification Profile Selection (Run First, Mandatory)

Before Stage 1 and before any Stage 4 verification command:

1. If `repoContext.verificationProfile` is provided, use it directly and skip to step 4.
2. Read `.github/instructions/repo_code_base.instructions.md`.
3. Determine verification profile using these rules:
   - If the file mentions `.NET Framework`, set profile to `net-framework`.
   - Otherwise set profile to `dotnet-cli`.
4. Use commands based on the selected profile and verification scope:
   - `net-framework`:
     - If `repoContext.msbuildPath` and `repoContext.vstestConsolePath` are provided, use them directly. Otherwise resolve full tool paths via `.github/skills/common-csharp-code-review/scripts/get_netfx_tool_paths.ps1` (canonical command below).
     - **Scoped mode (Stage 4 default)**: Build only affected `.csproj` targets. Test only dependent test assemblies. See "Scoped Verification" section.
     - **Full mode (fallback)**: Build the relevant `.sln` (preferred) or affected `.csproj`. Run relevant test assemblies.
     - Do not use `dotnet build`/`dotnet test` as the default path.
   - `dotnet-cli`:
     - **Scoped mode (Stage 4 default)**: Build only affected `.csproj` targets with `dotnet build <project> --no-restore`. Test only relevant test projects with `dotnet test <project> --no-build`.
     - **Full mode (fallback)**: Run `dotnet build`. Run relevant unit tests, or `dotnet test` if no narrower test scope is defined.
5. Report the selected verification profile in review output context.

**Note**: When `reviewDepth` is `review-only`, the verification profile is still determined (for reporting purposes) but no build/test commands are executed.

### Canonical .NET Framework Tool Path Resolution (Required for `net-framework` Profile)

```powershell
$toolPaths = & ".github\skills\common-csharp-code-review\scripts\get_netfx_tool_paths.ps1" -RequireAll

$msbuildPath = $toolPaths.MSBuildPath
$vstestConsolePath = $toolPaths.VSTestConsolePath
```

Rules:

- Do not hardcode machine-specific Visual Studio installation paths inline.
- Use `$msbuildPath` and `$vstestConsolePath` returned by the helper script when running verification commands.
- If `-RequireAll` fails, treat as execution error and stop with actionable error output.
- When repoContext provides these paths, skip running the helper script.

## Git Review Scope Rules (Working Tree Review)

### Scope Mode

Use working-tree review mode (no target branch required):

- Unstaged changes + staged changes (`Included Diffs: unstaged + staged`)
- When a baseline ref is provided by the caller (e.g. executor agent), use incremental mode (`Included Diffs: incremental (baseline: <ref>)`)
- Use the canonical PowerShell helper script below (do not improvise alternative diff collection logic unless the user requests it)

### Canonical PowerShell Diff File Collection (Required)

Use the helper script to collect the combined review scope:

```powershell
$diffScope = & ".github\skills\common-csharp-code-review\scripts\get_included_diffs.ps1"

$unstagedDiffFiles = @($diffScope.UnstagedDiffFiles)
$stagedDiffFiles = @($diffScope.StagedDiffFiles)
$includedDiffFiles = @($diffScope.IncludedDiffFiles)
```

Script path:

- `.github/skills/common-csharp-code-review/scripts/get_included_diffs.ps1`

Optional (machine-readable output):

```powershell
& ".github\skills\common-csharp-code-review\scripts\get_included_diffs.ps1" -AsJson
```

### Incremental Review Mode (Optional)

When reviewing sequential tasks without intermediate commits, pass a baseline ref to scope the diff to only changes made since the previous task review:

```powershell
$diffScope = & ".github\skills\common-csharp-code-review\scripts\get_included_diffs.ps1" `
  -Baseline $baseline

$includedDiffFiles = @($diffScope.IncludedDiffFiles)
```

The baseline ref should be obtained via `git stash create` after the previous task's review completes. `git stash create` is read-only — it creates a tree snapshot and returns a SHA without modifying the working tree, index, or stash list.

Rules:

- When `-Baseline` is omitted, the helper uses full working-tree diff mode (original behavior).
- When `-Baseline` is provided, `$includedDiffFiles` contains only files changed since the baseline snapshot.
- The executor agent is responsible for creating and passing the baseline ref. The code review skill itself does not manage baseline lifecycle.
- Stage 4 auto-remediation iterations within a single task review must NOT use `-Baseline`. They need the full task diff to correctly verify fixes. Baseline is only used at task-to-task boundaries.
- The Final Review Gate (after all tasks) must NOT use `-Baseline`. It reviews all changes as a single unit.

### Helper Usage Split (Filename vs Content)

Use the helpers for different purposes to avoid duplicated logic and unnecessary diff loading:

- `scripts/get_included_diffs.ps1` (filename helper)
  - Use for scope detection, hard-stop checks (`no code changes`), `Files Reviewed` reporting, and any workflow step that only needs file paths/counts.
  - Preferred default for Stage 1 scope setup because it is lighter and returns only filenames + counts.
  - Accepts optional `-Baseline` for incremental mode.
  - **Always used**, regardless of `reviewDepth`.

- `scripts/get_included_diff_content.ps1` (content helper)
  - Use when full staged/unstaged diff text is required (for example Dify request payload construction).
  - Reuses `get_included_diffs.ps1` internally, then adds `StagedDiffText`, `UnstagedDiffText`, and combined `QueryText`.
  - Accepts optional `-Baseline` (passthrough to `get_included_diffs.ps1`).
  - **Only used when `reviewDepth` is `full`** (Stage 2 Dify needs diff content).

Rule:

- Do not use the content helper when only filenames/counts are needed.
- Do not re-implement `git diff` collection inline in other scripts; call the appropriate helper instead.
- When the caller provides a baseline ref, pass `-Baseline` consistently to all helper invocations within the same review cycle.

Rules:

- Treat `$includedDiffFiles` as the authoritative review file set for the current scope (full or incremental).
- If `$includedDiffFiles.Count -eq 0`, trigger the no-code-changes hard stop.
- Use `$includedDiffFiles` as the source set, then derive the C#-related reviewed subset by default and report `Files Reviewed` from the actual reviewed set.

### Files Included

- Prioritize C#-related files from `$includedDiffFiles`.
- C#-related default set includes: `.cs`, `.csproj`, `.props`, `.targets`, `.sln`, `.config`, `appsettings*.json`, `Directory.Build.props`, `Directory.Build.targets`, `global.json`, `nuget.config`.
- Expand to non-C# files only when required by task requirements, clear runtime/build impact, or explicit user request.

### Scope Reporting

Include these fields in the report header:

- Review Mode: `working-tree`
- Review Depth: `full` or `review-only`
- Included Diffs: `unstaged + staged` or `incremental (baseline: <ref>)` — use the value from `$diffScope.IncludedDiffs`
- Repo Context: `cached (from executor)` or `fresh`
- Files Reviewed: list/count based on the actual reviewed set (C#-related subset by default, expanded scope when applicable)

## Hard Stop Conditions

Stop immediately and request clarification or prerequisites when any of these occur:

1. No code changes exist in both unstaged and staged diffs (or in incremental diff when baseline is provided).
2. Task `Description` is missing/empty and no authoritative replacement requirement text is provided.
3. Checklist file is missing and meaningful checks cannot continue (limited checks are allowed only if core requirements can still be validated).
4. Critical requirement ambiguity blocks verification of key behaviors.
5. Any execution error occurs during any step.
6. During auto-remediation (`full` depth only), a disallowed change category is required, change limits are exceeded, or build/test fails.
7. During auto-remediation (`full` depth only), post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run evidence is missing for the latest applied changes.

## Auto-Remediation Loop Configuration

- `MAX_ITERATIONS`: 3
- `NO_IMPROVEMENT_LIMIT`: 1
- `N_FILES_MAX`: 8 (max modified files per iteration)
- `N_LINES_MAX`: 300 (max changed lines per iteration)

**Note**: Auto-remediation only runs when `reviewDepth` is `full`.

## Scoped Verification (Stage 4 Optimization)

### Problem

Full solution builds and full test suite runs are expensive. In Stage 4 auto-remediation,
each iteration typically modifies 1-8 files in 1-3 projects, but verification rebuilds the
entire solution and re-runs all tests. For repositories with 20+ projects, this wastes
60-80% of verification time on unchanged code.

### Solution

Use the `get_affected_projects.ps1` helper to resolve changed files into affected source
projects and their dependent test projects. Build and test only those projects.

### Canonical Usage

```powershell
# Resolve affected projects from the current diff scope
$affected = & ".github\skills\common-csharp-code-review\scripts\get_affected_projects.ps1" `
  -ChangedFiles $includedDiffFiles

# Check if scoped build is possible
if ($affected.FallbackToFullBuild) {
  # Cannot scope — fall back to full solution build
} elseif ($affected.IsScopedBuild) {
  # Scoped build: only affected projects
  # $affected.BuildTargets  — array of .csproj paths to build
  # $affected.TestTargets   — array of test .csproj paths to run
}
```

### Build Commands by Profile

#### `dotnet-cli` profile (scoped)

```powershell
foreach ($target in $affected.BuildTargets) {
  dotnet build $target --no-restore
}
foreach ($testTarget in $affected.TestTargets) {
  dotnet test $testTarget --no-build
}
```

#### `net-framework` profile (scoped)

```powershell
foreach ($target in $affected.BuildTargets) {
  & $msbuildPath $target /p:Configuration=Debug /v:minimal
}
foreach ($testTarget in $affected.TestTargets) {
  & $vstestConsolePath $testAssembly
}
```

### Scoped Verification Rules

1. **Stage 4 iterations**: Always attempt scoped verification first. Fall back to full
   solution build only when `FallbackToFullBuild` is `$true`.
2. **Stage 1/2/3 review** (`review-only` or `full`): Does not run build/test, so scoped verification does not apply.
3. **No-change iterations**: When `Applied fixes summary: none`, skip verification entirely
   and reuse the previous iteration's verification result.
4. **Full solution fallback**: If the affected project set covers >80% of solution projects,
   fall back to full solution build.
5. **Report verification scope**: Always report whether verification was scoped or full.

**Note**: Scoped verification only applies when `reviewDepth` is `full` (Stage 4).

## Quick Closure Checklist

Before marking an auto-remediation iteration as complete (`full` depth only), verify all items below:

- [ ] Applied fixes are summarized (or explicitly `none`).
- [ ] Build result is recorded with the selected verification profile command (or skipped if no changes).
- [ ] Relevant unit test result is recorded with the selected verification profile command (or skipped if no changes).
- [ ] Post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run is completed.
- [ ] Re-run evidence is recorded (counts, locations, and key deltas).
- [ ] Iteration output has a clear `continue` or `stop` decision with reason.
- [ ] Verification scope is reported (`scoped` / `full solution` / `skipped`).

## Execution Rules

- Apply automatic changes only within Stage 4 safety boundaries and only during the auto-remediation loop (`full` depth only).
- Preserve UTF-8 encoding for file operations.
- Keep findings evidence-based with file/line references (or best approximation).
- Stop on execution error and report exact error details, failed step, and recommended next action.
- Do not invent requirements beyond Azure DevOps `Description`.
- Use `[BLOCKED]` for unclear or unverifiable requirements and ask for clarification.
- Prefer an isolated working branch when possible and report what was changed.
- Do not finalize auto-remediation without a completed post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run and iteration evidence.

## Failure Handling

### Checklist File Missing

- Report the missing dependency.
- Continue with requirements-based validation and general best-practice checks only.
- Do not claim checklist coverage.

### Dify Script Missing or Fails

- Report the missing dependency or execution failure.
- Provide requirements + checklist-only results.
- Applies to both `full` and `review-only` modes (Dify runs in both).

### Line References Unavailable

- Provide the best available location reference (file + symbol/function/class name).
- State the limitation explicitly.