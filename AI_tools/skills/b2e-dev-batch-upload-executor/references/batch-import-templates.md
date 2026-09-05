# 批次匯入 Code Templates

## Excel 對映 Entity 兩種模式

### 模式 A：屬性名稱與 Excel 欄位名稱相同（不需 `[ExcelColumn]`）
適用：Excel 欄位標題就是中文屬性名稱，且只有單一語系。
```csharp
using System;

namespace NineYi.Sms.BL.BE.BatchUploads
{
    /// <summary>
    /// {前端顯示名稱} Excel 資料實體
    /// </summary>
    public class {EntityClassName}
    {
        /// <summary>
        /// Error Mapping
        /// </summary>
        private const string ErrorMapping = "excelErrorMapping";

        /// <summary>
        /// Initializes a new instance of the <see cref="{EntityClassName}"/> class.
        /// </summary>
        public {EntityClassName}()
        {
            this.{屬性名稱1} = ErrorMapping;
            this.{屬性名稱2} = ErrorMapping;
            // 逐一初始化所有屬性
        }

        /// <summary>
        /// {欄位說明}（必填）
        /// </summary>
        public string {屬性名稱1} { get; set; }

        /// <summary>
        /// {欄位說明}
        /// </summary>
        public string {屬性名稱2} { get; set; }
    }
}
```

### 模式 B：欄位名稱與屬性名稱不同，需支援 TW/EN 雙語（需 `[ExcelColumn]`）
適用：Excel 欄位標題為中英文或需要明確指定對應欄位名稱。
using 來源：`NineYi.Sms.Utilities.Mappings`
```csharp
using NineYi.Sms.Utilities.Mappings;

namespace NineYi.Sms.BL.BE.BatchUploads
{
    /// <summary>
    /// {前端顯示名稱} Excel 資料實體
    /// </summary>
    public class {EntityClassName}
    {
        /// <summary>
        /// Error Mapping
        /// </summary>
        private const string ErrorMapping = "excelErrorMapping";

        /// <summary>
        /// Initializes a new instance of the <see cref="{EntityClassName}"/> class.
        /// </summary>
        public {EntityClassName}()
        {
            this.{屬性名稱1} = ErrorMapping;
            this.{屬性名稱2} = ErrorMapping;
        }

        /// <summary>
        /// {欄位說明}（必填）
        /// </summary>
        [ExcelColumn("{TW欄位標題}", "{EN欄位標題}")]
        public string {屬性名稱1} { get; set; }

        /// <summary>
        /// {欄位說明}
        /// </summary>
        [ExcelColumn("{TW欄位標題}", "{EN欄位標題}")]
        public string {屬性名稱2} { get; set; }
    }
}
```

### 模式 C：CSV 格式（需 `[ImportCsv]`）
適用：上傳格式為 CSV，且欄位對應使用索引位置。
using 來源：`NineYi.Sms.Utilities.Attributes`
```csharp
using NineYi.Sms.Utilities.Attributes;

namespace NineYi.Sms.BL.BE.BatchUploads
{
    /// <summary>
    /// {前端顯示名稱} CSV 資料實體
    /// </summary>
    public class {EntityClassName}
    {
        public {EntityClassName}()
        {
            this.{屬性名稱1} = string.Empty;
            this.{屬性名稱2} = string.Empty;
        }

        /// <summary>
        /// {欄位說明}
        /// </summary>
        [ImportCsv(ColumnIndex = 0, ColumnName = "{TW欄位名稱}", ColumnEnglishName = "{EN欄位名稱}")]
        public string {屬性名稱1} { get; set; }

        /// <summary>
        /// {欄位說明}
        /// </summary>
        [ImportCsv(ColumnIndex = 1, ColumnName = "{TW欄位名稱}", ColumnEnglishName = "{EN欄位名稱}")]
        public string {屬性名稱2} { get; set; }
    }
}
```

---

## ColumnMappingProfile 完整模板
**位置**：`CrossLayer\Mappers\BatchUploads\{功能名稱}ColumnMappingProfile.cs`

此 Profile 由 Autofac 自動掃描，無需手動注冊。若未建立，執行期會拋出 `ComponentNotRegisteredException`。

```csharp
using NineYi.Common.Utility.Upload.Mappers;
using NineYi.Sms.BL.BE.BatchUploads;
using NineYi.Sms.Utilities.Helpers;

namespace NineYi.Sms.Mappers.BatchUploads
{
    /// <summary>
    /// {功能名稱}ColumnMappingProfile
    /// </summary>
    public class {功能名稱}ColumnMappingProfile : IColumnMapping<{EntityClassName}>
    {
        #region Implementation of IColumnMapping<{EntityClassName}>
        /// <summary>
        /// MapExcelToEntity
        /// </summary>
        /// <param name="excelFile">MappingDefinition</param>
        public void MapExcelToEntity(MappingDefinition<{EntityClassName}> excelFile)
        {
            //// 語系 Hard Code
            //// 除台灣以外, 其他國家一律預設英文
            switch (SettingHelper.DefaultCountry)
            {
                case "TW":
                    excelFile.Add(a => a.{屬性1}, "{TW欄位標題1}");
                    excelFile.Add(a => a.{屬性2}, "{TW欄位標題2}");
                    //// TODO: 依欄位清單逐一加入（不需對映的欄位如計算欄位不加）
                    break;

                default:
                    excelFile.Add(a => a.{屬性1}, "{EN欄位標題1}");
                    excelFile.Add(a => a.{屬性2}, "{EN欄位標題2}");
                    //// TODO: 依欄位清單逐一加入
                    break;
            }
        }
        #endregion
    }
}
```

