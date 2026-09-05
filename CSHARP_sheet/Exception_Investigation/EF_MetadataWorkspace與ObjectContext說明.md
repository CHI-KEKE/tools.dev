# EF Metadata Workspace 與 ObjectContext.CreateQuery 說明

## 什麼是 Metadata Workspace？

Entity Framework 在執行任何查詢前，需要知道「資料庫的欄位對應到 C# 的哪個 property」。這張對應表就叫 **Metadata Workspace**。

可以把它想成 EF 的「翻譯字典」：

```
資料庫：SalesOrderCustomInfo_SourceCode (nvarchar)
  ↕  對應
C#：SalesOrderCustomInfoEntity.SourceCode (string)
```

---

## 初始化時機：Lazy（懶惰載入）

Metadata Workspace **不是在 DbContext 建立時初始化**，而是在**第一次需要時才建立**（Lazy Initialization）。

觸發初始化的操作包含：
- `ObjectContext.CreateQuery<T>()`
- 部分 EF 的 Entity 型別解析操作

---

## 初始化過程做了什麼？

```
ObjectContext.CreateQuery<T>() 第一次被呼叫
  │
  └─ MetadataWorkspace.ImplicitLoadAssemblyForType()
       │
       └─ AssemblyCache.LoadAssembly()（掃描）
            │
            └─ 對 AppDomain 中所有已載入的 Assembly
                 呼叫 Assembly.GetTypes()
                      │
                      └─ 建立 CLR 型別 ↔ EDM 型別對應表
                           └─ 快取結果（之後不再掃描）
```

**關鍵**：這個掃描只發生一次。第一次成功 → 之後所有 cfn call 都沒問題。第一次失敗 → 直接拋出例外。

---

## 什麼是 CLR 型別？

CLR = **Common Language Runtime**，.NET 的執行環境。

CLR 型別就是你在 C# 裡定義的 class：

```csharp
public class SalesOrderCustomInfoEntity   // 這是 CLR 型別
{
    public string SourceCode { get; set; }
    public string JsonData { get; set; }
}
```

EF 需要把它對應到資料庫的 table/column。

EDM 型別（Entity Data Model）則是資料庫層面的描述（table、column、type）。

---

## 為什麼 Table-Valued Function 會觸發？

EF Database First 自動產生的 Table-Valued Function 方法實作是這樣的：

```csharp
// ERPDB.Context.cs（自動產生，不要手動改）
public IQueryable<string> cfn_NvarcharSplitToVarcharTable(string inputString, string splitString)
{
    var inputStringParameter = new ObjectParameter("inputString", inputString);
    var splitStringParameter = new ObjectParameter("splitString", splitString);

    return ((IObjectContextAdapter)this).ObjectContext
        .CreateQuery<string>(   // ← 這裡觸發 Metadata Workspace 初始化
            "[ERPDBEntitiesV2].[cfn_NvarcharSplitToVarcharTable](@inputString, @splitString)",
            inputStringParameter,
            splitStringParameter);
}
```

這是 EF 設計的一部分，無法繞過（除非不用這個方法）。

---

## ObjectContext vs DbContext

| 項目 | ObjectContext | DbContext |
|------|--------------|-----------|
| 世代 | EF 4（舊） | EF 5+（新，包裝了 ObjectContext） |
| Table-Valued Function | 用 ObjectContext.CreateQuery | EF 自動產生時仍走 ObjectContext |
| Metadata Workspace | 是 ObjectContext 的一部分 | 底層還是 ObjectContext |

`.CreateQuery<T>()` 是 ObjectContext 的方法，DbContext 的 `Set<T>()` 系列（LINQ）不走這個路徑，不觸發全 Assembly 掃描。

---

## 重點摘要

- Metadata Workspace 是 EF 的型別對應表，第一次使用時才建立
- 建立時會掃描所有已載入 dll 的所有型別
- `ObjectContext.CreateQuery<T>()` 是觸發這個掃描的常見入口
- Table-Valued Function 的自動產生程式碼內部就用這個方法
- 掃描只發生一次，成功就快取，失敗就爆
- 用 LINQ DbSet 查詢（`context.Table.Where(...)`）不走這條路，不觸發掃描
