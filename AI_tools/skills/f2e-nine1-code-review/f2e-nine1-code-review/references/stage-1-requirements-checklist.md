# Stage 1: Requirements and Checklist Validation

## Requirements Extraction Rules (Highest Priority)

### Source of Truth

- Treat Azure DevOps work item `Description` as the single source of truth.
- If `Description` is missing or empty, allow user-provided requirements only as a fallback.
- Mark the review as `[BLOCKED]` unless the user confirms fallback requirements are complete and authoritative.

### Requirements Breakdown Format

Convert the `Description` into reviewable requirements using these sections when present. If a section is missing, record `Not provided` and mark related validations as `[BLOCKED]` when needed.

- Context & Scope
- Goals & Non-Goals
- Work Summary
- Design Considerations & Trade-offs
- Key Implementation Logic
- Unit Test Plan
- Affected File Paths
- Dependencies and Task Relationships (with Task IDs)
- Cross-cutting Concerns

When validating frontend work, explicitly look for requirement coverage across these concerns when they are relevant to the task:

- UI rendering and layout behavior
- Loading, empty, error, and success states
- Route, query-string, and navigation behavior
- API integration and client-side error handling
- Form validation and submission flow
- Accessibility, localization, and responsive behavior
- Unit test coverage for public user-facing behavior

### Reporting Note

- Do not reproduce full section text in the report.
- Produce a condensed summary and reference section name + short snippet in findings for traceability.

### Ambiguity Handling

- Do not infer requirements when expected behavior is unclear.
- Record missing information as `[BLOCKED]` and list specific clarification questions.

## Stage 1 Workflow

### 0) Initialize Repository Runtime Context

1. Resolve the verification profile from the target project's `package.json` using `references/prerequisites-and-stop-conditions.md`.
2. Record the returned package manager and selected lint/test/build commands for later Stage 4 verification reporting.

### 1) Gather Changed Files (Working Tree)

1. Collect the review scope using `.github/skills/f2e-nine1-code-review/scripts/get_included_diffs.ps1` (see the canonical usage in `references/prerequisites-and-stop-conditions.md`).
2. Build a frontend-related review subset from `$includedDiffFiles` (the detected frontend app's source, tests, styles, locales, and frontend build/config files first).
3. If the frontend-related subset is empty, use task requirements and runtime/build impact to decide whether to expand scope to other changed files.
4. Stop if `$includedDiffFiles.Count -eq 0`.
5. Report `Included Diffs: unstaged + staged` and `Files Reviewed` using the actual reviewed set.

### 2) Load Requirements and Checklist

1. Load task requirements from Azure DevOps `Description`.
2. Convert requirements into the breakdown format listed above.
3. Load `.github/checklists/code-implementation-checklist.md`.

### 3) Validate Requirements and Checklist Items

Validate the implementation against:

- Description-derived requirements (by section and statement).
- Repository checklist items.

For frontend changes, prefer behavior-oriented validation over implementation-only validation. Confirm whether the current diff preserves user-visible behavior, route/state consistency, and recoverability when requests fail.

Do not assume missing requirements. Use `[BLOCKED]` when verification is not possible.

### 4) Detect and Classify Scope Creep

Classify implementation beyond explicit requirements into one of these types:

- Type 1: Necessary extension
  - Work needed for cross-cutting concerns implied by repository standards (validation, accessibility, localization, error handling, responsive support).
  - Usually acceptable, but justify and document it.
- Type 2: Optional refactor
  - Refactoring, renaming, component extraction, or hook abstraction improvements not required for the task.
  - Accept only if low-risk; otherwise recommend splitting into a separate PR/task.
- Type 3: Out-of-scope functionality
  - New features or behavior changes not requested.
  - Usually not acceptable; escalate based on risk.

### 5) Mark Result Status

Use exactly one status per checklist item and major requirement:

- `[PASS]`: Fully satisfied with clear evidence.
- `[PARTIAL]`: Mostly satisfied but incomplete (tests, edge cases, error handling, or other gaps).
- `[FAIL]`: Not satisfied or contradicts the requirement.
- `[N/A]`: Not applicable, with a reason.
- `[BLOCKED]`: Cannot verify because of missing requirements, context, or incomplete change set.

### 6) Evidence Standard

Every finding must include:

- Concrete evidence with `file:line` reference (or closest possible reference).
- Impact (what could break and why it matters).
- Suggested fix (one actionable sentence).

## Stage 1 Output

Use the Stage 1 report template in `assets/review-report-template.md` (`Code Review Report` section).
