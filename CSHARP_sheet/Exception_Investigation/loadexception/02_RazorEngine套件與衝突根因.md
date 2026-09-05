# RazorEngine 套件與版本衝突根因

## RazorEngine 是什麼

RazorEngine 是一個**第三方 NuGet 套件**（非 Microsoft 官方）：

| | 官方 Razor | RazorEngine |
|--|-----------|-------------|
| 出處 | Microsoft | Antaris（第三方） |
| NuGet ID | Microsoft.AspNet.Razor | RazorEngine |
| 用途 | 編譯 .cshtml 給 ASP.NET MVC 用 | 在非 Web 環境用 Razor 語法產生字串（例如 Email 模板） |
| 依賴 | - | 依賴 Microsoft.AspNet.Razor 3.x |

本案中 BLV2 引入 RazorEngine 3.10.0 的目的是：**用 .cshtml 模板產生 Email 內容**。

## 版本衝突如何形成

```
時間點 A：Eric Hsu（2014-11-26）建立 BLV2 專案
  安裝 Microsoft.AspNet.Mvc 4.0.x
  → bin 裡：System.Web.Mvc.dll（MVC 4.0）
  → bin 裡：System.Web.Razor.dll 2.0（MVC 4.0 配套）
  ✅ 相安無事

時間點 B：Bill Chang（2020-10-20，VSTS119687）
  安裝 RazorEngine 3.10.0
  → NuGet 自動帶進：System.Web.Razor.dll 3.0
  → 蓋掉原本的 Razor 2.0

bin 結果：
  System.Web.Mvc.dll    ← 編譯時綁定 Razor 2.0（永久刻在 dll 裡）
  System.Web.Razor.dll  ← 執行時是 Razor 3.0（被換掉了）
  → 定時炸彈埋下
```

## csproj 直接證據

**BE.csproj（正確配對）：**
```xml
<Reference Include="System.Web.Mvc, Version=4.0.0.1, ...">
  <HintPath>packages\Microsoft.AspNet.Mvc.4.0.40804.0\lib\net40\System.Web.Mvc.dll</HintPath>
</Reference>
<Reference Include="System.Web.Razor, Version=2.0.0.0, ...">
  <HintPath>packages\Microsoft.AspNet.Razor.2.0.20710.0\lib\net40\System.Web.Razor.dll</HintPath>
</Reference>
```

**BLV2.csproj（問題所在）：**
```xml
<Reference Include="System.Web.Razor, Version=3.0.0.0, ...">
  <HintPath>packages\Microsoft.AspNet.Razor.3.0.0\lib\net45\System.Web.Razor.dll</HintPath>
</Reference>
```

BLV2 參考了 BE.dll（間接帶進 MVC 4.0），又自己引入 Razor 3.0，  
導致同一個 bin 裡出現版本矛盾的兩個 dll。

## Dependency Hell（相依性地獄）

這種問題叫做 **Dependency Hell**，在 .NET Framework 時代特別常見：

> 開發者只裝了兩個套件，但 NuGet 的相依性自動帶進來的 dll 互相衝突。

.NET Core 之後用 `PackageReference` 搭配統一版本解析機制，大幅改善此問題。
