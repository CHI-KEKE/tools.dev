# common-bitbucket-pr-reviewer

自動對指定的 Bitbucket PR 新增預設 Reviewer。

---

## 前置準備

### 1. 申請 Bitbucket API Token

> ⚠️ Bitbucket 自 2025 年 9 月起停止新增 App Password，需改用 API Token。

1. 登入 Bitbucket，點選右上角頭像 → **Personal settings**
2. 左側選單選擇 **API tokens**
3. 點擊 **Create API token**
4. 填入名稱（例如：`copilot-reviewer`）
5. 勾選以下權限：
   - ☑ **Pull requests: Read**（查詢 PR 資訊 / reviewer UUID）
   - ☑ **Pull requests: Write**（新增 reviewer）
6. 點擊 **Create**，**立即複製 token**（只顯示一次）

---

### 2. 建立設定檔

在以下路徑建立 `bitbucket.json`：

- **Windows**：`%USERPROFILE%\.copilot\bitbucket.json`
- **macOS / Linux**：`~/.copilot/bitbucket.json`

內容如下：

```json
{
  "email": "your@email.com",
  "api_token": "your_api_token",
  "default_reviewers": "",
  "reviewer_map": {}
}
```

| 欄位 | 說明 |
|---|---|
| `email` | 帳號 Email，用於 Basic Auth fallback |
| `api_token` | 步驟 1 申請的 API Token |
| `default_reviewers` | 預設要加入的 reviewer，以逗號分隔（填 nickname） |
| `reviewer_map` | nickname → UUID 對照表 |

> **Auth 策略**：預設使用 Bearer Token；若某個 repo 回傳 401，自動 fallback 到 Basic Auth（`email:api_token`）。

---

### 3. 建立 Reviewer Map

Reviewer Map 用來將好記的 nickname 對應到 Bitbucket UUID，避免直接管理難以辨識的 UUID 字串。

#### 方法一：從現有 PR 批次取得（推薦）

對已有正確 reviewer 的 PR，可一次列出所有人的 UUID：

```powershell
$cfg     = Get-Content "$env:USERPROFILE\.copilot\bitbucket.json" -Raw | ConvertFrom-Json
curl -s -H "Authorization: Bearer $($cfg.api_token)" `
  "https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}/pullrequests/{id}?fields=reviewers" |
  python -c "import sys,json; pr=json.load(sys.stdin); [print(r['uuid'],'  ',r.get('display_name','')) for r in pr.get('reviewers',[])]"
```

輸出範例：

```
{aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa}   Alice
{bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb}   Bob
```

取得後，將結果填入 `reviewer_map` 並設定好記的 nickname。

也可以直接請 Copilot 操作：

```
請幫我從這個 PR 的 reviewer 建立 reviewer map：
https://bitbucket.org/{workspace}/{repo}/pull-requests/{id}
```

Copilot 會自動查詢並將結果寫入 `bitbucket.json` 的 `reviewer_map`。

#### 方法二：手動查詢單一使用者

若要查詢特定人員的 UUID：

```powershell
$cfg     = Get-Content "$env:USERPROFILE\.copilot\bitbucket.json" -Raw | ConvertFrom-Json
$headers = @{ "Authorization" = "Bearer $($cfg.api_token)" }
Invoke-RestMethod -Uri "https://api.bitbucket.org/2.0/users/TARGET_NICKNAME" -Headers $headers |
    Select-Object display_name, nickname, uuid
```

將查詢結果手動加入 `reviewer_map`：

```json
{
  "reviewer_map": {
    "alice": "{aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa}",
    "bob":   "{bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb}"
  }
}
```

---

### 4. 設定預設 Reviewer

在 `bitbucket.json` 的 `default_reviewers` 填入要自動加入的人員 nickname（需已存在於 `reviewer_map`）：

```json
{
  "default_reviewers": "alice,bob"
}
```

---

## 使用方式

設定完成後，在 Copilot CLI 貼上 PR URL 並說：

```
幫我加 reviewer
https://bitbucket.org/{workspace}/{repo}/pull-requests/{id}
```

Copilot 會自動：
1. 讀取 `bitbucket.json` 的設定與對照表
2. 將 `default_reviewers` 的人員解析為 UUID
3. 保留 PR 原有的 reviewer，僅新增缺少的人
4. 回報新增結果

---

## 設定範例

完整的 `bitbucket.json`：

```json
{
  "email": "your@email.com",
  "api_token": "ATATT3x...",
  "default_reviewers": "alice,bob",
  "reviewer_map": {
    "alice": "{aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa}",
    "bob":   "{bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb}"
  }
}
```

---

## 錯誤排查

| 錯誤訊息 | 原因 | 解決方式 |
|---|---|---|
| `Token is invalid, expired, or not supported` | Token 錯誤或已過期 | 重新產生 API Token 並更新設定檔 |
| `credentials lack one or more required privilege scopes` | Token 缺少權限 | 重新建立 Token 並勾選 Pull requests: Read / Write |
| `404 Not Found` | PR URL 錯誤 | 確認 URL 格式與存取權限 |
| reviewer 無效 | UUID 不正確 | 確認 reviewer_map 的 UUID，或重新查詢 |
