# TWQA 環境 qa-ai-code-review 服務錯誤日誌分析報告

- **調查日期**：2026-08-17
- **調查範圍**：過去 7 天（2026-08-10 ~ 2026-08-17）
- **環境**：TWQA（Loki datasource: `TW-PX-QA-Loki`）
- **服務**：`service="qa-ai-code-review"`（container: `nine1-ai-code-review-api`）

---

## 一、結論摘要（先看這裡）

過去 7 天內，本服務共出現約 **235 筆**明確的 FAIL / ERROR 類型日誌，其中：

> 🥇 **最大宗問題（佔比約 8 成）：Dify API 回傳 400 BadRequest（`invalid_param`，`model_schema: null`）**，集中在 `SmsFrontEnd`、`WebStoreFrontEnd`、`FrontendStandard` 三個前端 Code Review 規則，**建議優先排查這三個 Dify Workflow 的設定**。

其餘為 Dify API 逾時、Bitbucket API 呼叫失敗等，多屬外部依賴或個案問題，非本服務程式邏輯 bug。

---

## 二、錯誤類型總表

| # | 錯誤類型 | 次數（7天） | Log Level | 嚴重度 | 說明 |
|---|---------|:---:|:---:|:---:|------|
| 1 | **Dify API error: 400 BadRequest**（`invalid_param` / `Run failed` / `model_schema: null`） | **185** | Warning | 🔴 高 | Dify Workflow 回傳錯誤，導致該檔案 Review 失敗，詳見第三節 |
| 2 | **Dify API timeout**（呼叫超過 120 秒被取消） | 8 | Error | 🟠 中 | `TaskCanceledException`，Dify 服務端回應過慢 |
| 3 | **GetRepoSrcTree failed**（取 Bitbucket 目錄樹失敗） | 8 | Error | 🟡 低 | 呼叫 Bitbucket Source Tree API 失敗 |
| 4 | **GetDiffStat failed**（取 Bitbucket diffstat 失敗） | 6 | Error | 🟡 低 | 呼叫 Bitbucket Diffstat API 失敗 |
| 5 | **Bitbucket GET failed（404）** | 14 | Warning | 🟢 可忽略 | 主要是 `nineyi.configuration` repo 的 commit 已不存在 |
| 6 | **Bitbucket GET failed（302）** | 1 | Warning | 🟢 可忽略 | `nineyi.databases` PR 8163 diffstat 重導向 |
| 7 | **Review aborted（設定/API 錯誤）** | 1 | Error | 🟡 低 | 個案：手動觸發測試 PR 13766 時發生的 BaseAddress 未設定錯誤 |
| 8 | Failed to determine the https port for redirect | 12 | Warning | ⚪ 可忽略 | ASP.NET Core 內建警告，與 HTTPS 導向設定有關，非業務邏輯錯誤 |

---

## 三、重點問題詳解：Dify API 400 BadRequest

### 錯誤訊息範例
```
["Bitbucket-51919-fb63"] Dify failed: pr=51919
file="WebStore/Frontend/MobileWebMallV2/ClientApp/src/shop/components/salePageComment/commentPhotoLightbox.tsx"
rule="WebStoreFrontEnd"
error="Dify API error: 400 BadRequest — {"code":"invalid_param","message":"Run failed: {\"code\":0,\"message\":\"success\",\"data\":{\"model_schema\":null}}","status":400}"
```

### 發生次數依 Rule 分類

| Rule（Dify Workflow） | 次數 | 佔比 |
|---|:---:|:---:|
| `SmsFrontEnd` | 33 | 33% |
| `WebStoreFrontEnd` | 31 | 31% |
| `FrontendStandard` | 21 | 21% |
| `PostgreSQL` | 3 | 3% |
| `CodeMentorPro` | 2 | 2% |
| `StandardBackend` | 2 | 2% |
| （其餘抽樣未完整涵蓋，實際總量 185 筆） | — | — |

> 抽樣自最近 100 筆 `Dify failed` 訊息中的 92 筆為此錯誤，`SmsFrontEnd` + `WebStoreFrontEnd` + `FrontendStandard` 三者合計約佔 85%。

