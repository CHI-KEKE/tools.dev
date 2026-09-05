# common-implementation-notes-generator

## 概要

`common-implementation-notes-generator` 是一個在實作與 Code Review 結束後使用的共用技能，目標是：

- 彙整本次實作異動、驗證結果與流程觀察
- 產出固定格式的 Implementation Notes
- 回寫到 Azure DevOps Task Discussion
- 於流程完成後自動補上可查詢的 Azure DevOps Tags
- 在 Post-merge 或 Work Item 已 Closed 情境下，支援以歷史資料回填
- 回寫失敗時提供 fallback（完整 Markdown 可人工貼上）

主要規格來源：
- [SKILL.md](SKILL.md)

---

## 何時使用

建議在以下情境觸發：

- 使用者明確要求「產生 implement note / implementation notes」
- 其他 agent 完成實作與 review 後，需要統一回寫 Task Discussion
- 程式已 commit / PR 已建立或已合併，仍需補寫紀錄

---

## 流程摘要

1. 決定模式（live 或 historical）
2. 收集來源資料（工作樹或 PR/commit 歷史）
3. 標準化輸入（缺值補 None）
4. 條件式掃描受影響 API（含 service-only 上溯追蹤）
5. 產生固定區塊順序的 Markdown
6. 呼叫 `add_work_item_comment` 回寫
7. 更新 Work Item Tags（預設 `b2e-impl-notes-generated`）
8. 若失敗，輸出 fallback Markdown 並不中斷流程

---

## 輸入欄位說明

### 必填欄位

- `VSTS_WORK_ITEM_ID`
  - 目標 Task ID。

- `title`
  - Task 標題，會出現在 Implementation Notes 標頭。

- `files_changed`
  - 實際異動檔案清單，含 `[NEW]` / `[MODIFIED]` 標記。
  - 若為 historical 且暫時無法完整取得，可先填 `None`，但不可杜撰。

- `decisions`
  - 關鍵設計取捨（例如：為何改用某種實作）。
  - 沒有就填 `None`。

- `deviations`
  - 與 Task Design 的差異（Planned vs Actual）。
  - 沒有就填 `None`。

- `verification`
  - Build / Unit Test / Code Review 最終結果。
  - 禁止把未執行檢查標記為 Pass。

- `open_questions`
  - 仍需人工確認的事項。
  - 沒有就填 `None`。

- `flow_feedback`
  - 流程品質觀察（不是功能正確性），例如依賴資訊不完整、流程可改進點。
  - 沒有就填 `None`。

### 選填欄位（historical 建議提供）

- `pr_url`
  - 用於從 PR 擷取檔案異動與驗證線索。

- `repo`
  - Repo 名稱或路徑，供歷史查詢使用。

- `commit_range`
  - 例如 `abc123..def456`，當沒有 PR 時可用於回填異動。

- `source_mode`
  - `live`：直接使用當前工作樹與呼叫端輸入。
  - `historical`：從 PR/commit 歷史回填。

---

## Implementation Notes 各欄位說明

Implementation Notes 固定輸出以下 7 個區塊，順序不可更改：

1. `Files Changed`
2. `Affected APIs`
3. `Decisions`
4. `Deviations from Task Design`
5. `Verification`
6. `Open Questions`
7. `Flow Feedback`

### 1) Files Changed

用途：列出本次實作實際動到的檔案。  
建議格式：單層條列，檔案後附 `[NEW]` / `[MODIFIED]`。

### 2) Affected APIs

用途：說明對外 API 影響與追蹤證據。  
規則重點：

- 若變更含 Controller，直接彙整 Action/Route。
- 若只有 Service/Repository/Domain/Entity `.cs`，必須上溯追蹤到 Controller Action。
- 每筆需附 evidence（例如 `OrderService.Submit -> OrdersController.Submit`）。
- 無法自動追蹤時要輸出警示，不可直接 `None`。

### 3) Decisions

用途：記錄關鍵設計判斷，讓後續維護者理解「為何這樣做」。

### 4) Deviations from Task Design

用途：記錄計畫與實作不一致處。  
建議寫法：`Planned: ... / Actual: ... / 原因: ...`。

### 5) Verification

用途：記錄驗證狀態。  
常見內容：

- Build 結果
- Unit Tests 結果（若未跑需誠實註記）
- Code Review 結果（可含 P1/P2/P3 或 iteration）

### 6) Open Questions

用途：列出尚未釐清、需要人工或跨團隊確認的議題。  
沒有則 `None`。

### 7) Flow Feedback

用途：記錄流程層面的觀察與可改善點。  
常見範例：

- `dependency-check-warning: 建議上游任務補齊異動檔案路徑`
- 「歷史資料不足，導致欄位只能回填 None」

重點：

- 這是流程品質訊號，不是功能 bug 欄位。
- 沒有可回饋項目時填 `None`。

---

## 格式規範

- 以 bulleted list 為主
- 禁用 Markdown table（避免 Azure DevOps 顯示異常）
- 各 section 無資料時，明確填 `None`
- 所有 user-facing 內容使用繁體中文

---

## 回寫與失敗處理

- 正常流程：呼叫 Azure DevOps `add_work_item_comment` 回寫
- 回寫成功後：呼叫 Azure DevOps `update_work_item` 補上 tags
  - 必填標籤：`b2e-impl-notes-generated`
  - 若 `source_mode = historical`：加上 `b2e-impl-notes-historical`
  - 若 comment 回寫失敗但已提供 fallback Markdown：加上 `b2e-impl-notes-fallback`
- Work Item 已 Closed：仍應先嘗試回寫
- 回寫失敗：輸出警告與完整 fallback Markdown，流程不中斷
- Tag 更新失敗：輸出警告但不阻斷主流程

---

## Tag 命名規範

- 命名風格：全小寫、kebab-case、使用 `b2e-` 前綴
- 基礎查詢 tag：`b2e-impl-notes-generated`
- 模式輔助 tag（選配）：`b2e-impl-notes-historical`
- 例外流程 tag（選配）：`b2e-impl-notes-fallback`

建議查詢方式（WIQL）：

- `CONTAINS 'b2e-impl-notes-generated'`：查全部已完成 Notes 的 Work Item
- `CONTAINS 'b2e-impl-notes-historical'`：查歷史回填案例
- `CONTAINS 'b2e-impl-notes-fallback'`：查需人工補貼或流程改善案例

---

## 實作建議

- 在 agent 中以獨立步驟統一呼叫本 skill，避免每個 agent 內嵌不同模板。
- 若是 batch 任務，可「逐 task」觸發，單筆失敗不阻斷整批。
- 若 source mode 為 historical，建議優先提供 `pr_url`，其次 `commit_range`。
