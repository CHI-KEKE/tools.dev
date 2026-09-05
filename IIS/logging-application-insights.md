# Application Insights Telemetry

## 原理

Application Insights（簡稱 AI）是 Microsoft Azure 的 APM（Application Performance Monitoring）工具。在 .NET 專案中，透過 NuGet 安裝 `Microsoft.ApplicationInsights` SDK 後，SDK 會自動收集：

| Telemetry 類型 | 說明 |
|----------------|------|
| **Request** | 每個 HTTP request 的 URL、duration、success/fail |
| **Exception** | 未被處理或主動 track 的例外 |
| **Dependency** | 對外的 HTTP call、DB query、Redis 呼叫等 |
| **Trace** | `TelemetryClient.TrackTrace()` 的訊息 |
| **Metric** | 自訂指標 |
| **Event** | 自訂事件 |

這些資料會透過 **InstrumentationKey** 送到你的 Azure Application Insights resource。

---

## SCMAPIV2 的狀態：Unconfigured 模式

SCMAPIV2 **沒有設定 InstrumentationKey**，因此 Application Insights SDK 進入 **unconfigured 模式**：

- 所有 telemetry **只輸出到 Visual Studio Debug Output 視窗**
- **不會送到 Azure**（沒有 key，送不出去）
- 功能上完全正常，只是沒有雲端收集

### Unconfigured 模式的輸出格式

每筆 telemetry 在 VS Output 視窗輸出格式：

```
Application Insights Telemetry (unconfigured): {json_payload}
```

範例：

```
Application Insights Telemetry (unconfigured): {"name":"Microsoft.ApplicationInsights.Dev.Request","time":"2026-04-20T10:23:45.123Z","data":{"baseType":"RequestData","baseData":{"id":"a3f2b1c9","name":"POST /api/promotion/update","duration":"00:00:00.145","responseCode":"500","success":false,"url":"https://localhost/api/promotion/update"}}}

Application Insights Telemetry (unconfigured): {"name":"Microsoft.ApplicationInsights.Dev.Exception","time":"2026-04-20T10:23:45.130Z","data":{"baseType":"ExceptionData","baseData":{"exceptions":[{"typeName":"System.Collections.Generic.KeyNotFoundException","message":"The given key was not present in the dictionary.","hasFullStack":true,"stack":"   at ScmApiV2.Services.PromotionService.GetById(Int32 id)\r\n   at ScmApiV2.Controllers.PromotionController.UpdatePromotion(...)"}]}}}
```

> 詳細說明請參考 [logging-vs-output.md](./logging-vs-output.md)，VS Output 視窗的 attach 方式。

---

## 本機 Unconfigured 怎麼看

**唯一方式：透過 VS Output 視窗**

1. Visual Studio → Attach to `w3wp.exe`
2. Debug → Windows → Output → 下拉選 "Debug"
3. 觸發 API request
4. 看到 `Application Insights Telemetry (unconfigured): {...}` 的輸出

無法用其他工具（Azure Portal、Fiddler 等）看到，因為根本沒送出去。

---

## Configured 模式（正式環境）怎麼看

若正式環境有設定 InstrumentationKey，可以到 Azure Portal 查詢：

### Azure Portal 查詢路徑

```
Azure Portal
└── Application Insights resource（對應 SCMAPIV2 正式環境）
    ├── Transaction search（搜尋特定 request）
    ├── Failures（所有失敗 request 和 exception）
    ├── Performance（response time 分析）
    └── Logs（使用 Kusto Query Language 查詢）
```

### 用 ErrorId 搜尋特定 Request

SCMAPIV2 的 API response 在發生錯誤時回傳 `ErrorId`，這個 ID 對應 Application Insights 的 `operation_Id`（operation correlation ID）。

**在 Azure Portal 操作：**

1. 進入 Application Insights → **Transaction search**
2. **Search** 欄位輸入 ErrorId（例如 `a3f2b1c9-4b2e-4f3a-8c1d-123456789abc`）
3. 可以看到完整的 request timeline：
   - Request 本身（URL、duration、status）
   - 所有相關的 Dependency（DB query、Redis、downstream API）
   - Exception（含 stack trace）
   - Trace（TelemetryClient.TrackTrace 的訊息）

**用 Kusto Query Language（KQL）查詢：**

```kusto
-- 找特定 operation（ErrorId）
requests
| where operation_Id == "a3f2b1c9-4b2e-4f3a-8c1d-123456789abc"
| project timestamp, name, duration, resultCode, success

-- 找相關的 exception
exceptions
| where operation_Id == "a3f2b1c9-4b2e-4f3a-8c1d-123456789abc"
| project timestamp, type, outerMessage, innermostMessage, stack

-- 找最近 1 小時所有失敗的 request
requests
| where timestamp > ago(1h)
| where success == false
| summarize count() by name, resultCode
| order by count_ desc
```

---

## Operation ID 與 ErrorId 的對應關係

```
API Response Body
{
  "errorId": "a3f2b1c9-4b2e-4f3a-8c1d-123456789abc"  ← 這個
}
          ↕
Application Insights
{
  "operation_Id": "a3f2b1c9-4b2e-4f3a-8c1d-123456789abc"  ← 對應這個
}
```

只要拿到 `ErrorId`，就能在 Azure AI 找到這個 request 的完整 telemetry。

---

## 適用情境

| 情境 | 使用方式 |
|------|----------|
| 本機 debug | VS Output 視窗（unconfigured 輸出） |
| 正式環境追查特定 ErrorId | Azure Portal Transaction search |
| 正式環境效能分析 | AI Performance blade |
| 正式環境找某段時間的 500 錯誤 | AI Failures blade |
| 複雜查詢（跨多個 request） | AI Logs + KQL |

---

## 看得到什麼 vs 看不到什麼

| | Unconfigured（本機） | Configured（正式） |
|---|---|---|
| Request telemetry | ✅ VS Output | ✅ Azure Portal |
| Exception with stack | ✅ VS Output | ✅ Azure Portal |
| Dependency tracking | ✅ VS Output | ✅ Azure Portal |
| 跨時段查詢 | ❌ | ✅ |
| 用 ErrorId 搜尋 | ❌（看不到歷史） | ✅ |
| NLog 寫的 log 內容 | ❌ | ❌ |
| Request body | ❌ | ❌（需要自訂） |
