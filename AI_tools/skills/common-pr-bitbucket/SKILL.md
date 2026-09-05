---
name: pr-bitbucket
description: >
  Push the current feature branch to origin (personal fork) and create a Pull Request
  to the upstream Bitbucket repository via REST API. Use when the user wants to open a PR,
  push and create PR, or submit their changes for review on Bitbucket. Triggers on phrases
  like "開PR", "發PR", "push and PR", "create pull request", "submit PR", "建立PR".
  Requires BB_TOKEN (Bitbucket API Token with scopes: Repositories:Read + Pull requests:Write),
  BB_USERNAME (Atlassian account email), and optionally BB_PROJECT_KEY (Bitbucket project key for default reviewers) environment variables.
  Run check_env.py first to validate prerequisites, then create_pr.py to push and open the PR interactively.
---

# pr-bitbucket

Push feature branch to origin fork and open a cross-repo PR to upstream — all via CLI.

## ⚠️ Agent Rules (Non-Negotiable)

> These rules govern how the AI agent must behave when running this skill.

1. **NEVER ask the user to provide BB_TOKEN or BB_USERNAME in conversation.** Tokens and emails are sensitive — requesting them verbally is a security risk.
2. If `check_env.py` reports `BB_TOKEN` or `BB_USERNAME` is not set, **stop immediately** and show the user the setup instructions below. Do NOT attempt workarounds (e.g., `--token` flag, `Read-Host`, interactive prompts).
3. After showing setup instructions, tell the user to **restart their terminal** and invoke the skill again.

## Prerequisites

### 1. Create a Bitbucket API Token (with scopes)

> ⚠️ You must use **"Create API token with scopes"** and select **Bitbucket** as the app.  
> A plain Atlassian API token (without scopes / for Jira/Confluence) will **not** work with Bitbucket REST API.

1. Go to: **https://id.atlassian.com/manage-profile/security/api-tokens**
2. Click **"Create API token with scopes"** (NOT the plain "Create API token")
3. Enter a name and expiry date → **Next**
4. Select App: **[Bitbucket]** → **Next**
5. Select scopes:
   - `read:project:bitbucket`
   - `read:pullrequest:bitbucket`
   - `read:repository:bitbucket`
   - `write:pullrequest:bitbucket`
6. Click **Create token** → copy the generated token

### 2. Set environment variables (persistent, user-level)

Both `BB_TOKEN` and `BB_USERNAME` (your Atlassian account email) are required for Basic Auth.  
`BB_PROJECT_KEY` (your Bitbucket project key, e.g. `YOUR_PROJECT_KEY`) is optional but required for default reviewers.

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("BB_TOKEN", "your-api-token-here", "User")
[System.Environment]::SetEnvironmentVariable("BB_USERNAME", "your@email.com", "User")
[System.Environment]::SetEnvironmentVariable("BB_PROJECT_KEY", "YOUR_PROJECT_KEY", "User")
# Restart your terminal / IDE after running this
```

**macOS / Linux (bash):**
```bash
echo 'export BB_TOKEN="your-api-token-here"' >> ~/.bashrc
echo 'export BB_USERNAME="your@email.com"' >> ~/.bashrc
echo 'export BB_PROJECT_KEY="YOUR_PROJECT_KEY"' >> ~/.bashrc
source ~/.bashrc
```

**macOS / Linux (zsh):**
```bash
echo 'export BB_TOKEN="your-api-token-here"' >> ~/.zshrc
echo 'export BB_USERNAME="your@email.com"' >> ~/.zshrc
echo 'export BB_PROJECT_KEY="YOUR_PROJECT_KEY"' >> ~/.zshrc
source ~/.zshrc
```

> ⚠️ Never hardcode or paste the token into conversation. Always set it as an environment variable.

## Authentication

This skill uses **HTTP Basic Auth**: `Authorization: Basic base64(BB_USERNAME:BB_TOKEN)`

This is the required authentication method for Bitbucket REST API when using personal API tokens.

## Usage

```bash
# Step 1: 環境檢查（建議每次執行前先跑）
python check_env.py

