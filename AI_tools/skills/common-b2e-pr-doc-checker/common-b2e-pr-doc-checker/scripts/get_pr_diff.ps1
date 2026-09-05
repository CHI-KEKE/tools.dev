<#
.SYNOPSIS
    取得 PR branch 相對於 base branch 的 git diff，回傳結構化異動清單。

.DESCRIPTION
    - 自動偵測 base branch（origin/main → origin/master → upstream tracking）
    - 偵測 PR 平台（Bitbucket / GitLab / Unknown）
    - 分離 /.doc/ 文件異動 與 程式碼異動
    - 回傳 PSCustomObject 供 Stage 1 使用

.PARAMETER BaseBranch
    若提供，強制使用此值作為 base branch（跳過自動偵測）

.OUTPUTS
    PSCustomObject with:
      BaseBranch   : string
      Platform     : string  ('bitbucket' | 'gitlab' | 'unknown')
      ChangedFiles : string[]
      DocFiles     : string[]  (/.doc/ 底下的異動)
      CodeFiles    : string[]  (排除 /.doc/ 後的程式碼異動)
      DiffContent  : string   (完整 diff 文字)
#>
param(
    [string]$BaseBranch = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── 1. 偵測平台 ──────────────────────────────────────────────────
$remoteUrl = git remote -v 2>&1 | Select-Object -First 1
$platform = "unknown"
if ($remoteUrl -match "bitbucket") { $platform = "bitbucket" }
elseif ($remoteUrl -match "gitlab")    { $platform = "gitlab" }

# ── 2. 偵測 base branch ──────────────────────────────────────────
if (-not $BaseBranch) {
    $candidates = @("origin/main", "origin/master")
    foreach ($candidate in $candidates) {
        $exists = git rev-parse --verify $candidate 2>&1
        if ($LASTEXITCODE -eq 0) {
            $BaseBranch = $candidate
            break
        }
    }

    # fallback: upstream tracking branch
    if (-not $BaseBranch) {
        $upstream = git rev-parse --abbrev-ref "@{upstream}" 2>&1
        if ($LASTEXITCODE -eq 0 -and $upstream) {
            $BaseBranch = $upstream
        }
    }

    if (-not $BaseBranch) {
        Write-Error "無法偵測 base branch。請以 -BaseBranch 參數指定，例如：-BaseBranch 'origin/develop'"
        exit 1
    }
}

# ── 3. 取得異動檔案清單 ───────────────────────────────────────────
$changedFiles = git diff --name-only "$BaseBranch...HEAD" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "git diff 執行失敗：$changedFiles"
    exit 1
}

$changedFilesArray = $changedFiles | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim() }

# ── 4. 分類：/.doc/ vs 程式碼 ────────────────────────────────────
$docFiles  = $changedFilesArray | Where-Object { $_ -match "^\.doc[/\\]" -or $_ -match "^\.doc$" }
$codeFiles = $changedFilesArray | Where-Object { $_ -notmatch "^\.doc[/\\]" -and $_ -ne ".doc" }

# ── 5. 取得完整 diff 內容（供 AI 語意分析用）─────────────────────
$diffContent = git diff "$BaseBranch...HEAD" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "git diff content 取得失敗，僅回傳檔案清單。"
    $diffContent = ""
}

# ── 6. 回傳結構化結果 ────────────────────────────────────────────
return [PSCustomObject]@{
    BaseBranch   = $BaseBranch
    Platform     = $platform
    ChangedFiles = $changedFilesArray
    DocFiles     = @($docFiles)
    CodeFiles    = @($codeFiles)
    DiffContent  = $diffContent
}
