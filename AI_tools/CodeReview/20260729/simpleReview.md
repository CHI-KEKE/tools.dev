# Simple Review API — 實作規劃書

> 目標：在既有 `NineYi.Ai.CodeReview.v2` 專案中，新增一支同步式、供 Copilot CLI / CI Script 直接呼叫的
> 「一次性 diff 審查」API，並在設計上兼顧未來擴充性。
>
> 本文件為**規劃書**，尚未動手實作程式碼。

---

## 1. 背景與現況落差

先前（2026-07-27）分析的 `DirectReviewController` / `IRuleRepository`（DB 驅動規則）等程式碼，
在目前這版程式庫中**已不存在**。現況改為：

- 規則（Rule）改為**設定檔驅動**：`CodeReviewConfig.Rules`（`List<RuleEntry>`），對應 `_N1CONFIG:CodeReview`。
- `IDifyService` 目前只有 `ReviewCodeAsync`，內部已經是打 Dify **Chat API**（`/v1/chat-messages`，與 `DifySettings.ApiEndpoint` 預設值一致），但輸入/輸出的資料契約是綁死「單一檔案、逐行回貼 PR 留言」的場景，並非另一支 Workflow API（先前規劃書誤植為「Workflow API」，已更正）。
- Webhook 流程（`PullRequestReviewService.StartAsync`）已有完整的「依 repo 找適用 Rule → 逐檔呼叫 Dify → 回貼 Git 平台留言」邏輯，且規則比對邏輯（`GetApplicableRules` / `IsRepoMatch` / `IsFrontendRule` / `IsFilePatternMatch`）目前是 `PullRequestReviewService` 內的 `private` 方法。

因此這次是**從目前架構出發新增功能**，而非修改舊的 DirectReview 程式碼。

---

## 2. 設計決策（討論後定案）

| 決策點 | 定案 | 理由 |
|---|---|---|
| Controller 命名 | **`ReviewController`**，路由 `api/review`（沿用 `[Route("api/[controller]")]` 慣例） | 比照既有 `WebhookController`（`api/webhook` 底下多個 Action 處理不同平台）的模式：一個 Controller、多個 Action，未來新增審查相關端點不必再開新 Controller |
| Action 命名 | **`POST /api/review/diff`** | 語意對應 body 裡的 `diffContent`：提交一段 diff 進行審查。避免 `direct` 與 Controller 語意重複，也避免用 `quick`/`full` 這種「值即 Action」的做法，導致未來每多一種審查尺度就要多開一個 Action |
| taskingFlow 型別 | 由**字串**改為**強型別 enum** `ReviewScope { Quick = 1, Full = 2 }`，作為 body 參數傳入，不做成獨立 Action | 避免打錯字、Swagger 可自動列出合法值；未來加 `Deep` 等新尺度只需加一個 enum 值，不必新增 Action 或修改路由 |
| Rule 是否支援依 scope 篩選 | 支援。`RuleEntry` 新增欄位 `ApplicableScopes`（`List<ReviewScope>`）。**語意為「空清單＝僅 Full 適用」**，Quick 需明確加入白名單（例如 `["Quick","Full"]`）才會在 Quick 模式下被觸發；Webhook 流程呼叫時不傳 scope，不受此篩選影響 | 對應原本「review-only 只跑 Custom+Standard」的需求；預設保守（不誤觸發全部 Dify Bot），Quick 是需要明確標記的白名單，而不是需要把其餘 21 條既有 Rule 都手動排除 |
| 規則比對邏輯是否共用 | **是**，抽出獨立的 `IRuleMatcher`／`RuleMatcher`，讓 Webhook 流程（`PullRequestReviewService`）與新的 Diff Review 流程共用同一套「依 repo/scope/file pattern 找 Rule」邏輯 | 避免兩條路徑各自維護一份規則比對程式碼，未來調整比對規則（例如 NMQ 排除前端規則）只需改一處 |
| Dify 呼叫方式 | 新增 `IDifyService.ChatReviewAsync`（仍是同一支 Dify Chat API `/v1/chat-messages`，端點沒有換） | 新增理由**不是**因為要換 Dify 端點，而是**輸入/輸出的資料契約不同**：`ReviewCodeAsync` 綁死單一檔名＋單檔 diff 當輸入、把 `answer` 依 `[MUST]/[SHOULD]/[MAY]` 標籤切成結構化 `CodeReviewComment` 清單（設計目的是回貼 PR 行內留言）；新功能要送整段多檔 diff＋context 當輸入，且不需要回貼任何地方，只要把 `answer` 原文整段回傳即可，兩者資料契約不同，硬共用會造成語意錯亂 |
| 回傳內容 | 純文字 `Answer` + 中繼資料（成功與否、耗時），不做結構化 Comment 解析 | 對齊 Chat API 的自由格式回答特性，維持與先前 Direct Review 設計文件一致的簡單彙整模式 |
| 兩個核心 Service 命名 | **既有服務改名為 `PullRequestReviewService`**（`ICodeReviewService`→`IPullRequestReviewService`）；**新服務接手 `CodeReviewService` 這個名字**（`ICodeReviewService`/`CodeReviewService`） | 「Code Review」是通用的核心領域動作，新的 Diff 審查才是最貼近這個通用動作的實作；既有服務除了審查程式碼，還額外背負 PR 實體的抓取、比對、回貼留言、DB 寫入等副作用，屬於「操作 PR 實體」的特化應用，改名為 `PullRequestReviewService` 更精準（強調操作對象是 PR 實體，而非強調 Webhook 這個觸發管道，因為未來即使改成手動重跑，職責本質不變）|

