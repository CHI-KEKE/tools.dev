## 簡化模式（直接重用匯入 Entity，不建 ExcelEntity）

**適用時機**：錯誤明細要呈現的欄位與原始匯入 Entity 完全一致時，可省略建立 ExcelEntity。

**位置**：`BusinessLogic\Services\BatchUploads\Excels\{功能名稱}ExcelService.cs`

```csharp
using System.Collections.Generic;
using System.Data;
using NineYi.Sms.BL.BE.BatchUploads;
using NineYi.Sms.BL.BE.BatchUploads.Enums;
using NineYi.Sms.DA.WebStoreDB.Tables;
using NineYi.Sms.Utilities.Excels;
using NineYi.Sms.Utilities.Helpers;

namespace NineYi.Sms.BL.Services.BatchUploads.Excels
{
    /// <summary>
    /// {前端顯示名稱}錯誤明細匯出
    /// </summary>
    public class {功能名稱}ExcelService : BatchUploadMessageExcelService, IBatchUploadExcelService
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="{功能名稱}ExcelService"/> class.
        /// </summary>
        /// <param name="excelService">IExcelService</param>
        public {功能名稱}ExcelService(IExcelService excelService) : base(excelService)
        {
        }

        /// <summary>
        /// 大量上傳類型
        /// </summary>
        public List<BatchUploadTypeDefEnum> BatchUploadTypes =>
            new List<BatchUploadTypeDefEnum> { BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱} };

        /// <summary>
        /// 取得工作表名稱
        /// </summary>
        /// <param name="batchUploadTypeDef">大量上傳類型</param>
        /// <returns>工作表名稱</returns>
        public string GetSheetName(BatchUploadTypeDefEnum batchUploadTypeDef)
        {
            return SettingHelper.DefaultCountry == "TW" ? "{TW工作表名稱}" : "{非TW工作表名稱}";
        }

        /// <summary>
        /// 轉為DataTable
        /// </summary>
        /// <param name="batchUploadDataList">BatchUploadData List</param>
        /// <returns>DataTable</returns>
        public DataTable GetDataTable(List<BatchUploadData> batchUploadDataList)
        {
            //// 直接將失敗批次資料反序列化為匯入 Entity 後轉換為 DataTable
            return this.ConvertToDataTable<{匯入Entity名稱}>(batchUploadDataList);
        }
    }
}
```

> **實際範例**：`BusinessLogic\Services\BatchUploads\Excels\BatchUpdateSkuPropertyNameExcelService.cs`  
> 直接重用 `BatchUpdateSkuPropertyNameEntity`，不需另建 ExcelEntity。

---

# 錯誤明細 Excel Entity
**位置**：`BusinessLogic\BE\BatchUploads\Excels\{功能名稱}ExcelEntity.cs`
using 來源：`NineYi.Sms.Utilities.Attributes`

```csharp
using NineYi.Sms.Utilities.Attributes;

namespace NineYi.Sms.BL.BE.BatchUploads.Excels
{
    /// <summary>
    /// {前端顯示名稱}錯誤明細 Excel Entity
    /// </summary>
    public class {功能名稱}ExcelEntity
    {
        /// <summary>
        /// {欄位說明}
        /// </summary>
        [ExportExcel(ColumnName = "{Excel欄位顯示名稱}", Module = "backend.entity.{module_key}", Key = "{field_key}")]
        public string {屬性名稱} { get; set; }

        // 逐一對應上傳 Entity 的欄位...

        /// <summary>
        /// 錯誤訊息
        /// </summary>
        [ExportExcel(ColumnName = "錯誤訊息", Module = "backend.entity.{module_key}", Key = "error_message")]
        public string Message { get; set; }
    }
}
```

**規則**：
- `ColumnName`：Excel 欄位的顯示名稱（TW）
- `Module`：多語系模組鍵，格式：`backend.entity.{snake_case_功能名稱}_excel`
- `Key`：多語系欄位鍵，格式：`{snake_case_屬性名稱}`
- 末尾必須有 `Message` 欄位

---

## IBatchUploadExcelService 實作 — 簡單版（直接轉換）
**位置**：`BusinessLogic\Services\BatchUploads\Excels\{功能名稱}ExcelService.cs`

適用：不需額外處理，直接將 JSON 反序列化為 Entity。

