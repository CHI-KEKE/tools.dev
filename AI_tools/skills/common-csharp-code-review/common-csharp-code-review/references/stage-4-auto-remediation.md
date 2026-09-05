# Stage 4: Auto-Remediation Loop

## Goal

Automatically remediate low-risk issues from consolidated review results, verify the build/tests, and re-run the review until convergence or termination.

## Closed-Loop Definition (Mandatory)

An iteration is considered closed only when all of the following are completed:

1. Auto-fix changes are applied (or explicitly `none`).
2. Verification gate passes, fails with reported evidence, or is explicitly skipped (no-change iteration).
3. A post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run is completed.
4. Iteration output includes findings deltas and an explicit `continue/stop` decision.

If item 3 is missing, the iteration is incomplete and must not be finalized.

## Loop Execution Contract (Mandatory)

Treat Stage 4 as an actual loop, not a one-time patch step.

- Maintain loop state explicitly in the response (`iteration`, findings counts, delta vs previous iteration, and latest decision).
- After any successful code modification, the next required actions are:
  1. verification (`build`/tests) — scoped or full
  2. post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run
  3. new `continue/stop` decision
- Do not end the overall task immediately after applying fixes, even if the fixes look correct.
- A final response is invalid if it includes applied code fixes but lacks a completed post-fix re-run summary for the same iteration.

## Iteration Algorithm (Execute Literally)

Use this control flow once Stage 4 starts:

1. Start with the latest consolidated findings from Stage 3.
2. Select `auto-fixable` items in priority order (`P1 -> P2 -> P3`).
3. Apply allowed fixes within safety boundaries (or explicitly record `Applied fixes summary: none`).
4. Run verification gate:
   - If `Applied fixes summary: none`, skip verification (no-change fast path).
   - Otherwise, resolve affected projects and run scoped verification.
   - Fall back to full solution build only when scoping fails or affected set is too large (>80% of solution).
5. If verification fails, stop (hard-stop) and report errors.
6. Re-run `Stage 1 -> Stage 2 -> Stage 3`.
7. Record updated findings counts and delta vs previous iteration.
8. Decide `continue` or `stop` using Section 4.5.
9. If decision is `continue`, start the next iteration immediately (do not wait for user input).

Only exit Stage 4 after Step 8 produces `Decision: stop` or a hard-stop condition blocks Step 4/5.

## 4.1 Auto-Fix Policy (No Human Selection)

- Automatically select fixes from the consolidated list.
- Apply fixes in priority order: `P1 -> P2 -> P3`.
- Attempt only items classified as `auto-fixable`.

## 4.2 Safety Boundaries (Hard Constraints)

### Allowed (Low-Risk, Auto-Fixable)

- Null checks or guard clauses
- Non-sensitive logging improvements
- Exception handling improvements that do not change business logic
- Small refactors limited to the changed scope (no public contract changes)
- Unit test additions aligned with the Unit Test Plan

### Disallowed (Needs Human Intervention)

- Public API or contract changes
- Authentication or authorization behavior changes
- Data schema migrations or persistence model changes
- Cross-module or large-scale refactors
- Any behavior changes outside the task `Description` scope

### Change Limits Per Iteration

- Max modified files: `N_FILES_MAX` (default `8`)
- Max changed lines: `N_LINES_MAX` (default `300`)
- Stop and require human intervention if either limit is exceeded.

## 4.3 Verification Gate (Required Every Iteration)

### No-Change Fast Path

If the current iteration applied zero code changes (`Applied fixes summary: none`):

- Skip build and test execution entirely.
- Reuse the previous iteration's verification result.
- Report: `Verification scope: skipped (no changes)`
- Report: `Verification: skipped (no changes), previous: [profile] build [pass/fail], tests [pass/fail]`
- Proceed directly to the post-fix re-run (Stage 1 → 2 → 3).

### Scoped Verification (Default for Stage 4)

When code changes were applied, use scoped verification:

