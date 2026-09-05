# IIS Access Log（W3C Format）

## 原理

IIS 的 Access Log 是由 **IIS 本身**（不是你的應用程式）記錄的，記錄每一個打進來的 HTTP request 的基本資訊。

這層 log 和你的 .NET 程式碼完全無關：
- 即使你的程式碼完全崩潰，IIS log 照寫
- 即使 App Pool 還沒啟動完，靜態檔案請求也會被記錄
- 就算 request 被 IIS 層擋掉（例如 URL Rewrite、Request Filter），也有記錄

這也是確認「**request 到底有沒有打進來**」最可靠的依據。

---

## 查看 Log 路徑

### 方法一：IIS Manager

1. 打開 **IIS Manager**（`inetmgr`）
2. 左側樹狀選單 → **Sites** → 點選你的站台（例如 `SCMAPIV2`）
3. 中間功能面板找 **Logging** 圖示，雙擊開啟
4. **Directory** 欄位就是 log 路徑

### 方法二：直接看 SCMAPIV2 的路徑

```
C:\inetpub\logs\LogFiles\W3SVC5\
```

> `W3SVC5` 中的數字 `5` 是 IIS 站台 ID，不同站台不同。

---

## 檔案命名規則

```
u_ex{yyyyMMdd}.log
```

範例：`u_ex20260420.log`

每天一個新檔，自動 rotate。

---

## W3C 格式欄位說明

典型的一行記錄長這樣：

```
2026-04-20 10:23:45 POST /api/promotion/update - 443 - 192.168.1.100 - 200 0 0 145
```

| 欄位 | 說明 | 範例 |
|------|------|------|
| `date` | 日期（UTC） | `2026-04-20` |
| `time` | 時間（UTC） | `10:23:45` |
| `cs-method` | HTTP 方法 | `POST` |
| `cs-uri-stem` | 路徑（不含 query string） | `/api/promotion/update` |
| `cs-uri-query` | Query string | `id=123&shopId=456` |
| `s-port` | Server port | `443` |
| `cs-username` | 認證使用者（匿名為 `-`） | `-` |
| `c-ip` | Client IP | `192.168.1.100` |
| `cs(User-Agent)` | User Agent | `-` |
| `sc-status` | HTTP status code | `200`, `500`, `404` |
| `sc-substatus` | IIS substatus（細分錯誤） | `0` |
| `sc-win32-status` | Win32 error code（正常為 `0`） | `0` |
| `time-taken` | Response time（毫秒） | `145` |

> ⚠️ IIS log 用的是 **UTC 時間**，要換算台灣時間（UTC+8）記得加 8 小時。

---

## 如何查看

### 直接開檔案

用 Notepad++、VS Code 直接打開即可，純文字。

### PowerShell 過濾

```powershell
# 找特定 URL 的 request
Get-Content "C:\inetpub\logs\LogFiles\W3SVC5\u_ex20260420.log" |
    Select-String "UpdatePromotion"

# 找所有 500 錯誤
Get-Content "C:\inetpub\logs\LogFiles\W3SVC5\u_ex20260420.log" |
    Select-String " 500 "

# 找特定 IP 的 request
Get-Content "C:\inetpub\logs\LogFiles\W3SVC5\u_ex20260420.log" |
    Select-String "192.168.1.100"

# 找 response time 超過 3 秒的 request（time-taken > 3000ms）
# W3C 格式最後一欄是 time-taken
Get-Content "C:\inetpub\logs\LogFiles\W3SVC5\u_ex20260420.log" |
    Where-Object { $_ -notmatch "^#" } |  # 跳過 header 行
    ForEach-Object {
        $cols = $_ -split " "
        if ([int]$cols[-1] -gt 3000) { $_ }
    }
```

### Log Parser Studio（GUI 工具）

微軟出的免費工具，可以用 SQL-like 語法查詢 IIS log：

```sql
SELECT cs-uri-stem, COUNT(*) AS Hits, AVG(time-taken) AS AvgMs
FROM '[LOGFILEPATH]'
WHERE sc-status = 500
GROUP BY cs-uri-stem
ORDER BY Hits DESC
```

下載：[Log Parser Studio](https://techcommunity.microsoft.com/t5/exchange-team-blog/log-parser-studio-2-2-is-now-available/ba-p/593266)

---

## 看得到什麼

- ✅ 每個 HTTP request 的 URL、method、status code
- ✅ Response time（time-taken，毫秒）
- ✅ Client IP
- ✅ 404 / 500 / 401 等 HTTP 錯誤
- ✅ Request 有沒有打進來（最可靠的確認方式）

## 看不到什麼

- ❌ Exception 內容、stack trace
- ❌ Request body（POST body 不記錄）
- ❌ Response body
- ❌ 自訂 header（預設不記錄）
- ❌ 業務邏輯層面的錯誤原因

---

## 適用情境

| 情境 | 說明 |
|------|------|
| 確認 request 有沒有打到 server | 最可靠，IIS 不記錄代表根本沒到 |
| Response time 分析 | `time-taken` 欄位，找效能瓶頸 |
| 確認 HTTP status | 先看 status，再決定去哪裡找 application log |
| 找特定 IP 的行為 | 資安調查、頻繁請求分析 |

---

## 小技巧：搭配 NLog 一起用

IIS log 確認了「request 進來了，回了 500」→ 再去 NLog 的對應時間目錄找 exception 細節。

這兩個 log 是互補的：IIS log 告訴你「發生了什麼」，NLog 告訴你「為什麼」。
