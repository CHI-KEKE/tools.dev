---
name: nine1-story-to-tasks
description: 91APP 標準 Story 分析到 Task 開立的完整工作流程。當使用者要求「分析某張 User Story 並開 Tasks」時使用此 Skill。涵蓋：拉取 Story、程式碼分析、文件產出、Task 規劃確認、Azure DevOps Task 建立。
---

# Skill: 91APP Story → Task 開立流程

## 重要原則

> **每一個步驟執行前，必須先向使用者確認，取得明確同意後才繼續執行下一步。**  
> 禁止連續執行多個步驟而不停下來確認。

---

## 快速路徑（已分析過的 Story）

若該 Story **已完成分析且文件已存在**，直接跳至 Step 4。

**判斷方式（按順序檢查）**：
1. Session 對話記錄中已有此 Story 的分析結論
2. 文件路徑下已存在對應的 md 資料夾（`05-改動建議.md` 存在且結論明確）

若符合上述任一條件，執行以下動作後直接進入 Step 4：
- 向使用者說明：「#XXXXX 已分析完畢，跳過 Step 1-3，直接進入 Task 規劃確認。」
- 簡短摘要分析結論（修改位置、修改內容、是否需要改 Code）

---

## 完整流程

### Step 1：拉取 User Story

**執行前確認**：「我將拉取 User Story #{id}，請確認。」

**動作**：
- 使用 `get_work_item_details` 取得指定 Story 的完整內容
- 向使用者說明：Story 標題、問題描述、Acceptance Criteria 重點摘要

---

### Step 1.5：拆分點確認（複雜 Story 適用）

**觸發條件**：Story 內容涉及以下任一情況時，在進入 Step 2 前先執行此步驟：
- 多個顯示位置（如：列表頁 + 購物車區塊）
- 多個排除條件或檢核項目（3 個以上）
- 需對照既有功能作為基準（如：「對照 CartAddOns 邏輯」）
- 描述中有「分別處理」或「各自獨立」的暗示

**執行前確認**：「這張 Story 包含多個邏輯處理點，我先拆分後請確認方向再開始分析。」

**動作**：
- 閱讀 Story 內容，列出所有獨立處理點，以表格方式呈現：

| # | 處理點 | 說明 | 需分析的問題 |
|---|--------|------|------------|
| A | {處理點名稱} | {一行說明} | {需釐清的問題} |

- **等使用者確認拆分方向後**，才進入 Step 2

**注意**：
- 拆分點應以「獨立可分析、可驗證」為原則
- 拆分結果會直接影響後續 Task 數量，需使用者明確認可

---

### Step 2：程式碼分析

**執行前確認**：「我將開始分析相關程式碼，請提供下列資訊（或確認使用預設路徑）：
- 相關 Repo 或站台路徑
- 是否有特定需要重點分析的檔案或模組」

**動作**：
- 根據使用者提供的路徑，逐一分析相關程式碼
- 找出 BUG 根因 / 影響範圍 / 修改點
- **每分析完一個關鍵面向，停下來向使用者確認認知是否一致**，不直接跳到結論

**常見分析面向**（視 Story 類型調整）：
- 識別機制（商品如何被標記）
- 加購 / 購買流程追蹤
- 各層現狀（SPL → Cart Domain → MWeb BLV2 → 前端）
- BUG 根因定位

---

### Step 3：產生分析文件

