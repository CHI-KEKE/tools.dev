# Visual Studio Output 視窗

## 原理

當你用 Visual Studio **Attach to Process** 掛上 `w3wp.exe`（IIS worker process）時，CLR 會把以下資訊串流到 VS 的 Output 視窗：

- CLR 丟出的例外（包含 first-chance exception，即使被 catch 住也看得到）
- Application Insights SDK 在 unconfigured 模式下的 telemetry 輸出
- `System.Diagnostics.Debug.WriteLine()` 的輸出
- `System.Diagnostics.Trace.WriteLine()` 的輸出

這個方式和 NLog 完全獨立，**不需要任何 log 設定**，只要 attach 成功就能看到。

---

## 如何開啟 Output 視窗

1. 頂端選單 → **Debug** → **Windows** → **Output**（快捷鍵：`Ctrl+Alt+O`）
2. 視窗右上角下拉選單選 **"Debug"**（預設可能是 "Build"，要切換）

---

## 如何 Attach 到 w3wp.exe

1. **Debug** → **Attach to Process**（`Ctrl+Alt+P`）
2. 找到 `w3wp.exe`（可能有多個，對應不同 App Pool）
   - 如果看不到，勾選 **「顯示所有使用者的處理序」**
   - 透過右邊的 User 欄位或 Title 欄位判斷是哪個站台的 worker
3. 確認 **"Attach to"** 欄位是 **Managed (v4.6, v4.5, v4.0)** 或 **Automatic**
4. 按 **Attach**

> 💡 每次 App Pool Recycle 後 `w3wp.exe` 的 PID 會換，要重新 attach。

---

## 看得到什麼

| 類型 | 範例 |
|------|------|
| First-chance exception | `Exception thrown: 'System.Collections.Generic.KeyNotFoundException' in mscorlib.dll` |
| AI Telemetry（unconfigured） | `Application Insights Telemetry (unconfigured): {"name":"Microsoft.ApplicationInsights.Message",...}` |
| Debug.WriteLine | 你在程式碼裡手動寫的 debug 訊息 |
| Unhandled exception stack | 完整 stack trace，包含 inner exception |

---

## 看不到什麼

- **NLog 寫檔的內容**（NLog FileTarget 是寫到磁碟，Output 視窗感知不到）
- **IIS access log**（那是 IIS 自己記的，和 CLR 無關）
- **其他 App Pool 的輸出**（attach 是針對特定 PID）

---

## 適用情境

- **本機開發 debug**：最即時、最詳細，是第一線 debug 工具
- 想看「exception 在哪一層被丟出」時，first-chance exception 特別有用
- 確認 Application Insights telemetry 有沒有正確觸發

---

## 範例輸出片段

以下是在 SCMAPIV2 本機環境，某個 request 觸發 `KeyNotFoundException` 時，Output 視窗看到的典型輸出：

```
Exception thrown: 'System.Collections.Generic.KeyNotFoundException' in mscorlib.dll
Exception thrown: 'System.Collections.Generic.KeyNotFoundException' in mscorlib.dll
Application Insights Telemetry (unconfigured): {
  "name": "Microsoft.ApplicationInsights.Dev.RemoteDependency",
  "time": "2026-04-20T10:23:45.123Z",
  "data": {
    "baseType": "RemoteDependencyData",
    "baseData": {
      "name": "GET /api/promotion/123",
      "duration": "00:00:00.045",
      "success": false
    }
  }
}
Application Insights Telemetry (unconfigured): {
  "name": "Microsoft.ApplicationInsights.Dev.Exception",
  "time": "2026-04-20T10:23:45.130Z",
  "data": {
    "baseType": "ExceptionData",
    "baseData": {
      "exceptions": [{
        "typeName": "System.Collections.Generic.KeyNotFoundException",
        "message": "The given key was not present in the dictionary.",
        "stack": "   at System.Collections.Generic.Dictionary`2.get_Item(...)\r\n   at ScmApiV2.Services.PromotionService.GetById(...)"
      }]
    }
  }
}
```

> 注意：`(unconfigured)` 代表目前 SCMAPIV2 沒有設定 InstrumentationKey，telemetry 只輸出到這裡，不會送到 Azure。
