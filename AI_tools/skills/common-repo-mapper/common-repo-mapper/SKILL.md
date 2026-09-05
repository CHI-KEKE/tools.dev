---
name: common-repo-mapper
description: >
  掃描指定的資料夾路徑，列出各路徑下的子目錄（即專案），產生 RepositoryMapping.md 對照表。
  當使用者說「掃描專案資料夾」、「建立 RepositoryMapping」、「更新 repo 對照表」、
  「重新掃描路徑」、「掃描這些路徑」、「列出專案目錄」、「repo 對照表」、
  「RepositoryMapping」時，立即使用此 skill。
---

# common-repo-mapper

掃描指定路徑下的子目錄，產生 `RepositoryMapping.md` 對照表。

## 執行步驟

**Step 1**：確認掃描路徑與輸出位置

- 從使用者訊息取得要掃描的根目錄清單（可多個）
- 若未指定輸出路徑，預設輸出至目前工作目錄
- 若使用者指定覆蓋現有的 `RepositoryMapping.md`，直接更新

**Step 2**：執行 PowerShell 掃描

```powershell
# 由使用者指定的路徑清單
$scanPaths = @(
    "C:\91APP",
    "D:\Code\Service",
    "D:\Code\Console",
    "D:\Code\Package",
    "D:\Code\Other"
)

$outputPath = "RepositoryMapping.md"  # 依使用者指定調整

$sections = @()

foreach ($root in $scanPaths) {
    if (-not (Test-Path $root)) {
        Write-Host "⚠️  路徑不存在，略過：$root"
        continue
    }

    $dirs = Get-ChildItem -Path $root -Directory |
        Where-Object {
            $_.Name -notmatch '^\.' -and        # 排除隱藏目錄（.nuget 等）
            $_.Name -notmatch '-worktrees$'      # 排除 worktree 目錄
        } |
        Sort-Object Name

    $rows = $dirs | ForEach-Object {
        "| $($_.Name) | ``$root\$($_.Name)`` |"
    }

    $section = @"
## $root

| 專案名稱 | 路徑 |
|---|---|
$($rows -join "`n")
"@
    $sections += $section
}

$content = ($sections -join "`n`n---`n`n") + "`n`n---`n"
$content | Set-Content -Path $outputPath -Encoding UTF8
Write-Host "✅ 已產生：$outputPath"
```

**Step 3**：向使用者報告結果

執行後，整理並回報：
- 各路徑掃描到的專案數量
- 輸出檔案的完整路徑
- 若有路徑不存在，列出警告

**Step 4**：詢問是否加入 copilot-instructions.md

產生完成後，使用 ask_user 工具詢問：

> 是否要將 RepositoryMapping.md 加入 copilot-instructions.md，讓每次 session 自動載入？

若使用者同意，執行以下 PowerShell：

```powershell
$instructionsPath = "$env:USERPROFILE\.copilot\copilot-instructions.md"
$outputFullPath   = (Resolve-Path $outputPath).Path   # 取得輸出檔的完整路徑

$newLine = "- 每次 session 開始時，執行 /add-context `"$outputFullPath`" 將該檔案加入"

if (-not (Test-Path $instructionsPath)) {
    Write-Host "⚠️  找不到 copilot-instructions.md：$instructionsPath"
    exit
}

$content = Get-Content $instructionsPath -Raw -Encoding UTF8

# 若已存在相同路徑的指令，不重複加入
if ($content -match [regex]::Escape($outputFullPath)) {
    Write-Host "⚠️  copilot-instructions.md 已包含此路徑，略過。"
} else {
    # 加在檔案結尾（保留換行）
    if (-not $content.EndsWith("`n")) { $content += "`n" }
    $content += "$newLine`n"
    $content | Set-Content $instructionsPath -Encoding UTF8 -NoNewline
    Write-Host "✅ 已加入 copilot-instructions.md"
    Write-Host "   $newLine"
}
```

## 注意事項

- 以 `.` 開頭的目錄（如 `.nuget`、`.git`）一律排除
- 以 `-worktrees` 結尾的目錄（git worktree）一律排除
- 若指定路徑不存在，不中斷整體流程，跳過並警告
- 輸出檔案格式為 UTF-8 無 BOM 的 Markdown 表格
- copilot-instructions.md 寫入時使用完整解析路徑（不含 `$env` 變數），skill 原始碼中不寫死使用者名稱
