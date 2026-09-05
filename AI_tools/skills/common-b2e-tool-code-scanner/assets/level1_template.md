# 📦 {Solution 名稱} 盤點報告

> **一句話摘要**：{這個 repo 的核心職責，20 字以內}

## 概述
- **用途**：{詳細描述，2-3 句話說明業務價值}
- **技術棧**：{TargetFramework} / {主要套件，例如 EF Core 8 / Redis / RabbitMQ}
- **狀態**：{活躍開發 | 維護模式 | 已棄用 | 未知}
- **專案數量**：{N} 個

## 模組地圖
| 模組/專案名稱 | 職責說明 | 類型 | 備註 |
|---|---|---|---|
| {ProjectA} | {職責描述} | {Web API / Class Library / Console App / Worker Service} | {主要對外服務 / 核心共用模組 / 已棄用} |
| {ProjectB} | {職責描述} | {類型} | {備註} |

## 關鍵進入點（Entry Points）
- **API 進入點**：`{Controllers 路徑}`
- **Worker 進入點**：`{Worker 路徑}`（若無此類型，刪除此行）
- **訊息消費者**：`{Handlers/Consumers 路徑}`（若無此類型，刪除此行）
- **排程作業**：`{Job 路徑}`（若無此類型，刪除此行）

## 共用資源

### 被 ≥ 3 個專案引用的模組
| 模組名稱 | 被引用次數 | 提供的功能 |
|---|---|---|
| {LibraryName} | {N} 個專案 | {功能描述} |

*若無共用模組，填：「目前無被 3 個以上專案引用的共用模組。」*

### 關鍵設定項（appsettings.json 頂層 Key）
- `{ConnectionStrings}` — 資料庫連線設定
- `{Redis}` — Redis 連線設定
- `{MQ}` — 訊息佇列設定
- `{ExternalApis}` — 外部 API 端點設定
- *(僅列出 Key 名稱，不列值)*

---
*盤點時間：{YYYY-MM-DD HH:MM}*
