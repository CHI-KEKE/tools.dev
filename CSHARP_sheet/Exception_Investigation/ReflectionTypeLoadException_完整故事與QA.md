# ReflectionTypeLoadException 完整故事：從根因到解法

## 📖 故事背景

User Story #604561：調整「所有線上訂單查詢」批次匯出，讓「是否為加價購品」欄位能區分「滿額加價購」與「滿件加價購」（原本兩者都顯示 "Yes"）。

實作完成後，推上 CI 測試機座，ELMAH 出現：

```
System.Reflection.ReflectionTypeLoadException: Unable to load one or more of the requested types.
  at System.Reflection.Assembly.GetTypes()
  at System.Data.Metadata.Edm.ObjectItemConventionAssemblyLoader.LoadTypesFromAssembly()
  ...
  at System.Data.Objects.ObjectContext.CreateQuery[T](String queryString, ObjectParameter[] parameters)
  at SalesOrderGroupRepository.GetOrderCustomInfos(...)
  at SalesOrderDataExportService.GetSalesOrderData(...)
```

---

## 🔍 完整觸發鏈

### Step 1：新增的查詢觸發了 EF 初始化

```csharp
// 我們新加的程式碼
if (cartExtraTsCodes.Any())
{
    cartExtraCustomInfos = _salesOrderGroupRepository
        .GetOrderCustomInfos("CartExtraPurchase", cartExtraTsCodes, shopId);
}
```

這呼叫了 `GetOrderCustomInfos`，裡面用了：

```csharp
var codeTable = context.cfn_NvarcharSplitToVarcharTable(strCodeList, ",");
```

### Step 2：cfn 內部用了 ObjectContext.CreateQuery

EF Database First 自動產生的 Table-Valued Function 實作：

```csharp
return ((IObjectContextAdapter)this).ObjectContext
    .CreateQuery<string>("[Schema].[cfn_NvarcharSplitToVarcharTable](@p1, @p2)", ...);
```

### Step 3：ObjectContext.CreateQuery 第一次被呼叫時初始化 Metadata Workspace

Metadata Workspace = EF 的「CLR 型別 ↔ 資料庫型別」對應表。  
初始化時會遍歷 AppDomain 所有已載入的 Assembly，呼叫 `Assembly.GetTypes()`。

### Step 4：掃描到 System.Web.Mvc.dll

掃到 `MvcCSharpRazorCodeGenerator`，這個 class 繼承自 `CSharpRazorCodeGenerator`（Razor 2.0）。

但 bin 裡的 `System.Web.Razor.dll` 是 3.0 版。

### Step 5：.NET 4.5 繼承安全性驗證失敗

```
.NET 4.5 規則：子類別的安全性標記必須 ≤ 父類別的安全性標記

MvcCSharpRazorCodeGenerator（編譯時連結 Razor 2.0）
  └─ 執行時找到的父類別是 Razor 3.0
       └─ 兩個版本的安全性標記不符
            └─ 💥 ReflectionTypeLoadException
```

---

## ❓ QA 問答

### Q1：NMQ 是背景服務，為什麼 bin 裡有 MVC dll？

NMQ 本身不需要 MVC，但它依賴的 BE/BL 層在 packages.config 宣告了 `Microsoft.AspNet.Mvc 4.0`。Build 時這些 dll 都會複製進最終 bin，所以 MVC dll 就進來了。

### Q2：為什麼 bin 裡是 Razor 3.0？

整個 solution 幾乎所有專案都用 Razor 2.0，唯獨 `ERP\Backend\BLV2` 因為引入 `RazorEngine 3.x`（用來產生 Email HTML 模板），帶進了 Razor 3.0。

Build 時多個專案把 dll 複製到同一個 bin，**後複製的蓋掉先複製的**，結果 bin 裡 Razor 被換成 3.0。

```
packages.config 版本分布：
  所有其他 BE/BL 專案 → Razor 2.0
  ERP\Backend\BLV2    → Razor 3.0  ← 唯一異類（因 RazorEngine）
```

### Q3：這個問題早就存在嗎？為什麼之前沒爆？

是的，版本衝突一直存在。`ObjectContext.CreateQuery` 的 EF 掃描只在**第一次被呼叫時**發生一次。

之前唯一用 cfn 的地方是 CustomPackaging 查詢，但它被 `if (IsEnableCustomPackaging)` 保護，大多數商店這個開關是關閉的，所以從未在 CI 環境被真正呼叫。

**我們的新 call** 只要訂單裡有加購品就執行，成為 CI 環境第一個真正觸發 `ObjectContext.CreateQuery` 的地方。

### Q4：為什麼生產環境沒問題？

生產伺服器安裝了較完整的 .NET Framework patch，GAC 中的 MVC/Razor 版本組合通過了繼承安全性驗證。CI 機座和本機沒有那些 patch，才踩到。

