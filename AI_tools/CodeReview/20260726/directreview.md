# DirectReview API 說明文件

> `POST /api/review/direct`
> 提供同步式 diff 審查端點，供 Copilot CLI / CI Script 直接呼叫。
> **不依賴 Webhook，不寫入資料庫，不與 Git 平台互動。**

---

## 1. 這支 API 是什麼

`DirectReviewController` 是既有「Webhook-based Code Review」流程之外，另外提供的一條**輕量、同步、無狀態**審查通道。

呼叫端（Copilot CLI 或 CI Script）直接把整段 diff 內容 POST 給 Server，Server 依 `RepositoryName` 查出對應的審查規則（Rule），**平行**呼叫每條規則對應的 Dify Chat App，等全部回應完成後，把每個規則的回答彙整成清單，一次性同步回傳。

```
Client (Copilot CLI / CI)
      │  diff + repoName + taskingFlow
      ▼
DirectReviewController  (POST /api/review/direct)
      ▼
DirectReviewService.ReviewAsync()
      │
      ├─ 1. 依 RepositoryName + TaskingFlow 查詢 Rules  (IRuleRepository)
      ├─ 2. 組 ContextSummary（branch / workItem / author / 完整檔案內容）
      ├─ 3. 對每條 Rule 平行呼叫 Dify Chat API           (IDifyService.ChatReviewAsync)
      └─ 4. Task.WhenAll 彙整 → DirectReviewResponse
      ▼
回傳 JSON 結果給呼叫端（不寫 DB、不回貼 PR comment）
```

---

## 2. 與既有 Webhook 流程的差異

| 面向 | Webhook 流程（`CodeReviewService`） | Direct Review（`DirectReviewService`） |
|---|---|---|
| 觸發方式 | Git 平台 Webhook（PR 建立/更新） | 呼叫端主動 POST diff |
| 呼叫的 Dify API | Workflow API `/v1/workflows/run`，**逐檔案**呼叫 | Chat API `/v1/chat-messages`，**整段 diff 一次**呼叫 |
| 執行順序 | 依檔案序列處理，檔案內各 Rule 依序呼叫 | 符合條件的 Rules **平行**（`Task.WhenAll`）呼叫 |
| Repository 查詢 | 依 Platform + PlatformId/FullName 找 `Repository` 實體，檢查 `IsActive` | 直接用字串 `RepositoryName` 模糊比對找 Repository |
| Git 平台互動 | 取檔案清單、回貼 PR comment | 完全不與 Git 平台互動（diff 由呼叫端提供） |
| Hot Keyword 掃描 | 有 | 沒有 |
| 資料庫寫入 | 建立/更新 `ReviewLog`、`ReviewFileLog`、`DifyUsageLog`、`RuleStatistics` | 完全不寫 DB |
| 回傳內容 | 結構化 Comment（行號、嚴重度、分類） | 純文字 Answer（Dify Chat 的 `answer` 欄位） |
| 共用資源 | `IRuleRepository`（Rules 表）、`IDifyService`（底層 HTTP 呼叫） | 同左 |

**結論**：兩者共用「Rules 資料來源」與「Dify 服務物件」，但**沒有共用核心審查邏輯**——file pattern 比對、統計寫入、Comment 格式化都是各自獨立實作，彼此是兩條互不影響的程式碼路徑。

---

## 3. Request

### Endpoint

```
POST /api/review/direct
Content-Type: application/json
```

### Body — `DirectReviewRequest`

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `repositoryName` | string | ✅ | Repository 名稱，用於查詢 DB 中對應的 Rules。支援 `FullName` 精確比對、`Name` 比對，或 `FullName` 以 `/repositoryName` 結尾比對。例如 `"nine1.live.buy"` 或 `"g11n/nine1.live.buy"`。 |
| `taskingFlow` | string | 　 | 觸發流程標籤，對應 `Rule.FlowTags` 欄位，用來篩選這次要跑哪些 Rule。詳見第 4 節。 |
| `diffContent` | string | ✅ | Git diff 內容（例如 `git diff --staged` 的輸出）。 |
| `reviewContext` | object | 　 | 補充給 AI 的上下文，減少誤判（見下表）。 |

### `reviewContext` — `DirectReviewContext`

| 欄位 | 型別 | 說明 |
|---|---|---|
| `branch` | string? | Git branch 名稱（例如 `feature/VSTS12345-xxx`） |
| `workItemId` | string? | Work Item / VSTS Task ID（通常從 branch 名稱解析） |
| `author` | string? | 提交者 email（`git config user.email`） |
| `fullFileContents` | array | 變更檔案的完整內容，至少包含被異動 method 所在的檔案，避免 AI 只看 diff 片段造成誤判。每筆為 `{ filePath, content }`。 |

### Request 範例

