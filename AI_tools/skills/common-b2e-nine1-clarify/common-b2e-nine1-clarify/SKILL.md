---
name: common-b2e-nine1-clarify
description: >
  分析 Azure DevOps Work Item 需求，透過結構化問題識別技術模糊點，收集釐清回答並
  回寫至 VSTS Discussion，最後驗證 Arc42 架構就緒度。為 User Story to Tasks 流程的
  Phase 1。完成後建議執行 `common-b2e-nine1-plan` 進行架構規劃。
---

# common-b2e-nine1-clarify

User Story to Tasks — **Phase 1：需求釐清**

Senior backend engineer perspective — identify technical blind spots, data model concerns, API design issues, **technical compatibility risks**, and system integration blockers in the Work Item.

---

## Quick Start

1. Load `tf-work-item-context` skill → get WI Context (with ImplementPlan validation)
2. Call `tf-clarifications-reader` → load existing clarification history (count rounds, avoid duplicate questions)
3. Run technical compatibility gate scan (load `references/compatibility-gate.md`) ⏸ (if result is Unverified)
4. Run requirements ambiguity scan (load `references/ambiguity-taxonomy.md`)
5. Generate clarification questions (load `references/question-generation.md`) ⏸
6. Collect and validate user responses
7. Call `tf-work-item-writer` to write collected responses to VSTS Discussion; assess whether additional rounds are needed ⏸
8. Run Arc42 readiness validation (load `references/arc42-readiness.md`)
9. Output Phase 1 completion summary, prepare handoff to `common-b2e-nine1-plan`

---

## Shared Skill Dependencies

| Skill | Purpose | Required |
|-------|---------|:--------:|
| `tf-work-item-context` | WI loading, ImplementPlan validation | ✅ |
| `tf-clarifications-reader` | Load existing clarification history, count rounds | ✅ |
| `tf-work-item-writer` | Write clarification results to VSTS Discussion | ✅ |

---

## Reference Map (load on demand)

| File | Load timing |
|------|-------------|
| `references/compatibility-gate.md` | Before Step 2 technical compatibility gate |
| `references/ambiguity-taxonomy.md` | Before Step 3 ambiguity scan |
| `references/question-generation.md` | Before Step 4 question generation |
| `references/arc42-readiness.md` | Before Step 7 Arc42 validation |
| `references/summary-template.md` | Before Step 8 output summary |

---

## Execution Flow

### Step 1 — Load WI Context

Call `tf-work-item-context` (`requireImplementPlan: true`).

If validation fails → abort, do not continue.

Display (Traditional Chinese):
```markdown
## 📊 Work Item 分析開始

**Work Item ID：** #{workItemId}
**標題：** {title}
**類型：** {type}
**狀態：** {state}

**描述預覽：**
{前 200 字元...}

**作法概述（Implement Plan）：**
{Custom.ImplementPlan 前 300 字元...}

⏳ 正在執行技術相容性閘門掃描...
```

---

### Step 1.5 — Load Existing Clarification History

Call `tf-clarifications-reader`, obtain `prior_clarifications`.

- Calculate current round `N = number of prior_clarifications rounds + 1`
- If existing clarification records exist, load all Q&A content into memory as a filter basis for subsequent question generation

---

### Step 2 — Technical Compatibility Gate

Load `references/compatibility-gate.md`, evaluate trigger conditions to determine if a scan is needed.

**If the WI does not meet any trigger conditions:**
```markdown
## ✅ 技術相容性閘門：跳過

Work Item 無版本升級、新整合或新技術引入，跳過相容性掃描。

⏳ 繼續進行需求模糊度掃描...
```
→ Proceed directly to Step 3.

**If the WI meets trigger conditions, apply the gate behavior based on scan result:**

