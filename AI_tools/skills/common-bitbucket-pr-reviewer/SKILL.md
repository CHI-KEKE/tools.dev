---
name: common-bitbucket-pr-reviewer
description: >
  對指定 Bitbucket PR URL 自動新增預設 Reviewer。當使用者貼上 Bitbucket PR URL
  並要求加上 reviewer、指派審核人員、或說「幫我加 reviewer」、「加審核者」、
  「新增 reviewer」時，請務必使用此 skill。
  同樣適用於使用者貼上 bitbucket.org 連結後說「review 這個」的情況。
  透過 Bitbucket Cloud REST API 操作，設定存放於 $env:USERPROFILE\.copilot\bitbucket.json。
---

# Bitbucket PR Reviewer

自動對指定的 Bitbucket PR 新增預設 Reviewer。

## 設定檔

路徑：`$env:USERPROFILE\.copilot\bitbucket.json`

```json
{
  "email": "your@email.com",
  "api_token": "your_api_token",
  "default_reviewers": "knight,alice",
  "reviewer_map": {
    "knight": "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}",
    "alice":  "{yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy}"
  }
}
```

> `reviewer_map` 與原 `~/.copilot/bitbucket-reviewers.json` 合併，集中在同一檔管理。
>
> `email` 用於 Basic Auth fallback：部分 repo 不支援 Bearer Token，會自動改用 `email:api_token` 進行 Basic Auth。

## 執行步驟

**Step 1**：從使用者訊息中擷取 PR URL

格式為：`https://bitbucket.org/{workspace}/{repo-slug}/pull-requests/{id}`

**Step 2**：執行以下 PowerShell 指令

```powershell
$prUrl = "<使用者提供的 PR URL>"

# 讀取設定檔
$cfgPath = "$env:USERPROFILE\.copilot\bitbucket.json"
if (-not (Test-Path $cfgPath)) { throw "找不到設定檔：$cfgPath" }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json

$email            = $cfg.email
$token            = $cfg.api_token
$defaultReviewers = $cfg.default_reviewers
$reviewerMap      = $cfg.reviewer_map

# 驗證必要欄位
$missing = @()
if (-not $token)            { $missing += "api_token" }
if (-not $defaultReviewers) { $missing += "default_reviewers" }
if ($missing.Count -gt 0) { throw "設定檔缺少欄位：$($missing -join ', ')" }

# 解析 URL
$uri       = [System.Uri]$prUrl
$seg       = $uri.Segments
$workspace = $seg[1].TrimEnd('/')
$repoSlug  = $seg[2].TrimEnd('/')
$prId      = $seg[4].TrimEnd('/')

$base = "https://api.bitbucket.org/2.0"

# 呼叫 API：Bearer 優先，若 401 且有 email 則 fallback 到 Basic Auth
function Invoke-BbApi {
    param($Url, $Method = 'Get', $Body)
    $bh = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
    try {
        if ($Body) { return Invoke-RestMethod -Uri $Url -Headers $bh -Method $Method -Body $Body }
        else       { return Invoke-RestMethod -Uri $Url -Headers $bh -Method $Method }
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 401 -and $email) {
            $cred   = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${email}:${token}"))
            $basicH = @{ "Authorization" = "Basic $cred"; "Content-Type" = "application/json" }
            if ($Body) { return Invoke-RestMethod -Uri $Url -Headers $basicH -Method $Method -Body $Body }
            else       { return Invoke-RestMethod -Uri $Url -Headers $basicH -Method $Method }
        }
        throw
    }
}

# 將名稱解析為 UUID（名稱不存在時視為直接輸入 UUID）
$targetUuids = $defaultReviewers -split ',' |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    ForEach-Object {
        $name = $_
        $mapped = $reviewerMap.PSObject.Properties[$name] | Select-Object -ExpandProperty Value
        if ($mapped) { $mapped } else { $name }
    }

# 取得現有 reviewers（PUT 會整個覆蓋清單，必須保留原有的人）
$pr        = Invoke-BbApi "$base/repositories/$workspace/$repoSlug/pullrequests/$prId"
$reviewers = @($pr.reviewers | ForEach-Object { @{ uuid = $_.uuid } })

$added = @()
foreach ($uuid in $targetUuids) {
    if (-not ($reviewers | Where-Object { $_.uuid -eq $uuid })) {
        $reviewers += @{ uuid = $uuid }
        $added += $uuid
    }
}

if ($added.Count -eq 0) {
    Write-Host "⚠️  所有 reviewer 皆已在清單中，無需更新。"
} else {
    # 必須保留 title / description / destination，否則 PUT 會將 destination branch 重置為 repo 預設分支
    $body = @{
        title       = $pr.title
        description = $pr.description
        destination = @{ branch = @{ name = $pr.destination.branch.name } }
        reviewers   = $reviewers
    } | ConvertTo-Json -Depth 5
    try {
        Invoke-BbApi "$base/repositories/$workspace/$repoSlug/pullrequests/$prId" -Method Put -Body $body | Out-Null
        Write-Host "✅ 已新增 $($added.Count) 位 reviewer 至 PR #${prId}：$($added -join ', ')"
    } catch {
        $errMsg = if ($_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.ToString() }
        if ($errMsg -match "branch not found") {
            Write-Host "⚠️ PR #${prId} 的 destination branch '$($pr.destination.branch.name)' 為尚未建立的新分支，目前不支援此情境，請至 Bitbucket 手動新增 reviewer。"
        } else {
            throw
        }
    }
}
```

## 回應格式

執行結果向使用者清楚回報：

- ✅ **成功**：已新增的 reviewer 名稱（或 UUID）及 PR 連結
- ⚠️ **跳過**：reviewer 已在清單中，不需要更新
- ❌ **失敗**：錯誤原因與排查建議

## 錯誤排查

| 錯誤 | 可能原因 |
|---|---|
| 401 Unauthorized | `api_token` 錯誤或已過期 |
| 404 Not Found | PR URL 錯誤，或 token 無法存取此 repo |
| reviewer 無效 | UUID 不存在，或此人不屬於該 workspace |

**查詢使用者 UUID（新增至 reviewer_map 前）：**

```powershell
$cfg     = Get-Content "$env:USERPROFILE\.copilot\bitbucket.json" -Raw | ConvertFrom-Json
$headers = @{ "Authorization" = "Bearer $($cfg.api_token)" }
Invoke-RestMethod -Uri "https://api.bitbucket.org/2.0/users/TARGET_USERNAME" -Headers $headers |
    Select-Object display_name, uuid, account_id
```

> 若回傳 401，改用 Basic Auth：
> ```powershell
> $cred    = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($cfg.email):$($cfg.api_token)"))
> $headers = @{ "Authorization" = "Basic $cred" }
> ```

