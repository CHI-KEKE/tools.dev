# Example: Consolidated Findings and Iteration Output

Use this as a compact example for Stage 3 and Stage 4 reporting. Keep issue summaries evidence-based and aligned with actual review results.

## Example Consolidated Findings (Stage 3)

```markdown
### Consolidated Findings
1. Issue: Settlement list fetch failure does not render an actionable error state.
   Priority: P2
   Source: requirements, checklist
   Location: `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Page/SettlementList/index.tsx:164`
   Suggested fix: Render the shared error feedback component with a retry action when the list request fails.
   Fix classification: auto-fixable

2. Issue: Missing automated test for restoring all supported filters from the query string.
   Priority: P2
   Source: requirements
   Location: `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/tests/unit/Page/SettlementList.test.tsx:88`
   Suggested fix: Add a test that verifies keyword, date range, and status are restored from the query string on initial render.
   Fix classification: auto-fixable

3. Issue: Dify flagged a possible race between filter changes and stale request responses.
   Priority: P2
   Source: dify
   Location: location unknown (likely `SettlementList/useSettlementList*`)
   Suggested fix: Confirm request cancellation or stale-response guarding before applying the returned data to state.
   Fix classification: needs-human
```

## Example Iteration Output (Stage 4)

```markdown
### Iteration 1
- Applied fixes summary:
   - `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/src/Page/SettlementList/index.tsx`: reused shared error state component and added retry wiring for fetch failures.
   - `src/Web/Nine1.Payment.Client.Dashboard.Partial.Web.Api/ClientApp/tests/unit/Page/SettlementList.test.tsx`: added query-string restore coverage for all supported filters.
- Verification: lint pass, tests pass, build pass
- Post-fix re-run: Stage 1 pass, Stage 2 pass, Stage 3 pass
- Re-run evidence: `P2: 3 -> 1`, `P3: 1 -> 1`; remaining issue from Dify is location unknown (likely `SettlementList/useSettlementList*`)
- Findings counts: P1 = 0, P2 = 1, P3 = 1
- Decision: continue
- Reason: One P2 remains (stale-response concern) and requires manual confirmation of request lifecycle safety.

### Iteration 2
- Applied fixes summary: none
- Verification: lint pass, tests pass, build pass
- Post-fix re-run: Stage 1 pass, Stage 2 pass, Stage 3 pass
- Re-run evidence: `P1/P2/P3 unchanged vs iteration 1`; no new actionable auto-fixable findings
- Findings counts: P1 = 0, P2 = 1, P3 = 1
- Decision: stop
- Reason: No meaningful improvement after one full iteration; remaining P2 is `needs-human`.
```
