---
name: common-implementation-notes-generator
description: >
  在 Code Review 完成後，彙整本次實作異動與驗證結果，生成固定格式的
  Implementation Notes，並回寫到 Azure DevOps Task Discussion，且自動補上可查詢 tags。
  支援受影響 API 掃描、Post-merge/Post-closure 歷史資料回填，與失敗時 fallback 輸出。
---

# common-implementation-notes-generator

將 Implementation Notes 產生與回寫流程獨立成可重用 skill。

---

## 觸發時機

- 使用者要求「產生 implement note」或「生成 implementation notes」
- 其他 agent 在實作完成與 code review 後，需要回寫 Task Discussion
- 程式已完成 commit/PR，甚至 Work Item 已 Closed，仍需補寫 Implementation Notes

---

## 輸入

| 欄位 | 說明 |
|------|------|
| `VSTS_WORK_ITEM_ID` | 目前 Task ID |
| `title` | Task 標題 |
| `files_changed` | Step 2.3 產生的實際異動清單（含 `[NEW]` / `[MODIFIED]`） |
| `decisions` | 關鍵設計取捨（無則 `None`） |
| `deviations` | 與 Task Design 的差異（無則 `None`） |
| `verification` | Build / Unit Test / Code Review 最終結果 |
| `open_questions` | 待人工確認事項（無則 `None`） |
| `flow_feedback` | 流程品質觀察（無則 `None`） |

可選欄位（Post-merge/Post-closure 模式建議提供）：

| 欄位 | 說明 |
|------|------|
| `pr_url` | 對應 Pull Request 連結 |
| `repo` | Repo 名稱或路徑（用於查詢 commit/diff） |
| `commit_range` | 例如 `abc123..def456` |
| `source_mode` | `live` 或 `historical`（未提供時自動判定） |

補充：

- 若工作樹無異動，或 Work Item 已 Closed / 已改走 PR、commit 歷史補寫，請明確傳 `source_mode: historical`
- `source_mode: live` 僅適用於仍能直接從工作樹異動取得資料的情境

---

## 執行步驟

### Step 0 — Determine Mode

- 若使用者提供 `source_mode`，依指定模式執行
- 否則自動判定：
  - 若可取得當前工作樹異動，使用 `live`
  - 若工作樹無異動或 Work Item 已關閉，改用 `historical`

### Step 1 — Collect Source Data

- `live` 模式：
  - 直接使用呼叫端傳入欄位（`files_changed`、`verification` 等）
- `historical` 模式：
  - 優先用 `pr_url` 彙整異動檔案、檢查結果與主要決策線索
  - 若無 `pr_url`，使用 `commit_range` 或近期 commit 歷史回填 `files_changed`
  - 若仍不足，允許部分欄位為 `None`，但不可杜撰

### Step 2 — Normalize Input

- 若任一章節無資料，統一填入 `None`
- 驗證 `files_changed` 是否可解析為清單格式

### Step 3 — Scan Affected APIs (Conditional)

- 若 `files_changed` 含 `.cs` 檔案，觸發：`Use skill: common-dotnet-roslyn-analyzer`
- 先判斷變更型態：
  - 若含 Controller `.cs`：直接彙整該 Controller Action/Route 影響
  - 若僅有 Service/Repository/Domain/Entity `.cs`（無 Controller `.cs`）：必須執行「由下往上」影響追蹤，找到呼叫該 Service/Entity 的 Controller Action 與對應 Route
- 追蹤要求（service-only 情境必做）：
  - 以變更的 Service public method 為起點，向上追查 references / call chain
  - 至少回報到 Controller Action 層級；若可解析，附上 HTTP Method + Route
  - Affected APIs 每筆需含 evidence（例如：`OrderService.Submit -> OrdersController.Submit`）
- 取得受影響 API 結果：
  - 有結果：以條列清單輸出（每個 API 一個 bullet）
  - 無結果：輸出 `⚠️ 無法自動追蹤到 Controller/Route，請人工確認`，不得直接標 `None`
  - 失敗：`⚠️ Roslyn 分析失敗，請人工確認影響範圍`

### Step 4 — Generate Markdown

產生以下固定區塊，且順序不可變更：

1. `Files Changed`
2. `Affected APIs`
3. `Decisions`
4. `Deviations from Task Design`
5. `Verification`
6. `Open Questions`
7. `Flow Feedback`

Markdown 標題格式：

```markdown
## 📋 Implementation Notes - {YYYY-MM-DD}

**Task:** #{VSTS_WORK_ITEM_ID} {title}
**Executed By:** common-implementation-notes-generator
```

Implementation Notes 內文格式規範：

- 主要格式必須是 bulleted list
- 各 section 內若有多筆項目，使用 `-` 單層條列
- 若需補充細節，使用短句附註在同一個 bullet 或下一個 bullet
- 禁用 Markdown table（`|---|`）以避免 Azure DevOps 顯示異常

Section 參考模板：

