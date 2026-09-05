---
name: nine1-clarify
description: >
  分析 Azure DevOps Work Item 需求，透過結構化問題識別技術模糊點，收集釐清回答並
  回寫至 VSTS Discussion，最後驗證 Arc42 架構就緒度。為 User Story to Tasks 流程的
  Phase 1。完成後可 handoff 至 nine1-plan 進行架構規劃。
---

# nine1-clarify

User Story to Tasks — **Phase 1：需求釐清**

資深後端工程師視角，識別 Work Item 的技術盲點、資料模型疑慮、API 設計問題與系統整合風險。

---

## Quick Start

1. 載入 `tf-work-item-context` skill → 取得 WI Context（含 ImplementPlan 驗證）
2. 執行需求模糊度掃描（載入 `references/ambiguity-taxonomy.md`）
3. 生成釐清問題（載入 `references/question-generation.md`）
4. 收集使用者回答，呼叫 `tf-discussion-writer` 寫入 VSTS
5. 評估是否需要多輪釐清
6. 執行 Arc42 就緒度驗證（載入 `references/arc42-readiness.md`）
7. 輸出 Phase 1 完成摘要，準備 handoff 至 `nine1-plan`

---

## 共用 Skill 依賴

| Skill | 用途 | 必要性 |
|-------|------|:------:|
| `tf-work-item-context` | WI 載入、ImplementPlan 驗證 | ✅ |
| `tf-discussion-writer` | 將釐清結果寫入 VSTS Discussion | ✅ |

---

## Reference Map（按需載入）

| 檔案 | 載入時機 |
|------|---------|
| `references/ambiguity-taxonomy.md` | Step 2 執行模糊度掃描前 |
| `references/question-generation.md` | Step 3 生成問題前 |
| `references/arc42-readiness.md` | Step 6 執行 Arc42 驗證前 |

---

## 執行流程

### Step 1 — 載入 WI Context

呼叫 `tf-work-item-context`（`requireImplementPlan: true`）。

若驗證失敗 → 中止，不繼續執行。

顯示（繁體中文）：
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

⏳ 正在分析需求模糊度...
```

---

### Step 2 — 模糊度掃描

載入 `references/ambiguity-taxonomy.md`，對 5 個優先類別進行系統性掃描，評估每個類別狀態：**Clear / Partial / Missing**。

**若所有類別均為 Clear：**
```markdown
## ✅ 需求分析完成

未檢測到關鍵模糊點。需求已足夠清晰，可進行架構驗證。

⏳ 繼續進行 Arc42 架構就緒度驗證...
```
→ 跳至 Step 6。

**否則：** 繼續 Step 3。

---

### Step 3 — 生成釐清問題（每輪最多 5 題）

載入 `references/question-generation.md`，依 **Impact × Uncertainty** 優先序生成問題。

每題必須包含：
- 類別標籤（雙語）
- 推薦答案 + 1-2 句理由（繁體中文）
- 選項表格或簡答格式

呈現完問題後，**暫停等待使用者回答**。

---

### Step 4 — 收集與驗證回答

**支援輸入格式：**
- `全部接受` / `yes to all` → 採用所有推薦答案
- `1: A, 2: yes, 3: 使用 Repository` → 個別回答
- 指定問題要求重新說明 → 針對該題補充說明後重新等待

驗證確認後，以繁體中文列出所有已記錄的回答摘要。

---

### Step 5 — 寫入 VSTS Discussion

呼叫 `tf-discussion-writer`：
- `commentTitle`：`📋 Clarifications - {YYYY-MM-DD}`
- `commentMarkdown`：格式化的釐清 Q&A 內容（僅記錄答案實質內容，不記錄選項字母）

成功後評估是否需要多輪釐清（載入 `references/question-generation.md` 中的 multi-round 邏輯）：
- `[Y]` 繼續下一輪 → 回 Step 3
- `[N]` / `[S]` → 繼續 Step 6

---

### Step 6 — Arc42 就緒度驗證

載入 `references/arc42-readiness.md`，評估各 section 就緒狀態（Ready / Needs Input / Missing）。
**不暫停等待使用者，直接進入 Step 7。**

---

### Step 7 — 輸出 Phase 1 完成摘要

輸出包含：
- 模糊度改善表格
- 釐清問題完整 Q&A（依輪次分組）
- Arc42 各 section 就緒度表格
- 整體就緒評估（✅ Ready / ⚠️ Proceed with Caution / ❌ Needs More Input）
- 建議下一步行動

**完成後可 handoff 至 `nine1-plan`。**

---

## 行為規則

- 所有使用者可見輸出使用**繁體中文**
- 類別標籤使用雙語格式：`[English / 繁體中文]`
- 答案記錄僅存實質內容（例如「使用 httpOnly cookie」，不記錄「選項 B」）
- 每輪至多 5 題，輪次不限
- 遇到終止訊號（「結束」、「不用了」）立即停止提問，進行 Arc42 驗證
- **不修改** Work Item Description 欄位

---

## ⛔ MUST NOT

- 不修改 Work Item `Description` 欄位
- 不在釐清記錄中寫入選項字母（`選項 A`、`yes`、`suggested`）
- 不跳過 Arc42 驗證（即使無模糊點也需執行）
