# New-GitBranch (ng) — PowerShell Git 工具

## 功能說明

在任意 git repository 目錄下，輸入 origin branch 名稱與新 branch 名稱，自動依序執行以下三步：

1. `git checkout <originBranch>` — 切換到來源分支
2. `git pull upstream <originBranch>` — 從 upstream 拉取最新版本
3. `git checkout -b <newBranch>` — 建立並切換到新分支

---

## 使用方式

```powershell
ng <originBranch> <newBranch>
```

### 範例

```powershell
ng master feature/my-new-feature
```

### 執行結果

```
▶ Step 1: Checkout 'master' ...
▶ Step 2: Pull latest from upstream/master ...
▶ Step 3: Create and checkout new branch 'feature/my-new-feature' ...

✅ Done! Branch 'feature/my-new-feature' created from 'master' (latest upstream)
```

---

## 實作方式

### 適用環境

| 項目 | 版本 |
|------|------|
| 作業系統 | Windows |
| PowerShell | 5.1 (主要使用) / 7.5.4 |
| Git | 2.51.0 |

### 安裝位置

函式寫入 PowerShell Profile，每次開啟 PowerShell 時自動載入，無需額外安裝。函式名稱為 `ng`。

| PowerShell 版本 | Profile 路徑 |
|----------------|-------------|
| Windows PowerShell 5.1 | `C:\Users\Allen Lin\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| PowerShell 7 | `C:\Users\Allen Lin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |

### 函式內容

```powershell
function ng {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Origin,

        [Parameter(Mandatory, Position = 1)]
        [string]$New
    )

    git rev-parse --is-inside-work-tree 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Not a git repository. Please cd into a git repo first." -ForegroundColor Red
        return
    }

    Write-Host "▶ Step 1: Checkout '$Origin' ..." -ForegroundColor Cyan
    git checkout $Origin
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to checkout branch '$Origin'" -ForegroundColor Red
        return
    }

    Write-Host "▶ Step 2: Pull latest from upstream/$Origin ..." -ForegroundColor Cyan
    git pull upstream $Origin
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to pull from upstream/$Origin" -ForegroundColor Red
        return
    }

    Write-Host "▶ Step 3: Create and checkout new branch '$New' ..." -ForegroundColor Cyan
    git checkout -b $New
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create branch '$New' (it may already exist)" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "✅ Done! Branch '$New' created from '$Origin' (latest upstream)" -ForegroundColor Green
}
```

---

## 錯誤處理

| 情況 | 行為 |
|------|------|
| 不在 git repo 目錄內 | 顯示錯誤並中止 |
| origin branch 不存在 | 顯示錯誤並中止，不繼續執行 |
| upstream pull 失敗 | 顯示錯誤並中止，不繼續執行 |
| new branch 已存在 | git 報錯並中止 |

---

## 如何驗證安裝

在 PowerShell 視窗執行：

```powershell
# 重新載入 profile（不需重開視窗）
. $PROFILE

# 確認函式存在
Get-Command ng
```

## 如何查看 Profile 內容

```powershell
notepad $PROFILE
# 或
Get-Content $PROFILE
```
