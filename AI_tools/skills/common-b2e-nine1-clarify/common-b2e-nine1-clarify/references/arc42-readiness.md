# Arc42 Readiness — Architecture Readiness Assessment

---

## Assessment Goal

Review the Work Item content (Description, ImplementPlan, Comments, Clarifications) to check whether each Arc42 section has enough information for Phase 2 - plan (common-b2e-nine1-plan) to generate a complete architecture document.

---

## Per-Section Assessment Criteria

### 1. Solution Strategy（作法概述）— Required
- ✅ Ready: implementation approach described (architecture pattern, tech stack, module breakdown)
- ⚠️ Needs Input: only a general direction mentioned, missing concrete decisions
- ❌ Missing: not described at all

### 2. Container Diagram — Recommended (required for multi-service architectures)
- ✅ Ready: system containers mentioned (Web App, API, DB)
- ⚠️ Needs Input: some containers mentioned but incomplete (e.g. DB type not specified)
- ❌ Missing: system boundary not mentioned

### 3. Component Diagram — Recommended (required for complex internal structures)
- ✅ Ready: internal components mentioned (Controllers, Services, Repositories)
- ⚠️ Needs Input: layering concept exists but incomplete
- ❌ Missing: internal structure not mentioned

### 4. Database Schema — Required if there is a DB change
- ✅ Ready: tables, columns, relations mentioned
- ⚠️ Needs Input: DB change needed but no structure description
- ❌ Missing: no DB information mentioned at all

### 5. API Specification — Required if there is an API change
- ✅ Ready: endpoints, Request/Response format listed
- ⚠️ Needs Input: API needed but no format description
- ❌ Missing: API design not mentioned

### 6. Runtime View — Recommended (required for complex flows)
- ✅ Ready: data flow or sequence described
- ⚠️ Needs Input: flow description exists but missing error handling
- ❌ Missing: runtime behavior not described

### 7. Non-Functional Requirements — Required
- ✅ Ready: performance targets, security, scalability mentioned
- ⚠️ Needs Input: some non-functional requirements defined but incomplete
- ❌ Missing: not mentioned at all

---

## Overall Readiness Calculation

```python
required_sections = [
    "Solution Strategy",
    "Non-Functional Requirements",
    # Conditionally required (if there is a related change)
    "Database Schema",    # If the WI mentions a DB change
    "API Specification",  # If the WI mentions an API change
]

def calculate_readiness(arc42_status):
    required_statuses = [arc42_status[s] for s in required_sections]
    
    if "Missing" in required_statuses:
        return "❌ Needs More Input"
    elif "Needs Input" in required_statuses:
        return "⚠️ Proceed with Caution"
    else:
        return "✅ Ready for Planning"
```

---

## Output Format (integrated into the final summary)

```markdown
### 🗂️ Arc42 架構就緒度

| 段落 | 必要性 | 狀態 | 備註 |
|-----|--------|------|------|
| Solution Strategy (作法概述) | ✅ 必要 | ✅ Ready | {說明} |
| Container Diagram (容器圖) | 建議 | ⚠️ Needs Input | {說明} |
| Component Diagram (元件圖) | 建議 | ✅ Ready | {說明} |
| Database Schema (資料庫結構) | ✅ 必要 | ❌ Missing | {說明} |
| API Specification (API 規格) | ✅ 必要 | ✅ Ready | {說明} |
| Runtime View (執行時期視圖) | 建議 | ⚠️ Needs Input | {說明} |
| Non Functional Requirements (非功能需求) | ✅ 必要 | ✅ Ready | {說明} |

**整體就緒度：** {✅ Ready / ⚠️ Proceed with Caution / ❌ Needs More Input}

**建議行動：**
- **{section}（{狀態}）**：{具體建議}
```

---

## Assessment Principles

- **✅ Ready**: Phase 2 - plan can directly generate the complete section, no `[TBD]` marker needed
- **⚠️ Needs Input**: the section can be generated but will contain `[TBD]`, requiring the user to supply more detail during Phase 2 - plan
- **❌ Missing**: the section cannot be generated; Phase 2 - plan must supply it first or mark it `[需補充]`

This assessment **does not pause for user confirmation** — the result is integrated directly into the final summary output.
