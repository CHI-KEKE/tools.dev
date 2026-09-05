# 輸出格式規範

本文件定義四個盤點層級的輸出欄位詳細說明與填寫規範。

---

## Level 1：Repository 層級輸出規範

### 必填欄位

| 欄位 | 來源 | 填寫規範 |
|---|---|---|
| Solution 名稱 | `.sln` 檔案名稱 | 去掉副檔名 |
| 一句話摘要 | README 或 namespace 命名推斷 | 20 字以內，動詞開頭 |
| 用途 | README.md 第一段 | 2-3 句話，描述業務價值 |
| 技術棧 | `.csproj` 的 `<TargetFramework>` + 主要 NuGet | 格式：`net8.0 / EF Core 8 / Redis / RabbitMQ` |
| 狀態 | 最近 commit 時間或 README 說明 | 活躍開發 / 維護模式 / 已棄用 / 未知 |
| 專案數量 | solution 中的專案數量 | 整數 |

### 模組地圖欄位

| 欄位 | 說明 |
|---|---|
| 模組/專案名稱 | `.csproj` 的專案目錄名稱（不含路徑） |
| 職責說明 | 從 namespace、README、主要類別名稱推斷，10-15 字 |
| 類型 | Web API / Class Library / Console App / Worker Service |
| 備註 | 主要對外服務、被多個模組引用、已棄用 等標記 |

### 進入點識別規則

| 進入點類型 | 識別方式 |
|---|---|
| API 進入點 | 有 `Controllers/` 目錄 |
| Worker 進入點 | `Program.cs` 含 `AddHostedService` 或 `BackgroundService` |
| 訊息消費者 | 有 `Consumers/`、`Handlers/` 目錄，或繼承 `IMessageHandler` |
| 排程作業 | `IHostedService` + Cron，或明確的 Job 命名 |

---

## Level 2：模組層級輸出規範

### 一句話摘要

- 格式：`{動詞} {業務對象} 的 {核心功能}`
- 範例：`處理訂單建立、修改與查詢的核心業務模組`

### 目錄結構摘要格式

使用 ASCII tree：
```
ModuleName/
├── Controllers/     # API 端點（N 個 Controller）
├── Services/        # 業務邏輯層（N 個 Service）
└── ...
```

子目錄說明格式：`# {職責說明}（{N} 個{檔案/Controller/Service}）`

### 核心類別清單規則

1. 按重要度排序（🔴 → 🟡 → 🟢）
2. 同重要度按行數降冪
3. 超過 30 個 class 時：只列 🔴 高重要度的全部 + 🟡 中重要度前 5 名，其餘彙整
4. 純 DTO/Entity 若超過 10 個，彙整為一行：`其餘 N 個 🟢 低重要度 DTO/Entity 類別`

### 相依關係填寫規則

**依賴類型標準**：
- `內部模組`：solution 內其他專案（`<ProjectReference>`）
- `NuGet 套件`：第三方套件
- `外部服務`：HTTP API、Redis、RabbitMQ 等（通常從 appsettings 設定推斷）

**用途說明規範**：說明「為什麼用」而非「是什麼」
- ✅ `快取商品價格資料，減少 DB 查詢`
- ❌ `Redis 快取`

---

## Level 3：類別層級輸出規範

### 方法清單欄位規範

| 欄位 | 說明 |
|---|---|
| 方法名稱 | 含括號，如 `CreateOrder()` |
| 用途 | 從方法名稱和方法體第一個動作推斷，8-12 字 |
| 參數摘要 | 格式：`{型別} {名稱}[, ...]`，超過 3 個參數用 `(N 個參數)` 替代 |
| 回傳值 | 完整型別名稱，如 `Task<OrderResponse>` |
| 行數 | 方法起訖行數計算 |
| 備註 | async / 主要進入點 / 已棄用 / 含複雜邏輯 |

### 邏輯流程描述規範

- 步驟數量：3-7 步，過多代表需要分解
- 每步格式：`{動詞} {做了什麼}（呼叫 \`{DependencyName}.{Method}\`）`
- 只描述主線流程，不描述錯誤處理細節（除非錯誤處理是核心邏輯）
- 範例：
  1. 驗證輸入參數（呼叫 `_validator.Validate()`）
  2. 查詢會員等級（呼叫 `_memberService.GetTier(memberId)`）
  3. 計算折扣金額（本地邏輯）
  4. 寫入訂單（呼叫 `_repository.Insert(order)`）
  5. 發布建立事件（呼叫 `_eventBus.Publish()`）

