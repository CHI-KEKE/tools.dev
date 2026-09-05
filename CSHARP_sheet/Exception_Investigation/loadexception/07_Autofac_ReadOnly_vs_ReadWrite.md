# Autofac ReadOnly vs ReadWrite Context 說明

## 核心概念

`ResolveNamed<T>("ReadOnly")` 不是 C# 層面的限制，  
而是 **Autofac 注冊了兩個不同連線字串的 DbContext 實例**。

---

## DAModule 注冊設定

```csharp
// DAModule.cs

// ReadWrite（預設）→ 主庫
builder.RegisterType<ERPDBEntitiesV2>()
    .WithParameter("connectionString", this.GetConnectionString("ERP"))
    .AsSelf()
    .InstancePerDependency();

// ReadOnly → 唯讀副本（另一台機器）
builder.RegisterType<ERPDBEntitiesV2>()
    .WithParameter("connectionString", this.GetConnectionString("ERP.ReadOnly"))
    .Keyed<ERPDBEntitiesV2>("ReadOnly")
    .InstancePerDependency();
```

同樣的 `ERPDBEntitiesV2` class，但注冊了兩個 key，指向不同的連線字串。

---

## 連線字串解析流程

```csharp
// ConnectionStringHelper.cs line 119
ConfigurationManager.ConnectionStrings[Execmode.GetMode().ToString() + "." + databaseName]
```

```
Resolve<ERPDBEntitiesV2>()
  → GetConnectionString("ERP")
  → app.config key：{Mode}.ERP
  → Data Source = 主庫 SQL Server

ResolveNamed<ERPDBEntitiesV2>("ReadOnly")
  → GetConnectionString("ERP.ReadOnly")
  → app.config key：{Mode}.ERP.ReadOnly
  → Data Source = 唯讀副本 SQL Server（另一台）
```

---

## 實際架構

```
應用程式
  ├─ Resolve<ERPDBEntitiesV2>()            → 主庫（可讀寫）
  └─ ResolveNamed<ERPDBEntitiesV2>("ReadOnly") → AlwaysOn 唯讀副本（只能 SELECT）
```

**SQL Server AlwaysOn 架構：**
- 主庫負責 INSERT / UPDATE / DELETE
- 唯讀副本接收主庫同步資料，只開放 SELECT
- 查詢導流到副本，減輕主庫壓力

---

## 判斷要用哪個的原則

| 操作 | 使用 |
|------|------|
| 只查詢（SELECT） | `ResolveNamed<T>("ReadOnly")` |
| 需要寫入（INSERT/UPDATE/DELETE） | `Resolve<T>()` |
| 同一個 UoW 先查後寫 | `Resolve<T>()`（保持同一 context） |
| 批次匯出、報表 | `ResolveNamed<T>("ReadOnly")` |

---

## 本案結論

`GetOrderCustomInfosByContains` 只做 SELECT 查詢，  
使用 `ResolveNamed<ERPDBEntitiesV2>("ReadOnly")` 是**正確且更嚴謹的做法**。

原版 `GetOrderCustomInfos` 使用 `Resolve<ERPDBEntitiesV2>()`（ReadWrite）是不必要的，屬於當時的小瑕疵。

---

## 使用方式

```csharp
// ReadOnly（查詢用）
using (ERPDBEntitiesV2 context = scope.ResolveNamed<ERPDBEntitiesV2>("ReadOnly"))
{
    // 只做 SELECT，連到唯讀副本
}

// ReadWrite（寫入用）
using (ERPDBEntitiesV2 context = scope.Resolve<ERPDBEntitiesV2>())
{
    // INSERT / UPDATE / DELETE，連到主庫
}
```
