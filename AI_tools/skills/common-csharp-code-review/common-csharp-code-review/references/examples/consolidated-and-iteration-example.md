# Example: Per-Task Review, Consolidated Findings, and Iteration Output

Use this as a compact example for per-task review-only mode (Stage 1 + 2 + 3), Final Gate consolidated findings, and Stage 4 iteration reporting. Keep issue summaries evidence-based and aligned with actual review results.

## Example Per-Task Report (review-only mode)

This example shows what a per-task review produces when invoked with `reviewDepth: review-only`. It includes Stage 1 (requirements + checklist), Stage 2 (Dify), and Stage 3 (consolidated findings), but no build/test or auto-remediation.

```markdown
## Code Review Report
Date: 2026-02-25
Review Mode: working-tree
Review Depth: review-only
Included Diffs: incremental (baseline: a1b2c3d)
Files Reviewed: 3
Verification Profile: dotnet-cli
Iteration: 0 (initial review)

### Summary
- Merge-ready: Deferred (pending Final Gate)
- Priority counts: P1 = 0, P2 = 2, P3 = 1
- Major risks:
  - Missing test for expired-token scenario (deferred to Final Gate for build verification).
  - Possible null dereference flagged by Dify (needs human confirmation).

### Part 1: Requirements Validation (from Azure DevOps Description)

#### Requirements Summary (condensed)
- Scope summary:
  - Standardize `401` response behavior for live session APIs.
- Key behaviors / acceptance points:
  - Return `401` for invalid or expired auth token.
  - Response body should follow existing error contract.
- Testing expectations:
  - Add unit/integration coverage for unauthorized access cases.

#### Traceability
- Source: Azure DevOps Work Item Description
- Requirement sections used: Context & Scope, Work Summary, Key Implementation Logic, Unit Test Plan

#### Validation Findings
1. [P2] [PARTIAL] Requirement (Unit Test Plan): "add unauthorized test cases" - evidence: `tests/Auth/LiveSessionsControllerTests.cs:87` - missing expired-token scenario - add a test that asserts `401` and error payload for expired token.

### Part 2: Checklist Findings
#### Other Checklist Issues
1. [P3] Logging does not include correlation context for unauthorized branch - evidence: `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:139` - include request/session identifier in warning log.

### Part 3: Scope Creep
#### Type 1: Necessary extensions
1. Added auth warning log line - `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:139` - acceptable if kept non-sensitive.

### Consolidated Findings
1. Issue: Missing automated test for expired-token unauthorized scenario.
   Priority: P2
   Source: requirements
   Location: `tests/Auth/LiveSessionsControllerTests.cs:87`
   Suggested fix: Add a test that asserts `401` and the standard error payload when token validation reports expired.
   Fix classification: auto-fixable

2. Issue: Dify flagged possible null dereference when reading user context before auth guard completes.
   Priority: P2
   Source: dify
   Location: location unknown (likely `LiveSessionsController.GetLiveSession*`)
   Suggested fix: Confirm execution order and add a guard clause before dereferencing user context in unauthorized branches.
   Fix classification: needs-human

3. Issue: Logging does not include correlation context for unauthorized branch.
   Priority: P3
   Source: checklist
   Location: `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:139`
   Suggested fix: Include request/session identifier in warning log if available.
   Fix classification: auto-fixable

---
**Note**: This is a per-task review (Stage 1 + 2 + 3, review-only). Build/test verification
and auto-remediation (Stage 4) are deferred to the Final Review Gate after all tasks complete.
P2/P3 findings listed above will be re-evaluated in the Final Gate's full review.
```

## Example Consolidated Findings (Stage 3 — Final Gate)

The Final Gate re-runs Stage 1 + 2 + 3 on the FULL change set (all tasks combined), then proceeds to Stage 4. The consolidated findings may differ from per-task results because cross-task interactions are now visible.

```markdown
### Consolidated Findings
1. Issue: Unauthorized response path returns non-standard error payload for expired token case.
   Priority: P2
   Source: requirements, checklist
   Location: `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:142`
   Suggested fix: Replace ad-hoc anonymous response object with the shared error response factory/model used by auth endpoints.
   Fix classification: auto-fixable

2. Issue: Missing automated test for expired-token unauthorized scenario.
   Priority: P2
   Source: requirements
   Location: `tests/Auth/LiveSessionsControllerTests.cs:87`
   Suggested fix: Add a test that asserts `401` and the standard error payload when token validation reports expired.
   Fix classification: auto-fixable

3. Issue: Dify flagged possible null dereference when reading user context before auth guard completes.
   Priority: P2
   Source: dify
   Location: location unknown (likely `LiveSessionsController.GetLiveSession*`)
   Suggested fix: Confirm execution order and add a guard clause before dereferencing user context in unauthorized branches.
   Fix classification: needs-human
```

## Example Iteration Output (Stage 4 — Final Gate Only)

Stage 4 only runs in the Final Gate. It uses scoped verification (build/test only affected projects).

```markdown
### Iteration 1
- Applied fixes summary:
  - `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs`: reused shared error response helper in unauthorized return path.
  - `tests/Auth/LiveSessionsControllerTests.cs`: added expired-token unauthorized test case.
- Verification scope: scoped (2 build targets, 1 test target)
- Verification: dotnet-cli build pass, tests pass
- Post-fix re-run: Stage 1 pass, Stage 2 pass, Stage 3 pass
- Re-run evidence: `P2: 3 -> 1`, `P3: 1 -> 1`; remaining issue from Dify is location unknown (likely `LiveSessionsController.GetLiveSession*`)
- Findings counts: P1 = 0, P2 = 1, P3 = 1
- Decision: continue
- Reason: One P2 remains (Dify null-deref concern) and requires manual confirmation of control-flow safety.

### Iteration 2
- Applied fixes summary: none
- Verification scope: skipped (no changes)
- Verification: skipped (no changes), previous: dotnet-cli build pass, tests pass
- Post-fix re-run: Stage 1 pass, Stage 2 pass, Stage 3 pass
- Re-run evidence: `P1/P2/P3 unchanged vs iteration 1`; no new actionable auto-fixable findings
- Findings counts: P1 = 0, P2 = 1, P3 = 1
- Decision: stop
- Reason: No meaningful improvement after one full iteration; remaining P2 is `needs-human`.
```