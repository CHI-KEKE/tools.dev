# Stage 4: Auto-Remediation Loop

## Goal

Automatically remediate low-risk issues from consolidated review results, verify lint/tests/build, and re-run the review until convergence or termination.

## Closed-Loop Definition (Mandatory)

An iteration is considered closed only when all of the following are completed:

1. Auto-fix changes are applied (or explicitly `none`).
2. Verification gate passes or fails with reported evidence.
3. A post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run is completed.
4. Iteration output includes findings deltas and an explicit `continue/stop` decision.

If item 3 is missing, the iteration is incomplete and must not be finalized.

## Loop Execution Contract (Mandatory)

Treat Stage 4 as an actual loop, not a one-time patch step.

- Maintain loop state explicitly in the response (`iteration`, findings counts, delta vs previous iteration, and latest decision).
- After any successful code modification, the next required actions are:
  1. verification (`lint`/tests/build)
  2. post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run
  3. new `continue/stop` decision
- Do not end the overall task immediately after applying fixes, even if the fixes look correct.
- A final response is invalid if it includes applied code fixes but lacks a completed post-fix re-run summary for the same iteration.

## Iteration Algorithm (Execute Literally)

Use this control flow once Stage 4 starts:

1. Start with the latest consolidated findings from Stage 3.
2. Select `auto-fixable` items in priority order (`P1 -> P2 -> P3`).
3. Apply allowed fixes within safety boundaries (or explicitly record `Applied fixes summary: none`).
4. Run verification gate with the selected command set resolved from the target project's `package.json`.
5. If verification fails, stop (hard-stop) and report errors.
6. Re-run `Stage 1 -> Stage 2 -> Stage 3`.
7. Record updated findings counts and delta vs previous iteration.
8. Decide `continue` or `stop` using Section 4.5.
9. If decision is `continue`, start the next iteration immediately (do not wait for user input).

Only exit Stage 4 after Step 8 produces `Decision: stop` or a hard-stop condition blocks Step 4.

## 4.1 Auto-Fix Policy (No Human Selection)

- Automatically select fixes from the consolidated list.
- Apply fixes in priority order: `P1 -> P2 -> P3`.
- Attempt only items classified as `auto-fixable`.

## 4.2 Safety Boundaries (Hard Constraints)

### Allowed (Low-Risk, Auto-Fixable)

- Null checks or guard clauses
- Loading, empty, or error-state fixes that do not change approved UX flows
- Accessibility improvements that do not alter product requirements
- Small styling or layout fixes limited to the changed scope
- API error handling improvements that do not change business logic
- Small refactors limited to the changed scope (no public UI contract changes)
- Unit test additions aligned with the Unit Test Plan

### Disallowed (Needs Human Intervention)

- Public UI contract or information architecture changes
- Authentication or authorization behavior changes
- API contract changes
- Cross-module or large-scale refactors
- Any behavior changes outside the task `Description` scope

### Change Limits Per Iteration

- Max modified files: `N_FILES_MAX` (default `8`)
- Max changed lines: `N_LINES_MAX` (default `300`)
- Stop and require human intervention if either limit is exceeded.

## 4.3 Verification Gate (Required Every Iteration)

After applying fixes:

1. Read and reuse the verification profile selected from `references/prerequisites-and-stop-conditions.md`.
2. Resolve the working directory and package-manager commands with `.github\skills\f2e-nine1-code-review\scripts\get_frontend_verification_profile.ps1 -RequireProject`.
3. If a lint command is available, run it from the returned working directory.
4. If a test command is available, run relevant unit tests from the Unit Test Plan, or run the resolved test command if unspecified.
5. If a build command is available, run it from the same working directory.

If lint, build, or tests fail:

- Stop immediately.
- Report exact errors (include the most relevant excerpt).
- Require human intervention.

## 4.4 Re-Run Review (Self-Review)

After verification passes:

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
- Verification results (lint/test/build pass/fail)
- Post-fix re-run status (`Stage 1/2/3`: pass/fail/blocked) with minimal evidence
- Re-run evidence (finding count deltas and at least one key location/reference, when available)
- Updated consolidated findings (`P1`/`P2`/`P3` counts)
- Decision (`continue` or `stop`) with reason

Use the iteration template in `assets/review-report-template.md`.

### Optional Validation Helper (Recommended Before Final Answer)

Use the helper script to validate the latest iteration block format before finalizing Stage 4:

```powershell
powershell -ExecutionPolicy Bypass -File ".github\skills\f2e-nine1-code-review\scripts\stage4_iteration_check.ps1" -FilePath "<path-to-stage4-report>.md"
```

Options:

- `-AllIterations`: validate every `### Iteration` block, not only the latest one.
- `-PrintTemplate`: print a compliant iteration block template and finalization gate checklist.

If script execution is unavailable, perform the equivalent manual check using the `Stage 4 Finalization Gate` checklist in `assets/review-report-template.md`.
