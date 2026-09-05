---
name: common-csharp-code-review
description: Use when reviewing working-tree C# changes in this repository against Azure DevOps requirements and repository checklists, including per-task review-only gates, Final Gate validation, and post-implementation self-review.
---

# Nine1 Code Review

Use this skill to perform a requirements-aware C#-focused code review for this repository and optionally run a bounded self-fix loop.

Keep the main skill file minimal. Load detailed instructions from `references/` only when needed.

## Quick Start

1. Load `references/prerequisites-and-stop-conditions.md`.
2. For per-task `review-only`, prefer a bounded caller context: pass cached `repoContext`, pass the latest accepted `baseline` whenever available, and avoid sending whole-story context unless it is required to verify the current task.
3. Check the `reviewDepth` parameter provided by the caller:
   - `review-only`: Run Stage 1 + Stage 3 (consolidation of Stage 1 findings only), then stop. **Skip Stage 2 (Dify) and Stage 4.** Dify is deferred to the caller's Final Gate.
   - `full` (default): Run the complete pipeline (Stage 1 → 2 → 3 → 4 if applicable).
4. Read `.github/instructions/repo_code_base.instructions.md` first and determine verification profile:
   - If `.NET Framework` is present, use `net-framework` verification commands (MSBuild/VSTest or repository-equivalent).
   - Otherwise use `dotnet-cli` verification commands (`dotnet build` / `dotnet test`).
5. Run Stage 1 from `references/stage-1-requirements-checklist.md` (requirements + checklist + scope creep).
6. **If `reviewDepth` is `review-only`**: Skip Stage 2 (Dify). Jump directly to Step 8 (Stage 3 — consolidate Stage 1 findings only), format the report, then STOP. Do NOT proceed to Stage 4.
7. **If `reviewDepth` is `full`**: Run Stage 2 (Dify) from `references/stage-2-3-dify-consolidation.md` with a **5-minute timeout**. If Dify does not respond within 5 minutes, record `⚠️ Dify timeout after 5 min` and continue to Stage 3 with Stage 1 findings only.
8. Run Stage 3 (consolidation) from `references/stage-2-3-dify-consolidation.md`. In `full` mode, consolidate Stage 1 + Dify findings (or Stage 1 only on Dify timeout). In `review-only` mode, consolidate Stage 1 findings only.
9. Use `assets/review-report-template.md` to format the report output.
10. **If `reviewDepth` is `review-only`**: STOP HERE. Do NOT proceed to Stage 4.
11. Run Stage 4 from `references/stage-4-auto-remediation.md` only when auto-remediation is requested or clearly beneficial and within safety bounds.

## Caller Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `reviewDepth` | `full`, `review-only` | `full` | Controls which stages execute. `review-only` runs Stage 1+3 only (no Dify, no build/test/Stage 4). `full` runs all stages including Dify (5-min timeout) and Stage 4. |
| `baseline` | git ref (SHA) | `null` | When provided, limits diff scope to changes since this ref. |
| `repoContext` | object | `null` | Cached repository configuration to skip redundant file reads. |

### `reviewDepth` Behavior

- **`full`** (default): Runs the complete pipeline — Stage 1 → Stage 2 (Dify, 5-min timeout) → Stage 3 → Stage 4 (if applicable). Used for standalone reviews and the Final Review Gate in multi-task execution.
- **`review-only`**: Runs Stage 1 → Stage 3 (consolidation of Stage 1 findings only), then STOPS. Skips Stage 2 (Dify) **and** Stage 4. Does NOT run build, test, or Dify. Used for per-task review in multi-task execution where Dify is deferred to the Final Gate.

| Step | `review-only` | `full` |
|------|--------------|--------|
| Stage 1: Requirements + Checklist | ✅ RUN | ✅ RUN |
| Stage 2: Dify code review | ❌ SKIP | ✅ RUN (5-min timeout) |
| Stage 3: Consolidate findings | ✅ RUN (Stage 1 only) | ✅ RUN (Stage 1 + Dify) |
| Stage 4: Build + Test + Auto-fix | ❌ SKIP | ✅ RUN |

