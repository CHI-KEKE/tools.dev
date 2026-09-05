# Windows 事件檢視器（Event Viewer）

## 原理

Windows 事件檢視器是作業系統層級的 log 系統，記錄系統、應用程式、安全性等各種事件。

對 ASP.NET / IIS 而言，以下情況會寫進 Event Log：

- **App Pool crash**：w3wp.exe 非預期結束
- **ASP.NET unhandled exception**：沒有被任何 global error handler 攔截的例外
- **.NET Runtime 錯誤**：CLR 層面的嚴重錯誤（OutOfMemoryException、StackOverflowException 等）
- **IIS 服務本身的狀態**：site start/stop、binding 錯誤

> ⚠️ 一般的 API 業務邏輯錯誤（被 SCMAPIV2 的 global exception handler 攔截並回傳 ErrorId 的那種）**不會**出現在 Event Log。Event Log 是「系統層級出問題」的訊號。

---

## 如何開啟

**方法一：執行指令**

```
Win + R → 輸入 eventvwr → Enter
```

或在 PowerShell / CMD 輸入：

```powershell
eventvwr.msc
```

**方法二：搜尋**

開始選單搜尋「事件檢視器」或「Event Viewer」

---

## 查看 ASP.NET 錯誤的路徑

```
事件檢視器
└── Windows 記錄
    └── 應用程式（Application）
```

1. 展開左側 **Windows 記錄**
2. 點選 **應用程式**
3. 右側面板可以看到所有事件

### 篩選 ASP.NET 來源

1. 右側動作面板點選 **篩選目前記錄**（Filter Current Log）
2. **來源（Event sources）**：輸入或選擇 `ASP.NET 4.0.30319.0`
3. **事件層級**：勾選「錯誤」（Error）、「重大」（Critical）

---

## PowerShell 查詢

### 最近 1 小時的應用程式錯誤

```powershell
Get-EventLog -LogName Application -EntryType Error -After (Get-Date).AddHours(-1) |
    Select-Object TimeGenerated, Source, Message |
    Format-List
```

### 篩選 ASP.NET 相關錯誤（最新 10 筆）

```powershell
Get-EventLog -LogName Application -Source "ASP.NET*" -EntryType Error -Newest 10 |
    Select-Object TimeGenerated, Message |
    Format-List
```

### 篩選 IIS-W3SVC 相關事件（App Pool 狀態）

```powershell
Get-EventLog -LogName System -Source "Microsoft-Windows-WAS*" -Newest 20 |
    Select-Object TimeGenerated, EntryType, Message |
    Format-List
```

### 找 .NET Runtime 崩潰

```powershell
Get-EventLog -LogName Application -Source ".NET Runtime*" -EntryType Error -Newest 10 |
    Select-Object TimeGenerated, Message |
    Format-List
```

### 新版 PowerShell（Get-WinEvent，更精確）

```powershell
# 最近 2 小時內所有應用程式錯誤
Get-WinEvent -FilterHashtable @{
    LogName   = 'Application'
    Level     = 2  # 2=Error, 1=Critical
    StartTime = (Get-Date).AddHours(-2)
} | Select-Object TimeCreated, ProviderName, Message | Format-List
```

---

## 看得到什麼

| 事件類型 | 說明 |
|----------|------|
| App Pool crash | w3wp.exe 非預期終止，含 crash dump 路徑 |
| ASP.NET unhandled exception | 沒被 global handler 攔截的例外（比較少見） |
| .NET CLR 錯誤 | OutOfMemoryException、CLR 內部錯誤 |
| IIS 站台啟動/停止 | Site 被手動或自動停止 |
| Windows 服務錯誤 | W3SVC、WAS 服務狀態 |

## 看不到什麼

- ❌ 一般 API 業務邏輯錯誤（被 SCMAPIV2 的 global exception handler 攔截後就不會到這裡）
- ❌ HTTP request 的細節（那是 IIS Access Log 的範疇）
- ❌ NLog 寫的應用程式 log
- ❌ 被 try/catch 包住的例外

---

## 適用情境

| 情境 | 說明 |
|------|------|
| App Pool 不明原因停止 | 第一個要看的地方 |
| w3wp.exe crash | Event Log 會記錄 crash dump 路徑 |
| 站台啟動失敗 | `Global.asax` 或 `Application_Start` 炸掉 |
| Autofac DI 容器初始化失敗 | 若在 startup 炸，會出現在這裡 |
| 懷疑是 OS / CLR 層問題 | 先排除應用程式 log，再來這裡確認 |

---

## 常見的 EventId 對照

| Source | EventId | 意義 |
|--------|---------|------|
| `ASP.NET 4.0.30319.0` | 1325 | Application error |
| `ASP.NET 4.0.30319.0` | 1309 | Event code: 3005（unhandled exception） |
| `.NET Runtime` | 1026 | Application crashed（.NET 例外） |
| `Windows Error Reporting` | 1001 | Crash dump 已建立 |
| `Microsoft-Windows-WAS` | 5011 | App Pool 已停止 |
| `Microsoft-Windows-WAS` | 5021 | App Pool 已停用（太多 crashes） |
