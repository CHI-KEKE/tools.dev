---
name: settings-diff-export
description: >-
  比對此專案 config 資料夾內各環境的 Settings 檔案結構差異，以 TW-QA 為 QA 基準、TW-Prod 為 Prod 基準，
  找出其他環境中「缺少的節點」與「多餘的節點」（不包含值不同），並匯出成 Excel 到使用者的下載資料夾。
  當使用者說「比對 settings」、「settings 差異」、「設定檔比對」、「config 比對」、「匯出設定差異」、
  「哪些環境 config 節點不一樣」、「settings 缺少節點」、「settings 多餘節點」時，使用此 skill。
allowed-tools:
  - run_in_terminal
  - create_file
  - create_directory
  - read_file
  - list_dir
---

# Settings 差異比對匯出指南

## 目的

比對此專案 `config` 資料夾內各環境 Settings JSON 的**結構差異**（節點存在與否），
以 `TW-QA` 為 QA 基準、`TW-Prod` 為 Prod 基準，
產出 Excel 報表（**QA** 與 **Prod** 各一個 Sheet），匯出至使用者的 `Downloads` 資料夾。

> 只比對「缺少節點」與「多餘節點」，**不**列出值不同的項目。

---

## 觸發條件

使用者說以下任一關鍵字時，立即執行本 skill：

- 比對 settings / settings 差異 / 設定檔比對
- config 比對 / config 差異
- 匯出設定差異 / 哪些環境 config 節點不一樣
- settings 缺少節點 / settings 多餘節點

---

## 執行步驟

### Step 1：確認 ImportExcel 模組

```powershell
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber
}
Import-Module ImportExcel
```

### Step 2：執行比對並匯出 Excel

將以下完整腳本在 Terminal 執行（直接 copy & run）：