| Result | Behavior |
|--------|----------|
| ✅ All Compatible | Output pass summary, continue to Step 3 |
| ⚠️ Needs Evidence | Record risk, continue to Step 3, flag in final report |
| 🔍 Unverified | **Soft block**: present confirmation prompt, wait for user to choose [A/B/C], then continue to Step 3 |
| ❌ Incompatible | **Hard block**: output blocking message, terminate flow, wait for issue resolution |

> ⚠️ **When Incompatible, flow terminates completely** — Step 3 is not entered. User must correct the technical approach and restart.

---

### Step 3 — Ambiguity Scan

Load `references/ambiguity-taxonomy.md`, systematically scan 5 priority categories, evaluate each category status: **Clear / Partial / Missing**.

**If all categories are Clear:**
```markdown
## ✅ 需求分析完成

未檢測到關鍵模糊點。需求已足夠清晰，可進行架構驗證。

⏳ 繼續進行 Arc42 架構就緒度驗證...
```
→ Skip to Step 7.

**If any category is Partial or Missing:** continue to Step 4.

---

### Step 4 — Generate Ambiguity Clarification Questions (up to 5 per round)

Load `references/question-generation.md`, generate questions by **Impact × Uncertainty** priority order.

**If `prior_clarifications` is not empty:**
- Skip question categories already sufficiently answered in history
- Only ask about Partial / Missing items not yet clarified
- Display at the top of the question list: `**第 {N} 輪釐清**（前 {N-1} 輪已釐清 {M} 個問題）`

Each question must include:
- Category label (bilingual)
- Recommended answer + 1-2 sentence rationale (Traditional Chinese)
- Option table or short-answer format

After presenting the questions, **pause and wait for user response**.

---

### Step 5 — Collect and Validate Responses

**Supported input formats:**
- `全部接受` / `yes to all` → adopt all recommended answers
- `1: A, 2: yes, 3: 使用 Repository` → individual answers
- Specify a question for re-explanation → provide additional explanation for that question, then wait again

After validation, list all recorded responses in Traditional Chinese.

---

### Step 6 — Write to VSTS Discussion

Call `tf-work-item-writer`:
- `commentTitle`: `📋 Clarifications - {YYYY-MM-DD}`
- `commentMarkdown`: formatted clarification Q&A content (record only the substantive answer, not option letters)
  - **If `prior_clarifications` is not empty**, prepend to the comment:
    > 🔄 **多輪釐清**：本次為第 {N} 輪，延續前 {N-1} 輪的問答記錄。前輪 Clarifications 留言仍保留，供參考。

After success, apply the multi-round strategy from `references/question-generation.md`: display continue prompt, wait for user selection, and execute the corresponding route (back to Step 4 / continue to Step 7 / skip to Step 8).

---

### Step 7 — Arc42 Readiness Validation (ImplementPlan content validation)

Load `references/arc42-readiness.md`, evaluate each section readiness status (Ready / Needs Input / Missing).
**Do not pause for the user — proceed directly to Step 8.**

---

### Step 8 — Output Phase 1 Completion Summary

Load `references/summary-template.md`, produce the complete summary.

**After completion, recommend running `common-b2e-nine1-plan`.**

---

## Execution Rules

- Pause points for user confirmation are detailed in each Step description; marked with ⏸ in Quick Start
- Upon termination signal ("結束", "不用了"), immediately stop questioning and run Arc42 validation
- All user-visible output uses **Traditional Chinese**; technical terms remain in English; category labels use bilingual format `[English / 繁體中文]`
- Answer records contain only substantive content (e.g., "使用 httpOnly cookie", not "選項 B")

---

## ⛔ MUST NOT

- Do not modify Work Item `Description` field
- Do not write option letters in clarification records (`選項 A`, `yes`, `suggested`)
- Do not skip Arc42 validation (must run even when there are no ambiguous points)
- **Do not continue flow in ❌ Incompatible state** (must hard-terminate)
- **Do not accept unofficial sources as grounds for resolving Incompatible / Unverified status** (StackOverflow, blogs do not qualify)