### 研判方向
- 錯誤訊息中 `data.model_schema: null` 顯示 Dify 端該 Workflow 的模型輸出 Schema 設定可能有問題，或呼叫時傳入的 App/Workflow 版本設定不完整。
- 建議動作：
  1. 登入 Dify 後台，檢查 `SmsFrontEnd`、`WebStoreFrontEnd`、`FrontendStandard` 這三個 App/Workflow 的輸出 Schema（Output Variables）設定是否正確。
  2. 確認近期是否有針對這幾個 Workflow 做過調整（新增/修改 Output 欄位）導致與服務端解析邏輯不相容。
  3. 若為前端相關規則共通問題，檢查是否共用了同一份底層 Prompt/Schema 範本。

---

## 四、次要問題：Dify API Timeout（120秒逾時）

### 錯誤訊息範例
```
Dify API timeout: endpoint="https://dify.91app.biz/v1/chat-messages"
file="src/NineYi.IMS.CronJob.BusinessLogic/.../BasePlatformService.cs"
elapsedMs=120005 innerException="The operation was canceled."
```

- 共發生 8 次，散見於不同 repo / rule，時間點分散於 8/11 ~ 8/16。
- 每次都是卡在約 120,000 ms（即服務端設定的 120 秒 timeout 上限）才被取消。
- **研判**：屬 Dify 服務端處理效能問題（單一請求處理時間過長），非本服務程式邏輯問題。若頻率持續增加，建議與 Dify 維運團隊確認該時段負載狀況。

---

## 五、次要問題：Bitbucket API 呼叫失敗

| 錯誤 | 次數 | 說明 |
|---|:---:|---|
| `GetRepoSrcTree failed` | 8 | 取目錄樹失敗，多為讀取 `nineyi.configuration` 時發生 |
| `GetDiffStat failed` | 6 | 取 diffstat 失敗 |
| `Bitbucket GET failed（404）` | 14 | 主要是 `nineyi.configuration` repo 的 `src/{commit}` 路徑找不到（commit 可能已被清除或分支已重寫） |
| `Bitbucket GET failed（302）` | 1 | `nineyi.databases` PR 8163 的 diffstat 呼叫被重導向 |

**研判**：這些多屬正常業務情境（例如查詢已經不存在的 commit/分支），非服務本身的程式錯誤，暫不需要修復，但可留意 `nineyi.configuration` repo 是否有 pipeline 會頻繁清除舊 commit。

---

## 六、個案：Review Aborted（PR 13766）

```
["Bitbucket-13766-2083"] Review aborted due to API/configuration error:
Repo="nineyi/nineyi.scm.apiv2" PR=13766
Error="An invalid request URI was provided. Either the request URI must be an absolute URI or BaseAddress must be set."
```

- 發生時間：2026-08-12。
- 背景：此為手動觸發 Webhook 測試該 PR 時所產生的錯誤，屬於當次測試 payload 或設定問題所致的個案，非常態性問題。
- 若後續要再次手動測試，建議確認呼叫端的 `BaseAddress` / diff URL 設定正確。

---

## 七、可忽略項目

- **`Failed to determine the https port for redirect`**（12次）：ASP.NET Core 在沒有明確設定 HTTPS Port 時的內建提示訊息，不影響服務運作，可忽略或視需要調整 Kestrel/反向代理設定移除此警告。

---

## 八、附錄：查詢方式

本報告透過 Grafana Loki MCP 查詢 TWQA 環境（datasource UID: `xV5Pve7Vz`）取得，主要查詢語法：

```logql
# 總日誌量
{service="qa-ai-code-review"}

# 例外日誌（獨立 tenant，等級皆為 Error）
{service="qa-ai-code-review", __tenant_id__="exception_logs"}

# 一般日誌中的 FAIL/ERROR 關鍵字
{service="qa-ai-code-review", __tenant_id__="fake"} |~ "(?i)(fail|error)"

# Dify 400 BadRequest 次數統計
count_over_time({service="qa-ai-code-review"} |= "Dify API error: 400 BadRequest" [7d])
```