---

## 3. 分層實作計畫

### Phase 0 — Domain 基礎型別

| 檔案 | 動作 | 內容 |
|---|---|---|
| `Domain/Enums/ReviewScopeEnum.cs`（新增） | 新建 | `public enum ReviewScope { Quick = 1, Full = 2 }`，附 XML 註解說明各檔位涵蓋範圍 |
| `Domain/Entities/Rule.cs`（設定用的是 `RuleEntry`，非此檔） | 不變 | DB 版 `Rule` entity 目前未被使用於本次流程，暫不調整 |
| `Application/Config/RuleEntry.cs` | 修改 | 新增 `public List<ReviewScope> ApplicableScopes { get; set; } = new();`。**語意：空清單＝僅 Full 適用（保守預設）**；要讓某條 Rule 也在 Quick 模式下觸發，需明確加入 `["Quick", "Full"]`。補上 XML 註解明確記載此預設語意，避免設定檔維護者誤解 |
| `Domain/Interfaces/IDifyService.cs` | 修改 | 新增方法 `Task<DifyChatReviewResult> ChatReviewAsync(DifyChatReviewRequest request, CancellationToken cancellationToken = default);`，並新增 `DifyChatReviewRequest` / `DifyChatReviewResult` 兩個 DTO class（沿用現有檔案內 class 並列的寫法）。**注意**：此方法底層仍打同一支 Dify Chat API（`/v1/chat-messages`），新增的原因是輸入（整段多檔 diff＋context，而非單一 FileName+FileDiff）與輸出（回傳原始 `answer` 文字，而非切成 `[MUST]/[SHOULD]/[MAY]` 結構化 Comment）的資料契約都跟 `ReviewCodeAsync` 不同，不是換端點 |

`DifyChatReviewRequest` 欄位：`ApiKey`、`ApiEndpoint?`、`DiffContent`、`ContextSummary?`
`DifyChatReviewResult` 欄位：`IsSuccess`、`Answer`、`DurationMs`、`ErrorMessage?`

---

### Phase 1 — 既有服務改名 + 抽出共用的 RuleMatcher（重構，不改變 Webhook 行為）

> **命名討論結論**：`IRuleMatcher` 名稱維持不變（不拆分、不改名）。實際上它同時承擔兩種粒度的職責——① `GetApplicableRules` 是「依 repo + scope 情境**篩選**出適用規則清單」的組合式決策，② `IsFilePatternMatch` 是單一檔名對單一 pattern 的**布林判斷**，語意上比「Matcher」更重一些。考量到拆分成兩個介面在目前規模下屬於過度設計，決定保留單一介面，但**要求在 `IRuleMatcher.cs` 上加上 XML 文件註解，明確寫出兩個方法各自的職責邊界**，避免未來維護者誤以為它只是單純的 pattern 比對工具。
>
> **本階段額外新增「既有服務改名」任務**：`ICodeReviewService`/`CodeReviewService` → `IPullRequestReviewService`/`PullRequestReviewService`，把「CodeReviewService」這個名字讓給新的 Diff Review 服務（理由見上方設計決策表）。這是本規劃書中**唯一一項會改動既有生產程式碼命名**的任務，改名範圍與這次 session 稍早完成的 `GitPlatformType`→`GitPlatformTypeEnum` 重構規模相當（約 4-7 個檔案，且目前無對應單元測試需要同步修改），可在同一個 PR 內與 RuleMatcher 抽取一起完成並整合驗證。

