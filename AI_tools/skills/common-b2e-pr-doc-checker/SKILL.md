---
name: common-b2e-pr-doc-checker
description: >
  掃描 PR（Pull Request / Merge Request）的程式碼異動，比對 /.doc/ 底下的知識文件是否已同步更新，偵測程式碼與開發文件之間的落差並輸出結構化的文件對齊報告。
  分析來源優先度：Code diff → Commit message → User story → Task。
  支援 Bitbucket（nineyi.* 類型 repo）及 GitLab（nine1.* 類型 repo）兩種平台。
  當使用者說「幫我確認文件有沒有更新」、「PR 有沒有補文件」、「確認 doc 有沒有對齊」、「檢查文件落差」、「PR doc 對齊」、「文件是否同步」，應優先觸發此 Skill。
---

# PR Doc Checker Skill

掃描 PR 的程式碼異動，確認 `/.doc/` 底下的知識文件是否已同步覆蓋，偵測落差並給出具體補件建議。

Keep the main skill file minimal. Load detailed instructions from `references/` only when needed.

---

## Quick Start

1. 載入 `references/prerequisites.md`，確認輸入條件並偵測 PR 平台與 base branch。
2. 執行 Stage 1（`references/stage-1-diff-analysis.md`）：取得 PR diff，分類程式碼異動信號。
3. 執行 Stage 2（`references/stage-2-doc-coverage.md`）：比對 `/.doc/` 的覆蓋狀況。
4. 若 Stage 2 判定模糊或需補充意圖，執行 Stage 3（`references/stage-3-context-enrichment.md`）。
5. 使用 `assets/gap-report-template.md` 產出最終文件落差報告。

---

## Core Rules（Always Apply）

- **分析順序**：Code diff → Commit → User story → Task，前者優先；前者已明確時不需讀取後者。
- **`/.doc/` 為比對基準**：比對的對象是 `/.doc/` 目錄下由 `common-b2e-tool-code-scanner` 與 `common-b2e-doc-system-design-creator` 產出的知識文件。
- **只回報落差**：不自動修改或補齊 `/.doc/`；補件動作需使用者明確指示後，再 handoff 至對應的 doc skill。
- **有依據才回報**：每個落差項目都需標註「觸發依據」（`檔案路徑#行號` 或 commit hash），不可憑空推斷。
- **平台無關的 git 操作**：Bitbucket 與 GitLab 都以 `git` 指令取得 diff，不依賴平台 API。
- **不改寫工作樹**：此 Skill 僅讀取，不寫入任何檔案（除非使用者要求觸發補件 handoff）。

---

## Reference Map（按需載入）

| 檔案 | 載入時機 |
|------|---------|
| `references/prerequisites.md` | 執行前，確認必要輸入與平台偵測 |
| `references/stage-1-diff-analysis.md` | Stage 1：取得 PR diff，分類異動信號 |
| `references/stage-2-doc-coverage.md` | Stage 2：比對 `/.doc/` 覆蓋狀況 |
| `references/stage-3-context-enrichment.md` | Stage 3（條件觸發）：從 commit / user story / task 補充意圖 |
| `references/stage-4-gap-report.md` | Stage 4：格式化並輸出落差報告 |
| `assets/gap-report-template.md` | 最終報告輸出範本 |

---

## Scripts

| 檔案 | 用途 |
|------|------|
| `scripts/get_pr_diff.ps1` | 取得 PR branch 相對 base branch 的 diff，回傳結構化異動清單 |
