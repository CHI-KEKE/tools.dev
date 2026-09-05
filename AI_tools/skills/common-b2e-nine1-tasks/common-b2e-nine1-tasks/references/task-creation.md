# Task Creation — VSTS Task Creation & Progress Tracking Table

---

## Creation Rules

### Content Anchoring Principle

- Use the **full original content** confirmed by the user in Step 6 as the task Description
- **Do not regenerate, summarize, or rewrite it**
- **Before calling `create_work_item`, first convert the description content to HTML following `tf-work-item-writer` Step 1 (1-A → 1-B → 1-C → 1-D)**; then pass the HTML string into the `description` parameter (the MCP tool preserves HTML as-is, ensuring correct rendering)

---

## create_work_item Parameters

```
create_work_item(
    type: "Task",
    state: "New",
    project: {project},              // from Step 5 confirmation
    areaPath: {areaPath},            // from Step 5 confirmation
    iterationPath: {iterationPath},  // from Step 5 confirmation
    parentId: {userStoryId},         // Work Item ID
    title: {formatted_title},
    description: {step6_content_as_html},  // converted to HTML per tf-work-item-writer Step 1
    tags: {tags}
)
```

---

## Title Format

| Type | Format |
|------|------|
| Sequential task | `1. 任務標題`, `2. 任務標題` |
| Parallel task | `[P] 1. 任務標題`, `[P] 2. 任務標題` |

---

## Tags List

| Tag | Applicable Condition |
|-----|---------|
| `Task-待檢核` | Must be added to **every task** |
| `B2E-Implement` | Must be added to **every task** |
| `ParallelGroup-N` | Tasks belonging to a parallel execution group, where N is the group number |
| `Coding-Agent` | Tasks that chose the cloud/asynchronous execution mode |

---

## Post-Creation Acceptance Confirmation

```markdown
## ✅ 任務建立完成

| 序號 | Task ID | 標題 | Tags |
|------|---------|------|------|
| 1 | #12345 | [P] 1. 建立資料模型層 | Task-待檢核, B2E-Implement, ParallelGroup-1 |
| 2 | #12346 | [P] 2. 建立業務邏輯層 | Task-待檢核, B2E-Implement, ParallelGroup-1 |
| 3 | #12347 | 3. 建立查詢 API | Task-待檢核, B2E-Implement |

**所有任務已連結至 Work Item #{workItemId}**
**所有任務均包含 `Task-待檢核` 和 `B2E-Implement` tag**
```

---

## Progress Tracking Table Format

**Immediately** after task creation, generate a tracking table in the following format:

```markdown
## 📊 Task Progress Tracking - YYYY-MM-DD

| SeqNo | Task ID | 標題 | 異動檔案 |
|-------|---------|------|----------|
| 1 | #12345 | [P] 1. 建立資料模型層 | `DataAccess/Entities/Product.cs` [NEW] |
| 2 | #12346 | [P] 2. 建立業務邏輯層 | `BusinessLogic/Services/PromotionService.cs` [NEW]<br>`BusinessLogic/Repositories/IPromotionRepository.cs` [NEW] |
| 3 | #12347 | 3. 建立查詢 API | `WebAPI/Controllers/ProductController.cs` [MODIFIED] |

---

**統計資訊：**
- 總任務數：{N}
- 可平行執行：{M}（標記 [P]）
- 循序執行：{K}
- 總影響檔案數：{T}（新增：{A}，修改：{B}）
```

Use `tf-work-item-writer` to write this table back to the `Custom.TaskProgress` field:

```
tf-work-item-writer(
    workItemId: workItemId,
    fieldUpdates: {
        "Custom.TaskProgress": {tracking_table_markdown}
    }
)
```

`tf-work-item-writer` automatically converts Markdown fully into HTML before writing, ensuring correct rendering in VSTS.

---

## AI Verification Trigger

```powershell
.\.github\ps\Invoke-TaskAIVerification.ps1 -TaskIds {comma_separated_task_ids}
```

**Execution mode:** Fire and forget (runs in the background in parallel)
**Result location:** VSTS Discussion (appears after roughly 1-3 minutes)

| Issue | Resolution |
|------|---------|
| Script not found | `Test-Path .\.github\ps\Invoke-TaskAIVerification.ps1` |
| Execution policy error | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Network error | Confirm `https://dify.91app.biz` is reachable |
