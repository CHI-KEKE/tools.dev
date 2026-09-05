# ReflectionTypeLoadException — MVC / Razor 版本衝突

## 🚨 錯誤訊息

```
System.Reflection.ReflectionTypeLoadException: 無法載入一或多個要求類型。
類型 'System.Web.Mvc.Razor.MvcCSharpRazorCodeGenerator' 違反繼承安全性規則。
衍生類型的安全性存取範圍必須符合或小於基底類型的安全性存取範圍。
類型 'System.Web.Mvc.Razor.SetModelTypeCodeGenerator' 違反繼承安全性規則。
類型 'System.Web.Mvc.Razor.MvcCSharpRazorCodeParser' 違反繼承安全性規則。
```

## 📍 發生背景

在本機 DebugConsole 執行 .NET Framework 4.5 專案，呼叫 EF 的 Table-Valued Function 時爆炸。

Call Stack：
```
GetOrderCustomInfos()
  └─ context.cfn_NvarcharSplitToVarcharTable(strCodeList, ",")
       └─ ObjectContext.CreateQuery<string>(queryString, parameters)   ← 觸發點
            └─ EF Metadata Workspace 初始化
                 └─ Assembly.GetTypes() 遍歷所有已載入 Assembly
                      └─ 掃到 System.Web.Mvc.dll
                           └─ TypeLoadException
```

## 🔍 根本原因

### 1. EF Table-Valued Function 的實作方式

`cfn_NvarcharSplitToVarcharTable` 是 EF Database First 自動產生的方法，內部使用：

```csharp
return ((IObjectContextAdapter)this).ObjectContext
    .CreateQuery<string>("[Schema].[cfn_NvarcharSplitToVarcharTable](@p1, @p2)", ...);
```

`ObjectContext.CreateQuery<T>` 在**第一次被呼叫時**，會初始化 EF 的 Metadata Workspace。

### 2. Metadata Workspace 初始化的副作用

Metadata Workspace 需要建立「CLR 型別 ↔ EDM 型別」的對應表，為此它會呼叫：

```csharp
Assembly.GetTypes()  // 對 AppDomain 中所有已載入的 Assembly
```

### 3. .NET 4.5 的繼承安全性規則

.NET 4.5 加強了 [APTCA（AllowPartiallyTrustedCallersAttribute）](https://learn.microsoft.com/en-us/dotnet/framework/misc/security-transparent-code) 的繼承安全性驗證：

> **子類別的安全性存取範圍（SecurityAction）必須 ≤ 父類別**

### 4. 版本衝突點

| 元件 | 版本 | 安全性層級 |
|------|------|-----------|
| `System.Web.Razor.dll`（bin 內） | 3.0 | SecurityTransparent |
| `System.Web.Mvc.dll`（4.0） | 4.0 | 繼承自 Razor 2.0 的基底類別 |

`MvcCSharpRazorCodeGenerator`（MVC 4.0）繼承自 `CSharpRazorCodeGenerator`（Razor 2.0），但 bin 裡的 Razor 是 3.0，兩個版本的安全性標記不符，.NET 4.5 驗證時拒絕載入 → `TypeLoadException`。

## 💡 為什麼線上環境沒問題

線上伺服器的 GAC（Global Assembly Cache）中，MVC / Razor 的版本組合通過驗證，不觸發此規則。這是「本機開發環境特有」的問題。

## ✅ 解決方案

### 方案 A：繞過 `ObjectContext.CreateQuery`（根本解法）

新增使用 LINQ `Contains` 的查詢方法，不走 Table-Valued Function：

```csharp
// 不用 cfn_NvarcharSplitToVarcharTable，改用 LINQ IN (...)
public List<SalesOrderCustomInfoEntity> GetOrderCustomInfosByContains(
    string type, List<string> codes, long shopId)
{
    using (var scope = this._lifetimeScope.BeginLifetimeScope())
    using (var context = scope.Resolve<ERPDBEntitiesV2>())
    {
        return context.SalesOrderCustomInfo.Valids()
            .Where(x => x.SalesOrderCustomInfo_SourceType == type
                     && codes.Contains(x.SalesOrderCustomInfo_SourceCode)
                     && x.SalesOrderCustomInfo_ShopId == shopId)
            .Select(x => new SalesOrderCustomInfoEntity { ... })
            .ToList();
    }
}
```

`Contains` 生成 `WHERE SourceCode IN ('TS001', 'TS002', ...)` 純 SQL，不觸發 EF 全 Assembly 掃描。

### 方案 B：binding redirect（無效）

把 Razor redirect 到同一版本，嘗試讓繼承關係合法。但 MVC 4.0 的 dll 本身就是用 Razor 2.0 編譯的，redirect 無法改變編譯時期的繼承標記。

### 方案 C：`NetFx40_LegacySecurityPolicy`（有副作用，見另一篇）

```xml
<runtime>
  <NetFx40_LegacySecurityPolicy enabled="true"/>
</runtime>
```

退回 .NET 4.0 舊安全模型，繼承規則變寬鬆，問題二消失。但會引發問題三（dynamic 失效）。

## 📝 重點摘要

- `ObjectContext.CreateQuery<T>` 是觸發點，不是錯誤本身
- 根本原因是 bin 裡 MVC / Razor dll 的版本組合，在 .NET 4.5 的安全性規則下不合法
- 線上可以、本機爆，是「環境差異」造成的，不是程式邏輯錯誤
- 根本解法是「不呼叫 `ObjectContext.CreateQuery`」，而不是修改安全性設定