### Q5：CrmMemberRepository 也有 cfn，為什麼沒爆？

兩個原因：

1. CRM 用的是 `CRMDBEntities`，ERP 用的是 `ERPDBEntitiesV2`，每個 DbContext 有**獨立的** Metadata Workspace，互不影響
2. CI 測試的是「訂單匯出」功能，CRM 路徑根本沒被執行

### Q6：ExpenseOrderRepository 也有 cfn，為什麼沒事？

它用的是**原生 SQL 字串**方式呼叫 cfn，不是 EF 的 Table-Valued Function API：

```csharp
// 這只是 SQL 字串，不走 ObjectContext.CreateQuery
var sql = "SELECT ... FROM dbo.cfn_SplitToIntTable(@InputString, @SplitString) ...";
context.ExecuteStoreCommand(sql, params);
```

這不會觸發 EF Metadata Workspace 初始化。

### Q7：這是只有 scm.nmqv2 的問題，還是 nmqv2 也有？

只有 `nineyi.scm.nmqv2` 有這個問題。`nineyi.nmqv2`（NMQ 框架本身）用的是 MVC 5.1 + Razor 3.1，版本一致，沒有衝突。

---

## 🛠️ 各種解法評估

### 解法 A：GetOrderCustomInfosByContains（最終採用）

新增方法，用 LINQ `Contains` 生成 `IN (...)` SQL，完全不走 `ObjectContext.CreateQuery`：

```csharp
public List<SalesOrderCustomInfoEntity> GetOrderCustomInfosByContains(
    string type, List<string> codes, long shopId)
{
    var result = new List<SalesOrderCustomInfoEntity>();
    const int batchSize = 1000;  // 避免 SQL Server 2100 參數上限

    using (var transactionScope = ...)
    using (var scope = ...)
    using (var context = ...)
    {
        for (var i = 0; i < codes.Count; i += batchSize)
        {
            var batch = codes.Skip(i).Take(batchSize).ToList();
            var batchResult = context.SalesOrderCustomInfo.Valids()
                .Where(x => x.SalesOrderCustomInfo_SourceType == type
                         && x.SalesOrderCustomInfo_ShopId == shopId
                         && batch.Contains(x.SalesOrderCustomInfo_SourceCode))
                .Select(...)
                .ToList();
            result.AddRange(batchResult);
        }
    }
    return result;
}
```

**優點**：根本不觸發 EF 掃描，風險低，邏輯等價。  
**注意**：分批處理避開 SQL Server 2100 參數上限。

### 解法 B：Binding Redirect（放棄）

在 app.config 加：

```xml
<dependentAssembly>
  <assemblyIdentity name="System.Web.Razor" publicKeyToken="31bf3856ad364e35" />
  <bindingRedirect oldVersion="0.0.0.0-2.0.0.0" newVersion="3.0.0.0" />
</dependentAssembly>
```

**問題**：MVC 4.0 是用 Razor 2.0 API **編譯**的，redirect 過去可能換一個 `MissingMethodException`。未知風險高，放棄。

### 解法 C：NetFx40_LegacySecurityPolicy（放棄）

```xml
<runtime>
  <NetFx40_LegacySecurityPolicy enabled="true"/>
</runtime>
```

讓 .NET 退回 4.0 舊安全模型，繼承規則變寬鬆，ReflectionTypeLoadException 消失。

**問題**：AppDomain 變成「非同質性」，導致 `dynamic` 關鍵字失效（`動態作業只能在同質性 AppDomain 中執行`）。兩個問題無法同時解決，放棄。

### 解法 D：手動替換 bin 裡的 Razor dll（緊急暫時）

在測試機座的部署目錄，把 `System.Web.Razor.dll` 從 3.0 換回 2.0：

```
來源：packages\Microsoft.AspNet.Razor.2.0.20710.0\lib\net40\System.Web.Razor.dll
目標：{部署目錄}\System.Web.Razor.dll
```

**問題**：BLV2 的 Email 功能依賴 RazorEngine 3.x，換成 2.0 可能讓 Email 炸掉。僅作緊急測試用，不能當正式解法。

---

## 📊 解法比較表

| 解法 | 根本解決 | CI 可用 | 生產可用 | 副作用 |
|------|---------|---------|---------|--------|
| A: Contains 分批 | ✅ | ✅ | ✅ | 無 |
| B: Binding Redirect | ❌ | ⚠️ 未知 | ⚠️ 未知 | 可能 MissingMethod |
| C: LegacySecurityPolicy | ❌ | ❌ | ❌ | dynamic 失效 |
| D: 手動換 dll | ❌ | ⚠️ 暫時 | ❌ | Email 可能炸 |
