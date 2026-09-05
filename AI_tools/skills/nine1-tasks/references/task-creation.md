# Task Creation — VSTS Task 建立與進度追蹤表

---

## 建立規則

### 內容錨定原則（Content Anchoring）

- 使用 Step 6（使用者確認）的**完整原始內容**作為任務 Description
- **不重新生成、不摘要、不改寫**
- 僅針對 Azure DevOps Markdown 相容性進行格式微調

---

## create_work_item 參數

```
create_work_item(
    type: "Task",
    state: "New",
    project: {project},              // 來自 Step 5 確認
    areaPath: {areaPath},            // 來自 Step 5 確認
    iterationPath: {iterationPath},  // 來自 Step 5 確認
    parentId: {userStoryId},         // Work Item ID
    title: {formatted_title},
    description: {exact_step6_content},
    tags: {tags}
)
```

---

## 標題格式

| 類型 | 格式 |
|------|------|
| 循序任務 | `1. 任務標題`、`2. 任務標題` |
| 平行任務 | `[P] 1. 任務標題`、`[P] 2. 任務標題` |

---

## Tags 清單

| Tag | 適用條件 |
|-----|---------|
| `Task-待檢核` | **所有任務**均須加入 |
| `ParallelGroup-N` | 屬於平行執行分組的任務，N 為組別編號 |
| `Coding-Agent` | 選擇雲端非同步執行模式的任務 |

---

## 建立後驗收確認

```markdown
## ✅ 任務建立完成

| 序號 | Task ID | 標題 | Tags |
|------|---------|------|------|
| 1 | #12345 | [P] 1. 建立資料模型層 | Task-待檢核, ParallelGroup-1 |
| 2 | #12346 | [P] 2. 建立業務邏輯層 | Task-待檢核, ParallelGroup-1 |
| 3 | #12347 | 3. 建立查詢 API | Task-待檢核 |

**所有任務已連結至 Work Item #{workItemId}**
**所有任務均包含 `Task-待檢核` tag**
```

---

## 進度追蹤表格式

任務建立完成後，**立即**生成以下格式的追蹤表：

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

使用 `update_work_item` 將此表格回寫至 `Custom.TaskProgress` 欄位：

```
update_work_item(
    id: workItemId,
    fields: {
        "Custom.TaskProgress": {tracking_table_markdown}
    }
)
```

---

## AI 驗證觸發

```powershell
.\.github\ps\Invoke-TaskAIVerification.ps1 -TaskIds {comma_separated_task_ids}
```

**執行模式：** Fire and Forget（背景平行執行）  
**結果位置：** VSTS Discussion（約 1-3 分鐘後出現）

| 問題 | 解決方式 |
|------|---------|
| 找不到 Script | `Test-Path .\.github\ps\Invoke-TaskAIVerification.ps1` |
| 執行原則錯誤 | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| 網路錯誤 | 確認 `https://dify.91app.biz` 可存取 |