### ColumnMappingProfile 建立規則
- `{功能名稱}` 與 Entity / Service 命名一致
- `switch` 以 `SettingHelper.DefaultCountry` 區分 `"TW"` 與 `default`（英文）
- `excelFile.Add(lambda, "欄位標題字串")` 的欄位標題必須與 Excel 實際表頭完全一致（含全形/半形空格）
- **不需要** 對映的欄位（例如由程式計算的欄位）直接略過，不呼叫 `Add`
- 建立後須加入 `CrossLayer\Mappers\NineYi.Sms.Mappers.csproj`：
  ```xml
  <Compile Include="BatchUploads\{功能名稱}ColumnMappingProfile.cs" />
  ```


**位置**：`BusinessLogic\Services\BatchUploads\{功能名稱}Service.cs`

```csharp
using System;
using System.Collections.Generic;
using NineYi.Common.Utility.Config;
using NineYi.Common.Utility.Upload.Mappers;
using NineYi.Sms.BL.BE.BatchUploads;
using NineYi.Sms.BL.BE.BatchUploads.Enums;
using NineYi.Sms.BL.Services.Users;
using NineYi.Sms.Utilities.Helpers;
using Utility.Logging;

namespace NineYi.Sms.BL.Services.BatchUploads
{
    /// <summary>
    /// {前端顯示名稱} Service
    /// </summary>
    public class {功能名稱}Service : AbstractCreateBatchTaskBaseService
    {
        /// <summary>
        /// ILogger
        /// </summary>
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="{功能名稱}Service"/> class.
        /// </summary>
        /// <param name="batchUploadService">IBatchUploadService</param>
        /// <param name="configService">IConfigService</param>
        /// <param name="userService">IUserService</param>
        /// <param name="mappingService">IMappingService</param>
        /// <param name="logger">ILogger</param>
        public {功能名稱}Service(
            IBatchUploadService batchUploadService,
            IConfigService configService,
            IUserService userService,
            IMappingService mappingService,
            ILogger logger)
            : base(batchUploadService, configService, userService, mappingService)
        {
            this._logger = logger;
        }

        /// <summary>
        /// 取得批次上傳類型
        /// </summary>
        /// <returns>批次上傳類型</returns>
        public override BatchUploadTypeDefEnum GetBatchUploadType()
            => BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱};

        /// <summary>
        /// 驗證檔案
        /// </summary>
        public override void VerifyFile()
        {
            //// 取得工作表名稱
            var sheetName = this.GetSheetName();

            //// 讀取 Excel 資料
            var excelList = this.MappingService.LoadFromFile<{EntityClassName}>(
                this.FilePath,
                sheetName,
                typeof({EntityClassName}));

            //// 驗證資料不可為空
            if (excelList == null || excelList.Count == 0)
            {
                throw new ApplicationException("檔案中沒有資料");
            }

            //// 驗證資料筆數限制
            var maxUploadCount = this.GetMaxUploadLimit();
            if (excelList.Count > maxUploadCount)
            {
                throw new ApplicationException($"上傳筆數不可超過 {maxUploadCount} 筆");
            }

            //// 逐筆驗證資料內容
            foreach (var item in excelList)
            {
                this.ValidateRow(item);
            }

            //// 設定資料筆數
            this.RowCount = excelList.Count;
        }

        /// <summary>
        /// 取得工作表名稱（依國家語系）
        /// </summary>
        /// <returns>工作表名稱</returns>
        private string GetSheetName()
        {
            //// 根據 DefaultCountryTag 回傳對應工作表名稱
            return SettingHelper.DefaultCountry == "TW"
                ? "{TW工作表名稱}"
                : "{非TW工作表名稱}";
        }

        /// <summary>
        /// 驗證單筆資料
        /// </summary>
        /// <param name="item">Excel 資料列</param>
        private void ValidateRow({EntityClassName} item)
        {
            //// 驗證必填欄位（欄位值等於 ErrorMapping 表示 Excel 未成功對映）
            if (string.IsNullOrWhiteSpace(item.{必填屬性}) || item.{必填屬性} == "excelErrorMapping")
            {
                throw new ApplicationException("{欄位說明}不可為空");
            }

            //// TODO: 依實際需求補充數值格式、範圍等驗證
        }
    }
}
```

---

