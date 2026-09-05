# Parallel Analysis — 平行執行分析與依賴矩陣

---

## [P] 標記條件（須全部符合 4 條）

1. **檔案獨立性**：與其他平行任務無重疊的檔案路徑
2. **依賴獨立性**：對同組其他任務無顯式或隱式的執行順序依賴（包含參考、注入、實作、繼承、映射、測試、或其他消費關係）
3. **共用合約/資源獨立性**：不修改其他任務使用的共用資源，包含：DB Schema、設定檔、全域狀態、共用介面、共用 DTO、基底類別、共用 Helper、DI 註冊
4. **獨立可測試性**：建置、DI 接線、單元測試可獨立執行，不依賴其他平行任務的輸出

---

## 強制依賴判斷準則

以下關鍵字出現時，視為依賴訊號，不可標記 `[P]`：

> `depends on`、`requires`、`uses`、`injects`、`implements`、`extends`、`maps to`、`based on`、`shared`

**依賴推論範例：**
- Task A 建立 `IPromotionService` 介面
- Task B 注入並使用 `IPromotionService`
- → Task B **不可**與 Task A 標記 `[P]`（消費 Task A 新建立的合約）

---

## 執行流程

### Step 1 — 建立依賴矩陣

| 任務 | 依賴於 | 產出/修改的產出物 | 消費的產出物 | 阻塞原因 |
|------|--------|-----------------|------------|---------|
| Task 1 | — | `IPromotionService`（新） | — | — |
| Task 2 | Task 1 | `PromotionService.cs`（新） | `IPromotionService` | 消費 Task 1 新建介面 |
| Task 3 | Task 1 | `ProductController.cs`（修改） | `IPromotionService` | 消費 Task 1 新建介面 |

### Step 2 — 驗證每個 [P] 任務對

對每個 `[P]` 任務對，驗證：
1. 無直接依賴
2. 無傳遞依賴
3. 無生產者-消費者合約關係
4. 無共用合約/資源衝突

**若任意一項失敗 → 移除 [P] 標記並重新分組。**

### Step 3 — 定義執行分組

```markdown
**Group 1（平行）：** [P] Task 1, [P] Task 2, [P] Task 4
**Group 2（Group 1 後）：** Task 3, Task 5
```

### Step 4 — 逐一說明

對每個任務，明確聲明：
- `[P]` 任務 → **平行安全原因**
- 非 `[P]` 任務 → **阻塞原因（Blocked By）**

---

## 執行模式分類

| 模式 | 適用情況 | Tag |
|------|---------|-----|
| 本地（同步） | 高複雜度、原型開發、需要即時監督的重構 | 無 |
| 雲端（非同步） | 功能新增、Bug 修復、重複性任務（測試良好的 Repo） | `Coding-Agent` |

---

## 任務標題格式

- 循序任務：`1. 任務標題`
- 平行任務：`[P] 1. 任務標題`
