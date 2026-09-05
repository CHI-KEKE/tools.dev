---
name: create-pr
description: 完整的 Git PR 建立工作流程。當 Allen 說「幫我發 PR」、「建立 PR」、「開 PR」、「create PR」、「發一個 pull request」時，使用此 skill。流程涵蓋：確認 staged 狀態 → stage & commit（含 AI 生成 commit message 確認）→ push 到 upstream 新 branch → 詢問目標 branch 並提供 PR 連結。
---

# Create PR

## 工作流程概覽

```
Step 1: 確認 git status（unstaged 狀態）
Step 2: 詢問是否 stage all 並 commit
Step 3: 分析 diff，生成 commit message，請 Allen 確認或修改
Step 4: git add . && git commit
Step 5: push 到 upstream 新 branch（branch 名稱由 commit message 推導）
Step 6: 詢問要對哪個 branch 發 PR，提供 PR 連結
```

---

## Step 1 — 確認 git status

執行 `git -C "<cwd>" status --short` 查看當前狀態。

- 若**沒有任何變更**：告知 Allen 目前沒有待提交的變更，結束流程。
- 若有 **unstaged 變更**：進入 Step 2。
- 若已全部 **staged**（全是綠色）：跳過 Step 2，直接進入 Step 3。

---

## Step 2 — 詢問是否 Stage All

使用 `ask_user` 詢問：

> 「偵測到以下 unstaged 變更，是否要將全部異動 `git add .` 並 commit？」
> 列出異動檔案清單（最多顯示 10 筆，超過以 "...共 N 個檔案" 顯示）

choices:
- `是，全部 stage（git add .）`
- `否，我要手動 stage`

若選「否」：提示 Allen 手動 stage 後再說「繼續」，結束本輪。

---

## Step 3 — 生成 Commit Message

執行 `git -C "<cwd>" diff --staged` 取得完整 diff。

根據 diff 內容，依照以下格式生成 commit message：

```
<type>(<scope>): <簡短中文描述>

- <變更說明 1>
- <變更說明 2>
（視需要加入）
```

**type 對照：**
| type | 使用時機 |
|------|----------|
| feat | 新功能 |
| fix | Bug 修復 |
| refactor | 重構（無功能變更） |
| chore | 設定、工具、依賴更新 |
| docs | 文件變更 |
| test | 測試相關 |

使用 `ask_user` 顯示生成的 commit message，詢問：

> 「以下是建議的 commit message，是否可以使用？」

choices:
- `✅ 可以，使用此 message`
- `✏️ 我要修改`

若選「修改」：使用 `ask_user` freeform 讓 Allen 輸入新的 message，確認後繼續。

---

## Step 4 — Commit

執行：
```bash
git -C "<cwd>" add .
git -C "<cwd>" commit -m "<confirmed commit message>"
```

確認 commit 成功後進入 Step 5。

---

## Step 5 — Push 到 Upstream 新 Branch

**推導 branch 名稱規則：**
- 從 commit message 的 `<type>/<簡短英文描述>` 推導
- 空格改 `-`，全小寫，特殊字元移除
- 範例：`feat/replace-dify-api-key-for-code-mentor-pro`

執行：
```bash
git -C "<cwd>" push origin HEAD:<branch-name> --set-upstream
```

若 push 失敗（branch 已存在），在名稱後加 `-v2`（-v3 依此類推）再重試。

---

## Step 6 — 詢問目標 Branch，提供 PR 連結

先執行 `git -C "<cwd>" remote get-url origin` 取得 remote URL，推導平台（GitHub / GitLab / Bitbucket）。

使用 `ask_user` 詢問：

> 「Branch `<branch-name>` 已 push 成功！要對哪個 branch 發 PR？」

choices（根據 repo 常見分支，預設提供）:
- `develop`
- `main`
- `master`
- `staging`

確認後，根據平台生成 PR 建立連結：

**GitHub：**
```
https://github.com/<org>/<repo>/compare/<target-branch>...<branch-name>?expand=1
```

**GitLab：**
```
https://gitlab.com/<org>/<repo>/-/merge_requests/new?merge_request[source_branch]=<branch-name>&merge_request[target_branch]=<target-branch>
```

**Bitbucket：**
```
https://bitbucket.org/<org>/<repo>/pull-requests/new?source=<branch-name>&dest=<target-branch>
```

輸出 PR 連結並告知 Allen 點擊即可開啟 PR 建立頁面。
