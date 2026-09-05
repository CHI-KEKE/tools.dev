---
name: common-brownfield-greenfield-service-analyzer
description: >
  針對任一系統、服務或模組做「棕地轉綠地」深度盤點：相依展開、邏輯拆解、風險盤點、Mermaid 流程圖、文件輸出。
  當使用者提到棕地轉綠地、系統交接、重構前盤點、影響分析、流程圖化、遷移規劃時都應優先使用。
---

# Brownfield to Greenfield Service Analyzer

## 觸發條件與關鍵語句
當使用者提出以下語意時觸發：
- 「幫我把這個服務做棕地轉綠地盤點」
- 「我要完整整理相依與流程圖」
- 「幫我做重構前影響分析」
- 「我要交接文件，請把程式邏輯講清楚」
- 「請盤點這個模組所有相關程式」
- 「我要做技術遷移，先幫我盤點現況」
- 「我要把舊系統拆分，先畫清楚流程」

## 輸入

| 輸入欄位 | 說明 | 必填 |
|---|---|---|
| `targetArtifactPath` | 目標盤點物件路徑（可為 service/module/package/folder，例如 `src/.../OrderSyncService.cs`） | 是 |
| `targetSymbol` | 目標符號（類別/函式/模組名稱，例如 `OrderSyncService`） | 建議 |
| `entryPointPaths` | 呼叫入口候選（CLI/Batch/API Controller/Event Handler/Orchestrator） | 否 |
| `outputDocsDir` | 文件輸出目錄（例如 `docs/OrderSyncService/`） | 是 |
| `scopeNotes` | 範圍備註（例如「只看結帳流程」、「先不含報表」） | 否 |

## 操作流程

### Step 1：關聯掃描（Dependency Discovery）
1. 找出目標物件的抽象與實作關係（interface/abstract/concrete/factory/adapter）。
2. 展開直接/間接依賴：
   - Application Service / Domain Service / Interface
   - Repository / DAO / Gateway
   - Utility / Helper / Shared Module
   - ApiClient / SDK / Message Broker Producer-Consumer
   - DTO / Entity / ViewModel / Contract
3. 掃描呼叫入口（CLI、Batch entry、Controller、Scheduler、事件訂閱器、協調服務）。
4. 掃描設定來源（環境變數、設定檔、Feature Flag、常數、祕密管理來源）。
5. 補齊跨專案引用（Business/Application/Domain/Infrastructure/Utilities/外部服務）。
6. 標記同步與非同步邊界（HTTP、Queue、Cron、Webhook、DB Transaction）。

### Step 2：邏輯盤點（Logic Inventory）
針對每個主要邏輯段落，固定輸出：
- 輸入參數與驗證
- 查詢與資料來源
- 轉換規則
- 外部呼叫（HTTP/API/Cache/DB）
- 寫入/更新行為
- 錯誤處理與 fallback
- log/telemetry 行為
- 可觀測性缺口（指標、追蹤、告警）
- 可替換邊界（未來綠地可抽換點）

### Step 3：流程圖（Mermaid）
- 每段主要邏輯至少產出一張圖。
- 方法內分支 → `flowchart TD`
- 跨元件互動 → `sequenceDiagram`
- 需要呈現錯誤分支與重試/補償時序。
- 每張圖需附依據來源（檔案路徑 + 方法）。

### Step 4：文件輸出
將結果寫入 `outputDocsDir`，使用固定檔名結構（見下方模板）。

## 固定輸出結構範本

於 `{outputDocsDir}` 產出：
- `README.md`
- `Service-Logic-DeepDive.md`
- `Dependency-Map.md`
- `Flowcharts.md`
- `Risks-And-EdgeCases.md`

### README.md 最低內容
- 盤點目標
- 文件導覽連結
- 範圍摘要
- 主要發現摘要
- 建議綠地切分策略摘要（可並行、可漸進、需一次切換）

### Service-Logic-DeepDive.md 最低內容
- 主要流程逐步拆解
- 每段至少包含輸入/查詢/轉換/外呼/寫入/錯誤/log
- 每段標記：穩定區、技術債區、高變更風險區

### Dependency-Map.md 最低內容
- 直接依賴表
- 間接依賴表
- 呼叫入口
- 設定來源表
- 同步/非同步邊界與資料一致性註記
- 關聯檔案清單（可追溯）

### Flowcharts.md 最低內容
- 各主要流程 Mermaid 圖（每段至少 1 張）
- 每張圖標示關鍵風險節點

### Risks-And-EdgeCases.md 最低內容
- 重要分支與例外路徑
- 潛在風險與邊界條件
- 建議監控點
- 建議遷移順序與回退策略

## 泛化規則（可重用）
- 不綁定任一特定領域、專案、語言或框架，完全由 `targetArtifactPath/targetSymbol` 驅動。
- 適用任一「單一服務、單一模組、子系統或 bounded context 為核心」的棕地轉綠地任務。
- 若範圍過大，可拆分多輪輸出，但維持同一份輸出結構與章節命名。
- 若輸入僅提供資料夾，先收斂核心入口與主流程再展開次要支線。
- 禁止修改 runtime 行為或商業邏輯，只允許分析與文件輸出。

## 使用範例

### 範例 1：單一服務盤點
- `targetArtifactPath`: `src/SomeModule/OrderSyncService.cs`
- `targetSymbol`: `OrderSyncService`
- `outputDocsDir`: `docs/OrderSyncService/`

### 範例 2：跨層模組盤點
- `targetArtifactPath`: `src/Inventory/Allocation/`
- `targetSymbol`: `AllocationService`
- `entryPointPaths`: `src/Batch/AllocationRebuild/Program.cs`
- `outputDocsDir`: `docs/AllocationService/`

### 範例 3：事件驅動子系統盤點
- `targetArtifactPath`: `services/payment-events/`
- `targetSymbol`: `PaymentEventOrchestrator`
- `entryPointPaths`: `apps/api/src/controllers/payment-controller.ts, jobs/reconcile/main.go`
- `scopeNotes`: `先盤點授權與請款，不含退款`
- `outputDocsDir`: `docs/PaymentEventOrchestrator/`

## 品質檢核清單
- [ ] 已展開直接與間接依賴
- [ ] 已列出呼叫入口與設定來源
- [ ] 每個主要邏輯至少一張 Mermaid 圖
- [ ] 文件間連結可點擊且路徑正確
- [ ] 已標註同步/非同步邊界與一致性風險
- [ ] 已提出遷移順序與回退策略
- [ ] 僅修改文件/skill，無 runtime 行為異動
