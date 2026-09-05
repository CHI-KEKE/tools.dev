---
name: nine1-plan
description: >
  根據 Azure DevOps Work Item 生成完整的系統架構設計建議與實作計畫，產出 Arc42 格式
  的 ImplementPlan 並回寫至 VSTS。為 User Story to Tasks 流程的 Phase 2。
  完成後可 handoff 至 nine1-tasks 進行任務拆解。
---

# nine1-plan

User Story to Tasks — **Phase 2：架構規劃**

資深後端工程師視角，依據 WI 需求與釐清結果，生成具體可實作的架構設計藍圖。

---

## Quick Start

1. 載入 `tf-work-item-context` skill → 取得 WI Context（不強制驗證 ImplementPlan 非空）
2. 呼叫 `tf-clarifications-reader` → 彙整既有釐清記錄
3. 呈現 Context 摘要，等待使用者確認後繼續
4. 載入 `references/design-blueprint.md` → 生成核心設計（File Tree / DB / API）
5. 等待使用者確認核心設計後繼續
6. 載入 `references/cross-cutting-concerns.md` → 分析 Security / Perf / Maintainability
7. 產生 Mermaid 視覺化圖表（複雜流程）
8. 等待使用者確認進階分析後繼續
9. 載入 `references/implementplan-updater.md` → 更新 VSTS Custom.ImplementPlan

---

## 共用 Skill 依賴

| Skill | 用途 | 必要性 |
|-------|------|:------:|
| `tf-work-item-context` | WI 載入（允許 ImplementPlan 為空） | ✅ |
| `tf-clarifications-reader` | 讀取既有釐清記錄 | ✅ |

---

## Reference Map（按需載入）

| 檔案 | 載入時機 |
|------|---------|
| `references/design-blueprint.md` | Step 4 生成核心設計前 |
| `references/cross-cutting-concerns.md` | Step 6 進階分析前 |
| `references/implementplan-updater.md` | Step 9 更新 VSTS 前 |

---

## 執行流程

### Phase 1：Context 收集（自動執行）

#### Step 1 — 載入 WI Context
呼叫 `tf-work-item-context`（`requireImplementPlan: false`）。

#### Step 2 — 載入釐清記錄
呼叫 `tf-clarifications-reader`。

---

### Phase 2：Context 確認（需等待使用者確認）

#### Step 3 — 呈現 Context 摘要

```markdown
## 📋 Context Summary

### Work Item 資訊
...（WI 基本資訊）

### ImplementPlan 各段落狀態
...（✅/❌ 各 section）

### 釐清記錄摘要
...（最多 5 則，或「無釐清記錄」）

### 萃取的關鍵需求
- **功能需求：** ...
- **非功能需求：** ...
- **限制條件：** ...

---
✅ Context 摘要已完成。確認後進入核心架構設計？
```

**等待使用者確認**

---

### Phase 3A：核心設計（需等待使用者確認）

#### Step 4 — 生成系統設計藍圖

載入 `references/design-blueprint.md`，產出：
- 新增檔案清單（含路徑與職責）
- 修改檔案清單（含變更原因）
- 完整 File Tree（標示 [NEW] / [MODIFIED]）
- DB 異動（新增表格、欄位、索引、Migration 策略）
- 核心程式碼職責與元件互動說明

呈現設計後：

```markdown
✅ 核心設計藍圖完成。確認以上系統設計並繼續進階分析？
```

**等待使用者確認**

若使用者要求修改 → 重新規劃後再確認。

---

### Phase 3B：進階分析（需等待使用者確認）

#### Step 5 — 橫切關注點分析

載入 `references/cross-cutting-concerns.md`，聚焦：
- **Security**：認證/授權風險與緩解措施
- **Performance**：潛在瓶頸與優化策略
- **Maintainability**：架構分層、測試覆蓋、文件

#### Step 6 — 視覺化圖表（條件執行）

```
IF 業務流程涉及 3+ 系統元件 OR 有複雜分支 OR 需狀態機表示：
  → 生成 Mermaid 圖表（sequence diagram 或 flowchart）
ELSE：
  → 略過，標注「簡單 CRUD，無需視覺化圖表」
```

呈現進階分析後：

```markdown
✅ 進階分析完成。確認並更新 Azure DevOps ImplementPlan？
```

**等待使用者確認**

---

### Phase 4：文件更新（確認後自動執行）

#### Step 7 — 更新 Custom.ImplementPlan

載入 `references/implementplan-updater.md`，將設計結果整合至各 Arc42 section，使用 `update_work_item` MCP Tool 更新 VSTS。

顯示更新確認（含 diff 摘要）後：

```markdown
🎯 **Phase 2 Complete — Ready for Task Breakdown**
建議執行 `nine1-tasks` skill 進行任務拆解。
```

---

## 執行規則

- Steps 1-2 自動執行；Steps 3、4、5-6、7 各需一次使用者確認
- 不確定時立即詢問，不假設
- 使用者拒絕設計 → 重新規劃後再確認
- 複雜邏輯必須以 Mermaid 視覺化（簡單 CRUD 可略過）
- 所有使用者可見輸出使用**繁體中文**，技術術語保留英文

## ⛔ MUST NOT

- 不修改 Work Item `Description` 欄位
- 不在此階段產生或修改任何原始碼
- 不在關鍵 section 使用 `[TBD]` 佔位符（應先向使用者確認）