```csharp
using System.Collections.Generic;
using System.Data;
using NineYi.Sms.BL.BE.BatchUploads.Enums;
using NineYi.Sms.BL.BE.BatchUploads.Excels;
using NineYi.Sms.DA.WebStoreDB.Tables;
using NineYi.Sms.Utilities.Excels;
using NineYi.Sms.Utilities.Helpers;

namespace NineYi.Sms.BL.Services.BatchUploads.Excels
{
    /// <summary>
    /// {前端顯示名稱}錯誤明細匯出
    /// </summary>
    public class {功能名稱}ExcelService : BatchUploadMessageExcelService, IBatchUploadExcelService
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="{功能名稱}ExcelService"/> class.
        /// </summary>
        /// <param name="excelService">IExcelService</param>
        public {功能名稱}ExcelService(IExcelService excelService)
            : base(excelService)
        {
        }

        #region Implementation of IBatchUploadExcelService

        /// <inheritdoc />
        public List<BatchUploadTypeDefEnum> BatchUploadTypes =>
            new List<BatchUploadTypeDefEnum> { BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱} };

        /// <inheritdoc />
        public string GetSheetName(BatchUploadTypeDefEnum batchUploadTypeDef)
        {
            //// 依國家語系回傳對應工作表名稱
            return SettingHelper.DefaultCountry == "TW"
                ? "{TW工作表名稱}"
                : "{非TW工作表名稱}";
        }

        /// <inheritdoc />
        public DataTable GetDataTable(List<BatchUploadData> batchUploadDataList)
        {
            //// 將失敗批次資料的 JSON 反序列化後轉換為 DataTable
            return this.ConvertToDataTableAsObject<{功能名稱}ExcelEntity>(batchUploadDataList);
        }

        #endregion Implementation of IBatchUploadExcelService
    }
}
```

---

## IBatchUploadExcelService 實作 — 進階版（需自訂資料處理）
適用：需要查詢 DB、代碼轉中文描述、自訂排序等情境。

```csharp
/// <inheritdoc />
public DataTable GetDataTable(List<BatchUploadData> batchUploadDataList)
{
    if (batchUploadDataList == null || batchUploadDataList.Any() == false)
    {
        return new DataTable();
    }

    //// 先轉換為 DataTable（保留可修改的彈性）
    var dataTable = this.ConvertToDataTable<{功能名稱}ExcelEntity>(batchUploadDataList);

    //// 依實際需求進行額外處理，例如：代碼轉中文、格式化日期等
    foreach (DataRow row in dataTable.Rows)
    {
        //// 範例：將數值代碼 "1" 轉換為中文說明 "啟用"
        if (row["{欄位名稱}"].ToString() == "1")
        {
            row["{欄位名稱}"] = "啟用";
        }
    }

    return dataTable;
}
```

---

## 兩個轉換方法的選擇邏輯

| 方法 | 使用時機 |
|------|---------|
| `ConvertToDataTableAsObject<T>` | 不需修改資料，直接輸出 |
| `ConvertToDataTable<T>` | 需要對 DataTable 的列逐行進行後處理 |

---

## 多個批次類型共用同一 ExcelService

若多種批次類型的錯誤欄位結構相同（例如：建立和更新商品頁）：

```csharp
public List<BatchUploadTypeDefEnum> BatchUploadTypes =>
    new List<BatchUploadTypeDefEnum>
    {
        BatchUploadTypeDefEnum.{類型A},
        BatchUploadTypeDefEnum.{類型B},
    };

public string GetSheetName(BatchUploadTypeDefEnum batchUploadTypeDef)
{
    //// 依類型回傳不同工作表名稱
    switch (batchUploadTypeDef)
    {
        case BatchUploadTypeDefEnum.{類型A}:
            return SettingHelper.DefaultCountry == "TW" ? "{TW名稱A}" : "{EN名稱A}";
        case BatchUploadTypeDefEnum.{類型B}:
            return SettingHelper.DefaultCountry == "TW" ? "{TW名稱B}" : "{EN名稱B}";
        default:
            return SettingHelper.DefaultCountry == "TW" ? "{TW預設名稱}" : "{EN預設名稱}";
    }
}
```

---

## 參考實作範例

| 難易度 | 檔案路徑 |
|--------|---------|
| 簡單（直接轉換） | `BusinessLogic\Services\BatchUploads\Excels\BatchCreateBrandTagsExcelService.cs` |
| 含代碼轉換 | `BusinessLogic\Services\BatchUploads\Excels\SalePageUpdateExcelService.cs` |
| 含訊息查詢 | `BusinessLogic\Services\BatchUploads\Excels\BatchPromoCodeImportExcelService.cs` |
| 含多類型 | `BusinessLogic\Services\BatchUploads\Excels\BatchModifyMemberTierSalePageExcelService.cs` |
