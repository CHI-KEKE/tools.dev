# Stage 2 and Stage 3: Dify Review and Consolidation

## Stage 2: Execute Dify Code Review

### Command

```powershell
powershell -ExecutionPolicy Bypass -File ".github\skills\f2e-nine1-code-review\scripts\dify_code_review_request.ps1"
```

### Handling Rules

1. Run the script and wait for completion.
2. Treat Dify input scope as frontend-related diff content by default (the detected frontend app's source, styles, tests, locales, and frontend config files first).
3. If no frontend-related diff content exists, allow fallback to full diff content.
4. Parse findings from the script output conservatively.
5. If Dify output is ambiguous or lacks locations, record the item as `location unknown`.
6. Do not over-interpret vague Dify output.

## Stage 3: Consolidate Final Review Results

### 1) Merge and De-duplicate Findings

1. Merge Stage 1 findings (requirements, checklist, scope creep) with Stage 2 (Dify) findings.
2. Remove duplicates when the same underlying issue appears at the same file/location or the same function/class.

### 2) Group by Type and Severity

Use categories such as:

- Correctness / Logic
- Requirement compliance
- UX / interaction
- Accessibility / localization / responsiveness
- Error handling / resilience
- Security / privacy
- State / data flow
- API integration
- Performance
- Maintainability
- Testing
- Observability (logging/metrics/tracing)
- Build / CI / config

### 3) Priority Definitions (Consistency Rules)

#### P1 (Blockers)

- Lint, type, or build failures that block delivery
- Test failures, or missing critical tests mandated by the `Description`
- Breaking public UI contract or navigation behavior changes without approval
- Data loss or corruption risk
- Payment/order/critical business flow errors in the UI journey
- Clear security vulnerabilities (authorization/authentication bypass, sensitive data exposure, unsafe HTML rendering)

#### P2 (Critical)

- Likely runtime exceptions in common paths
- Incorrect edge-case handling that can fail in production
- Missing required validations, loading state, or error handling
- Significant performance regressions in hot paths
- Important observability gaps for critical flows
- Accessibility or localization regressions on required flows

#### P3 (Minor)

- Style or readability improvements
- Minor refactors, naming, styling, or small duplication
- Low-impact warnings or minor optimizations

### 4) Consolidated Output Schema

Present a single prioritized list. Include:

- Issue
- Priority
- Source (`requirements`, `checklist`, `dify`)
- Location (`file:line` or best approximation)
- Suggested fix
- Fix classification (`auto-fixable` or `needs-human`)

Use the consolidated findings template in `assets/review-report-template.md`.
