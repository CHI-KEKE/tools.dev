---
name: b2e-dev-batch-upload-executor
description: >
  **WORKFLOW SKILL** — 執行 B2E 批次作業（批次匯入 or 批次匯出）的完整程式碼生成工作流程。
  USE FOR: 開發新的批次上傳（BatchUpload）功能、批次匯出功能、以及批次錯誤明細匯出（IBatchUploadExcelService）。
  DO NOT USE FOR: 修改現有批次 NMQ Worker 邏輯、前端 UI 開發、部署設定。
  當使用者說「新增批次匯入」、「新增批次匯出」、「新增 batch upload」、「批次作業」、「批次上傳」、
  「BatchUploadTypeDefEnum 新增」、「AbstractCreateBatchTaskBaseService 繼承」等詞彙時，必須啟動此 Skill。
---

# B2E 批次作業開發執行器

此 Skill 協助開發者依序完成批次作業的所有程式碼生成與檔案修改步驟。

## Reference 檔案（按需載入）

| 檔案 | 用途 |
|------|------|
| `references/batch-import-templates.md` | Entity 三種模式 + Service + 單元測試的完整 Code Template |
| `references/batch-export-templates.md` | 匯出 Entity + Service + Controller + 單元測試的完整 Code Template |
| `references/excel-error-export-templates.md` | IBatchUploadExcelService 兩種實作模式的完整 Code Template |

---

## Step 0：需求收集

啟動時，向使用者確認以下資訊（未提供的才詢問）：

### 共用
- **功能類型**：批次匯入 or 批次匯出
- **BatchUploadTypeDefEnum 名稱**：英文 PascalCase，例：`BatchModifyProductStock`
- **前端顯示名稱**：繁體中文，例：`批次修改商品庫存`

### 批次匯入額外確認
- **Excel 工作表名稱**（TW / 非TW）
- **欄位清單**：名稱、說明、是否必填
- **是否需 `[ExcelColumn]`**：欄位標題與 C# 屬性名稱是否不同（若不同則用 `[ExcelColumn("TW名稱","EN名稱")]`）
- **最大上傳筆數**
- **是否需預約執行**（最早預約分鐘數）
- **是否需錯誤明細匯出**（IBatchUploadExcelService）

### 批次匯出額外確認
- **所屬 Service 模組**，例：`IProductService`
- **匯出條件欄位**（名稱、型別）
- **API 路徑**

確認後，**列出將要生成/修改的檔案清單**，讓使用者確認再執行。

---

## 執行步驟總覽

| 步驟 | 說明 | 適用 |
|------|------|------|
| Step 1 | 修改 Enum 檔案 | 匯入 + 匯出 |
| Step 2 | 生成資料庫 SQL | 匯入 + 匯出 |
| Step 3 | 建立 Entity 檔案 | 匯入 + 匯出 |
| Step 3.5 | 建立 ColumnMappingProfile | 匯入專用 |
| Step 4 | 建立 Service 類別 | 匯入 + 匯出 |
| Step 5 | 修改 GetBatchUploadExecuteTaskType() | 匯入 + 匯出 |
| Step 5.5 | 新增 GetBatchUploadPermissionList() 權限項目 | 匯入 + 匯出 |
| Step 6 | Web.config 設定 | 匯入專用 |
| Step 7 | 錯誤明細匯出（ExcelService） | 依需求 |
| Step 8 | 建立單元測試 | 匯入 + 匯出 |
| Step 9 | 更新 .csproj | 匯入 + 匯出 |

---

## Step 1：修改 Enum 檔案

### BatchUploadTypeDefEnum
**檔案**：`BusinessLogic\BE\BatchUploads\Enums\BatchUploadTypeDefEnum.cs`

依字母順序插入：
```csharp
/// <summary>
/// {前端顯示名稱}
/// </summary>
{BatchUploadTypeDefEnum名稱},
```

### BatchUploadExecuteTaskTypeEnum（依需求）
**檔案**：`BusinessLogic\BE\BatchUploads\Enums\BatchUploadExecuteTaskTypeEnum.cs`

若功能無法重用 `BatchUploadTask`，才須新增：
```csharp
/// <summary>
/// {前端顯示名稱}任務
/// </summary>
{BatchUploadTypeDefEnum名稱}Task,
```

---

