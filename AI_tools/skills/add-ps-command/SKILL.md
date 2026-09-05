---
name: add-ps-command
description: 新增 PowerShell 自訂指令到 Allen 的 PS profile。當使用者要求「新增一個 ps 指令」、「幫我包成 powershell 指令」、「加到 profile」、「像 gup 那樣的指令」時使用此 skill。會同時更新 PS5 與 PS7 兩個 profile，確保相容性，並提醒使用者 reload 當下視窗。
---

# Add PS Command

## Profile 路徑（兩個都要更新）

| 版本 | 路徑 |
|------|------|
| PS7 | `C:\Users\Allen Lin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| PS5 | `C:\Users\Allen Lin\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |

## Function 撰寫規範

### 樣板格式（對齊現有 gup / ng / gmerge 風格）

```powershell
# ============================================================
# <funcName>: <一行說明>
# Usage: <funcName> <params>
# ============================================================
function <funcName> {
    param(
        [Parameter(Mandatory = $true, Position = 0)]   # 必須用 Mandatory = $true，不可省略（PS5 不支援簡寫）
        [string]$ParamName
    )

    Write-Host "[Step 1] ..." -ForegroundColor Cyan
    <command>
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] ..." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "[DONE] ..." -ForegroundColor Green
}
```

### PS5 / PS7 相容性規則

| 不可用（PS5 不支援） | 改用 |
|----------------------|------|
| `[Parameter(Mandatory)]` | `[Parameter(Mandatory = $true)]` |
| `&&` 串接指令 | `if ($LASTEXITCODE -ne 0)` 逐步檢查 |
| `??=` null coalescing | 傳統 `if ($x -eq $null)` |

## 新增流程

1. 讀取現有 profile 尾端，確認最後一個 function 結尾位置
2. 同時編輯 PS5 + PS7 兩個 profile，內容一致
3. Optional parameter 不加 Mandatory，改用 `[Parameter(Position = 0)]` + 預設值
4. **新增後確認 UTF-8 BOM**：若函式含中文字，必須確保 PS5 profile 有 UTF-8 BOM（`EF BB BF`），否則 PS5 以 ANSI 讀取會 parse error

```powershell
# 檢查並補上 UTF-8 BOM（新增含中文的函式後執行）
$path = "C:\Users\Allen Lin\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$bytes = [System.IO.File]::ReadAllBytes($path)
if (-not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) {
    [System.IO.File]::WriteAllBytes($path, ([byte[]]@(0xEF,0xBB,0xBF) + $bytes))
    Write-Host "UTF-8 BOM added"
}
```

## 完成後必做（每次都要）

編輯完兩個 profile 後，**主動告知使用者在當下的 PowerShell 視窗執行**：

```powershell
. $PROFILE
```

若使用者同時開著 PS5 視窗，也需在那個視窗執行一次 `. $PROFILE`。

## 現有指令清單（供參考風格）

| 指令 | 用法 | 說明 |
|------|------|------|
| `refedit` | `refedit` | 開啟 shortcuts.md |
| `hd` | `hd [path]` | Hexo 一鍵部署 |
| `gcp` | `gcp [message]` | git add all → commit → push |
| `ref` | `ref [keyword]` | fzf 搜尋 shortcuts.md 並複製 |
| `cds` | `cds [keyword] [root]` | fd+fzf 搜尋檔案並 cd |
| `cdf` | `cdf [keyword] [root]` | fd+fzf 搜尋目錄並 cd |
| `es` | `es [keyword]` | 開啟 Everything 搜尋 |
| `gup` | `gup <branch>` | checkout + pull upstream |
| `ng` | `ng <originBranch> <newBranch>` | gup 後建立新 branch |
| `gmerge` | `gmerge <sourceBranch>` | gup source → 回當前 branch → merge |