**執行前確認**：「分析完畢，我將產生文件到以下路徑，請確認：
`{使用者指定的桌面路徑}\{Story主題名稱}\`

將產生以下文件：
- README.md（核心結論索引）
- 01-需求說明.md
- 02-識別機制.md（或對應的機制文件）
- 03-完整流程追蹤.md
- 04-BUG根因.md
- 05-改動建議.md」

**動作**：
- 在使用者確認路徑與文件清單後，建立所有 md 文件
- 每個文件內容必須反映 Step 2 中雙方確認一致的分析結論

**文件產出路徑規範**：
```
C:\Users\Allen Lin\Desktop\joy_2\joy_\ShoppingCart\滿額加價購\{主題名稱}\
├── README.md
├── 01-需求說明.md
├── 02-{機制名稱}.md
├── 03-完整流程追蹤.md
├── 04-BUG根因.md
└── 05-改動建議.md
```

---

### Step 4：確認 Task 規劃

**執行前確認**：「根據分析，我建議開立以下 RD Tasks，請確認內容與數量是否符合預期：

| # | Task 標題 | 說明 |
|---|---------|------|
| 1 | {Task 1 標題} | {一行說明} |
| 2 | {Task 2 標題} | {一行說明} |

**不需要開 Task 的部分**：
- {Repo/層級}：{原因}」

**注意**：
- 只開 RD Task（不含 QA、PM Task）
- 只改有必要改的 Repo，不開多餘 Task
- 若分析結論為「不需要改 Code」，明確告知使用者，詢問是否仍需開 Task

---

### Step 5：實際建立 Tasks

**執行前確認**：「我將以下列參數建立 Tasks，請最終確認：
- **Owner**：{assigned_to}
- **Start Date**：{start_date}
- **End Date**：{end_date}
- **Original Estimate**：{hours}hr
- **Remaining Work**：{hours}hr
- **Parent Story**：#{story_id}
- **Sprint**：{iteration_path}
- **Area**：{area_path}」

**動作**：
- 使用 `create_work_item` 建立每個 Task，parent 指向原 Story
- 同時設定 `Microsoft.VSTS.Scheduling.OriginalEstimate` 與 `Microsoft.VSTS.Scheduling.RemainingWork`
- 建立完成後列出所有 Task ID 供使用者確認

---

## Azure DevOps 欄位對照

| 欄位 | API 名稱 |
|------|---------|
| 負責人 | `assigned_to` |
| 開始日期 | `Microsoft.VSTS.Scheduling.StartDate` |
| 結束日期 | `Microsoft.VSTS.Scheduling.FinishDate` |
| 估時 | `Microsoft.VSTS.Scheduling.OriginalEstimate` |
| 剩餘工時 | `Microsoft.VSTS.Scheduling.RemainingWork` |
| Sprint | `iteration_path` |
| Area | `area_path` |

---

## 預設參數（固定，不需詢問）

| 參數 | 預設值 |
|------|-------|
| 文件根路徑 | `C:\Users\Allen Lin\Desktop\joy_2\joy_\ShoppingCart\滿額加價購\` |
| Owner | `allenlin@91app.biz`（固定，不需詢問）|
| Project | 從 Parent Story 繼承（固定，不需詢問）|
| Area Path | 從 Parent Story 繼承（固定，不需詢問）|
| Sprint | 從 Parent Story 繼承（固定，不需詢問）|

## 每次必問參數（不可假設，即使上一張 Story 用過相同值）

> ⚠️ 每次進入 Step 5 前，無論之前有無範例，**必須**向使用者詢問以下三個參數：

| 參數 | 說明 |
|------|------|
| **估時（hr）** | Original Estimate 與 Remaining Work 均設為此值 |
| **Start Date** | 格式 YYYY-MM-DD |
| **End Date** | 格式 YYYY-MM-DD |

---

## 流程圖

```
User Story ID
     │
     ▼
[已分析過？] ──YES──→ 摘要結論 → Step 4 → Step 5
     │
     NO
     │
     ▼ [確認後執行]
Step 1：拉取 Story → 說明摘要
     │
     ▼ [確認後執行]
Step 2：程式碼分析 → 來回確認認知
     │
     ▼ [確認後執行]
Step 3：產生 md 文件（6 個）
     │
     ▼ [確認後執行]
Step 4：列出 Task 規劃 → 使用者確認
     │
     ▼ [確認後執行]
Step 5：建立 Azure DevOps Tasks
```