## Step 2：資料庫 SQL

```sql
USE [WebStoreDB]
GO
DECLARE @maxSort int;
SELECT @maxSort = MAX(Definition_Sort)
FROM dbo.Definition WITH(NOLOCK)
WHERE Definition_ValidFlag = 1
  AND Definition_TableName = 'BatchUpload'
  AND Definition_ColumnName = 'BatchUpload_TypeDef'

INSERT INTO [dbo].[Definition]
    ([Definition_TableName],[Definition_ColumnName],[Definition_Code],
     [Definition_Desc],[Definition_Note],[Definition_Sort],
     [Definition_CreatedDateTime],[Definition_CreatedUser],
     [Definition_UpdatedTimes],[Definition_UpdatedDateTime],
     [Definition_UpdatedUser],[Definition_ValidFlag])
VALUES
    ('BatchUpload','BatchUpload_TypeDef','{BatchUploadTypeDefEnum名稱}',
     N'{前端顯示名稱}',N'批次上傳類型',@maxSort + 10,
     GETDATE(),'{開發者帳號}',0,GETDATE(),'{開發者帳號}',1)
GO
```

---

## Step 3：建立 Entity

> 載入 `references/batch-import-templates.md` 取得三種 Entity 模式的完整程式碼。

### 三種模式快速判斷
| 情境 | 模式 |
|------|------|
| Excel 欄位標題 = C# 屬性名稱（不需多語系） | 模式 A：無 `[ExcelColumn]` |
| Excel 欄位標題與 C# 屬性名稱不同，或需 TW/EN 雙語系 | 模式 B：`[ExcelColumn("TW名稱","EN名稱")]` |
| 上傳格式為 CSV | 模式 C：`[ImportCsv]` |

### 命名規範
- 批次匯入：`Batch{功能名}Entity` 或 `BatchImport{功能名}Entity`
- 批次匯出條件：`{功能名}ExportEntity`，放於 `BusinessLogic\BE\{功能模組}\`

### 共用規則
- 所有欄位使用 `string` 型別
- 建構函式初始化所有屬性為 `"excelErrorMapping"` 常數
- 每個 public 屬性須有繁體中文 XML 文件注解

---

## Step 3.5：建立 ColumnMappingProfile（批次匯入）

> 載入 `references/batch-import-templates.md` 取得 ColumnMappingProfile 完整模板。

**位置**：`CrossLayer\Mappers\BatchUploads\{功能名稱}ColumnMappingProfile.cs`

### 何時需要建立

**所有批次匯入都必須建立**，否則 Autofac 無法解析 `IColumnMapping<T>`，執行時會拋出：
```
ComponentNotRegisteredException: The requested service 'IColumnMapping<{EntityClassName}>' has not been registered.
```

### 快速規則
- 實作 `IColumnMapping<{EntityClassName}>`
- 使用 `SettingHelper.DefaultCountry == "TW"` switch 分支，分別對應 TW / 非TW 欄位標題
- `excelFile.Add(a => a.{屬性名稱}, "{欄位標題字串}")` 逐一對映欄位
- **不需要對映的欄位**（如 `Title`、計算欄位）就不加入 Add

> ⚠️ **注意**：此 Profile 須加入 `CrossLayer\Mappers\NineYi.Sms.Mappers.csproj` 才會被 Autofac 掃描到。

---

## Step 4：建立 Service

> 套用 `references/batch-import-templates.md` 或 `references/batch-export-templates.md` 的完整模板。

> ⚠️ **ILogger 注意事項**：注入 Logger 時必須使用 `Utility.Logging.ILogger`（`using Utility.Logging;`），**不可使用** `NLog.ILogger`（`using NLog;`）。  
> Autofac 透過 `NLogLoggerAutofacModule` 自動解析 `Utility.Logging.ILogger`，若誤用 `NLog.ILogger` 會在執行期拋出 `DependencyResolutionException`。

### 批次匯入
- 繼承 `AbstractCreateBatchTaskBaseService`
- 必須實作 `GetBatchUploadType()` 和 `VerifyFile()`
- `VerifyFile()` 流程：讀取 Excel → 驗證空資料 → 驗證筆數 → 逐筆驗證 → 設定 `RowCount`

### 批次匯出
- 在 `IBatchUploadService` 介面宣告 `Create{功能名}Task()` 方法
- 在 `BatchUploadService` 實作，呼叫 `CreateBatchUploadNMQTask()`
- 在功能模組 Service 做參數驗證後呼叫 `BatchUploadService`

---

## Step 5：修改 GetBatchUploadExecuteTaskType()

**檔案**：`BusinessLogic\Services\BatchUploads\BatchUploadService.cs`

```csharp
case BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱}:
    return BatchUploadExecuteTaskTypeEnum.{對應TaskType};
