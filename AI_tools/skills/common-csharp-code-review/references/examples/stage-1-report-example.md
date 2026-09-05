# Example: Stage 1 Code Review Report

Use this as a tone/format example for Stage 1 output. Adapt facts to the actual task and diff. Do not copy findings blindly.

## Full Diff Mode Example

```markdown
## Code Review Report
Date: 2026-02-25
Review Mode: working-tree
Included Diffs: unstaged + staged
Files Reviewed: 4
Verification Profile: dotnet-cli
Iteration: 0 (initial review)

### Summary
- Merge-ready: No
- Priority counts: P1 = 0, P2 = 2, P3 = 1
- Major risks:
  - Unauthorized requests may still return inconsistent error payloads.
  - Missing test coverage for token-expired and missing-header paths.

### Part 1: Requirements Validation (from Azure DevOps Description)

#### Requirements Summary (condensed)
- Scope summary:
  - Standardize `401` response behavior for live session APIs.
  - Preserve existing success-path behavior.
- Key behaviors / acceptance points:
  - Return `401` for invalid or expired auth token.
  - Response body should follow existing error contract.
  - Add/adjust tests for unauthorized scenarios.
- Non-goals / exclusions:
  - No changes to login/token issuance flow.
- Testing expectations:
  - Add unit/integration coverage for unauthorized access cases.

#### Traceability
- Source: Azure DevOps Work Item Description
- Requirement sections used: Context & Scope, Work Summary, Key Implementation Logic, Unit Test Plan
- Notes: Full section text is intentionally not reproduced to keep the report concise. Each finding references the relevant section and a short snippet.

#### Validation Findings
1. [P2] [PARTIAL] Requirement (Unit Test Plan): "add unauthorized test cases" - evidence: `tests/Auth/LiveSessionsControllerTests.cs:87` - missing expired-token scenario leaves a common failure path unverified - add a test that asserts `401` and error payload for expired token.
2. [P2] [FAIL] Requirement (Key Implementation Logic): "follow existing error contract" - evidence: `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:142` - returns ad-hoc anonymous object and may break clients expecting standard error schema - return the shared error response factory/model used by other auth endpoints.

### Part 2: Checklist Findings
#### Critical Issues from Checklist
1. [P2] Error handling path lacks consistent contract reuse - evidence: `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:142` - duplicated error shape increases drift risk - reuse shared error formatter/helper.

#### Other Checklist Issues
1. [P3] Logging does not include correlation context for unauthorized branch - evidence: `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:139` - troubleshooting is harder in production - include request/session identifier in warning log if available.

### Part 3: Scope Creep
#### Type 1: Necessary extensions
1. Added auth warning log line - `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:139` - acceptable if kept non-sensitive.

#### Type 2: Optional refactors
1. Renamed local variables in unrelated success-path mapping - `src/Web/Nine1.Nine1.Livebuy.Web/Controllers/LiveSessionsController.cs:52` - low risk but should be split if it expands further.

#### Type 3: Out-of-scope functionality
1. None observed.
```

## Incremental Diff Mode Example

When reviewing a task in a sequential multi-task execution, the `Included Diffs` field reflects the baseline snapshot from the previous task.

```markdown
## Code Review Report
Date: 2026-02-25
Review Mode: working-tree
Included Diffs: incremental (baseline: a1b2c3d)
Files Reviewed: 3
Verification Profile: dotnet-cli
Iteration: 0 (initial review)

### Summary
- Merge-ready: Yes
- Priority counts: P1 = 0, P2 = 0, P3 = 1
- Major risks:
  - None significant for this task scope.
```

Note: In incremental mode, the diff scope only includes changes made after the baseline snapshot. Changes from previous tasks are excluded and do not produce duplicate findings.