When `reviewDepth` is `review-only`:
- The skill MUST collect diff scope using the canonical helpers.
- When `baseline` is provided, the skill MUST keep the review incremental and MUST NOT re-review already accepted changes unless current evidence requires wider scope.
- The skill MUST validate requirements and checklist (Stage 1).
- The skill MUST detect scope creep (Stage 1).
- The skill MUST skip Stage 2 (Dify). **Do NOT invoke Dify in this mode.**
- The skill MUST merge and consolidate Stage 1 findings only (Stage 3). **This is NOT optional.**
- The skill MUST NOT run build/test or attempt auto-remediation (Stage 4).
- The skill reports `Review Depth: review-only (Stage 1 + 3, Dify deferred)` in the output header.
- The skill outputs the Stage 1 report AND consolidated findings list, but no Dify results and no iteration output.

When `reviewDepth` is `full` and Stage 2 (Dify) times out (> 5 minutes):
- Record `⚠️ Dify timeout after 5 min` in the Stage 2 output section.
- Do NOT retry Dify in the same run.
- Proceed to Stage 3 consolidation using Stage 1 findings only.
- Report `Stage 2 (Dify): timed-out` in the final output.

## Core Rules (Always Apply)

- Treat Azure DevOps work item `Description` as the source of truth for requirements.
- Read `.github/instructions/repo_code_base.instructions.md` at the beginning and use it to select the verification profile (`net-framework` or `dotnet-cli`) before any build/test step.
- Use working-tree review mode and collect diff scope with the canonical PowerShell commands defined in `references/prerequisites-and-stop-conditions.md`. When a baseline ref is provided by the caller, pass `-Baseline` to the diff helpers to limit scope to incremental changes only.
- In bounded per-task `review-only` mode, prefer incremental baseline scope plus caller-provided `repoContext`; widen scope only when the current task cannot be verified from that evidence.
- Report the actual `Included Diffs` value from the diff helper output (`unstaged + staged` for full mode, `incremental (baseline: <ref>)` for incremental mode).
- Prioritize C#-related files in the combined diff set (`.cs` first, then C# support files such as `.csproj`, `.props`, `.targets`, `.sln`, and relevant config files). Broaden scope only when required by task requirements or explicit user request.
- Do not infer missing requirements. Mark unverifiable items as `[BLOCKED]`.
- Keep findings evidence-based with `file:line` references (or best available location).
- Stop immediately on hard-stop conditions, missing prerequisites, or execution errors.
- **Respect `reviewDepth`**: When set to `review-only`, run Stage 1 + Stage 3 (consolidation of Stage 1 findings only), then stop. Skip Stage 2 (Dify) **and** Stage 4. When set to `full`, run all stages; apply a **5-minute timeout** to Stage 2 (Dify) — on timeout record `⚠️ Dify timeout` and proceed with Stage 1 findings only.
- Apply code changes only inside the Stage 4 safety boundaries.
- In Stage 4, use scoped verification by default: build only affected projects and run only relevant test assemblies. Fall back to full solution build only when scoping fails or the affected set exceeds 80% of solution projects. Skip verification entirely when an iteration applies no code changes.
- Auto-remediation is not complete until a post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run is finished and reported in iteration output.
- Once Stage 4 starts, continue autonomously across iterations (no user confirmation between iterations) until Stage 4 outputs `Decision: stop` or a hard-stop condition blocks progress.
- If the latest action modified code, do not finalize yet; the next actions must be verification and a post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run.

## Reference Map (Progressive Disclosure)

- `references/prerequisites-and-stop-conditions.md`
  - Required inputs, `reviewDepth` parameter rules, working-tree scope rules (including incremental baseline mode), stop conditions, loop config, scoped verification rules, execution rules, and failure handling.