# Step 2: 建立 PR
python create_pr.py
```

**No pip install required** — uses Python standard library only (`urllib`, `subprocess`, `json`, `base64`).

## Behaviour

| 項目 | 處理方式 |
|------|---------|
| **Token / Username 未設定** | 印出 Bitbucket 建立 Token 步驟與各平台**使用者層級**持久設定指令後結束 |
| **origin + upstream** | push 至 origin，PR 指向 upstream |
| **只有 origin** | push 至 origin，PR 在 origin 內建立 |
| **只有 upstream** | push 至 upstream，PR 在 upstream 內建立 |
| **目標 branch** | 單次輸入：直接輸入分支名稱或關鍵字搜尋 |
| **輸入 QA{n}** | 呼叫 Bitbucket API 搜尋包含該 tag 的分支，列出後確認 |
| **PR 標題** | 自動取最近一次 commit subject，不詢問使用者 |
| **Default Reviewers** | 呼叫 `GET /workspaces/{workspace}/projects/{BB_PROJECT_KEY}/default-reviewers` API 取得，加入 PR payload；未設定 `BB_PROJECT_KEY` 時略過 |

### 互動流程範例

```
==================================================
Select target branch:
  develop  (press Enter for default)
  (or type a keyword to search remote branches)
==================================================

> QA7

Searching for remote branches containing 'QA7'...

Found 2 matching branch(es):
  1  feature/VSTS000000-QA7-OMO-Develop
  2  feature/VSTS591380-QA7-hotfix

Enter number: 1
```

### Agent 互動規則

當腳本顯示 `Select target branch:` 提示時，agent **必須**使用 `ask_user` 工具，設定如下：
- `choices: ["develop"]` — 顯示 develop 作為可點選選項
- `allow_freeform: true` — 同時允許使用者直接輸入分支名稱

使用者點選 "develop" 時，agent 送出 `{enter}`；使用者輸入自訂名稱時，agent 直接送出該名稱。**不需兩次詢問。**

## What the Script Does

1. 驗證 BB_TOKEN 與 BB_USERNAME（缺少則印出建立教學並結束）
2. 偵測 `origin` / `upstream` remote，決定 push 目標與 PR 來源/目標 repo
3. 單次輸入詢問目標 branch：直接輸入分支名稱；輸入 QA{n} 時自動搜尋遠端分支確認
4. `git push <remote> <current-branch>`
5. 呼叫 `GET /workspaces/{workspace}/projects/{BB_PROJECT_KEY}/default-reviewers` 取得 Default Reviewers（未設定 `BB_PROJECT_KEY` 時略過）
6. `POST /2.0/repositories/{dest}/pullrequests`（Basic Auth），PR 標題自動取最近 commit subject，自動帶入 Default Reviewers
7. 印出 PR 編號與 URL

## Git Remote Requirements

| Remote | 用途 |
|--------|------|
| `origin` | 個人 fork（來源） |
| `upstream` | 主線 repo（PR 目標） |

兩者都有時走 fork → upstream 架構；只有其中一個時在該 remote 內建立 PR。

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `BB_TOKEN is not set` | 環境變數未設定 | 依 Prerequisites 步驟建立並設定後重啟 terminal |
| `BB_USERNAME is not set` | 環境變數未設定 | `[System.Environment]::SetEnvironmentVariable("BB_USERNAME","your@email.com","User")` 後重啟 terminal |
| `BB_PROJECT_KEY is not set` | 環境變數未設定 | `[System.Environment]::SetEnvironmentVariable("BB_PROJECT_KEY","YOUR_KEY","User")` 後重啟 terminal；不設定則略過 Default Reviewers |
| `HTTP 401` | Token 無效、過期，或建立時未選 Bitbucket app | 重新建立 Token，確認步驟 4 選擇 **Bitbucket** |
| `HTTP 403` | Token scope 不足 | 確認建立 Token 時已勾選 `read:project:bitbucket`、`read:pullrequest:bitbucket`、`read:repository:bitbucket`、`write:pullrequest:bitbucket` |
| `HTTP 422` | PR 已存在或 branch 未 push | 確認現有 PR；重新 push |
| `git push 失敗` | SSH key 或 remote URL 問題 | 確認 SSH key 設定與 remote URL |
