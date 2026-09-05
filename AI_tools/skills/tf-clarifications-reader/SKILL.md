---
name: tf-clarifications-reader
description: >
  Tasking Flow 共用 Skill：從 Azure DevOps Work Item Discussion 中讀取釐清記錄
  （Clarifications 留言），解析 Q&A 內容，排除非釐清留言，並輸出結構化釐清清單。
  適用於 nine1-plan、nine1-tasks 等需要彙整既有釐清結果的場景。
---

# tf-clarifications-reader

Tasking Flow shared Skill. Reads and parses clarification records from VSTS Discussion, providing structured output for use by subsequent Skills as context input.

**Prerequisite:** `workItemId` must have been obtained via `tf-work-item-context` before calling this Skill.

---

## Input

| Parameter | Required | Description |
|-----------|:--------:|-------------|
| `workItemId` | ✅ | Azure DevOps Work Item ID |

---

## Step 1 — Get All Discussion Comments

```
get_work_item_comments(id: workItemId)
```

**Error handling:**
- If MCP Tool call fails → display warning and continue (treat as "no clarification records"):

```markdown
⚠️ 無法載入 Discussion 留言（#{workItemId}）。
將繼續執行，但缺少釐清上下文，部分分析可能不完整。
```

---

## Step 2 — Filter Clarification Comments

**Include conditions:**
- Comment title matches format: `📋 Clarifications - YYYY-MM-DD`

**Exclude conditions:**
- Comments containing `Task檢核結果`
- Comments containing `Task Progress Tracking`
- Any other comments not matching the Include format

---

## Step 3 — Parse Q&A Content

Extract structured content from each clarification comment:

**Identification format:**
```markdown
#### 問題 N: [Category / 類別] - {問題標題}
**答案：** {答案內容}
```

**Extracted fields:**
- `round`: round number derived from comment date (earliest comment = Round 1)
- `questionNo`: question number
- `category`: category (Functional Scope / Domain & Data Model / Integration & Dependencies / Edge Cases / Non-Functional Requirements)
- `title`: question title
- `answer`: answer content (full text, without option letters)

---

## Output: Structured Clarification List

**If clarification records are found:**

```markdown
## 📋 釐清記錄已載入

**Work Item：** #{workItemId}
**釐清輪次：** {N} 輪 / 總計 {M} 個問題

### 第 1 輪（{YYYY-MM-DD}）
1. **[Functional Scope & Behavior / 功能範圍與行為]** {問題標題}
   → {答案內容}

2. **[Domain & Data Model / 資料模型]** {問題標題}
   → {答案內容}

### 第 2 輪（{YYYY-MM-DD}）（若存在）
...
```

**If no clarification records are found:**

```markdown
## ℹ️ 釐清記錄

**Work Item：** #{workItemId}
**狀態：** 未找到釐清留言（`📋 Clarifications - YYYY-MM-DD` 格式）

後續分析將僅依據 Work Item Description 與 ImplementPlan 進行。
```

---

## Error Handling Summary

| Situation | Behavior |
|-----------|---------|
| MCP Tool call failure | Display warning, treat as no clarification records, continue execution |
| Comments present but none matching clarification format | Return "no clarification records" status, continue execution |
| Clarification comment found but format is irregular | Parse best-effort, mark unparseable items as `[無法解析]` |
