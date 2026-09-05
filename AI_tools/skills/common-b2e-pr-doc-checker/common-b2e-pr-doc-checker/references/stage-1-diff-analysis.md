# Stage 1：PR Code Diff 分析

**目標**：取得 PR 的完整程式碼異動，將異動依層次分類，產出「異動信號清單」並判斷是否觸發文件更新需求。

---

## Step 1.1：取得 PR Diff

執行腳本取得 diff 資料：

```powershell
$result = & ".github\skills\common-b2e-pr-doc-checker\scripts\get_pr_diff.ps1"
```

腳本回傳以下屬性：

| 屬性 | 說明 |
|------|------|
| `$result.BaseBranch` | 偵測到的 base branch（如 `origin/main`） |
| `$result.Platform` | `bitbucket` / `gitlab` / `unknown` |
| `$result.ChangedFiles` | 所有異動檔案的相對路徑陣列 |
| `$result.DocFiles` | 只包含 `/.doc/` 底下的異動檔案 |
| `$result.CodeFiles` | 排除 `/.doc/` 後的異動程式碼檔案 |
| `$result.DiffContent` | 完整 diff 文字（用於 AI 分析） |

---

## Step 1.2：程式碼異動分類

依照以下規則將 `$result.CodeFiles` 分類：

### 分類規則

| 分類標籤 | 對應特徵（檔案名稱或路徑關鍵字） | 文件觸發等級 |
|---------|-------------------------------|------------|
| `API_ENDPOINT` | `*Controller.cs`、`*Endpoint.cs`、路由屬性 `[Route]`、`[HttpGet/Post/Put/Delete]` | 🔴 必須更新 |
| `REQUEST_RESPONSE` | `*Request.cs`、`*Response.cs`、`*Dto.cs`、`*ViewModel.cs` | 🔴 必須更新 |
| `BUSINESS_LOGIC` | `*Service.cs`，且 diff 包含業務條件（`if`/`switch`/`throw` 新增）| 🟡 建議更新 |
| `DB_SCHEMA` | `*Migration*.cs`、`*DbContext.cs`、`*Entity.cs`（欄位新增/修改）| 🔴 必須更新 |
| `DOMAIN_EVENT` | `*Event.cs`、`Publish(`、`Subscribe(`、`IEventHandler` | 🟡 建議更新 |
| `EXTERNAL_INTEGRATION` | `HttpClient`、`RestClient`、`IFooClient.cs`、`appsettings*.json`（新增 endpoint key）| 🟡 建議更新 |
| `WORKER` | `*Worker.cs`、`*BackgroundService.cs`、`*Consumer.cs` | 🟡 建議更新 |
| `CONFIG_ONLY` | 只有 `.csproj`、`*.json`（非 appsettings endpoint）、`Dockerfile`、CI 設定 | 🟢 通常不需更新 |
| `TEST_ONLY` | `*Tests.cs`、`*.Tests/`、`*.Spec.cs` | 🟢 不需更新 |

> **分類步驟**：
> 1. 先依檔案名做初步分類
> 2. 對 `BUSINESS_LOGIC` 候選，讀取 diff content 確認是否有條件邏輯異動，避免過度觸發
> 3. 一個檔案可屬於多個分類（如 `OrderController.cs` 可同時是 `API_ENDPOINT`）

---

## Step 1.3：判斷是否觸發文件需求

依分類結果決定後續行動：

| 結果 | 條件 | 後續動作 |
|------|------|---------|
| **需要核查文件** | 存在任何 🔴 或 🟡 分類的異動 | → 進入 Stage 2 |
| **可能不需要更新** | 全部為 🟢 分類 | → 仍進 Stage 2，但在報告中標注「低風險」|
| **PR diff 為空** | `$result.CodeFiles` 為空 | → Hard Stop（見 prerequisites.md）|

---

## Step 1.4：輸出 Stage 1 摘要

呈現以下內容給使用者確認後再繼續（**不等待額外確認，直接呈現後繼續**）：

```
## Stage 1 摘要

- Base Branch：{baseBranch}
- 平台：{platform}
- 異動程式碼檔案數：{count}
- /.doc/ 已異動檔案數：{docCount}（PR 中已修改的知識文件）

### 異動信號清單

| 分類 | 觸發等級 | 異動檔案（代表性） |
|------|---------|-----------------|
| API_ENDPOINT | 🔴 必須更新 | OrderController.cs |
| DB_SCHEMA | 🔴 必須更新 | 20240301_AddOrderStatus.cs |
| BUSINESS_LOGIC | 🟡 建議更新 | OrderService.cs |
```

若 `/.doc/` 中已有異動（`$result.DocFiles` 不為空），在摘要中加註：
> ⚠️ PR 已包含 `/.doc/` 修改，Stage 2 將核查覆蓋是否完整。