### 技術債嚴重度判斷表

| 問題類型 | 嚴重度 | 觸發條件 |
|---|---|---|
| 方法過長 | ⚠️ | 方法行數 > 100 行 |
| Magic Number | ⚠️ | 非 0、1、-1 的硬編碼數字 |
| 硬編碼字串 | ⚠️ | URL、SQL、固定路徑直接寫在程式碼中 |
| 空 catch 區塊 | ⚠️ | `catch { }` 或 `catch { /* ignored */ }` |
| TODO 備註 | ℹ️ | `// TODO` 或 `// FIXME` |
| 巢狀過深 | ℹ️ | 縮排超過 4 層 |

---

## Level 3.6：API Spec 層級輸出規範

### 文件章節結構（固定順序）

1. `## [API Name] - [HTTP Method]`
2. `### 1. 循序圖 (Sequence Diagram)`
3. `### 2. 請求與回應 (Request & Response)`
4. `### 3. 資料格式 (Data Schema)`
5. `### 4. 資料庫欄位對照 (DB Schema)`
6. `### 5. 使用範例 (Example)`

### Request/Response 欄位規範

| 欄位 | 說明 |
|---|---|
| Endpoint | 必填，格式：`POST /v1/orders` |
| Request Headers / Path / Query | 以表格呈現，欄位至少含：名稱、型別、必填、說明 |
| Request Body | 以表格呈現，欄位至少含：欄位路徑、層級、型別、必填、說明 |
| Response (Success) | 以表格呈現，至少包含狀態碼、欄位路徑、型別、說明 |
| Response (Error) | 以表格呈現，建議列出常見錯誤碼（400/401/403/404/500）與錯誤欄位 |

### 多階層 JSON 欄位展開規範

| 規則 | 說明 |
|---|---|
| 路徑表示法 | 使用 `parent.child` 表示物件巢狀欄位 |
| 陣列表示法 | 使用 `items[].field` 表示陣列元素欄位 |
| 層級欄位 | 需加上 `層級` 欄位（root=1，下一層=2，以此類推） |
| 葉節點展開 | 必須展開到可驗證的葉節點，不可只停在 `Object` 容器 |

### Data Schema 欄位規範

| 欄位 | 規範 |
|---|---|
| 欄位名稱 | 使用 API 契約名稱（非 DB 欄位名），建議用路徑格式 |
| 層級 | 以數字標示 JSON 層級 |
| 型別 | String / Integer / Boolean / Object / Array 等 |
| 必填 | `Yes` / `No` |
| 說明 | 包含限制條件（長度、枚舉、格式） |

### DB Schema 對照規範

| 欄位 | 規範 |
|---|---|
| 資料庫類型 | 如 MSSQL / MongoDB / DynamoDB / Redis |
| 資料表 / 集合 | 實際儲存位置 |
| 欄位 / Key | 實際落地欄位 |
| 型別 | DB 層型別 |
| 備註 | 預設值、索引、TTL、來源欄位映射 |

若無法從程式碼確認完整映射，仍需保留列並在備註填 `待確認`。

### Mermaid 規範

- 必須使用 `sequenceDiagram`
- 至少涵蓋：Client、API、Service、DB（或外部系統）
- 需標示主成功路徑；若有主要錯誤分支，至少補一條失敗回應

---

## Level 4：跨系統相依輸出規範

### 互動方式標準用詞

| 實際實作 | 顯示用語 |
|---|---|
| HttpClient / RestClient | REST API |
| StackExchange.Redis | Redis TCP |
| RabbitMQ | AMQP |
| Azure Service Bus | Azure Service Bus |
| EF Core / Dapper | SQL（{DB 名稱}） |
| gRPC Client | gRPC |
| 直接 ProjectReference | 直接引用 DLL |

### 影響評估標準

| 等級 | 條件 | 標記 |
|---|---|---|
| 必須驗證 | 直接呼叫此模組的 HTTP API 或直接引用 DLL | ✅ |
| 建議通知 | 透過共用 Library 間接依賴 | 📢 |
| 注意監控 | 訊息佇列消費者、共用資料表讀取方 | 👀 |

### 頻率估算規則

| 訊號 | 頻率標記 |
|---|---|
| `[HttpPost]`、`[HttpPut]`（寫入 API） | 高（即時） |
| `[HttpGet]`（查詢 API） | 中至高（即時） |
| `IHostedService` + 固定時間 | 低（定時排程） |
| 訊息佇列消費者 | 依訊息量而定 |
| 無法判斷 | 未知 |
