# 邊界識別模式（Boundary Patterns）

本文件說明如何在 C# 專案中識別領域邊界，以及如何定義與外部系統的整合邊界。

---

## 什麼是領域邊界？

領域邊界（Domain Boundary）定義了「這個程式碼範圍負責什麼，以及從哪裡開始是別人的責任」。

邊界的核心問題：
- **我的入口**：誰可以呼叫我？（API endpoint、MQ Consumer、排程）
- **我的出口**：我呼叫誰？（外部 API、MQ Publisher、共用 DB）
- **我的資料主權**：哪些 Table 是我主要負責寫入的？

---

## 識別外部服務邊界

### REST API 呼叫

```csharp
// 注入識別
private readonly HttpClient _httpClient;
private readonly IXxxApiClient _xxxClient;  // 通常是包裝好的 SDK

// 呼叫識別
await _httpClient.GetAsync("https://external-api/endpoint");
await _xxxClient.GetMemberInfoAsync(memberId);
```

**邊界定義方式**：
- 我的職責：呼叫對方取得資料 / 通知對方執行動作
- 對方的職責：維護該資料 / 執行對應的業務邏輯
- 邊界：我透過 HTTP 合約取得結果，失敗時我自行處理 fallback

### Redis 快取

```csharp
// 識別
private readonly IDistributedCache _cache;
private readonly IConnectionMultiplexer _redis;

await _cache.SetStringAsync(key, value, options);
var result = await _cache.GetStringAsync(key);
```

**邊界定義方式**：
- 我的職責：決定快取哪些資料、設定 TTL
- Redis 的職責：儲存與失效管理
- 邊界：Cache miss 時我負責回源取得資料

### 共用 DB Table

當多個服務共用同一個 DB Table 時，需要明確定義讀寫邊界。

**識別方式**：
- 找出 Repository 中 INSERT / UPDATE 的 Table 清單（這是「我主要寫入」的 Table）
- SELECT 其他服務主要寫入的 Table（這是「我讀取別人的資料」）

**邊界定義方式**：
- 寫入方負責資料的正確性與一致性
- 讀取方負責處理讀取失敗或資料不存在的情況

---

## 識別邊界模糊點（風險）

以下情況代表邊界不清晰，值得在文件中特別標注：

⚠️ **直接跨服務寫入 DB**
- 跳過對方的 API，直接寫入對方負責的 Table
- 識別：Repository 寫入的 Table 名稱，不在此服務的主要業務資料表中

⚠️ **雙向事件**
- A 發布事件給 B，B 又發布事件回 A（循環相依風險）

⚠️ **同步呼叫鏈過長**
- A → B → C → D 的同步呼叫
- 識別：Service 中 HTTP Client 的呼叫結果，作為另一個 HTTP Client 的輸入

---

## 邊界描述範例

### 良好的邊界描述

| 外部服務 | 整合方式 | 此範圍的職責 | 對方的職責 | 邊界定義 |
|---|---|---|---|---|
| 會員系統 | REST API | 查詢會員當前等級 | 維護會員等級資料 | 只讀取，不直接修改會員系統資料 |
| 點數系統 | MQ 事件 | 發布升等成功事件 | 監聽事件並加發升等禮包點數 | 我只負責通知，點數計算由點數系統決定 |
| CRM | Redis | 快取 CRM 會員資料（TTL 5分鐘） | 維護 CRM 原始資料 | Cache miss 時回源呼叫 CRM API |

---

## 注意事項

- 如果程式碼中沒有明確的外部整合，直接記錄「此範圍為自包含（Self-contained）服務」
- 共用 DB 的邊界比 API 邊界更難識別，需要仔細比對 Repository 的 Table 名稱
- Configuration 檔案（`appsettings.json`）中的 URL 設定，是識別外部服務的重要線索