1. Read and reuse the verification profile selected from `references/prerequisites-and-stop-conditions.md`.
2. Resolve affected projects using the helper script:
   ```powershell
   $affected = & ".github\skills\common-csharp-code-review\scripts\get_affected_projects.ps1" `
     -ChangedFiles $includedDiffFiles
   ```
   If `repoContext.solutionPath` is available, pass it:
   ```powershell
   $affected = & ".github\skills\common-csharp-code-review\scripts\get_affected_projects.ps1" `
     -ChangedFiles $includedDiffFiles `
     -SolutionPath $repoContext.solutionPath
   ```
3. If `$affected.FallbackToFullBuild` is `$true`, use full solution build (see "Full Solution Fallback" below).
4. If `$affected.IsScopedBuild` is `$true`:

   **`dotnet-cli` profile:**
   ```powershell
   foreach ($target in $affected.BuildTargets) {
     dotnet build $target --no-restore
   }
   foreach ($testTarget in $affected.TestTargets) {
     dotnet test $testTarget --no-build
   }
   ```

   **`net-framework` profile:**
   ```powershell
   foreach ($target in $affected.BuildTargets) {
     & $msbuildPath $target /p:Configuration=Debug /v:minimal
   }
   # Resolve and run test assemblies for each test project
   foreach ($testTarget in $affected.TestTargets) {
     # Resolve output assembly from .csproj OutputPath/AssemblyName
     & $vstestConsolePath $testAssembly
   }
   ```

5. Report verification scope in iteration output:
   - `Verification scope: scoped (N build targets, M test targets)`
   - `Verification: [profile] build [pass/fail], tests [pass/fail]`

### Full Solution Fallback

Use full solution build when:
- `$affected.FallbackToFullBuild` is `$true` (changed files cannot be mapped to projects, or affected set exceeds 80% of solution).
- The scoped build fails with a dependency resolution error (retry with full build once before treating as hard-stop).

Commands remain unchanged from the original specification:
- `net-framework`: Run `$msbuildPath` on the `.sln`. Run `$vstestConsolePath` on relevant test assemblies.
- `dotnet-cli`: Run `dotnet build`. Run `dotnet test`.

Report: `Verification scope: full solution (fallback)`

### Failure Handling

If build or tests fail:

- Stop immediately.
- Report exact errors (include the most relevant excerpt).
- Include verification scope in the error report (scoped vs full).
- If scoped build failed with a dependency error (not a code error), retry once with full solution build before treating as hard-stop.
- Require human intervention for confirmed failures.

## 4.4 Re-Run Review (Self-Review)

After verification passes (or is skipped for no-change iterations):

1. Re-run Stage 1 -> Stage 2 -> Stage 3.
2. Compare current findings with the previous iteration.
3. Record evidence snippets (for example: finding count deltas, key location references, or Dify summary) in the iteration output.

Expectations:

- `P1` and `P2` counts should decrease, or remain stable only with clear justification.
- Do not introduce new `P1` issues.
- If counts changed, cite the delta explicitly (for example `P2: 3 -> 1`) in the iteration output.

## 4.5 Loop Stop Conditions (Termination)

Stop the loop when any of these is true:

- All `P1` issues are resolved and verification passes, and remaining issues are acceptable (`P2`/`P3` only), or no issues remain.
- No meaningful improvement occurs for `NO_IMPROVEMENT_LIMIT` iteration(s).
- A disallowed change category is required to proceed.
- Change limits are exceeded.
- Build or tests fail.
- Iteration count reaches `MAX_ITERATIONS`.
- Latest iteration does not include a completed post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run (must continue until completed, unless blocked by hard-stop condition).

### Decision Guardrails (Prevent Premature Stop)

- `Decision: stop` is not allowed immediately after code edits unless:
  - verification failed (hard-stop), or
  - a post-fix re-run has completed for the same iteration and Section 4.5 stop conditions are satisfied.
- If the latest iteration reports `Applied fixes summary` with real file changes and verification passed, but no post-fix re-run evidence exists yet, the decision must be `continue`.

## 4.6 Iteration Output (Required)

For each iteration, report:

- Iteration number
- Applied fixes summary (file list plus brief change summary)
- Verification scope (`scoped (N build, M test)` / `full solution (fallback)` / `skipped (no changes)`)
- Verification results (build/test pass/fail, or `skipped` with previous result reference)
- Post-fix re-run status (`Stage 1/2/3`: pass/fail/blocked) with minimal evidence
- Re-run evidence (finding count deltas and at least one key location/reference, when available)
- Updated consolidated findings (`P1`/`P2`/`P3` counts)
- Decision (`continue` or `stop`) with reason

Use the iteration template in `assets/review-report-template.md`.

### Optional Validation Helper (Recommended Before Final Answer)

Use the helper script to validate the latest iteration block format before finalizing Stage 4:

```powershell
powershell -ExecutionPolicy Bypass -File ".github\skills\common-csharp-code-review\scripts\stage4_iteration_check.ps1" -FilePath "<path-to-stage4-report>.md"
```

Options:

- `-AllIterations`: validate every `### Iteration` block, not only the latest one.
- `-PrintTemplate`: print a compliant iteration block template and finalization gate checklist.

If script execution is unavailable, perform the equivalent manual check using the `Stage 4 Finalization Gate` checklist in `assets/review-report-template.md`.