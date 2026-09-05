# 如何驗證 dll 依賴的 Razor 版本

## 問題背景

`System.Web.Mvc.dll` 聲稱「認識 Razor 2.0」，  
但 bin 裡的 `System.Web.Razor.dll` 實際是 3.0，  
這個衝突不看原始碼無法直接感知，需要工具驗證。

## 方法 1：PowerShell 讀取 dll 相依清單（推薦）

```powershell
$dll   = "路徑\System.Web.Mvc.dll"
$bytes = [System.IO.File]::ReadAllBytes($dll)
$asm   = [System.Reflection.Assembly]::Load($bytes)
$asm.GetReferencedAssemblies() | Select-Object Name, Version
```

### 實際執行結果

```
Name                      Version
----                      -------
System.Web.Razor          2.0.0.0   ← MVC 4.0 綁定 Razor 2.0（證明）
System.Web.WebPages.Razor 2.0.0.0
System.Web.WebPages       2.0.0.0
```

### 為什麼用 `Load(bytes)` 而不是 `ReflectionOnlyLoadFrom`

.NET 5+ 不支援 `ReflectionOnlyLoadFrom`，會拋出：
```
ReflectionOnly loading is not supported on this platform.
```
改用 `File.ReadAllBytes` + `Assembly.Load(bytes)` 可在所有平台執行。

## 方法 2：查看 csproj Reference 區塊

在 VS Code 搜尋 csproj 檔案中的 Reference：

```xml
<!-- BE.csproj：正確配對 -->
<Reference Include="System.Web.Mvc, Version=4.0.0.1, ...">
<Reference Include="System.Web.Razor, Version=2.0.0.0, ...">

<!-- BLV2.csproj：衝突來源 -->
<Reference Include="System.Web.Razor, Version=3.0.0.0, ...">
```

在 VS Code 用 `Ctrl+Shift+F` 搜尋 `System.Web.Razor`，  
比對各專案引用的版本是否一致。

## 方法 3：查看 packages.config

```xml
<!-- BLV2/packages.config -->
<package id="Microsoft.AspNet.Razor" version="3.0.0" targetFramework="net45" />
<package id="RazorEngine" version="3.10.0" targetFramework="net45" />
```

看到 Razor 3.0.0 就代表這個專案會把 Razor 3.0 帶進 bin。

## 根解方案比較

| 方案 | 做法 | 代價 |
|------|------|------|
| A：升級 MVC 4.0 → 5.x | MVC 5.x 配套 Razor 3.x | Breaking changes，全面回歸測試 |
| B：降版 RazorEngine → 2.x | RazorEngine 2.x 依賴 Razor 2.0 | Email API 要改寫 |
| C：ExcludeAssets 排除 Razor | 強制不帶進 Razor 3.0 | 需測試 Email 功能是否正常 |
| D：繞開（我們做的） | 改用 LINQ Contains，不觸發 EF 掃描 | 非根解，定時炸彈仍在 |

**短期**：維持方案 D（`GetOrderCustomInfosByContains`）  
**長期根解**：方案 B 或 C，由負責 Email 功能的 owner 評估。
