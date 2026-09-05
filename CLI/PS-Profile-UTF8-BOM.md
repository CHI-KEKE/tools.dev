# PowerShell Profile 中文亂碼 — UTF-8 BOM 問題釐清

## 問題描述

啟動 PowerShell 5 時出現以下錯誤：

```
At Microsoft.PowerShell_profile.ps1:388 char:18
+     Write-Host "[Step 1] Checkout '$Source' ..." -ForegroundColor Cyan
+                  ~
Array index expression is missing or not valid.
...
Missing closing '}' in statement block or type definition.
```

---

## 根本原因

### 編碼基礎

| 編碼 | 說明 |
|------|------|
| UTF-8 | 現代通用編碼，英文 1 byte，中文 3 bytes |
| ANSI (Windows-1252) | 舊式 Windows 編碼，只支援英文與西歐字元，每字 1 byte |
| BOM（Byte Order Mark） | 放在檔案最開頭的 3 bytes（`EF BB BF`），告訴讀取程式「這是 UTF-8」 |

### PS5 與 PS7 的差異

| 程式 | 遇到無 BOM 的檔案 |
|------|------------------|
| **PS7** | 預設當 UTF-8 讀 ✅ |
| **PS5** | 預設當 ANSI 讀 ❌（若檔案含中文則出錯） |

### 為什麼以前沒問題

Profile 中的舊函式（`gup`、`ng`、`gmerge`）的 Write-Host 訊息**全是英文**。  
英文字元在 UTF-8 和 ANSI 裡的 bytes 完全相同，所以 PS5 用 ANSI 讀也讀得出來。

### 為什麼加了 `gmergev2` 後才爆發

`gmergev2` 的函式本體內含中文字串：

```powershell
Write-Host "  gmergev2 執行計畫" -ForegroundColor Yellow
$confirm = Read-Host "確認執行？(Y/N)"
Write-Host "[ABORT] 已取消。" -ForegroundColor Yellow
```

這些中文字的 UTF-8 bytes 被 PS5 拆解成多個 ANSI 亂碼字，  
夾在字串中間，把 `"` 引號的邊界搞亂，parser 就崩潰。

---

## 問題鏈

```
Profile 檔案 = UTF-8 without BOM
    ↓
PS5 沒看到 BOM，假設是 ANSI
    ↓
"確" 的 UTF-8 bytes E7 A2 BA → 被拆成 3 個亂碼字
    ↓
字串邊界錯亂，" 引號對不上
    ↓
Parser 報錯：Array index expression missing、Missing closing '}'
```

---

## 修復方式

為 PS5 profile 加上 UTF-8 BOM：

```powershell
$path = "C:\Users\Allen Lin\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$bytes = [System.IO.File]::ReadAllBytes($path)
if (-not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) {
    [System.IO.File]::WriteAllBytes($path, ([byte[]]@(0xEF, 0xBB, 0xBF) + $bytes))
    Write-Host "UTF-8 BOM added"
}
```

加上 BOM 後，PS5 正確識別 UTF-8，PS7 也完全相容。

---

## 預防措施

每次用 `add-ps-command` skill 新增**含中文的函式**後，執行上方腳本確認 BOM 存在。  
（已寫入 `add-ps-command` skill 的新增流程規範）

---

## 相關檔案

| 檔案 | 說明 |
|------|------|
| `C:\Users\Allen Lin\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` | PS5 profile（已修復，含 BOM） |
| `C:\Users\Allen Lin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | PS7 profile |
| `C:\Users\Allen Lin\.copilot\skills\add-ps-command\SKILL.md` | 新增指令的規範（已更新） |
