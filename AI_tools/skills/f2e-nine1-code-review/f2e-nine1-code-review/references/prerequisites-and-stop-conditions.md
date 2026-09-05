# Prerequisites, Scope, and Stop Conditions

## Required Inputs

- Task description source: Azure DevOps work item `Description` (preferred) or user-provided requirement text if Azure DevOps is unavailable.
- Git working tree frontend code changes for the current task in the current repository.
- Checklist file: `.github/checklists/code-implementation-checklist.md`
- Dify script: `.github/skills/f2e-nine1-code-review/scripts/dify_code_review_request.ps1`
- For auto-remediation: latest iteration evidence for post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run

Stop and ask for scope or implementation completion if there are no relevant code changes to review.

## Verification Profile Selection (Run First, Mandatory)

Before Stage 1 and before any Stage 4 verification command:

1. Resolve the frontend verification profile with `.github/skills/f2e-nine1-code-review/scripts/get_frontend_verification_profile.ps1`.
2. Use the returned repository root, working directory, package manager, and commands resolved from the current repo's target frontend `package.json`.
3. Report the selected verification profile in review output context.

### Canonical Frontend Verification Profile Resolution

```powershell
$profile = & ".github\skills\f2e-nine1-code-review\scripts\get_frontend_verification_profile.ps1" -RequireProject

$repositoryRoot = $profile.RepositoryRoot
$workingDirectory = $profile.WorkingDirectory
$packageManager = $profile.PackageManager
$lintCommand = $profile.LintCommand
$testCommand = $profile.TestCommand
$buildCommand = $profile.BuildCommand
```

Rules:

- Do not hardcode a frontend working directory inline when the helper can resolve it from the current repo.
- Use the working directory and commands returned by the helper script when running verification commands.
- If `-RequireProject` fails, treat as execution error and stop with actionable error output.

## Git Review Scope Rules (Working Tree Review)

### Scope Mode

Use working-tree review mode (no target branch required):

- Unstaged changes + staged changes (`Included Diffs: unstaged + staged`)
- Use the canonical PowerShell helper script below (do not improvise alternative diff collection logic unless the user requests it)

### Canonical PowerShell Diff File Collection (Required)

Use the helper script to collect the combined review scope:

```powershell
$diffScope = & ".github\skills\f2e-nine1-code-review\scripts\get_included_diffs.ps1"

$unstagedDiffFiles = @($diffScope.UnstagedDiffFiles)
$stagedDiffFiles = @($diffScope.StagedDiffFiles)
$includedDiffFiles = @($diffScope.IncludedDiffFiles)
```

Script path:

- `.github/skills/f2e-nine1-code-review/scripts/get_included_diffs.ps1`

Optional (machine-readable output):

```powershell
& ".github\skills\f2e-nine1-code-review\scripts\get_included_diffs.ps1" -AsJson
```

### Helper Usage Split (Filename vs Content)

Use the helpers for different purposes to avoid duplicated logic and unnecessary diff loading:

- `scripts/get_included_diffs.ps1` (filename helper)
  - Use for scope detection, hard-stop checks (`no code changes`), `Files Reviewed` reporting, and any workflow step that only needs file paths/counts.
  - Preferred default for Stage 1 scope setup because it is lighter and returns only filenames + counts.

- `scripts/get_included_diff_content.ps1` (content helper)
  - Use when full staged/unstaged diff text is required (for example Dify request payload construction).
  - Reuses `get_included_diffs.ps1` internally, then adds `StagedDiffText`, `UnstagedDiffText`, and combined `QueryText`.

Rule:

- Do not use the content helper when only filenames/counts are needed.
- Do not re-implement `git diff` collection inline in other scripts; call the appropriate helper instead.

Rules:

- Treat `$includedDiffFiles` as the authoritative review file set for `Included Diffs: unstaged + staged`.
- If `$includedDiffFiles.Count -eq 0`, trigger the no-code-changes hard stop.
- Use `$includedDiffFiles` as the source set, then derive the frontend-related reviewed subset by default and report `Files Reviewed` from the actual reviewed set.

### Files Included

- Prioritize the detected frontend app and frontend-related files from `$includedDiffFiles`.
- Frontend-related default set includes: `.ts`, `.tsx`, `.js`, `.jsx`, `.css`, `.scss`, `.sass`, `.less`, `.json`, `.html`, `.mjml`, `package.json`, lockfiles, `tsconfig*.json`, `webpack*.js`, `vitest.config.*`, `tailwind.config.js`, `postcss.config.js`, `.eslintrc.*`, `.prettierrc.*`, and locale files under the detected frontend app.
- Expand to non-frontend files only when required by task requirements, clear runtime/build impact, or explicit user request.

### Scope Reporting

Include these fields in the report header:

- Review Mode: `working-tree`
- Included Diffs: `unstaged + staged`
- Files Reviewed: list/count based on the actual reviewed set (frontend-related subset by default, expanded scope when applicable)

## Hard Stop Conditions

Stop immediately and request clarification or prerequisites when any of these occur:

1. No code changes exist in both unstaged and staged diffs.
2. Task `Description` is missing/empty and no authoritative replacement requirement text is provided.
3. Checklist file is missing and meaningful checks cannot continue (limited checks are allowed only if core requirements can still be validated).
4. Critical requirement ambiguity blocks verification of key behaviors.
5. Any execution error occurs during any step.
6. During auto-remediation, a disallowed change category is required, change limits are exceeded, or lint/test/build fails.
7. During auto-remediation, post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run evidence is missing for the latest applied changes.

## Auto-Remediation Loop Configuration

- `MAX_ITERATIONS`: 3
- `NO_IMPROVEMENT_LIMIT`: 1
- `N_FILES_MAX`: 8 (max modified files per iteration)
- `N_LINES_MAX`: 300 (max changed lines per iteration)

## Quick Closure Checklist

Before marking an auto-remediation iteration as complete, verify all items below:

- [ ] Applied fixes are summarized (or explicitly `none`).
- [ ] Lint result is recorded with the selected verification profile command.
- [ ] Relevant unit test result is recorded with the selected verification profile command.
- [ ] Build result is recorded with the selected verification profile command.
- [ ] Post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run is completed.
- [ ] Re-run evidence is recorded (counts, locations, and key deltas).
- [ ] Iteration output has a clear `continue` or `stop` decision with reason.

## Execution Rules

- Apply automatic changes only within Stage 4 safety boundaries and only during the auto-remediation loop.
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

### Line References Unavailable

- Provide the best available location reference (file + symbol/function/class name).
- State the limitation explicitly.
