# 批次匯出 Code Templates

## 匯出條件 Entity
**位置**：`BusinessLogic\BE\{功能模組}\{功能名稱}ExportEntity.cs`

```csharp
namespace NineYi.Sms.BL.BE.{Namespace}
{
    /// <summary>
    /// {前端顯示名稱}匯出條件
    /// </summary>
    public class {功能名稱}ExportEntity
    {
        /// <summary>
        /// {欄位說明}
        /// </summary>
        public {型別} {屬性名稱} { get; set; }

        // 依實際需求新增匯出條件欄位
    }
}
```

---

## IBatchUploadService 介面方法宣告
**位置**：`BusinessLogic\Services\BatchUploads\BatchUploadService.cs`（介面區段）

```csharp
/// <summary>
/// 建立{前端顯示名稱}任務
/// </summary>
/// <param name="exportCondition">匯出條件</param>
/// <returns>批次作業代碼</returns>
string Create{功能名稱}Task({功能名稱}ExportEntity exportCondition);
```

## BatchUploadService 實作方法
在 `BatchUploadService` 類別中新增（參考同檔案內現有的 Export 方法）：

```csharp
/// <summary>
/// 建立{前端顯示名稱}任務
/// </summary>
/// <param name="exportCondition">匯出條件</param>
/// <returns>批次作業代碼</returns>
public string Create{功能名稱}Task({功能名稱}ExportEntity exportCondition)
{
    //// 取得當前使用者
    var currentUser = this._userService.GetCurrentUser();

    //// 取得執行任務類型
    var executeTaskType = this.GetBatchUploadExecuteTaskType(
        BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱});

    //// 序列化匯出條件
    var conditionJson = Newtonsoft.Json.JsonConvert.SerializeObject(exportCondition);

    //// 建立批次 NMQ 任務
    var batchUploadCode = this.CreateBatchUploadNMQTask(
        BatchUploadTypeDefEnum.{BatchUploadTypeDefEnum名稱},
        executeTaskType,
        currentUser,
        conditionJson);

    return batchUploadCode;
}
```

---

## 功能模組 Service 介面宣告

```csharp
/// <summary>
/// 建立{前端顯示名稱}任務
/// </summary>
/// <param name="{參數名稱}">{參數說明}</param>
/// <returns>批次作業代碼</returns>
string Create{功能名稱}Task({參數型別} {參數名稱});
```

## 功能模組 Service 實作
**位置**：`BusinessLogic\Services\{功能模組}\{功能模組}Service.cs`

```csharp
/// <summary>
/// 建立{前端顯示名稱}任務
/// </summary>
/// <param name="{參數名稱}">{參數說明}</param>
/// <returns>批次作業代碼</returns>
public string Create{功能名稱}Task({參數型別} {參數名稱})
{
    //// 驗證輸入參數
    if ({驗證條件})
    {
        throw new ArgumentException("{驗證失敗說明}");
    }

    this._logger.Info($"建立{前端顯示名稱}任務，{參數名稱}：{{參數名稱}}");

    //// 組裝匯出條件
    var exportCondition = new {功能名稱}ExportEntity
    {
        {屬性名稱} = {參數名稱},
    };

    //// 呼叫 BatchUploadService 建立任務
    return this._batchUploadService.Create{功能名稱}Task(exportCondition);
}
```

---

## API Controller 方法
**位置**：`WebSite\WebSite\Controllers\{功能模組}Controller.cs`

```csharp
/// <summary>
/// 建立{前端顯示名稱}任務
/// </summary>
/// <param name="request">請求參數</param>
/// <returns>批次作業代碼</returns>
[HttpPost]
[Route("Api/{功能模組}/Export{功能名稱}")]
public IHttpActionResult Export{功能名稱}({功能名稱}ExportEntity request)
{
    try
    {
        //// 呼叫 Service 建立匯出任務
        var batchUploadCode = this._{功能模組}Service.Create{功能名稱}Task(request);
        return this.Ok(batchUploadCode);
    }
    catch (ArgumentException ex)
    {
        return this.BadRequest(ex.Message);
    }
}
```

---

## 批次匯出單元測試
**位置**：`Test\BL.Services.Test.Xunit\{功能模組}\{功能模組}ServiceExportTest.cs`

```csharp
using FluentAssertions;
using NSubstitute;
using NineYi.Sms.BL.BE.{Namespace};
using NineYi.Sms.BL.Services.BatchUploads;
using NineYi.Sms.BL.Services.{功能模組};
using Utility.Logging;
using Xunit;

namespace NineYi.Sms.BL.Services.Test.{功能模組}
{
    /// <summary>
    /// {功能模組}Service 匯出功能單元測試
    /// </summary>
    public class {功能模組}ServiceExportTest
    {
        private readonly IBatchUploadService _batchUploadService;
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="{功能模組}ServiceExportTest"/> class.
        /// </summary>
        public {功能模組}ServiceExportTest()
        {
            //// 使用 NSubstitute 建立 mock 依賴
            this._batchUploadService = Substitute.For<IBatchUploadService>();
            this._logger = Substitute.For<ILogger>();
        }

        [Fact(DisplayName = "Create{功能名稱}Task 正常條件應成功建立任務")]
        public void Create{功能名稱}Task_正常條件應成功建立任務()
        {
            //// Arrange
            var expectedCode = "BATCH_CODE_001";
            this._batchUploadService
                .Create{功能名稱}Task(Arg.Any<{功能名稱}ExportEntity>())
                .Returns(expectedCode);
            var service = this.CreateService();

            //// Act
            var result = service.Create{功能名稱}Task({有效參數});

            //// Assert
            result.Should().Be(expectedCode);
        }

        [Fact(DisplayName = "Create{功能名稱}Task 無效參數應拋出例外")]
        public void Create{功能名稱}Task_無效參數應拋出例外()
        {
            //// Arrange
            var service = this.CreateService();

            //// Act
            Action act = () => service.Create{功能名稱}Task({無效參數});

            //// Assert
            act.Should().Throw<ArgumentException>();
        }

        // -------- 私有輔助方法 --------

        private {功能模組}Service CreateService()
        {
            return new {功能模組}Service(
                this._batchUploadService,
                this._logger);
        }
    }
}
```
