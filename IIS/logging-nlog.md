# NLog 應用程式 Log

## 原理

NLog 是 .NET 生態系最常用的 logging framework 之一。它的運作邏輯是：

1. 程式碼呼叫 `logger.Info(...)` / `logger.Error(...)` 等方法
2. NLog 根據 **Rules**（規則）判斷這條 log 要不要輸出、輸出到哪裡
3. 符合規則的 log 傳給對應的 **Target**（目標），SCMAPIV2 使用 `FileTarget`，寫到磁碟

NLog 的設定完全由 `NLog.config` 控制，和 IIS、Windows Event Log 都是獨立的。

---

## SCMAPIV2 設定檔位置

```
WebSite\WebSite\NLog.config
```

這個檔案定義了 log 的輸出路徑、格式、level 等設定。

---

## 路徑規則說明

SCMAPIV2 的 NLog FileTarget 路徑格式：

```
C:\Files\Log\ScmApiV2\NLog\{yyyyMM}\{yyyyMMdd}\{aspnetmvc-controller}\{aspnetmvc-action}_{aspnetmvc-requestid}.txt
```

| 變數 | 說明 | 範例值 |
|------|------|--------|
| `${aspnetmvc-controller}` | 處理該 request 的 Controller 名稱 | `Promotion` |
| `${aspnetmvc-action}` | 處理該 request 的 Action 名稱 | `UpdatePromotion` |
| `${aspnetmvc-requestid}` | 每個 request 的唯一識別碼 | `a3f2b1c9-...` 或自訂短 ID |
| `{yyyyMM}` | 年月（NLog date layout） | `202604` |
| `{yyyyMMdd}` | 年月日 | `20260420` |

### 完整路徑範例

一個呼叫 `PromotionController.UpdatePromotion` 的 request，log 會寫到：

```
C:\Files\Log\ScmApiV2\NLog\202604\20260420\Promotion\UpdatePromotion_a3f2b1c9.txt
```

---

## 特殊情況：DelegatingHandler 層炸掉

ASP.NET Web API 2 的 request pipeline 順序：

```
DelegatingHandler → Controller → Action Filter → Action
```

當錯誤發生在 **DelegatingHandler**（進入 Controller 之前），`${aspnetmvc-controller}` 和 `${aspnetmvc-action}` 的值都是**空字串**。

這時 NLog 的路徑會退化成：

```
C:\Files\Log\ScmApiV2\NLog\{yyyyMM}\{yyyyMMdd}\{HH}\_.txt
```

範例：

```
C:\Files\Log\ScmApiV2\NLog\202604\20260420\10\_.txt
```

> `{HH}` 是小時（24 小時制），`_` 是 controller + action 都空時的 fallback 檔名。  
> 看到這個路徑，就代表問題出在 middleware / handler 層，還沒進 Controller。

---

## 即時追蹤指令（PowerShell）

### 追蹤最新寫入的 log 檔

```powershell
$file = Get-ChildItem "C:\Files\Log\ScmApiV2\NLog" -Recurse -Filter "*.txt" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
Get-Content $file.FullName -Wait -Tail 50
```

### 追蹤特定 Controller / Action

```powershell
# 追蹤今天 PromotionController.UpdatePromotion 的所有 log
Get-Content "C:\Files\Log\ScmApiV2\NLog\202604\20260420\Promotion\UpdatePromotion_*.txt" -Wait -Tail 30
```

### 追蹤 Handler 層錯誤（controller/action 為空）

```powershell
$hour  = (Get-Date).ToString("HH")
$today = (Get-Date).ToString("yyyyMMdd")
$month = (Get-Date).ToString("yyyyMM")
Get-Content "C:\Files\Log\ScmApiV2\NLog\$month\$today\$hour\_.txt" -Wait -Tail 30
```

### 搜尋包含特定 RequestId 的 log

```powershell
$requestId = "a3f2b1c9"  # 從 API response ErrorId 取得
Get-ChildItem "C:\Files\Log\ScmApiV2\NLog" -Recurse -Filter "*$requestId*" |
    ForEach-Object { Get-Content $_.FullName }
```

### 找今天所有有 ERROR 的 log

```powershell
$today = (Get-Date).ToString("yyyyMMdd")
Get-ChildItem "C:\Files\Log\ScmApiV2\NLog\*\$today" -Recurse -Filter "*.txt" |
    Select-String "ERROR" |
    Select-Object -First 50
```

---

## 適用情境

- **正式環境 & 本機**：最主要的 debug 工具（進了 Controller 之後的錯誤）
- 用 `ErrorId`（request ID）定位到特定 log 檔
- 分析特定 Controller / Action 的行為
- 追查 handler 層問題（看 `{HH}\_.txt`）

---

## 注意事項

- `-Wait` 參數類似 Linux 的 `tail -f`，會持續輸出新內容（Ctrl+C 停止）
- Log 檔依日期目錄分類，**不會自動清除**，需要定期 rotation 或手動清理
- 若 Log 目錄不存在，NLog 會靜默失敗（不寫 log 也不噴錯），要確認目錄有建立
