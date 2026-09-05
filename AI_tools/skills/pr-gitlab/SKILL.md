---
name: pr-gitlab
description: >-
  Push the current feature branch to origin and create a Merge Request
  to the upstream GitLab repository via REST API. Use when the user wants to open a MR,
  push and create MR, or submit their changes for review on GitLab. Triggers on phrases
  like "開MR", "發MR", "push and MR", "create merge request", "submit MR", "建立MR",
  "gitlab PR", "gitlab merge request".
  Requires GL_TOKEN (GitLab Personal Access Token with api scope).
  Optional: GL_HOST (self-hosted GitLab URL, defaults to https://gitlab.com),
  GL_DEFAULT_REVIEWERS stored in ~/.copilot/gitlab-reviewers-registry.md per repo.
  Run check_env.py first to validate prerequisites, then create_pr.py to push and open the MR interactively.
  Also triggers on reviewer management phrases like "設定 reviewer", "管理 reviewer",
  "更新預設 reviewer", "取消預設 reviewer", "manage reviewers" — run manage_reviewers.py for these.
---

# pr-gitlab

Push feature branch to origin and open a Merge Request to upstream — all via CLI.

## ⚠️ Agent Rules (Non-Negotiable)

> These rules govern how the AI agent must behave when running this skill.

1. **NEVER ask the user to provide GL_TOKEN in conversation.** Tokens are sensitive — requesting them verbally is a security risk.
2. If `check_env.py` reports `GL_TOKEN` is not set, **stop immediately** and show the user the setup instructions below. Do NOT attempt workarounds (e.g., `--token` flag, `Read-Host`, interactive prompts).
3. After showing setup instructions, tell the user to **restart their terminal** and invoke the skill again.

## Prerequisites

### 1. Create a GitLab Personal Access Token

1. Go to: **Settings → Access Tokens** (or `https://{your-gitlab-host}/-/user_settings/personal_access_tokens`)
2. Click **"Add new token"**
3. Enter a name (e.g., `copilot-mr`) and expiry date
4. Select scopes: **`api`** (full API access, required for MR creation and member lookup)
5. Click **Create personal access token** → copy the generated token

### 2. Set environment variables (persistent, user-level)

`GL_TOKEN` is required. `GL_HOST` is optional (defaults to `https://gitlab.com`).

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("GL_TOKEN", "your-token-here", "User")
# Only needed for self-hosted GitLab:
[System.Environment]::SetEnvironmentVariable("GL_HOST", "https://gitlab.your-company.com", "User")
# Restart your terminal / IDE after running this
```

**macOS / Linux (bash):**
```bash
echo 'export GL_TOKEN="your-token-here"' >> ~/.bashrc
# Only needed for self-hosted GitLab:
echo 'export GL_HOST="https://gitlab.your-company.com"' >> ~/.bashrc
source ~/.bashrc
```

**macOS / Linux (zsh):**
```bash
echo 'export GL_TOKEN="your-token-here"' >> ~/.zshrc
# Only needed for self-hosted GitLab:
echo 'export GL_HOST="https://gitlab.your-company.com"' >> ~/.zshrc
source ~/.zshrc
```

> ⚠️ Never hardcode or paste the token into conversation. Always set it as an environment variable.

## Authentication

This skill uses **Private-Token header**: `PRIVATE-TOKEN: {GL_TOKEN}`

This is the standard authentication method for GitLab REST API v4.

## Usage

```bash
# Step 1: 環境檢查（建議每次執行前先跑）
python check_env.py

# Step 2: 建立 MR
python create_pr.py

# 獨立管理 Reviewers（不需建 MR）
python manage_reviewers.py          # 互動模式
python manage_reviewers.py show     # 顯示當前 repo 設定
python manage_reviewers.py set      # 設定預設 reviewers（從專案成員選取）
python manage_reviewers.py mode     # 切換模式 (default / ask / none)
python manage_reviewers.py clear    # 移除當前 repo 的設定
python manage_reviewers.py list     # 列出所有 repo 設定
```

**No pip install required** — uses Python standard library only (`urllib`, `subprocess`, `json`).

## Behaviour

| 項目 | 處理方式 |
|------|---------|
| **Token 未設定** | 印出 GitLab 建立 Token 步驟與各平台**使用者層級**持久設定指令後結束 |
| **origin + upstream** | push 至 origin，MR 指向 upstream (fork workflow) |
| **只有 origin** | push 至 origin，MR 在 origin 內建立 |
| **只有 upstream** | push 至 upstream，MR 在 upstream 內建立 |
| **目標 branch** | 單次輸入：直接輸入分支名稱或關鍵字搜尋 |
| **MR 標題** | 單 commit：自動取 commit subject，不詢問；多 commit：列出所有 commit，由 agent 整合出建議標題供使用者確認或自訂 |
| **Reviewers** | 依 Reviewer 管理流程決定（見下方） |

## Reviewer 管理流程

### Registry 機制

Reviewer 設定存放在 `~/.copilot/gitlab-reviewers-registry.md`，按 repo 名稱儲存。

**查找流程：**
1. 取得 repo 名稱（`git rev-parse --show-toplevel` 取根目錄名）
2. 讀取 `~/.copilot/gitlab-reviewers-registry.md`
   - 檔案不存在 → 建立空 registry，進入「首次設定」流程
   - 找到 repo → 使用已存 reviewer 清單
   - 未找到 repo → 進入「首次設定」流程

### 首次設定流程

使用 `ask_user` 詢問使用者：

**選項：**
- **"設定預設 Reviewers"** → 呼叫 GitLab API 取得專案成員列表，使用者選取後存入 registry
- **"每次詢問"** → registry 記錄 `mode=ask`，每次建 MR 時詢問
- **"不需要 Reviewers"** → registry 記錄 `mode=none`，不指派 reviewer

### 使用已存清單

如果 registry 中有該 repo 的設定：
- `mode=default` + usernames → 顯示 reviewer 清單，詢問：
  - "使用預設 Reviewers" → 直接帶入
  - "這次手動選擇" → 呼叫 API 取成員列表讓使用者選
  - "這次不要 Reviewers" → 略過
  - "更新預設 Reviewers" → 重新選取並更新 registry
- `mode=ask` → 每次呼叫 API 讓使用者選
- `mode=none` → 略過，不詢問

### Agent 互動規則

當腳本顯示 `Select target branch:` 提示時，agent **必須**使用 `ask_user` 工具，設定如下：
- `choices` 的第一個選項為**腳本輸出中顯示的實際 default branch**（從腳本輸出解析，不要硬寫 "main"）
- `allow_freeform: true` — 同時允許使用者直接輸入分支名稱或關鍵字搜尋

Agent **不應**將腳本的 raw prompt 文字原文顯示給使用者，只需透過 `ask_user` 轉接即可。使用者點選 default branch 時，agent 送出 `{enter}`；使用者輸入自訂名稱時，agent 直接送出該名稱。**不需兩次詢問。**

當腳本顯示 `MR Title (multiple commits detected)` 提示時，agent **必須**：
1. 閱讀腳本列出的 commit 清單
2. 根據所有 commit 的內容，**自行整合出一個能概括所有變更的 MR 標題**
3. 使用 `ask_user` 工具：
   - `question` 包含 commit 清單（供使用者參考）
   - `choices: ["{agent 整合的標題}"]` — agent 根據 commit 內容歸納的建議標題
   - `allow_freeform: true` — 允許使用者自訂標題

使用者點選建議標題時，agent 送出該標題文字；使用者輸入自訂標題時，agent 送出使用者的輸入。

當腳本顯示成員列表讓使用者選取 reviewer 時，agent **必須**使用 `ask_user` 工具：
- 若成員 ≤ 20 人：`choices` 為成員清單（格式：`username (display_name)`）
- 若成員 > 20 人：不提供 `choices`，僅在 `question` 中說明可輸入 username 或編號
- `allow_freeform: true` — 允許使用者輸入逗號分隔的編號或 username

## Reviewer 獨立管理（manage_reviewers.py）

當使用者**不是要建 MR，而是單純要管理 reviewer 設定**時，使用 `manage_reviewers.py`。

### 觸發時機

使用者說出以下意圖時，agent 應執行 `manage_reviewers.py`（而非 `create_pr.py`）：
- "設定預設 reviewer" / "set default reviewers"
- "取消預設 reviewer" / "不要預設 reviewer"
- "更新 reviewer" / "update reviewers"
- "管理 reviewer" / "manage reviewers"
- "查看 reviewer 設定" / "show reviewer settings"
- "移除 reviewer 設定" / "clear reviewer config"

### 可用指令

| 指令 | 用途 | 何時使用 |
|------|------|---------|
| `python manage_reviewers.py` | 互動模式（顯示現狀 + 選單） | 使用者意圖不明確時 |
| `python manage_reviewers.py show` | 查看當前 repo 設定 | 使用者問「現在設定是什麼」 |
| `python manage_reviewers.py set` | 從專案成員選取預設 reviewers | 使用者要「設定/更新預設」 |
| `python manage_reviewers.py mode` | 切換模式 (default/ask/none) | 使用者要「取消預設」或「改成每次問」 |
| `python manage_reviewers.py clear` | 移除此 repo 的所有設定 | 使用者要「清除設定」 |
| `python manage_reviewers.py list` | 列出所有已設定的 repo | 使用者問「哪些 repo 有設定」 |

### Agent 執行規則

1. 用 `glob` 找到 `manage_reviewers.py` 的實際路徑後執行
2. `set` 指令需要 `GL_TOKEN`，若未設定先跑 `check_env.py`
3. 腳本互動提示（成員列表、模式選擇）同樣透過 `ask_user` 轉接給使用者
4. 執行完畢後告知使用者結果（設定已儲存 / 已清除等）

## What the Script Does

1. 驗證 GL_TOKEN（缺少則印出建立教學並結束）
2. 偵測 `origin` / `upstream` remote，決定 push 目標與 MR 來源/目標 repo
3. 單次輸入詢問目標 branch：直接輸入分支名稱或關鍵字搜尋
4. 決定 MR 標題：fetch remote target branch，比對 commit 數量；多 commit 時提示使用者確認
5. `git push <remote> <current-branch>`
6. 處理 Reviewer（依 registry 設定）
7. `POST /api/v4/projects/{id}/merge_requests`（Private-Token auth）
8. 如有 reviewer，`PUT /api/v4/projects/{id}/merge_requests/{mr_iid}` 更新 reviewer_ids
9. 印出 MR 編號與 URL

## Git Remote Requirements

| Remote | 用途 |
|--------|------|
| `origin` | 個人 fork（來源） |
| `upstream` | 主線 repo（MR 目標） |

兩者都有時走 fork → upstream 架構；只有其中一個時在該 remote 內建立 MR。

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `GL_TOKEN is not set` | 環境變數未設定 | 依 Prerequisites 步驟建立並設定後重啟 terminal |
| `HTTP 401` | Token 無效或已過期 | 重新建立 Token |
| `HTTP 403` | Token scope 不足 | 確認建立 Token 時已勾選 `api` scope |
| `HTTP 409` | MR 已存在 | 檢查現有 MR |
| `git push 失敗` | SSH key 或 remote URL 問題 | 確認 SSH key 設定與 remote URL |