| 檔案 | 動作 | 內容 |
|---|---|---|
| `Application/Services/ICodeReviewService.cs` → `Application/Services/IPullRequestReviewService.cs` | 改名 | 介面改名為 `IPullRequestReviewService`，方法簽章不變（`StartAsync(StartCodeReviewCommand, CancellationToken)`） |
| `Application/Services/CodeReviewService.cs` → `Application/Services/PullRequestReviewService.cs` | 改名 | 類別改名為 `PullRequestReviewService`，XML 註解同步更新為「處理 Webhook 觸發的 PR 審查流程」，強調操作對象是 PR 實體 |
| `Api/Controllers/WebhookController.cs` | 修改 | 建構子注入型別由 `ICodeReviewService` 改為 `IPullRequestReviewService`（變數名稱、log 訊息同步調整） |
| `Application/DependencyInjection.cs` | 修改 | 註冊型別由 `services.AddScoped<ICodeReviewService, CodeReviewService>()` 改為 `services.AddScoped<IPullRequestReviewService, PullRequestReviewService>()` |
| `Application/Services/IRuleMatcher.cs`（新增） | 新建介面 | `GetApplicableRules(string repoFullName, ReviewScope? scope = null)`（含 XML 註解說明「依 repo/scope 篩選規則清單」）、`IsFilePatternMatch(string fileName, string? patterns)`（含 XML 註解說明「單一檔名與 pattern 的布林比對」） |
| `Application/Services/RuleMatcher.cs`（新增） | 新建實作 | 把 `PullRequestReviewService` 現有的 `GetApplicableRules` / `IsRepoMatch` / `IsFrontendRule` / `ExcludeFrontendRulesForNmqRepo` / `IsFilePatternMatch` 搬過來，額外加上 `scope` 篩選。篩選邏輯：`scope == null` → 不篩選（Webhook 相容）；`scope == Full` → `rule.ApplicableScopes.Count == 0 \|\| rule.ApplicableScopes.Contains(Full)`；`scope == Quick` → 必須 `rule.ApplicableScopes.Contains(Quick)`（空清單視為不適用 Quick） |
| `Application/Services/PullRequestReviewService.cs` | 修改 | 建構子改注入 `IRuleMatcher`，移除搬走的 private 方法，呼叫處改為 `_ruleMatcher.GetApplicableRules(command.RepoFullName)`（Webhook 流程不傳 scope，維持「全部規則皆適用」的原行為） |
| `Application/DependencyInjection.cs` | 修改 | 註冊 `services.AddSingleton<IRuleMatcher, RuleMatcher>();`（無狀態，可用 Singleton） |

> ⚠️ **重構風險控管**：改名本身是機械式操作但牽動既有生產程式碼（介面、DI 註冊、Controller 注入），加上 RuleMatcher 抽取，這兩件事**建議放在同一個 PR、同一輪迴歸驗證中完成**。搬移/改名後需以現有 Webhook 相關測試（若有）或手動觸發一次 Webhook 流程驗證行為完全一致（相同 repo 匹配相同 Rule 清單、NMQ 排除邏輯結果不變、log 內容與追蹤 ID 不受影響）。

---

### Phase 2 — Application：Diff Review 服務與 DTO

> **命名與分層討論結論**：新服務獨立為 `ICodeReviewService` / `CodeReviewService`，**不合併進 `PullRequestReviewService`**，也**不省略 Application 層直接讓 Controller 呼叫 `IDifyService`**。
>
> - **不合併的理由（已對照實際程式碼驗證）**：`PullRequestReviewService.ExecuteReviewAsync` 的既有步驟（PR Title Ignore Gate → `IRepoHostClientFactory.GetPullRequestDiffFilesAsync` 抓 diff → `PostComments` 去重分組回貼 PR）全部是「Git 事件驅動、有平台副作用」的邏輯，Diff Review 一個都用不到；唯一可能共用的「找 Rule」已經抽到 `IRuleMatcher`。合併只是共用 class 名稱與建構子，實質毫無程式碼共用，反而讓 `PullRequestReviewService` 建構子混入用不到的依賴。
> - **不省略此層的理由**：`ReviewController` 若直接注入 `IRuleMatcher` + `IDifyService`，會把「驗證參數 → 找規則 → 組 context → 平行呼叫 → 彙整」整段編排邏輯寫進 Controller，違背現有 `WebhookController → PullRequestReviewService` 的薄 Controller 慣例，也不利單元測試。
> - **命名分工**：`CodeReviewService` 拿到最通用的核心領域名字（純粹「審查程式碼」這個動作），`PullRequestReviewService` 的名字強調它操作的是「PR 這個實體」並背負對應副作用（抓 diff、回貼留言、寫 DB），兩者不是構詞對稱遊戲，而是「通用能力 vs 特化應用」的命名分工。
> - **YAGNI 範圍紀律**：本階段 `ICodeReviewService` **只定義 `ReviewAsync` 這一個方法**，不預先設計討論過的未來擴充方法（`ExplainDiffAsync`、`BatchReviewAsync` 等）。是否新增由未來實際需求觸發時再評估，避免「先射箭再畫靶」的過度設計。

