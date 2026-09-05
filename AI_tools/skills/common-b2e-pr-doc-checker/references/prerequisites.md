# Prerequisites、平台偵測與 Stop Conditions

## 必要輸入

| 輸入 | 說明 | 必要性 |
|------|------|:------:|
| PR branch 已 checkout | 使用者必須在 PR 的 feature branch 上 | ✅ |
| `/.doc/` 目錄存在 | target repo 已使用 code-scanner 或 doc skill 產過文件 | ✅ |
| Azure DevOps Work Item（User story / Task） | Stage 3 才需要，前兩個 Stage 若已明確可跳過 | ⚙️ 條件必要 |

若 `/.doc/` 目錄不存在，停止並提示：
> ⛔ 找不到 `/.doc/` 目錄。請先使用 `common-b2e-tool-code-scanner` 或 `common-b2e-doc-system-design-creator` 建立知識文件後再執行本 Skill。

---

## PR 平台偵測

執行以下指令偵測平台類型（**不依賴平台 API，只使用 git**）：

```powershell
git remote -v
```

| Remote URL 關鍵字 | 偵測結果 |
|------------------|---------|
| 包含 `bitbucket` | Bitbucket（通常為 `nineyi.*` repo，`.NET Framework` 技術棧） |
| 包含 `gitlab` | GitLab（通常為 `nine1.*` repo，`.NET 6+` 技術棧） |
| 其他 | Unknown — 提示使用者確認，但仍可繼續 |

偵測結果記入報告的「環境資訊」區塊，不影響後續 Stage 邏輯。

---

## Base Branch 決策

**優先順序**（依序嘗試，取第一個存在的）：

```powershell
# 使用 scripts/get_pr_diff.ps1 自動偵測
& ".github\skills\common-b2e-pr-doc-checker\scripts\get_pr_diff.ps1"
```

腳本依此順序偵測 base branch：
1. `origin/main`
2. `origin/master`
3. 當前 branch 的 upstream tracking branch（`git rev-parse --abbrev-ref @{upstream}`）

若三者皆不存在，停止並提示：
> ⛔ 無法偵測 base branch。請明確提供 base branch 名稱，例如：「base 是 develop」。

若使用者明確指定 base branch，優先使用使用者提供的值。

---

## Stop Conditions（Hard Stop）

以下情況必須立即停止，不可繼續：

| 條件 | 停止訊息 |
|------|---------|
| `/.doc/` 目錄不存在 | 見上方提示 |
| 無法偵測 base branch 且使用者未提供 | 見上方提示 |
| `git diff` 回傳錯誤（非 0 exit code） | 回報錯誤輸出，停止 |
| PR diff 為空（與 base branch 無差異） | 提示「目前 branch 與 base 沒有差異，無需進行文件異動分析。」|

---

## Soft Stop（需確認後繼續）

| 條件 | 處理方式 |
|------|---------|
| `/.doc/` 目錄存在但無任何 `.md` 檔案 | 提示使用者確認是否繼續（文件庫為空，報告可能無法判斷落差） |
| Azure DevOps Work Item 無法存取（Stage 3 需要時）| 標記為 `[BLOCKED: AzDO 無法存取]`，繼續以 Code diff 和 Commit 為依據 |
