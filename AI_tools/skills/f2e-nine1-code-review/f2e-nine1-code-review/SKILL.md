---
name: f2e-nine1-code-review
description: Review working-tree frontend code changes in this repository against Azure DevOps Description requirements, the frontend checklist, and Dify findings, then optionally run a bounded frontend-only auto-remediation loop. Avoid backend service invocation and backend implementation scope.
allowed-tools:
  - run_in_terminal
  - read_file
  - replace_string_in_file
---

## Preconditions

- Working-tree must have unstaged or staged changes
- Azure DevOps Work Item Description must be accessible
- PowerShell execution environment must be available
- All sub-files under the `references/` directory must exist
- Target project's `package.json` must be readable

## Workflow Steps

# F2E Nine1 Code Review

Use this skill to perform a requirements-aware frontend code review for this repository and optionally run a bounded self-fix loop.

Keep the main skill file minimal. Load detailed instructions from `references/` only when needed.

## Quick Start

1. Load `references/prerequisites-and-stop-conditions.md`.
2. Load the frontend verification profile from `scripts/get_frontend_verification_profile.ps1` and use the commands resolved from the target project's `package.json`.
3. Run Stage 1 from `references/stage-1-requirements-checklist.md` (requirements + checklist + scope creep).
4. Run Stage 2 and Stage 3 from `references/stage-2-3-dify-consolidation.md` (Dify + consolidation).
5. Use `assets/review-report-template.md` to format the report output.
6. Run Stage 4 from `references/stage-4-auto-remediation.md` only when auto-remediation is requested or clearly beneficial and within safety bounds.

## Core Rules (Always Apply)

- Treat Azure DevOps work item `Description` as the source of truth for requirements.
- Read the target frontend project's `package.json` through `scripts/get_frontend_verification_profile.ps1` before any lint/test/build step.
- Use working-tree review mode and collect `Included Diffs: unstaged + staged` with the canonical PowerShell commands defined in `references/prerequisites-and-stop-conditions.md`.
- Prioritize frontend-related files in the combined diff set (the detected frontend app's source, styles, tests, locale files, and frontend build/config files first). Broaden scope only when required by task requirements or explicit user request.
- Do not infer missing requirements. Mark unverifiable items as `[BLOCKED]`.
- Keep findings evidence-based with `file:line` references (or best available location).
- Stop immediately on hard-stop conditions, missing prerequisites, or execution errors.
- Apply code changes only inside the Stage 4 safety boundaries.
- Auto-remediation is not complete until a post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run is finished and reported in iteration output.
- Once Stage 4 starts, continue autonomously across iterations (no user confirmation between iterations) until Stage 4 outputs `Decision: stop` or a hard-stop condition blocks progress.
- If the latest action modified code, do not finalize yet; the next actions must be verification and a post-fix `Stage 1 -> Stage 2 -> Stage 3` re-run.

## Reference Map (Progressive Disclosure)

- `references/prerequisites-and-stop-conditions.md`
  - Required inputs, working-tree scope rules, stop conditions, loop config, execution rules, and failure handling.
- `references/stage-1-requirements-checklist.md`
  - Requirements extraction rules, checklist validation workflow, status labels, evidence standards, and scope creep classification.
- `references/stage-2-3-dify-consolidation.md`
  - Dify command, parsing guidance, de-duplication, grouping, priority rules, and consolidated output schema.
- `references/stage-4-auto-remediation.md`
  - Auto-fix policy, safety boundaries, verification gate, loop termination, and per-iteration output requirements.
- `references/examples/`
  - Example Stage 1 report and consolidated/iteration outputs for formatting and tone calibration.
- `scripts/stage4_iteration_check.ps1`
  - Optional helper to validate latest Stage 4 iteration output fields before finalizing (`Applied fixes`, `Verification`, `Post-fix re-run`, `Re-run evidence`, counts, decision, reason).
- `scripts/get_included_diffs.ps1`
  - Canonical PowerShell helper to collect `Included Diffs: unstaged + staged` and return unstaged/staged/combined file sets.
- `scripts/get_included_diff_content.ps1`
  - PowerShell helper that reuses `get_included_diffs.ps1` and returns staged/unstaged full diff text plus combined `QueryText` for Dify.
- `scripts/get_frontend_verification_profile.ps1`
  - PowerShell helper that inspects the target project's `package.json` and lockfiles, then returns the verification profile, working directory, package manager, and available lint/test/build commands.
- `assets/review-report-template.md`
  - Report skeletons for Stage 1 report, consolidated findings list, and iteration output.

## Operating Sequence

1. Check prerequisites and stop gates.
2. Collect changed files from unstaged and staged diffs.
3. Extract requirements from Azure DevOps `Description`.
4. Validate implementation against requirements and checklist.
5. Run Dify review and parse findings conservatively.
6. Merge and prioritize findings into a single list.
7. Format and present the report.
8. If running auto-remediation, fix only allowed low-risk items, verify with the selected package-manager command set resolved from `package.json`, and re-run the review loop until termination conditions are met.
9. Never finalize an auto-remediation run without explicit evidence of the latest post-fix `Stage 1 -> Stage 2 -> Stage 3` results.

## Quick Closure Checklist

Use this checklist before you finalize any auto-remediation run:

- [ ] Latest auto-fix changes are applied (or explicitly `none`).
- [ ] Verification gate executed with the selected package-manager command set resolved from `package.json`.
- [ ] Post-fix re-run completed: Stage 1, Stage 2, Stage 3.
- [ ] Re-run evidence recorded (finding deltas and key `file:line` references).
- [ ] Iteration output includes decision (`continue`/`stop`) and reason.
- [ ] If any code was modified in the latest iteration, the report includes post-fix re-run results before finalization.
- [ ] No unresolved hard-stop condition remains.

## Hard Constraints

- **Frontend scope only**: Must not call backend services or plan backend implementation
- **Evidence-based findings**: Every finding must include a `file:line` reference
- **No inferred requirements**: Mark missing requirements as `[BLOCKED]`; do not self-infer
- **Auto-remediation safety boundary**: Stage 4 only fixes low-risk items; after fixing, Stage 1 → Stage 2 → Stage 3 must be re-run
- **Finalization requires evidence**: Before Stage 4 can be finalized, evidence of the latest post-fix re-run must exist

## Good/Bad Examples

**✅ Good — Specific finding with evidence**
```
• [P1][REQUIREMENTS] Missing loading state handling
  - Requirement: AC2 requires adding a skeleton screen for loading state
  - Evidence: src/components/ProductList.tsx:45 - no loading state check
```

**❌ Bad — Missing file:line evidence**
```
• [P1] Missing loading state — should add
```
(No specific location; cannot pinpoint the problem)

## Quality Checklist

- [ ] Stage 1, Stage 2, Stage 3 all completed
- [ ] All findings include `file:line` evidence
- [ ] Missing requirement items marked as `[BLOCKED]`
- [ ] Report format matches `assets/review-report-template.md`
- [ ] If Auto-remediation was run, all items in Quick Closure Checklist are checked
