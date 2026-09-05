# Example: Stage 1 Code Review Report

Use this as a tone/format example for Stage 1 output. Adapt facts to the actual task and diff. Do not copy findings blindly.

```markdown
## Code Review Report
Date: 2026-02-25
Review Mode: working-tree
Included Diffs: unstaged + staged
Files Reviewed: 4
Verification Profile: frontend-package-scripts
Iteration: 0 (initial review)

### Summary
- Merge-ready: No
- Priority counts: P1 = 0, P2 = 2, P3 = 1
- Major risks:
  - Filter changes can leave the URL and screen state out of sync after refresh.
  - API failure path still leaves users without a visible retry path.

### Part 1: Requirements Validation (from Azure DevOps Description)

#### Requirements Summary (condensed)
- Scope summary:
  - Add settlement list filters and keep filter state synchronized with the query string.
  - Preserve existing table sorting and pagination behavior.
- Key behaviors / acceptance points:
  - Restore filters from the URL on page load.
  - Reset pagination when filters change.
  - Show a visible error message and retry affordance when the fetch fails.
  - Add or update unit tests for filter restore and fetch failure paths.
- Non-goals / exclusions:
  - No redesign of the settlement table layout.
- Testing expectations:
  - Add unit coverage for URL restore and error state behavior.

#### Traceability
- Source: Azure DevOps Work Item Description
- Requirement sections used: Context & Scope, Work Summary, Key Implementation Logic, Unit Test Plan
- Notes: Full section text is intentionally not reproduced to keep the report concise. Each finding references the relevant section and a short snippet.

#### Validation Findings
1. [P2] [PARTIAL] Requirement (Unit Test Plan): "add coverage for filter restore" - evidence: `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/tests/unit/Page/SettlementList.test.tsx:88` - the page restores keyword input from the URL but does not verify date-range restore, leaving a required path unverified - add a test that covers query-string to form-state restoration for all supported filters.
2. [P2] [FAIL] Requirement (Key Implementation Logic): "show a visible retry affordance when fetch fails" - evidence: `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Page/SettlementList/index.tsx:164` - the request failure branch only closes loading state and does not render an error banner or retry action, so users cannot recover from a common failure path - render the shared error feedback component with a retry handler.

### Part 2: Checklist Findings
#### Critical Issues from Checklist
1. [P2] Error handling path lacks visible user feedback - evidence: `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Page/SettlementList/index.tsx:164` - silent failure leaves the page blank after loading and increases support risk - reuse the shared general error dialog or inline error state used elsewhere in ClientApp.

#### Other Checklist Issues
1. [P3] Empty-state copy is not localized - evidence: `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Page/SettlementList/index.tsx:219` - hard-coded copy can drift from locale files and break translation coverage - move the string into `ClientApp/locales/zh-TW/common.json` and consume it through `t(...)`.

### Part 3: Scope Creep
#### Type 1: Necessary extensions
1. Added retry button state to the shared error panel - `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Component/ErrorFallback/index.tsx:28` - acceptable if kept scoped to the affected page flow.

#### Type 2: Optional refactors
1. Extracted filter parsing into a new helper hook - `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Page/SettlementList/hooks/useSettlementFilters.ts:1` - low risk but should be split if it expands beyond the current page.

#### Type 3: Out-of-scope functionality
1. None observed.
```
