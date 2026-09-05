# Ambiguity Taxonomy — Ambiguity Classification & Scanning Rules

The requirement ambiguity scan uses the following 5 priority categories, evaluating each category's status in order: **Clear / Partial / Missing**.

---

## Category Definitions

### Priority 1 — Functional Scope & Behavior（功能範圍與行為）
**Impact Score: 10**

Scan questions:
- Is the core user goal clearly defined?
- Are success criteria clearly described?
- Are out-of-scope items declared?
- Are user roles / role responsibilities distinguished?

### Priority 2 — Domain & Data Model（資料模型）
**Impact Score: 9**

Scan questions:
- Are entities, attributes, and relationships clear?
- Are identity and uniqueness rules defined?
- Is the lifecycle / state transition documented?
- Are data volume / scale assumptions stated?

### Priority 3 — Integration & External Dependencies（整合依賴）
**Impact Score: 8**

Scan questions:
- Are external services/APIs identified, including their failure modes?
- Are data import/export formats specified?
- Are protocol/version assumptions documented?

### Priority 4 — Edge Cases & Failure Handling（邊界案例）
**Impact Score: 7**

Scan questions:
- Are negative scenarios sufficiently covered?
- Are rate-limiting/throttling requirements specified?
- Is a conflict-resolution strategy defined (e.g. concurrent editing)?

### Priority 5 — Non-Functional Requirements（非功能需求）
**Impact Score: 8**

Scan questions:
- Are performance targets specified (latency, throughput)?
- Are security/privacy requirements clear (authN/authZ, data protection)?
- Are observability requirements defined (logging, metrics)?

---

## Status Evaluation Criteria

| Status | Definition |
|------|------|
| ✅ Clear | Relevant information for this category is complete enough to make architecture decisions |
| ⚠️ Partial | Some information exists, but key details are missing |
| ❌ Missing | No relevant information at all, needs to be supplied |

---

## Priority Calculation

```python
def calculate_priority(category, status):
    impact_scores = {
        "Functional Scope & Behavior": 10,
        "Domain & Data Model": 9,
        "Integration & Dependencies": 8,
        "Non-Functional Requirements": 8,
        "Edge Cases & Failure Handling": 7,
    }
    uncertainty_map = {"Clear": 0, "Partial": 5, "Missing": 10}
    return impact_scores[category] * uncertainty_map[status]
```

Higher score → higher priority for generating a clarification question.

---

## Decision Point

```python
if all_categories == "Clear":
    # Skip question generation, proceed directly to Arc42 validation
    proceed_to_arc42_validation()
else:
    # Generate questions by priority order (see question-generation.md)
    proceed_to_question_generation()
```
