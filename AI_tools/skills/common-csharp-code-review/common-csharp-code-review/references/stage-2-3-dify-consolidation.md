# Stage 2 and Stage 3: Dify Review and Consolidation

## Stage 2: Execute Dify Code Review

### Command

**If `$diffResult` is available from the SKILL.md pre-flight step (recommended):**
```powershell
powershell -ExecutionPolicy Bypass -File ".github\skills\common-csharp-code-review\scripts\dify_code_review_request.ps1" -PreloadedDiffScope $diffResult
```

**Standalone invocation (when pre-flight step was not run):**
```powershell
powershell -ExecutionPolicy Bypass -File ".github\skills\common-csharp-code-review\scripts\dify_code_review_request.ps1"
```

Passing `-PreloadedDiffScope $diffResult` reuses the diff data already collected in the pre-flight step and avoids a redundant `get_included_diff_content.ps1` invocation (saving 2–4 git operations).

### Handling Rules

1. Run the script and wait for completion.
2. Treat Dify input scope as C#-related diff content by default (`.cs` first, then C# support files such as `.csproj`, `.props`, `.targets`, `.sln`, and relevant config).
3. If no C#-related diff content exists, allow fallback to full diff content.
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
- Error handling / resilience
- Security / privacy
- Performance
- Maintainability
- Testing
- Observability (logging/metrics/tracing)
- Build / CI / config

### 3) Priority Definitions (Consistency Rules)

#### P1 (Blockers)

- Build or compile failures
- Test failures, or missing critical tests mandated by the `Description`
- Breaking public contract or backward compatibility changes without approval
- Data loss or corruption risk
- Payment/order/critical business flow errors
- Clear security vulnerabilities (authorization/authentication bypass, sensitive data exposure)

#### P2 (Critical)

- Likely runtime exceptions in common paths (for example NRE or invalid cast)
- Incorrect edge-case handling that can fail in production
- Missing required validations or error handling
- Significant performance regressions in hot paths
- Important observability gaps for critical flows

#### P3 (Minor)

- Style or readability improvements
- Minor refactors, naming, or small duplication
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
