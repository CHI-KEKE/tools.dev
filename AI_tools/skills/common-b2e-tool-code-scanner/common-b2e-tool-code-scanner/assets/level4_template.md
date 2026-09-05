# 🔗 跨系統相依關係盤點

> **目標模組**：{模組名稱}
> **一句話摘要**：{此模組在系統中的角色及主要互動，25 字以內}

## 外部系統互動

### 呼叫出去（Outbound）
| 目標系統 | 互動方式 | 用途 | 若不可用的影響 |
|---|---|---|---|
| {SystemName / API 名稱} | REST API | {用途描述} | {影響：失敗/降級/略過} |
| {Redis 實例名稱} | Redis TCP | {快取什麼資料} | {影響：降級查 DB / 功能失效} |
| {Queue 名稱} | {AMQP / Azure Service Bus} | {發送什麼訊息} | {影響：進 retry queue / 資料遺失} |
| {DB 名稱} | SQL（EF Core） | {存取哪些資料} | {影響：功能完全失效} |

*若無某類型呼叫，刪除對應行。若無任何 Outbound，填：「此模組無對外部系統的直接呼叫。」*

### 被呼叫（Inbound）
| 來源系統 | 互動方式 | 呼叫的端點/方法 | 預估頻率 |
|---|---|---|---|
| {SystemName} | REST API | `POST /api/{route}` | 高（即時） |
| {SystemName} | REST API | `GET /api/{route}` | 中（即時） |
| {ProjectName} | 直接引用 DLL | `{ClassName}.{Method}()` | 低（每日排程） |

*若無 Inbound，填：「此模組為頂層消費者，未被其他系統呼叫。」*

## 資料流向

### 寫入的資料儲存
| 儲存位置 | 寫入內容 | 寫入時機 |
|---|---|---|
| SQL Server — `{DBName}.{Schema}.{Table}` | {寫入內容描述} | {時機描述} |
| Redis | Key: `{prefix}:{id}` | {時機描述} |
| Log（結構化日誌） | 操作日誌 | 每次 API 呼叫 |

*若某類型不適用，刪除對應行*

### 共用資料表
| 資料表 | 其他共用系統 | 本模組 | 其他系統 | 風險說明 |
|---|---|---|---|---|
| `{Schema}.{TableName}` | {ProjectA}, {ProjectB} | 讀寫 | 唯讀 | Schema 變更需同步通知 |
| `{Schema}.{TableName}` | {ProjectA} | 唯讀 | 讀寫 | ⚠️ 注意資料一致性 |

*若無共用資料表，填：「無跨系統共用資料表。」*

## 變更影響範圍評估

### 若修改此模組，需要：

**✅ 必須驗證（高影響）**
- `{SystemName}`：直接呼叫 `{Route/Method}`，API 合約變更會立即影響
- `{ProjectName}`：直接引用此模組 DLL，介面變更需同步修改

**📢 建議通知（中影響）**
- `{SystemName}`：透過 `{SharedLibrary}` 間接依賴，共用資料結構變更時需留意

**👀 注意監控（低影響）**
- `{QueueName}` 下游消費者：訊息格式變更時需確認消費者相容性
- `{ReportProject}`：唯讀共用資料表，Schema 變更需通知

### API 合約變更風險

若以下 endpoint 的 Request/Response 結構有變更，需特別留意：

| Endpoint | 消費系統 | 風險等級 |
|---|---|---|
| `POST /api/{route}` | {SystemName} | 🔴 高（主要交易流程） |
| `GET /api/{route}` | {SystemName} | 🟡 中（查詢功能） |

*若此模組無對外 API，填：「此模組無對外 HTTP API，API 合約無變更風險。」*

---
*盤點時間：{YYYY-MM-DD HH:MM}*