```powershell
Import-Module ImportExcel

function Flatten-Json {
    param($obj, $prefix = "")
    $result = @{}
    foreach ($key in $obj.PSObject.Properties.Name) {
        $fullKey = if ($prefix) { "$prefix.$key" } else { $key }
        $val = $obj.$key
        if ($val -is [PSCustomObject]) {
            $nested = Flatten-Json $val $fullKey
            foreach ($nk in $nested.Keys) { $result[$nk] = $nested[$nk] }
        } elseif ($val -is [System.Collections.IEnumerable] -and $val -isnot [string]) {
            $result[$fullKey] = ($val | ConvertTo-Json -Compress -Depth 10)
        } else {
            $result[$fullKey] = "$val"
        }
    }
    return $result
}

$basePath   = "C:\repository\Peterji\nine1.cart\config\Cart-Service\API"
$outputPath = "$env:USERPROFILE\Downloads\nine1.cart.Settings比對.xlsx"
if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

$allQaRows   = @()
$allProdRows = @()

# ── QA ──
$twQaFile = Get-ChildItem "$basePath\QA\TW-QA" -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($twQaFile) {
    $twQaFlat  = Flatten-Json (Get-Content $twQaFile.FullName -Raw | ConvertFrom-Json)
    $qaEnvDirs = Get-ChildItem "$basePath\QA" -Directory | Where-Object { ---
name: settings-diff-export
description: >-
  比對此專案 config 資料夾內各環境的 Settings 檔案結構差異，以 TW-QA 為 QA 基準、TW-Prod 為 Prod 基準，
  找出其他環境中「缺少的節點」與「多餘的節點」（不包含值不同），並匯出成 Excel 到使用者的下載資料夾。
  當使用者說「比對 settings」、「settings 差異」、「設定檔比對」、「config 比對」、「匯出設定差異」、
  「哪些環境 config 節點不一樣」、「settings 缺少節點」、「settings 多餘節點」時，使用此 skill。
allowed-tools:
  - run_in_terminal
  - create_file
  - create_directory
  - read_file
  - list_dir
---

# Settings 差異比對匯出指南

## 目的

比對此專案 `config` 資料夾內各環境 Settings JSON 的**結構差異**（節點存在與否），
以 `TW-QA` 為 QA 基準、`TW-Prod` 為 Prod 基準，
產出 Excel 報表（**QA** 與 **Prod** 各一個 Sheet），匯出至使用者的 `Downloads` 資料夾。

> 只比對「缺少節點」與「多餘節點」，**不**列出值不同的項目。

---

## 觸發條件

使用者說以下任一關鍵字時，立即執行本 skill：

- 比對 settings / settings 差異 / 設定檔比對
- config 比對 / config 差異
- 匯出設定差異 / 哪些環境 config 節點不一樣
- settings 缺少節點 / settings 多餘節點

---

## 執行步驟

### Step 1：確認 ImportExcel 模組

```powershell
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber
}
Import-Module ImportExcel
```

### Step 2：執行比對並匯出 Excel

將以下完整腳本在 Terminal 執行（直接 copy & run）：

```powershell
##SCRIPT_PLACEHOLDER##
```

### Step 3：確認輸出

腳本執行完畢後，Excel 檔案會出現在：

```
%USERPROFILE%\Downloads\nine1.cart.Settings比對.xlsx
```

檔案包含兩個 Sheet：
| Sheet | 說明 |
|-------|------|
| **QA** | 所有 QA 環境與 TW-QA 的節點差異，第一欄為 `QA環境` |
| **Prod** | 所有 Prod 環境與 TW-Prod 的節點差異，第一欄為 `Prod環境` |

欄位：`QA環境 / Prod環境`、`類型`（缺少節點／多餘節點）、`節點路徑`、`基準值`、`環境值`

---

## 注意事項

- 比對基準為 `TW-QA` 與 `TW-Prod`，這兩個環境本身不列入比對
- 若某環境與基準**完全相同**（結構上），該環境不會出現在 Excel 中
- 若 `ImportExcel` 尚未安裝，Step 1 會自動安裝.Name -ne "TW-QA" } | Sort-Object Name
    foreach ($dir in $qaEnvDirs) {
        $envFile = Get-ChildItem $dir.FullName -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $envFile) { continue }
        $envFlat = Flatten-Json (Get-Content $envFile.FullName -Raw | ConvertFrom-Json)
        foreach ($k in ($twQaFlat.Keys | Sort-Object)) {
            if (-not $envFlat.ContainsKey($k)) {
                $allQaRows += [PSCustomObject]@{ QA環境=$dir.Name; 類型="缺少節點"; 節點路徑=$k; 基準值=$twQaFlat[$k]; 環境值="(不存在)" }
            }
        }
        foreach ($k in ($envFlat.Keys | Sort-Object)) {
            if (-not $twQaFlat.ContainsKey($k)) {
                $allQaRows += [PSCustomObject]@{ QA環境=$dir.Name; 類型="多餘節點"; 節點路徑=$k; 基準值="(不存在)"; 環境值=$envFlat[$k] }
            }
        }
    }
}

# ── Prod ──
$twProdFile = Get-ChildItem "$basePath\Prod\TW-Prod" -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($twProdFile) {
    $twProdFlat  = Flatten-Json (Get-Content $twProdFile.FullName -Raw | ConvertFrom-Json)
    $prodEnvDirs = Get-ChildItem "$basePath\Prod" -Directory | Where-Object { ---
name: settings-diff-export
description: >-
  比對此專案 config 資料夾內各環境的 Settings 檔案結構差異，以 TW-QA 為 QA 基準、TW-Prod 為 Prod 基準，
  找出其他環境中「缺少的節點」與「多餘的節點」（不包含值不同），並匯出成 Excel 到使用者的下載資料夾。
  當使用者說「比對 settings」、「settings 差異」、「設定檔比對」、「config 比對」、「匯出設定差異」、
  「哪些環境 config 節點不一樣」、「settings 缺少節點」、「settings 多餘節點」時，使用此 skill。
allowed-tools:
  - run_in_terminal
  - create_file
  - create_directory
  - read_file
  - list_dir
---

# Settings 差異比對匯出指南

## 目的

比對此專案 `config` 資料夾內各環境 Settings JSON 的**結構差異**（節點存在與否），
以 `TW-QA` 為 QA 基準、`TW-Prod` 為 Prod 基準，
產出 Excel 報表（**QA** 與 **Prod** 各一個 Sheet），匯出至使用者的 `Downloads` 資料夾。

> 只比對「缺少節點」與「多餘節點」，**不**列出值不同的項目。

---

## 觸發條件

使用者說以下任一關鍵字時，立即執行本 skill：

- 比對 settings / settings 差異 / 設定檔比對
- config 比對 / config 差異
- 匯出設定差異 / 哪些環境 config 節點不一樣
- settings 缺少節點 / settings 多餘節點

---

## 執行步驟

### Step 1：確認 ImportExcel 模組

```powershell
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber
}
Import-Module ImportExcel
```

### Step 2：執行比對並匯出 Excel

將以下完整腳本在 Terminal 執行（直接 copy & run）：

```powershell
##SCRIPT_PLACEHOLDER##
```

### Step 3：確認輸出

腳本執行完畢後，Excel 檔案會出現在：

```
%USERPROFILE%\Downloads\nine1.cart.Settings比對.xlsx
```

檔案包含兩個 Sheet：
| Sheet | 說明 |
|-------|------|
| **QA** | 所有 QA 環境與 TW-QA 的節點差異，第一欄為 `QA環境` |
| **Prod** | 所有 Prod 環境與 TW-Prod 的節點差異，第一欄為 `Prod環境` |

欄位：`QA環境 / Prod環境`、`類型`（缺少節點／多餘節點）、`節點路徑`、`基準值`、`環境值`

---

## 注意事項

- 比對基準為 `TW-QA` 與 `TW-Prod`，這兩個環境本身不列入比對
- 若某環境與基準**完全相同**（結構上），該環境不會出現在 Excel 中
- 若 `ImportExcel` 尚未安裝，Step 1 會自動安裝.Name -ne "TW-Prod" } | Sort-Object Name
    foreach ($dir in $prodEnvDirs) {
        $envFile = Get-ChildItem $dir.FullName -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $envFile) { continue }
        $envFlat = Flatten-Json (Get-Content $envFile.FullName -Raw | ConvertFrom-Json)
        foreach ($k in ($twProdFlat.Keys | Sort-Object)) {
            if (-not $envFlat.ContainsKey($k)) {
                $allProdRows += [PSCustomObject]@{ Prod環境=$dir.Name; 類型="缺少節點"; 節點路徑=$k; 基準值=$twProdFlat[$k]; 環境值="(不存在)" }
            }
        }
        foreach ($k in ($envFlat.Keys | Sort-Object)) {
            if (-not $twProdFlat.ContainsKey($k)) {
                $allProdRows += [PSCustomObject]@{ Prod環境=$dir.Name; 類型="多餘節點"; 節點路徑=$k; 基準值="(不存在)"; 環境值=$envFlat[$k] }
            }
        }
    }
}

if ($allQaRows.Count -gt 0) {
    $allQaRows | Export-Excel -Path $outputPath -WorksheetName "QA" -AutoSize -FreezeTopRow -BoldTopRow -AutoFilter -TableName "tblQA" -TableStyle Medium2
} else {
    [PSCustomObject]@{ QA環境="(無差異)"; 類型=""; 節點路徑=""; 基準值=""; 環境值="" } | Export-Excel -Path $outputPath -WorksheetName "QA" -AutoSize -FreezeTopRow -BoldTopRow
}

if ($allProdRows.Count -gt 0) {
    $allProdRows | Export-Excel -Path $outputPath -WorksheetName "Prod" -AutoSize -FreezeTopRow -BoldTopRow -AutoFilter -TableName "tblProd" -TableStyle Medium6
} else {
    [PSCustomObject]@{ Prod環境="(無差異)"; 類型=""; 節點路徑=""; 基準值=""; 環境值="" } | Export-Excel -Path $outputPath -WorksheetName "Prod" -AutoSize -FreezeTopRow -BoldTopRow
}

Write-Host "✅ 匯出完成: $outputPath"
Write-Host "   QA  sheet: $($allQaRows.Count) 筆"
Write-Host "   Prod sheet: $($allProdRows.Count) 筆"
```

### Step 3：確認輸出

腳本執行完畢後，Excel 檔案會出現在：

```
%USERPROFILE%\Downloads\nine1.cart.Settings比對.xlsx
```

檔案包含兩個 Sheet：
| Sheet | 說明 |
|-------|------|
| **QA** | 所有 QA 環境與 TW-QA 的節點差異，第一欄為 `QA環境` |
| **Prod** | 所有 Prod 環境與 TW-Prod 的節點差異，第一欄為 `Prod環境` |

欄位：`QA環境 / Prod環境`、`類型`（缺少節點／多餘節點）、`節點路徑`、`基準值`、`環境值`

---

## 注意事項

- 比對基準為 `TW-QA` 與 `TW-Prod`，這兩個環境本身不列入比對
- 若某環境與基準**完全相同**（結構上），該環境不會出現在 Excel 中
- 若 `ImportExcel` 尚未安裝，Step 1 會自動安裝
