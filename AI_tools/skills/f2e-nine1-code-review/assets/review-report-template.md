# Review Report Templates

## Code Review Report (Stage 1)

```markdown
## Code Review Report
Date: YYYY-MM-DD
Review Mode: working-tree
Included Diffs: unstaged + staged
Files Reviewed: N
Verification Profile: frontend-package-scripts
Verification Commands: [resolved from package.json]
Iteration: K (0 = initial review)

### Summary
- Merge-ready: Yes/No/Blocked
- Priority counts: P1 = X, P2 = Y, P3 = Z
- Major risks: [1-3 bullet points]

### Part 1: Requirements Validation (from Azure DevOps Description)

#### Requirements Summary (condensed)
- Scope summary: [1-3 bullets summarizing the expected change]
- Key behaviors / acceptance points: [up to 5 bullets]
- Non-goals / exclusions: [up to 3 bullets, if specified]
- Cross-cutting requirements: [if specified]
- Testing expectations: [if specified]

#### Traceability
- Source: Azure DevOps Work Item Description
- Requirement sections used: [list section names used]
- Notes: Full section text is intentionally not reproduced to keep the report concise. Each finding references the relevant section and a short snippet.

#### Validation Findings
1. [P?] [PASS/PARTIAL/FAIL/BLOCKED] Requirement (Section): "[short snippet]" - evidence: path:line - impact - suggested fix

### Part 2: Checklist Findings
#### Critical Issues from Checklist
1. [P?] [Issue description] - evidence: path:line - impact - suggested fix

#### Other Checklist Issues
1. [P?] ...

### Part 3: Scope Creep
#### Type 1: Necessary extensions
1. [Extra implementation] - path:line - justification needed

#### Type 2: Optional refactors
1. ...

#### Type 3: Out-of-scope functionality
1. [Extra implementation] - path:line - Not required in Description
```

## Consolidated Findings List (Stage 3)

```markdown
### Consolidated Findings
1. Issue: [summary]
   Priority: P1/P2/P3
   Source: requirements/checklist/dify
   Location: path:line (or best approximation)
   Suggested fix: [one actionable sentence]
   Fix classification: auto-fixable / needs-human
```

## Iteration Output (Stage 4)

```markdown
### Iteration K
- Applied fixes summary: [files + brief changes]
- Verification: [profile] lint [pass/fail], tests [pass/fail], build [pass/fail]
- Post-fix re-run: Stage 1 [pass/fail/blocked], Stage 2 [pass/fail/blocked], Stage 3 [pass/fail/blocked]
- Re-run evidence: [finding deltas (for example `P2: 3 -> 1`) and key references]
- Findings counts: P1 = X, P2 = Y, P3 = Z
- Decision: continue / stop
- Reason: [why]
```

### Stage 4 Finalization Gate (Required Before Final Answer)
- [ ] If code changed in the latest iteration, verification was executed.
- [ ] If code changed in the latest iteration, post-fix Stage 1/2/3 re-run was completed.
- [ ] Latest iteration includes findings deltas vs previous iteration (or `baseline` for iteration 1).
- [ ] Final `Decision: stop` is justified by a Section 4.5 stop condition or hard-stop condition.