| 檔案 | 動作 | 內容 |
|---|---|---|
| `Application/DTOs/DiffReviewDto.cs`（新增） | 新建 | `DiffReviewRequest`（`RepositoryName`、`Scope`（`ReviewScope`，預設 `Quick`）、`DiffContent`、`Context?`）／`ReviewContext`（`Branch?`、`WorkItemId?`、`Author?`、`FullFileContents`）／`FileFullContent`／`DiffReviewResponse`（`IsSuccess`、`Answers`、`TotalDurationMs`、`ErrorMessage?`）／`DiffReviewAnswer`（`Reviewer`、`Answer`、`IsSuccess`、`DurationMs`） |
| `Application/Services/ICodeReviewService.cs`（新增） | 新建介面 | `Task<DiffReviewResponse> ReviewAsync(DiffReviewRequest request, CancellationToken cancellationToken = default);` |
| `Application/Services/CodeReviewService.cs`（新增） | 新建實作 | 1) 驗證必填欄位 → 2) 呼叫 `_ruleMatcher.GetApplicableRules(request.RepositoryName, request.Scope)` → 3) 組 `ContextSummary`（沿用先前設計文件的 `BuildContextSummary` 邏輯）→ 4) 對每條 Rule 平行呼叫 `_difyService.ChatReviewAsync` → 5) `Task.WhenAll` 彙整成 `DiffReviewResponse` |

---

### Phase 3 — Infrastructure：Dify Chat API 實作

| 檔案 | 動作 | 內容 |
|---|---|---|
| `Infrastructure/Services/DifyService.cs` | 修改 | 實作 `ChatReviewAsync`：組 HTTP POST 至同一支 `{ApiEndpoint}`（`/v1/chat-messages`，與 `ReviewCodeAsync` 相同端點），`query` 帶入整段 `DiffContent`（必要時附加 `ContextSummary`），**直接回傳原始 `answer` 文字**（不像 `ReviewCodeAsync` 的 `ParseReviewComments` 那樣依標籤切成結構化 Comment），補上例外處理與耗時量測（沿用現有 `ReviewCodeAsync` 的 HttpClient/認證/錯誤處理慣例） |

---

### Phase 4 — Api：Controller 與 DI 註冊

| 檔案 | 動作 | 內容 |
|---|---|---|
| `Api/Controllers/ReviewController.cs`（新增） | 新建 | `[ApiController] [Route("api/[controller]")] public class ReviewController`；`[HttpPost("diff")]` 注入 `ICodeReviewService`，null 檢查 → 呼叫 `ReviewAsync` → 依 `IsSuccess`/`Answers.Count` 回傳 200/400/500（沿用先前設計文件的錯誤處理邏輯） |
| `Application/DependencyInjection.cs` | 修改 | 註冊 `services.AddScoped<ICodeReviewService, CodeReviewService>();` |

---

### Phase 5 — 設定檔調整

實際設定檔位於 `config/settings.json` 的 `_N1CONFIG:CodeReview:Rules`，目前共 23 條 Rule，全部預設 `ApplyToRepos: ["*"]`。

依討論定案，**Quick 檔位採白名單制**：只有明確加上 `ApplicableScopes` 且包含 `"Quick"` 的 Rule，才會在 `POST /api/review/diff` 傳入 `Scope=Quick` 時被觸發；未標記的 Rule 空清單視為「僅 Full 適用」。

本次只需異動 **2 條 Rule**（`StandardBackend`、`CustomRuleBackend`），其餘 21 條**完全不用修改**：