```json
{
  "repositoryName": "nine1.live.buy",
  "taskingFlow": "review-only",
  "diffContent": "=== STAGED DIFF (C# RELATED) ===\ndiff --git a/src/...",
  "reviewContext": {
    "branch": "feature/VSTS12345-my-feature",
    "workItemId": "12345",
    "author": "developer@91app.com",
    "fullFileContents": [
      { "filePath": "src/Services/MyService.cs", "content": "..." }
    ]
  }
}
```

---

## 4. `taskingFlow` — 審查規則的「檔位」

`taskingFlow` 用來決定「這次呼叫要跑哪一組 Rule」，而不是跑該 Repository 底下**全部**的 Rule。

底層對應到 `Rule.FlowTags`（逗號分隔字串，例如 `"review-only,full"`）：
- Rule 若 `FlowTags` 為空，代表**所有流程都適用**，永遠會被納入。
- 呼叫端傳入的 `taskingFlow`，會拿去比對每條 Rule 的 `FlowTags` 是否包含該 tag（不分大小寫）。

### 現況（程式碼中的實際命名）

| 值 | 涵蓋規則 |
|---|---|
| `review-only`（預設） | 只跑「Stage 2」用的 Rule（目前為 Custom + Standard 兩個 Dify App） |
| `full` | 所有適用此 Repository 的 Rule 都執行 |

> ⚠️ **命名問題**：`review-only` 與 `full` 不是同一維度的對稱詞（`full` 的反義應該是「部分/精簡」，而不是「只做審查」），容易讓呼叫端誤解語意，需要回頭查註解才能理解涵蓋範圍。

### 建議命名：`quick` / `full`

| 建議值 | 語意 | 涵蓋規則（沿用現有邏輯，僅改名） |
|---|---|---|
| `quick` | 快速檢查，只跑核心必要規則 | 對應現有 `review-only`：Custom + Standard 兩個 Dify App |
| `full` | 完整審查，跑所有適用規則 | 與現況相同，不需變動 |

選擇理由：
1. **對稱好懂**：`quick` / `full` 是同一維度的相對詞，呼叫端不用查文件就能猜出行為差異。
2. **相容性高**：`full` 沿用現有值，資料庫既有規則設定的 `FlowTags = "full"` 完全不用改；只需新增 `quick` 作為 `review-only` 的別名（或直接更名）。
3. **可擴充**：未來若要加第三檔（例如比 `full` 更深入的分析），可以延伸為 `quick` → `full` → `deep`，語意仍然一致。

> 📌 本文件僅為**設計提案**，尚未變更程式碼。若確認採用，需同步調整：
> `DirectReviewRequest.TaskingFlow` 預設值、`Rule.FlowTags` 既有資料、`IRuleRepository.GetByRepositoryNameAndFlowAsync` 的比對邏輯與相關文件/註解。

---

## 5. Response

### `200 OK` — 審查完成（至少一個 Rule 成功）／`400 Bad Request` — 參數錯誤或找不到 Rules

Body — `DirectReviewResponse`：

| 欄位 | 型別 | 說明 |
|---|---|---|
| `isSuccess` | bool | 只要有任一 Rule 成功即為 `true` |
| `answers` | array | 每條 Rule 的審查結果，見下表 |
| `totalDurationMs` | int | 全部平行呼叫的總耗時（毫秒） |
| `errorMessage` | string? | 找不到 Rules、參數錯誤或系統例外時的錯誤訊息 |

`answers[]` — `DirectReviewAnswer`：

| 欄位 | 型別 | 說明 |
|---|---|---|
| `reviewer` | string | 對應 `Rule.Name` |
| `answer` | string | Dify Chat App 的回答原文；失敗時為 `"[ERROR] {錯誤訊息}"` |
| `isSuccess` | bool | 該 Rule 呼叫是否成功 |
| `durationMs` | int | 該 Rule 呼叫耗時 |

### `500 Internal Server Error`

未預期例外，回傳 `{ "isSuccess": false, "errorMessage": "Internal server error." }`。

### Response 範例

```json
{
  "isSuccess": true,
  "answers": [
    {
      "reviewer": "Custom Rule",
      "answer": "整體變更看起來合理，建議在 MyService.cs 第 42 行加上 null 檢查。",
      "isSuccess": true,
      "durationMs": 3120
    },
    {
      "reviewer": "Standard Rule",
      "answer": "[ERROR] Dify API timeout",
      "isSuccess": false,
      "durationMs": 15000
    }
  ],
  "totalDurationMs": 15020,
  "errorMessage": null
}
```

---

## 6. 重點整理

1. **接收**：一段 diff 字串 + repositoryName（+ 可選的 taskingFlow、context）。
2. **查規則**：依 repositoryName（+ taskingFlow 篩選）找出對應的 Dify Rule 清單。
3. **平行呼叫**：對每條 Rule 同時打各自的 Dify Chat App，不是依序一個個打。
4. **彙整回傳**：等所有呼叫結束，把每條 Rule 的純文字回答彙整成清單一次回傳，全程不寫資料庫、不與 Git 平台互動。