```

---

## Step 5.5：新增 GetBatchUploadPermissionList() 權限項目

**檔案**：`BusinessLogic\Services\BatchUploads\BatchUploadService.cs`

在 `GetBatchUploadPermissionList()` 方法的 Dictionary 中，依功能性質加入對應的 action path 和權限值：

```csharp
//// {前端顯示名稱}
{
    "/{Controller路由}/{Action路由}", new List<string>()
    {
        nameof(BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱})
    }
},
```

### 路由命名規則
- Controller 路由通常為 `BatchUpload`
- Action 路由與 `BatchUploadTypeDefEnum` 名稱一致

> ⚠️ **注意**：使用 `nameof(BatchUploadTypeDefEnum.{名稱})` 而非 `.ToString()`，確保重構時不遺漏。

---

## Step 6：Web.config 設定（批次匯入）

**檔案**：`WebSite\WebSite\Web.config`

```xml
<!-- {前端顯示名稱}：最大上傳筆數 -->
<add key="BatchUpload.{BatchUploadTypeDefEnum名稱}.MaxUploadCount" value="{最大筆數}" />
<!-- {前端顯示名稱}：最早可預約時間（分鐘），0 表示不支援 -->
<add key="BatchUpload.{BatchUploadTypeDefEnum名稱}.SoonestScheduleTimeOffset" value="0" />
```

---

## Step 7：錯誤明細匯出（依需求）

> 載入 `references/excel-error-export-templates.md` 取得完整實作模板。

### 模式選擇

| 情境 | 建議模式 |
|------|---------|
| 需要顯示的欄位與原始匯入 Entity 完全一致，且 Entity 在 `BL.BE.BatchUploads` 中已存在 | **簡化模式（不建 ExcelEntity）** |
| 需要額外欄位、格式轉換、或代碼轉中文 | **標準模式（建 ExcelEntity）** |

### 簡化模式（直接重用匯入 Entity）

只需建立一個 ExcelService，直接使用原匯入 Entity：

**檔案**：`BusinessLogic\Services\BatchUploads\Excels\{功能名稱}ExcelService.cs`

```csharp
public DataTable GetDataTable(List<BatchUploadData> batchUploadDataList)
{
    return this.ConvertToDataTable<{匯入Entity名稱}>(batchUploadDataList);
}
```

> **適用條件**：匯入 Entity 欄位即為錯誤明細要呈現的欄位，不需另外建立 ExcelEntity。

### 標準模式（建 ExcelEntity + ExcelService）

需建立兩個檔案：
1. `BusinessLogic\BE\BatchUploads\Excels\{功能名稱}ExcelEntity.cs`
2. `BusinessLogic\Services\BatchUploads\Excels\{功能名稱}ExcelService.cs`

**ExcelEntity**：欄位使用 `[ExportExcel(ColumnName, Module, Key)]`，**不需要** `Message` 欄位（Message 由框架在其他地方處理）。
例：`BatchUpdateSkuPropertyNameExcelEntity` 有 9 個業務欄位、無 Message 欄位。

**ExcelService 選擇**：
- 不需額外處理 → `ConvertToDataTableAsObject<T>()`
- 需自訂邏輯 → `ConvertToDataTable<T>()` 後再處理 DataTable

### DI 說明

兩種模式的 ExcelService **都不需要手動 DI 註冊**。
`ServiceModule` 使用 `RegisterAssemblyTypes().AsImplementedInterfaces()` 自動掃描所有實作 `IBatchUploadExcelService` 的類別。
只需確認檔案已加入 `NineYi.Sms.BL.Services.csproj`。

---

## Step 8：建立單元測試

> 載入對應 reference 取得完整測試模板。

**批次匯入**必須覆蓋：
- `GetBatchUploadType()` 回傳正確類型
- `VerifyFile()` 資料為空拋出例外
- `VerifyFile()` 超過最大筆數拋出例外
- `VerifyFile()` 必填欄位空值拋出例外
- `VerifyFile()` 正常資料通過驗證

每個測試方法必須有繁體中文 `DisplayName`，使用 AAA 結構。

---

## Step 9：更新 .csproj 專案檔

| 專案檔 | 新增項目 |
|--------|---------|
| `BusinessLogic\BE\NineYi.Sms.BL.BE.csproj` | Entity 檔案 |
| `BusinessLogic\Services\NineYi.Sms.BL.Services.csproj` | Service / ExcelService 檔案 |
| `CrossLayer\Mappers\NineYi.Sms.Mappers.csproj` | ColumnMappingProfile 檔案（批次匯入專用） |
| `Test\BL.Services.Test.Xunit\NineYi.Sms.BL.Services.Test.csproj` | 測試檔案 |

規則：`<Compile Include="...路徑..." />`，依**字母順序**排入同資料夾群組，使用反斜線 `\`。

---

## 開發完成檢查清單

### 程式碼品質
- [ ] 所有 public 類別與方法有 `///` XML 文件注解（繁體中文）
- [ ] 方法內使用 `////` 說明主要邏輯區塊
- [ ] 布林判斷使用 `== false`，不使用 `!`
- [ ] `IDisposable` 物件使用 `using` 陳述式
- [ ] 無 `async/await`（此專案使用同步方法）
- [ ] 每個檔案只有一個類別