```json
{
  "Name": "StandardBackend",
  "DifyApiKey": "app-ZiyaCPCjqiTaN8YEAsMTZU8e",
  "FilePatterns": "*.cs",
  "ApplyToRepos": [ "*" ],
  "IsActive": true,
  "IsFrontendRule": false,
  "ApplicableScopes": [ "Quick", "Full" ]
},
{
  "Name": "CustomRuleBackend",
  "DifyApiKey": "app-CzdjFhacdnhKZ9z3vGZdL9DL",
  "FilePatterns": "*.cs",
  "ApplyToRepos": [ "*" ],
  "IsActive": true,
  "IsFrontendRule": false,
  "ApplicableScopes": [ "Quick", "Full" ]
}
```

其餘 21 條（`Exception`、`InfoSecurity`、`CodeMentorPro`、`Performance`、`FrontendStandard`、`NMQ` 等）維持原樣、不加 `ApplicableScopes`：依新語意，這些 Rule 只會在 `Scope=Full`（或 Webhook 流程，不受此篩選影響）時套用，**Quick 模式下不會被觸發**，剛好對應「Quick 只跑 StandardBackend + CustomRuleBackend 兩條核心規則」的設計目標。

> ⚠️ 若未來想調整 Quick 涵蓋的 Rule（增加或減少），只需要在對應 Rule 上加/改 `ApplicableScopes`，不用動程式碼。

---

### Phase 6 — 測試計畫

| 類型 | 內容 |
|---|---|
| 單元測試 | `RuleMatcher`：依 repo/scope/file pattern 篩選是否正確；NMQ 前端規則排除邏輯是否維持原行為 |
| 單元測試 | `CodeReviewService`：必填欄位驗證、找不到 Rule 時回傳訊息、多 Rule 平行呼叫後正確彙整、單一 Rule 失敗不影響其他 Rule 結果 |
| 迴歸驗證 | 重構 `PullRequestReviewService` 後，用既有 Webhook 測試案例（或手動觸發一次 PR）確認行為與重構前一致 |
| 整合測試 | 實際呼叫 `POST /api/review/diff`，涵蓋：找不到 repo（400）、找不到符合 scope 的 Rule（400）、正常成功（200）、Dify 逾時／失敗（單一 Rule 失敗但整體仍 200） |

---

## 4. 待辦拆解（依相依順序）

1. `ReviewScopeEnum` + `RuleEntry.ApplicableScopes`
2. `IDifyService.ChatReviewAsync` + DTO
3. **既有服務改名**：`ICodeReviewService`/`CodeReviewService` → `IPullRequestReviewService`/`PullRequestReviewService`（含 `WebhookController`、DI 註冊同步修改）
4. 抽出 `IRuleMatcher` / `RuleMatcher`，重構 `PullRequestReviewService` 改用它（與第 3 點同一輪迴歸驗證）
5. `DiffReviewDto`
6. `ICodeReviewService` / `CodeReviewService`（新服務）
7. `DifyService.ChatReviewAsync` 實作
8. `ReviewController`（`POST /api/review/diff`）+ DI 註冊
9. 設定檔補上 `ApplicableScopes`（僅 `StandardBackend`、`CustomRuleBackend` 兩條）
10. 單元測試 + 整合測試

---

## 5. 風險與注意事項

- **重構風險**：Phase 1 動到既有 Webhook 流程使用的私有方法，雖然是搬移不改邏輯，仍需迴歸驗證，避免影響現行生產中的 Webhook 審查功能。
- **既有服務改名風險**：`CodeReviewService`→`PullRequestReviewService` 是本規劃書唯一牽動既有生產程式碼命名的異動，需完整檢查是否有日誌關鍵字監控、儀表板告警規則、或其他未被 grep 到的文字引用（例如設定檔說明、Wiki 文件）綁死舊類別名稱；建議與 RuleMatcher 抽取合併在同一個 PR 送出，一次性完成迴歸驗證，避免分兩次改動、兩次驗證的重複成本。
- **Dify Chat API 額度／逾時**：多 Rule 平行呼叫會同時消耗多個 Dify App 的額度，需確認現有 `DifySettings`（timeout、重試策略）是否需要針對 Chat API 另外調整。
- **`ApplicableScopes` 預設值**：務必確認「空清單＝僅 Full 適用（Quick 需明確白名單）」的預設語意有清楚文件記載，避免設定檔維護者誤以為空清單代表「全部 scope 皆適用」而誤觸發 Quick。
