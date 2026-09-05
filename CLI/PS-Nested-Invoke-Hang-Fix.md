# PowerShell 巢狀呼叫 API 腳本「卡住不動」問題排查紀錄

## 問題描述

在修正 `nine1.live.buy` 專案的 `common-csharp-code-review` / `f2e-nine1-code-review` skill 的 AI Code Review 呼叫腳本（`dify_code_review_request.ps1` / `ai_code_review_request.ps1`）時，
腳本改為呼叫新的 `POST /api/review/diff` 端點後，透過 Copilot CLI 的 `powershell` 工具執行驗證時，出現「印出 `=== 檔名 ===` 後就完全卡住，不再有任何輸出、也不會 timeout」的現象：

```powershell
powershell -ExecutionPolicy Bypass -File ".github\ps\dify_code_review_request.ps1"
```

```
Calling AI Code Review Service: https://ai-code-review-service-io.qa.91dev.tw/api/review/diff
  repositoryName: g11n/nine1.live.buy
  scope:          Quick
=== src/BusinessLogic/.../__TempReviewTest.cs ===
（卡住，等再久都沒有下一行輸出）
```

因為在 AI Code Review 平台後台完全看不到任何請求進來的紀錄，一度懷疑是：
- API 端點打錯（新舊 host / 新舊路徑不一致）
- Request body 格式不符合新版 `DiffReviewRequest` schema
- `Invoke-RestMethod` 的 `-TimeoutSec` 沒有生效

---

## 排查過程

### 1) 先用 Swagger 反查正確的 API 規格，排除「打錯 API」的可能

```powershell
Invoke-RestMethod -Uri "https://ai-code-review-service-io.qa.91dev.tw/swagger/v1/swagger.json" `
  | Select-Object -ExpandProperty paths `
  | ForEach-Object { $_.PSObject.Properties.Name } `
  | Where-Object { $_ -match 'review' }
# => /api/Review/diff
```

確認 `DiffReviewRequest` / `ReviewScope` / `ReviewContext` / `FileFullContent` 的欄位定義，
逐一比對腳本組出的 JSON body，**欄位完全對得上**，排除格式問題。

### 2) 直接用最小化的 `Invoke-RestMethod` 呼叫同一支 API，確認 API 本身沒問題

```powershell
$body = '{"repositoryName":"...","scope":"Quick","diffContent":"...","fileName":"test.cs","context":{...}}'
Invoke-RestMethod -Uri "https://ai-code-review-service-io.qa.91dev.tw/api/review/diff" `
  -Method POST -ContentType "application/json; charset=utf-8" -Body $body -TimeoutSec 45
```

**結果：2~5 秒內就正常回應 200，內容正確**（`isSuccess: true`，含 Dify Reviewer 回答）。
→ 證實 API 端點、request body 格式、host 都沒有問題。

### 3) 但是「跑同一支 .ps1 腳本檔案」卻還是卡住

用 `-TimeoutSec 15 -RetryCount 0` 這種「一定要嘛 15 秒內成功、要嘛 15 秒後丟出例外」的極端參數再測一次，
結果過了 30 秒、60 秒、120 秒都沒有任何 `[ERROR]` 訊息印出 —— 這代表**執行根本沒有走到 `Invoke-RestMethod` 那一行**，
`-TimeoutSec` 沒有機會生效，問題出在更前面。

進一步懷疑並逐一排除：
- ❌ `[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials` 這行 proxy 設定 → 單獨測試只花 0.02 秒，不是原因
- ❌ `-ContentType 'application/json; charset=utf-8'` 造成的額外處理 → 單獨測試一樣 2~5 秒完成，不是原因
- ❌ Body 內容/檔案大小 → 測試檔案只有一行程式碼，不可能是內容過大

### 4) 真正原因：從「巢狀啟動一個新的 `powershell.exe` 子行程」改成「直接執行腳本」

問題重現的呼叫方式，都是在**已經在跑一個 PowerShell（pwsh 7）的工作階段裡**，再用

```powershell
powershell -ExecutionPolicy Bypass -File ".github\ps\dify_code_review_request.ps1"
```

去**開一個新的巢狀 `powershell.exe` (Windows PowerShell 5.1) 子行程**執行腳本。

改成在同一個工作階段中直接執行腳本本體（不額外開子行程）：

```powershell
& ".github\ps\dify_code_review_request.ps1" -TimeoutSec 15 -RetryCount 0
```

**結果：幾秒內就正常完成，並拿到 Dify 的真實回答**（`Code Reviewer (Custom Rules): 沒有問題` 等）。

---

## 根本原因

在本次的自動化執行環境（Copilot CLI 的 `powershell` 工具）中，
**巢狀啟動 `powershell.exe -File <script>` 子行程**時，該子行程對外發出的 HTTPS 請求（`Invoke-RestMethod`）會卡在網路層（推測與子行程繼承/重新協商 TLS、proxy 或工作階段的 stdio 重導向有關），
且卡住的行為**不受 `Invoke-RestMethod -TimeoutSec` 限制**（因為請求可能根本沒有真正送出，卡在更底層的連線建立/協商階段），因此腳本會無限期停在該行，也因為請求沒有真正送達伺服器，AI Code Review 平台後台自然看不到任何觸發紀錄。

這與腳本邏輯、API 端點、request body 格式**完全無關**——換句話說，這是「巢狀 shell 呼叫」在特定執行環境下的網路行為問題，不是程式碼寫錯。

---

## 解法 / 建議作法

| 情境 | 建議 |
|---|---|
| 在已啟動的 PowerShell 工作階段中要執行 `.ps1` 腳本 | 直接用 `& "path\to\script.ps1" [-參數 ...]` 呼叫，**不要**再包一層 `powershell -File ...` 產生巢狀子行程 |
| 一定要用 `powershell -File` 的情境（例如從 cmd.exe / 排程器 / CI pipeline 呼叫） | 屬於正常單層呼叫（不是巢狀在另一個 PowerShell 工作階段內），通常不會有此問題；若懷疑同樣卡住，先用最小化的 `Invoke-RestMethod` 直接測試該 API，排除 API/格式問題後，再檢查是否也是巢狀呼叫情境 |
| 懷疑「呼叫 API 卡住 / 沒有 log」時的排查順序 | 1. 查 Swagger 確認正確 endpoint 與 schema 2. 用最小化裸 `Invoke-RestMethod` 直接測 API（不透過腳本）3. 若裸測試正常、腳本卻卡住，檢查是否為巢狀 `powershell -File` 呼叫方式 4. 改用 `& script.ps1` 直接執行做對照 |

---

## 結論

| 現象 | 誤判方向 | 實際原因 | 解法 |
|---|---|---|---|
| 腳本呼叫 AI Code Review API 印出 `=== 檔名 ===` 後卡住，且平台後台無任何觸發紀錄 | 懷疑 API 端點打錯 / request body 格式不對 / `-TimeoutSec` 失效 | 在既有 PowerShell 工作階段中，用 `powershell -File` 巢狀啟動子行程執行腳本，導致該子行程的 HTTPS 請求卡在網路層、根本沒送達伺服器 | 改用 `& "script.ps1"` 直接在當前工作階段執行腳本，不额外開巢狀子行程 |