### 批次匯入
- [ ] Service 繼承 `AbstractCreateBatchTaskBaseService`
- [ ] Entity 建構函式初始化所有屬性為 `"excelErrorMapping"`
- [ ] `ColumnMappingProfile` 已建立並加入 `NineYi.Sms.Mappers.csproj`（否則執行期會拋 `ComponentNotRegisteredException`）
- [ ] `BatchUploadTypeDefEnum` 已新增列舉值
- [ ] `GetBatchUploadExecuteTaskType()` 已新增 case
- [ ] `GetBatchUploadPermissionList()` 已新增權限項目（使用 `nameof()`）
- [ ] `Web.config` 已新增 `MaxUploadCount`

### 批次匯出
- [ ] `IBatchUploadService` 介面與實作新增匯出方法
- [ ] 功能模組 Service 有對應匯出方法與參數驗證
- [ ] API Controller 有對應路由
- [ ] `GetBatchUploadPermissionList()` 已新增權限項目（使用 `nameof()`）

### 錯誤明細（依需求）
- [ ] `ExcelService.BatchUploadTypes` 包含正確列舉值
- [ ] `GetSheetName()` 支援 TW/非TW
- [ ] **簡化模式**：直接使用匯入 Entity，不需另建 ExcelEntity（適用欄位完全一致的情境）
- [ ] **標準模式**：`ExcelEntity` 有 `Message` 欄位及 `[ExportExcel]` 屬性
- [ ] ExcelService 已加入 `NineYi.Sms.BL.Services.csproj`（DI 為自動掃描，不需手動註冊）

### 測試與專案檔
- [ ] 單元測試涵蓋正常、空資料、超筆數、必填缺失情境
- [ ] 新增檔案都已加入對應的 `.csproj`，依字母順序排列

---

## 參考程式碼位置

| 目的 | 路徑 |
|------|------|
| 基底類別 | `BusinessLogic\Services\BatchUploads\AbstractCreateBatchTaskBaseService.cs` |
| 批次匯入完整範例 | `BusinessLogic\Services\BatchUploads\BatchModifyMemberTierSalePageService.cs` |
| Excel 服務簡單範例 | `BusinessLogic\Services\BatchUploads\Excels\BatchCreateBrandTagsExcelService.cs` |
| BatchUploadService | `BusinessLogic\Services\BatchUploads\BatchUploadService.cs` |
| IBatchUploadExcelService | `BusinessLogic\Services\BatchUploads\Excels\IBatchUploadExcelService.cs` |
| BatchUploadTypeDefEnum | `BusinessLogic\BE\BatchUploads\Enums\BatchUploadTypeDefEnum.cs` |
| ColumnMappingProfile 範例 | `CrossLayer\Mappers\BatchUploads\BatchUpdateSkuPropertyNameColumnMappingProfile.cs` |