## 單元測試完整模板
**位置**：`Test\BL.Services.Test.Xunit\BatchUploads\{功能名稱}ServiceTest.cs`

```csharp
using System;
using System.Collections.Generic;
using FluentAssertions;
using NSubstitute;
using NineYi.Common.Utility.Config;
using NineYi.Common.Utility.Upload.Mappers;
using NineYi.Sms.BL.BE.BatchUploads;
using NineYi.Sms.BL.BE.BatchUploads.Enums;
using NineYi.Sms.BL.Services.BatchUploads;
using NineYi.Sms.BL.Services.Users;
using Utility.Logging;
using Xunit;

namespace NineYi.Sms.BL.Services.Test.BatchUploads
{
    /// <summary>
    /// {功能名稱}Service 單元測試
    /// </summary>
    public class {功能名稱}ServiceTest
    {
        private readonly IBatchUploadService _batchUploadService;
        private readonly IConfigService _configService;
        private readonly IUserService _userService;
        private readonly IMappingService _mappingService;
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="{功能名稱}ServiceTest"/> class.
        /// </summary>
        public {功能名稱}ServiceTest()
        {
            //// 使用 NSubstitute 建立 mock 依賴
            this._batchUploadService = Substitute.For<IBatchUploadService>();
            this._configService = Substitute.For<IConfigService>();
            this._userService = Substitute.For<IUserService>();
            this._mappingService = Substitute.For<IMappingService>();
            this._logger = Substitute.For<ILogger>();
        }

        [Fact(DisplayName = "GetBatchUploadType 應回傳正確的批次類型")]
        public void GetBatchUploadType_應回傳正確的批次類型()
        {
            //// Arrange
            var service = this.CreateService();

            //// Act
            var result = service.GetBatchUploadType();

            //// Assert
            result.Should().Be(BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱});
        }

        [Fact(DisplayName = "VerifyFile 資料為空時應拋出例外")]
        public void VerifyFile_資料為空時應拋出例外()
        {
            //// Arrange
            var service = this.CreateService();
            this._mappingService
                .LoadFromFile<{EntityClassName}>(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<Type>())
                .Returns(new List<{EntityClassName}>());

            //// Act
            Action act = () => service.VerifyFile();

            //// Assert
            act.Should().Throw<ApplicationException>()
                .WithMessage("*沒有資料*");
        }

        [Fact(DisplayName = "VerifyFile 超過最大筆數應拋出例外")]
        public void VerifyFile_超過最大筆數應拋出例外()
        {
            //// Arrange
            var maxCount = 10;
            var service = this.CreateService();
            this._configService
                .GetAppSetting(Arg.Is<string>(k => k.Contains("MaxUploadCount")))
                .Returns(maxCount.ToString());
            this._mappingService
                .LoadFromFile<{EntityClassName}>(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<Type>())
                .Returns(this.CreateTestData(maxCount + 1));

            //// Act
            Action act = () => service.VerifyFile();

            //// Assert
            act.Should().Throw<ApplicationException>()
                .WithMessage($"*{maxCount}*");
        }

        [Fact(DisplayName = "VerifyFile 正常資料應成功通過驗證")]
        public void VerifyFile_正常資料應成功通過驗證()
        {
            //// Arrange
            var service = this.CreateService();
            this._configService
                .GetAppSetting(Arg.Is<string>(k => k.Contains("MaxUploadCount")))
                .Returns("1000");
            this._mappingService
                .LoadFromFile<{EntityClassName}>(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<Type>())
                .Returns(this.CreateTestData(1));

            //// Act
            Action act = () => service.VerifyFile();

            //// Assert
            act.Should().NotThrow();
        }

        [Fact(DisplayName = "VerifyFile 必填欄位空值應拋出例外")]
        public void VerifyFile_必填欄位空值應拋出例外()
        {
            //// Arrange
            var service = this.CreateService();
            this._configService
                .GetAppSetting(Arg.Is<string>(k => k.Contains("MaxUploadCount")))
                .Returns("1000");
            var invalidData = new List<{EntityClassName}>
            {
                new {EntityClassName} { {必填屬性} = string.Empty }
            };
            this._mappingService
                .LoadFromFile<{EntityClassName}>(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<Type>())
                .Returns(invalidData);

            //// Act
            Action act = () => service.VerifyFile();

            //// Assert
            act.Should().Throw<ApplicationException>();
        }

        // -------- 私有輔助方法 --------

        private {功能名稱}Service CreateService()
        {
            return new {功能名稱}Service(
                this._batchUploadService,
                this._configService,
                this._userService,
                this._mappingService,
                this._logger);
        }

        private List<{EntityClassName}> CreateTestData(int count)
        {
            var list = new List<{EntityClassName}>();
            for (var i = 0; i < count; i++)
            {
                //// TODO: 依據必填欄位填入有效測試資料
                list.Add(new {EntityClassName}
                {
                    // {必填屬性} = "有效測試值",
                });
            }

            return list;
        }
    }
}
```