```markdown
### Files Changed
- BusinessLogic/Services/PromotionService.cs [MODIFIED]
- BusinessLogic/Services/PromotionValidator.cs [NEW]

### Affected APIs
- `POST /api/promotion/dispatch` - Modified
  - evidence: `PromotionService.Dispatch -> PromotionController.Dispatch`
- `GET /api/promotion/{id}` - Impacted by validator change
  - evidence: `PromotionValidator.Validate -> PromotionController.GetById`

### Decisions
- 驗證邏輯集中於 PromotionValidator，避免 Service 類別膨脹

### Deviations from Task Design
- Planned: Repositories/OldPromotionRepo.cs
- Actual: removed（原因：重構後不再需要）

### Verification
- Build: Pass `dotnet build`
- Unit Tests: Not run `deferred to unit test handoff`
- Code Review: Pass (auto-fixed 1 items)

### Open Questions
- None

### Flow Feedback
- dependency-check-warning: 建議上游任務補齊異動檔案路徑
```

### Step 5 — Post Comment

- 使用 Azure DevOps MCP 工具 `add_work_item_comment` 回寫到目前 Task
- `id = {VSTS_WORK_ITEM_ID}`
- `text = Step 3 產生的 Markdown`

註記：

- 即使 Work Item 是 `Closed`，仍應先嘗試回寫 comment（若權限/流程允許通常可成功）
- 若因流程限制無法回寫，改走 fallback，不中斷流程

### Step 5.5 — Update Work Item Tags

- 使用 Azure DevOps MCP 工具 `update_work_item` 補上 tags
- tags 更新策略：
  - 必填：`b2e-impl-notes-generated`
  - 若 `source_mode = historical`：另加 `b2e-impl-notes-historical`
  - 若 comment 回寫失敗並觸發 fallback：另加 `b2e-impl-notes-fallback`
- 更新原則：
  - 以「append」方式加 tag，不可覆蓋既有 tags
  - 若 tag 已存在，不重複新增
  - tags 更新失敗時僅警告，不中斷流程

### Step 6 — Error Fallback

- 若回寫失敗：
  - 在對話中輸出警告
  - 印出完整 Markdown 供人工貼上
  - 不中斷上游工作流

---

## 輸出

成功時：

```markdown
✅ Implementation Notes Posted

**Task:** #{VSTS_WORK_ITEM_ID}
**Discussion Comment Title:** Implementation Notes - {YYYY-MM-DD}

Sections included: Files Changed / Affected APIs / Decisions / Deviations / Verification / Open Questions / Flow Feedback
```

失敗時：

- 顯示 `⚠️ add_work_item_comment failed`
- 顯示 fallback 的完整 Implementation Notes Markdown
- 若 tags 更新失敗，另顯示 `⚠️ update_work_item(tags) failed`

---

## 呼叫範例模板

### 範例 A：由 nine1-code-implement 觸發

```markdown
Use skill: common-implementation-notes-generator.

Input:
- VSTS_WORK_ITEM_ID: {VSTS_WORK_ITEM_ID}
- title: {title}
- files_changed:
  - BusinessLogic/Services/PromotionService.cs [MODIFIED]
  - BusinessLogic/Services/PromotionValidator.cs [NEW]
- decisions:
  - 驗證邏輯集中於 PromotionValidator，避免 Service 類別膨脹
- deviations:
  - Planned: Repositories/OldPromotionRepo.cs -> Actual: (removed) - 原因：重構後不再需要
- verification:
  - Build: Pass `dotnet build`
  - Unit Tests: Not run `deferred to unit test handoff`
  - Code Review: Pass (auto-fixed 1 items)
    - Initial: P1=0, P2=1, P3=0
    - Final: P1=0, P2=0, P3=0
    - Iterations: 1 / 3
- open_questions: None
- flow_feedback:
  - dependency-check-warning: 建議上游任務補齊異動檔案路徑
```

### 範例 B：單獨呼叫（手動補記錄）

```markdown
Use skill: common-implementation-notes-generator.

Input:
- VSTS_WORK_ITEM_ID: 514797
- title: [B2E] PromoCode dispatch refactor
- files_changed:
  - Domain/Entities/PromoCode.cs [MODIFIED]
  - BusinessLogic/Repositories/IPromoCodeRepository.cs [NEW]
- decisions: None
- deviations: None
- verification:
  - Build: Pass `dotnet build`
  - Unit Tests: Pass `dotnet test`
  - Code Review: Pass (auto-fixed 0 items)
    - Initial: P1=0, P2=0, P3=0
    - Final: P1=0, P2=0, P3=0
    - Iterations: 0 / 3
- open_questions: None
- flow_feedback: None
```

### 範例 C：Post-merge / Work Item Closed（歷史資料模式）

```markdown
Use skill: common-implementation-notes-generator.

Input:
- VSTS_WORK_ITEM_ID: 514797
- title: [B2E] PromoCode dispatch refactor
- source_mode: historical
- pr_url: https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/12345
- repo: nine1.shopping
- commit_range: 8fa12ab..91bc33d
- files_changed: None
- decisions: None
- deviations: None
- verification: None
- open_questions:
  - Work Item 已關閉，請以歷史資料回填，不要依賴工作樹異動
- flow_feedback: None
```

---

## 規則

- 所有 user-facing 內容使用繁體中文
- 各 section 無資料時必須明確填 `None`
- 不得將未實際執行的檢查標記為 `Pass`
- 若 `files_changed` 僅含 Service/Repository/Domain/Entity `.cs`，`Affected APIs` 必須執行上溯追蹤到 Controller；不可直接回填 `None`
- 若 Affected APIs 含無法完整解析 route，需附註：`⚠️ 部分 route 無法自動解析，請人工確認`
- `b2e-impl-notes-generated` 為完成本 skill 的標準 tag，不可省略