- `references/stage-1-requirements-checklist.md`
  - Requirements extraction rules, checklist validation workflow, status labels, evidence standards, scope creep classification, and `review-only` output notes.
- `references/stage-2-3-dify-consolidation.md`
  - Dify command, parsing guidance, de-duplication, grouping, priority rules, and consolidated output schema. Stage 2 (Dify) **runs in `full` mode only** (5-min timeout). Stage 3 (consolidation) **runs in both modes** (consolidates Stage 1+Dify in `full`; Stage 1 only in `review-only`).
- `references/stage-4-auto-remediation.md`
  - Auto-fix policy, safety boundaries, scoped verification gate, loop termination, and per-iteration output requirements. **Skipped when `reviewDepth` is `review-only`.**
- `references/examples/`
  - Example Stage 1 report (full, incremental, and review-only modes) and consolidated/iteration outputs for formatting and tone calibration.
- `scripts/stage4_iteration_check.ps1`
  - Optional helper to validate latest Stage 4 iteration output fields before finalizing.
- `scripts/get_included_diffs.ps1`
  - Canonical PowerShell helper to collect diff file sets. Supports optional `-Baseline` parameter for incremental review mode.
- `scripts/get_included_diff_content.ps1`
  - PowerShell helper that reuses `get_included_diffs.ps1` and returns full diff text plus combined `QueryText` for Dify. Supports optional `-Baseline` passthrough.
- `scripts/get_netfx_tool_paths.ps1`
  - PowerShell helper to resolve full paths for `MSBuild.exe` and `vstest.console.exe` when verification profile is `net-framework`.
- `scripts/get_affected_projects.ps1`
  - PowerShell helper to resolve changed files into affected `.csproj` build targets and dependent test projects. Used by Stage 4 for scoped verification.
- `assets/review-report-template.md`
  - Report skeletons for Stage 1 report (full and review-only), consolidated findings list, and iteration output.

## Operating Sequence

1. Check `reviewDepth` parameter (default: `full`).
2. Check prerequisites and stop gates.
3. Collect changed files from the diff scope (full or incremental depending on whether a baseline ref is provided).
4. Extract requirements from Azure DevOps `Description`.
5. Validate implementation against requirements and checklist (Stage 1).
6. **If `reviewDepth` is `full`**: Run Dify review with **5-minute timeout** (Stage 2). On timeout, record `⚠️ Dify timeout after 5 min` and proceed.
   **If `reviewDepth` is `review-only`**: SKIP Stage 2 (Dify) entirely.
7. Merge and prioritize findings into a single list (Stage 3). Use Stage 1 + Dify findings in `full` mode; Stage 1 findings only in `review-only` mode or after Dify timeout.
8. Format and present the report.
9. **If `reviewDepth` is `review-only`**: STOP HERE. Do NOT proceed to Stage 4.
10. If running auto-remediation, fix only allowed low-risk items, verify with scoped build/test (or full solution as fallback), and re-run the review loop until termination conditions are met (Stage 4).
11. Never finalize an auto-remediation run without explicit evidence of the latest post-fix `Stage 1 -> Stage 2 -> Stage 3` results.

## Quick Closure Checklist

Use this checklist before you finalize any auto-remediation run (Stage 4, `full` depth only):

- [ ] Latest auto-fix changes are applied (or explicitly `none`).
- [ ] Verification gate executed with the selected profile command set and appropriate scope (`scoped` / `full` / `skipped`).
- [ ] Post-fix re-run completed: Stage 1, Stage 2 (or `⚠️ Dify timeout` recorded), Stage 3.
- [ ] Re-run evidence recorded (finding deltas and key `file:line` references).
- [ ] Iteration output includes verification scope, decision (`continue`/`stop`) and reason.
- [ ] If any code was modified in the latest iteration, the report includes post-fix re-run results before finalization.
- [ ] No unresolved hard-stop condition remains.