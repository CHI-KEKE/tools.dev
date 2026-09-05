# Skill Enrichment — Capability-Driven Technical Enrichment & Skill Detection Rules

---

## Purpose

Before producing the core design blueprint, gather enough technical context (existing components, naming conventions, extension points),
and dynamically detect whether any implementation Skill applies to this requirement, so it can be explicitly referenced during later Task breakdown.

This step **does not bind to a fixed Skill list** — it scans and matches at runtime every time it executes, ensuring newly added/removed Skills are always covered.

---

## Part A — Technical Context Enrichment

### Determine Required Capabilities

Based on the confirmed Context (Step 3), determine whether the following capabilities are needed:
- Module/class structure analysis
- Existing component reuse analysis
- API surface discovery
- Shared dependency / integration boundary discovery

### Internal SDK Discovery (run before enrichment)

If the confirmed requirements (Step 3) involve any of the following capability categories:
`messaging`, `cache`, `session`, `payment`, `translation`, `notification`, `logging`,
`member`, `audit`, `monitoring`, `promotion`, `crm`, `http`, `basesdk`

Then call the **91app-sdk-discovery** MCP tool:
1. `search_sdk_by_purpose("<purpose>")` — find matching internal SDKs
2. `get_sdk_versions("<package_id>")` — confirm the latest version

Record the result as **Internal SDK Candidates**, for use in "Internal Summary" and Step 4 dependency design.
If no MCP tool is available or no match is found, do not block the flow — proceed directly.

> ⚡ SDK-first principle: before listing any NuGet dependency in the ImplementPlan, first confirm whether a corresponding internal SDK exists.

### Perform Targeted Enrichment

Inspect the relevant modules, classes, services, repositories, controllers, and contracts, extracting only the evidence needed for later design decisions:
- Reusable components
- Naming and layering conventions
- Dependency injection patterns
- Extension points
- Existing contract boundaries

### Internal Summary

Organize the findings into internal input for Step 4's core design:
- What already exists and should be reused
- What appears missing and may need to be newly created
- Boundaries or conventions that constrain the design
- **Internal SDK Candidates** (from Internal SDK Discovery, if any)

**If relevant modules cannot be fully identified:** proceed with the best-guess design, explicitly flag the assumption, and do not treat this as an error.

---

## Part B — Detect Applicable Implementation Skills

### Execution Steps

1. **Dynamically list all available Skills**: use `list_dir` to scan every subfolder under `.github/skills/`
2. **Read each `SKILL.md`**: extract from each Skill's `description` (or equivalent trigger section) "what conditions should trigger this Skill"
3. **Match trigger conditions against this requirement**: compare each Skill's trigger conditions against the functional requirements confirmed in Step 3
4. **Do not hardcode Skill names** — the Skill list is based on the current scan result and may grow/shrink over time

### Recording Format

For **every confirmed matching Skill**, record:

| Field | Description |
|------|------|
| Skill Name | the exact folder name under `.github/skills/` |
| Trigger Condition | why this Skill applies to this requirement |
| Applicable Scope | which Task types or deliverables should call this Skill |

If no Skill clearly matches, **record as empty** — do not force a match just to fill the table.

Store the result as the internal variable **Detected Skill Mapping**, for use in Step 4's design summary and Step 7's ImplementPlan update.

---

## Error Handling

- ⚠️ If technical enrichment cannot fully identify relevant modules → proceed with the best guess, explicitly flag the assumption
- ⚠️ If no dedicated capability is available → analyze directly with workspace tools (`grep`/`glob`/`view`), do not treat this as an error
- ⚠️ If Skill detection finds no match → proceed normally, omit the Skill Mapping section from the Design Summary
- ⚠️ If the 91app-sdk-discovery MCP tool does not exist, the call fails, or no matching internal SDK is found → do not block the flow, record Internal SDK Candidates as empty, proceed directly

---

## Output Example (for use in Step 4's design summary)

```markdown
### 🔧 建議套用的實作 Skills
{若 Detected Skill Mapping 非空，顯示下表；否則整段省略}

| 適用 Skill | 觸發條件 | 適用 Task 範疇 |
|-----------|---------|---------------|
| `add-cache-to-service` | {為何比對到此 Skill} | {哪些 Task 或產出物應呼叫此 Skill} |
```

> ⚠️ Agent 執行對應 Task 時，**必須顯式載入並遵循上表所列 Skill 的 SKILL.md**，以確保實作符合專案慣例、規範或標準。
> ℹ️ 若表格為空，表示本次異動無對應的實作 Skill，Agent 使用通用實作流程即可。
