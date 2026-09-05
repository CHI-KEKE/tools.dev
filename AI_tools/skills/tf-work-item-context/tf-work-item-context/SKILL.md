---
name: tf-work-item-context
description: >
  Tasking Flow 共用 Skill：載入 Azure DevOps Work Item 完整內容、驗證 Custom.ImplementPlan
  欄位是否已填寫，並輸出標準化的 WI Context 結構供後續 Skill 使用。
  適用於所有需要讀取 Work Item 資料作為輸入的場景，例如 nine1-clarify、nine1-plan、nine1-tasks。
---

# tf-work-item-context

Tasking Flow shared Skill. Loads the Work Item, validates prerequisites, and outputs a standardized `WI Context` for use by subsequent Skills.
Other Skills should call this Skill before executing any core logic.

---

## Input

| Parameter | Required | Description |
|-----------|:--------:|-------------|
| `workItemId` | ✅ | Azure DevOps Work Item ID (numeric) |
| `requireImplementPlan` | ❌ | Whether to enforce non-empty `Custom.ImplementPlan` validation (default: `true`) |

---

## Step 1 — Call MCP Tool to Get Work Item

```
get_work_item_details(id: workItemId)
```

**Fields to retrieve:**
- `id`, `title`, `type`, `state`
- `description` (full content)
- `Microsoft.VSTS.Common.AcceptanceCriteria`（驗收標準，完整內容 — 常包含具體的檢核項目與對應錯誤訊息文字，供 `nine1-plan` 等下游 Skill 逐字引用）
- `Custom.ImplementPlan` (including all Arc42 sub-sections)
- `tags`, `areaPath`, `iterationPath`, `parentId`, `project`

**Error handling:**
- If MCP Tool call fails or returns 404 → display error in Traditional Chinese and abort:

```markdown
## ❌ Work Item 載入失敗

**Work Item ID：** #{workItemId}
**錯誤原因：** Work Item 不存在或無存取權限。

**請確認：**
1. Work Item ID 是否正確
2. 當前帳號是否有讀取權限
3. Azure DevOps 連線是否正常
```

---

## Step 2 — Validate Custom.ImplementPlan (if requireImplementPlan = true)

```python
if custom_implement_plan is None or custom_implement_plan.strip() == "":
    display_error_and_exit()
```

**If validation fails, display (in Traditional Chinese):**

```markdown
## ❌ 前置驗證失敗

**錯誤類型：** 作法概述（Implement Plan）未填寫

**Work Item ID：** #{workItemId}
**標題：** {title}

**原因：** `Custom.ImplementPlan` 欄位為空值或未填寫。

**要求：**
1. 請先在 Azure DevOps 中補充 Work Item 的「作法概述」欄位
2. 提供實作方案的簡要說明，例如：
   - 採用的架構模式（Repository Pattern、CQRS 等）
   - 技術棧概述
   - 主要模組劃分
   - 與現有系統的整合方式

**中止原因回傳呼叫方：**
⚠️ 前置驗證失敗：Custom.ImplementPlan 未填寫，請補充後重新執行。
```

---

## Step 3 — Parse ImplementPlan Sections

Parse the fill status of each Arc42 section from `Custom.ImplementPlan`:

| Section | Keyword Identification | Status Evaluation |
|---------|----------------------|-------------------|
| 作法概述 (Approach Overview) | Any non-empty text | Populated / Empty |
| Container Diagram | `container`, `系統`, container-related descriptions | Populated / Empty |
| Component Diagram | `component`, `元件`, `Controller`, `Service` | Populated / Empty |
| DB Schema | `table`, `schema`, `資料表`, column definitions | Populated / Empty |
| API Spec | `endpoint`, `GET`, `POST`, `Request`, `Response` | Populated / Empty |
| Runtime View | `mermaid`, `sequence`, `流程`, sequence descriptions | Populated / Empty |
| Non Functional Requirements | `performance`, `security`, `效能`, `安全性` | Populated / Empty |

---

## Output: Standardized WI Context Structure

```markdown
## 📊 Work Item Context 已載入

**Work Item ID：** #{workItemId}
**標題：** {title}
**類型：** {type}
**狀態：** {state}
**Tags：** {tags}
**Area Path：** {areaPath}
**Iteration Path：** {iterationPath}

**ImplementPlan 各段落狀態：**
- {✅/❌} 作法概述 (Approach Overview)
- {✅/❌} Container Diagram
- {✅/❌} Component Diagram
- {✅/❌} DB Schema
- {✅/❌} API Spec
- {✅/❌} Runtime View
- {✅/❌} Non Functional Requirements

**描述預覽：**
{前 200 字元...}

**驗收標準（Acceptance Criteria）預覽：**
{前 200 字元，或「無驗收標準」}
```

This structure should be cached in the current session for direct access by subsequent Skills, avoiding redundant MCP Tool calls.

---

## Error Handling Summary

| Situation | Behavior |
|-----------|---------|
| Work Item not found | Display error message, abort execution |
| No access permissions | Display error message, abort execution |
| ImplementPlan empty (requireImplementPlan=true) | Display validation failure message, abort execution |
| ImplementPlan empty (requireImplementPlan=false) | Continue execution, mark as Empty |
| MCP Tool connection failure | Display error message, abort execution |
