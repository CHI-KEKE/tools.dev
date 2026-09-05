---
name: nine1-tasks
description: >
  將 Azure DevOps Work Item 拆解為可執行的 Tasks，分析平行執行可能性，驗證拆解完整性，
  在 VSTS 建立 Task，並生成任務進度追蹤表。為 User Story to Tasks 流程的 Phase 3。
---

# nine1-tasks

User Story to Tasks — **Phase 3：任務拆解與建立**

資深後端工程師視角，將架構設計藍圖轉換為可指派的原子化任務，並識別平行執行機會。

---

## Quick Start

1. 載入 `tf-work-item-context` skill → 取得 WI Context
2. 呼叫 `tf-clarifications-reader` → 彙整釐清記錄
3. 驗證 ImplementPlan 完整性，等待使用者確認
4. 載入 `references/task-breakdown.md` → 生成任務清單
5. 載入 `references/parallel-analysis.md` → 平行執行分析
6. 呈現完整任務拆解，等待使用者確認
7. 載入 `references/task-validation.md` → 7 維度驗證
8. 確認 VSTS 建立參數後，載入 `references/task-creation.md` → 建立 Tasks
9. 生成任務進度追蹤表並回寫 VSTS
10. 執行 AI 驗證（觸發驗證 Script）

---

## 共用 Skill 依賴

| Skill | 用途 | 必要性 |
|-------|------|:------:|
| `tf-work-item-context` | WI 載入與驗證 | ✅ |
| `tf-clarifications-reader` | 讀取既有釐清記錄 | ✅ |

---

## Reference Map（按需載入）

| 檔案 | 載入時機 |
|------|---------|
| `references/task-breakdown.md` | Step 4 生成任務清單前 |
| `references/parallel-analysis.md` | Step 5 平行分析前 |
| `references/task-validation.md` | Step 7 驗證前 |
| `references/task-creation.md` | Step 8 建立任務前 |

---

## 執行流程

### Step 1-2 — 載入 Context（自動執行）

呼叫 `tf-work-item-context` 和 `tf-clarifications-reader`。

---

### Step 3 — 驗證 ImplementPlan 完整性（等待確認）

呈現各 section 填寫狀態：

```markdown
## 📋 ImplementPlan 完整性確認

- ✅/❌ 作法概述
- ✅/❌ DB Schema
- ✅/❌ API Spec
...
```

**若所有 section 為空 → 停止，提示先執行 `nine1-plan`。**

**若有內容 → 詢問：** "ImplementPlan 已確認，開始任務拆解？"

---

### Step 4 — 生成任務清單

載入 `references/task-breakdown.md`，依以下原則生成任務：
- 每個任務 2-4 小時工作量
- 每個任務影響 3-8 個檔案
- 確保可獨立測試

---

### Step 5 — 平行執行分析

載入 `references/parallel-analysis.md`，使用 4 條件 Framework 評估哪些任務可平行執行，並建立依賴矩陣。

---

### Step 6 — 呈現完整拆解（等待確認）

```markdown
✅ 任務拆解包含 {N} 個任務，{M} 個可平行執行 [P]。確認或修改？
```

**等待使用者確認**

---

### Step 7 — 7 維度驗證

載入 `references/task-validation.md`，執行完整驗證報告。

- **若有 Critical Issues → STOP，回到 Step 4 重新規劃**
- **若只有 Warnings → 呈現使用者選項，等待決定**

---

### Step 8 — 確認 VSTS 建立參數（等待確認）

確認：`Project`、`Area Path`、`Iteration Path`

```markdown
✅ 確認建立參數：Project: `{name}`, Area: `{path}`, Iteration: `{path}`？
```

---

### Step 9 — 建立 Tasks

載入 `references/task-creation.md`，使用 `create_work_item` MCP Tool 建立所有 Tasks。

**關鍵規則：使用 Step 6 確認的完整內容，不重新生成或改寫。**

---

### Step 10 — 生成進度追蹤表

生成 Task Progress Tracking Table 並回寫至 WI `Custom.TaskProgress` 欄位。（**此步驟不可略過**）

---

### Step 11 — 觸發 AI 驗證

提供執行指令：
```powershell
.\.github\ps\Invoke-TaskAIVerification.ps1 -TaskIds {task_ids}
```

---

## 執行規則

- Steps 1-2 自動執行；Steps 3、6、8 各需使用者確認
- Step 7 驗證有 Critical Issues 時強制回 Step 4
- Step 10（進度表）不可略過
- Step 9 任務建立使用 Step 6 確認的原始內容，不重新生成
- 所有使用者可見輸出使用**繁體中文**

## ⛔ MUST NOT

- 不修改 Work Item `Description` 欄位
- 不在此階段產生或修改任何原始碼
- 不跳過 Step 10 進度追蹤表
- 不在 Step 9 重新生成或改寫 Step 6 確認的任務內容
