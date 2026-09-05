---
name: check-csharp-version
description: 檢查專案最高可用的 C# 語法版本，避免開發後才發現語法不支援的錯誤。當使用者說「檢查 C# 版本」、「check csharp version」、「這個專案可以用哪個 C# 版本」或類似意圖時使用此 skill。
allowed-tools: shell, view, grep, glob
---

## 目標

分析專案的 `.csproj` 或 `Directory.Build.props` 設定，判斷：
1. **Target Framework**（目標框架）
2. **預設 C# 版本**（編譯器依 Target Framework 自動判定）
3. **最高可用 C# 版本**（若有明確設定 `<LangVersion>` 則以該值為準）
4. **不可使用的常見語法**（提醒開發者）

---

## 執行步驟

### Step 1：確認目標專案路徑

若使用者已指定專案路徑，直接使用。若未指定，以 shell 搜尋當前目錄底下所有 `.csproj`：

```shell
Get-ChildItem -Path "." -Filter "*.csproj" -Recurse | Select-Object FullName
```

若找到多個，列出清單讓使用者選擇，或直接全部分析。

---

### Step 2：讀取 TargetFramework 與 LangVersion

對每個 `.csproj` 執行以下分析：

```shell
$csproj = "目標 .csproj 路徑"
$content = Get-Content $csproj -Raw

# 抓取 TargetFramework（SDK-style）
$tfm = [regex]::Match($content, '<TargetFramework[s]?>([^<]+)<').Groups[1].Value.Trim()

# 抓取 TargetFrameworkVersion（old-style .csproj）
if (-not $tfm) {
    $tfm = [regex]::Match($content, '<TargetFrameworkVersion>([^<]+)<').Groups[1].Value.Trim()
}

# 抓取 LangVersion（若有明確設定）
$langVersion = [regex]::Match($content, '<LangVersion>([^<]+)<').Groups[1].Value.Trim()

Write-Host "TargetFramework: $tfm"
Write-Host "LangVersion: $langVersion"
```

同時檢查是否有 `Directory.Build.props` 覆蓋設定：

```shell
$propsFile = Join-Path (Split-Path $csproj) "Directory.Build.props"
if (Test-Path $propsFile) {
    Get-Content $propsFile | Select-String "LangVersion|TargetFramework"
}
```

---

### Step 3：判斷 C# 版本

依下表對應 **Target Framework → 預設 C# 版本 → 最高可用版本**：

| Target Framework | 預設 C# 版本 | 最高可用 C# 版本 | 說明 |
|---|---|---|---|
| `v2.0` / `v3.5` | C# 3.0 | C# 3.0 | .NET Framework 2.x/3.5 |
| `v4.0` | C# 4.0 | C# 7.3 | 需明確設定 `<LangVersion>7.3` |
| `v4.5` / `v4.6` / `v4.7` / `v4.8` | C# 5.0 | C# 7.3 | 需明確設定 `<LangVersion>7.3` |
| `netstandard1.x` | C# 6.0 | C# 7.3 | |
| `netstandard2.0` | C# 7.3 | C# 7.3 | |
| `netstandard2.1` | C# 8.0 | C# 8.0 | |
| `netcoreapp2.x` | C# 7.3 | C# 7.3 | |
| `netcoreapp3.x` | C# 8.0 | C# 8.0 | |
| `net5.0` | C# 9.0 | C# 9.0 | |
| `net6.0` | C# 10.0 | C# 10.0 | |
| `net7.0` | C# 11.0 | C# 11.0 | |
| `net8.0` | C# 12.0 | C# 12.0 | |
| `net9.0` | C# 13.0 | C# 13.0 | |

> ⚠️ .NET Framework 專案（`v4.x`）預設 C# 5.0，但可透過 `<LangVersion>7.3</LangVersion>` 提升。
> 注意：即使設定更高的 LangVersion，部分需要 runtime 支援的語法（如 `default interface methods`）仍不可用。

若 `<LangVersion>` 有明確設定，則最高可用版本以該設定為準（但不可超過 Target Framework 的上限）。

---

### Step 4：列出版本對應的不可用語法

依判斷出的最高可用 C# 版本，列出**常見且容易踩雷的不可用語法**：

#### C# 5.0（.NET Framework 預設）— 不可使用：
- ❌ `out var`、`out int`（需先宣告變數）→ 改用 `int x; Method(out x);`
- ❌ Pattern matching（`is int n`、`switch` expressions）
- ❌ Tuples（`(int, string)`）
- ❌ `string interpolation $""`（C# 6+）
- ❌ `?.` null conditional operator（C# 6+）
- ❌ `nameof()`（C# 6+）
- ❌ Expression-bodied members（C# 6+）
- ❌ `throw` expressions（C# 7+）
- ❌ Local functions（C# 7+）
- ❌ `_` discard（C# 7+）

#### C# 6.0 — 不可使用（相較 C# 7+）：
- ❌ `out var`、inline `out` declaration
- ❌ Pattern matching
- ❌ Tuples
- ❌ Local functions

#### C# 7.3 — 不可使用（相較 C# 8+）：
- ❌ Nullable reference types（`string?`）
- ❌ `await` in catch/finally（C# 6 已支援，C# 7 擴充）
- ❌ Default interface implementations
- ❌ Switch expressions（`=> `）
- ❌ `using` declaration（`using var x = ...;`）

#### C# 8.0 — 不可使用（相較 C# 9+）：
- ❌ Record types
- ❌ `init` only setters
- ❌ Top-level statements
- ❌ `with` expression

---

### Step 5：輸出結果

以下列格式顯示分析結果：

```
📦 專案：{csproj 檔名}
🎯 Target Framework：{tfm}
📐 預設 C# 版本：{default version}
✅ 最高可用 C# 版本：{max version}
⚙️  LangVersion 設定：{langVersion 或 "未設定（使用預設）"}

⚠️  不可使用的語法（節錄）：
  - out var / inline out declaration
  - Pattern matching
  - ...
```

若有多個 `.csproj`，逐一顯示。

---

## 注意事項

- **目前本專案（NineYi.Sms）使用 .NET Framework 4.x，預設 C# 5.0**，除非在 .csproj 中明確設定 `<LangVersion>`，否則無法使用 C# 6+ 語法。
- 最常見踩雷點：`out var`、`is` pattern、`$""` 字串插值（若 C# < 6）。
- 若要提升版本，在 `.csproj` 加入：
  ```xml
  <PropertyGroup>
    <LangVersion>7.3</LangVersion>
  </PropertyGroup>
  ```
  並重新 Build 確認無誤。
