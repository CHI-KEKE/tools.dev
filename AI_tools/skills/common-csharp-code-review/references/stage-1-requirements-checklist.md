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

### Reporting Note

- Do not reproduce full section text in the report.
- Produce a condensed summary and reference section name + short snippet in findings for traceability.

### Ambiguity Handling

- Do not infer requirements when expected behavior is unclear.
- Record missing information as `[BLOCKED]` and list specific clarification questions.

## Stage 1 Workflow

### 0) Initialize Repository Runtime Context

1. Read `.github/instructions/repo_code_base.instructions.md` first.
2. Determine verification profile (`net-framework` or `dotnet-cli`) using `references/prerequisites-and-stop-conditions.md`.
3. Record the selected profile for later Stage 4 verification reporting.

### 1) Gather Changed Files (Working Tree)

1. Collect the review scope using `.github/skills/common-csharp-code-review/scripts/get_included_diffs.ps1` (see the canonical usage in `references/prerequisites-and-stop-conditions.md`). If the caller (e.g. executor agent) provides a baseline ref, pass `-Baseline $baseline` to limit the scope to incremental changes only.
2. Build a C#-related review subset from `$includedDiffFiles` (`.cs` first, then C# support files such as `.csproj`, `.props`, `.targets`, `.sln`, and relevant config files).
3. If the C#-related subset is empty, use task requirements and runtime/build impact to decide whether to expand scope to other changed files.
4. Stop if `$includedDiffFiles.Count -eq 0`.
5. Report `Included Diffs` using the value from `$diffScope.IncludedDiffs` (either `unstaged + staged` or `incremental (baseline: <ref>)`) and `Files Reviewed` using the actual reviewed set.

### 2) Load Requirements and Checklist

1. Load task requirements from Azure DevOps `Description`.
2. Convert requirements into the breakdown format listed above.
3. Load `.github/checklists/code-implementation-checklist.md`.

### 3) Validate Requirements and Checklist Items

Validate the implementation against:

- Description-derived requirements (by section and statement).
- Repository checklist items.

Do not assume missing requirements. Use `[BLOCKED]` when verification is not possible.

### 4) Detect and Classify Scope Creep

Classify implementation beyond explicit requirements into one of these types:

- Type 1: Necessary extension
  - Work needed for cross-cutting concerns implied by repository standards (logging, validation, error handling).
  - Usually acceptable, but justify and document it.
- Type 2: Optional refactor
  - Refactoring, renaming, or abstraction improvements not required for the task.
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

### Review-Only Mode (`reviewDepth: review-only`)

When the skill is invoked with `reviewDepth: review-only`:

- Output the Stage 1 report as defined above.
- Add `Review Depth: review-only` to the report header.
- **Continue to Stage 2 (Dify) and Stage 3 (consolidation)** — these still run in review-only mode.
- After Stage 3 completes, add a note at the end of the consolidated report:
  ```
  Note: This is a per-task review (Stage 1 + 2 + 3, review-only). Build/test verification
  and auto-remediation (Stage 4) are deferred to the Final Review Gate after all tasks complete.
  ```
- Do NOT proceed to Stage 4 after outputting the consolidated report.
- The caller (executor agent) is responsible for running the full review in the Final Gate.