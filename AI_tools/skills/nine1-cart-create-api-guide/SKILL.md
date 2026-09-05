---
name: nine1-cart-create-api-guide
description: 依照 Nine1.Cart 專案規範，建立正確的 API 程式碼殼（Scaffold），包含 Controller、Service 介面、Service 實作骨架、Request/Response Entity、自訂 Exception 及 ExceptionTypeEnum。當使用者說「新增一支 API」、「建立一個端點」、「幫我加一個 xx API」、「新增 xx 功能的 API」、「我要加一支 yy 的 route」時，一律使用此技能。即使使用者沒有明確說「依照規範」，只要是在 Nine1.Cart 專案下新增 API，都應使用此技能。
---

# Nine1.Cart 新增 API 指南

這個技能協助你在 Nine1.Cart 專案中，依照現有程式碼規範建立完整的 **API 程式碼殼（Scaffold）**，確保每個層次的結構正確且一致。

> ⚠️ **核心原則：此技能只負責建立程式碼殼，不實作業務邏輯。**
> - Service 方法內部展示正確的錯誤處理格式（`if` 判斷 + `throw new XxxException(...)`），但判斷條件與錯誤類型皆以 `TODO` 佔位，不補填實際邏輯
> - ExceptionTypeEnum 預設產生佔位項目展示正確格式，不根據業務情境猜測實際錯誤類型
> - 單元測試只建立方法殼與 AAA 結構，不撰寫具體的 Mock 設定或情境斷言

## 專案架構概覽

```
Nine1.Cart 專案分為以下幾層：

1. Web Layer        → Nine1.Cart.Web.Api/Controllers/
2. Service Layer    → Nine1.Cart.BL.Services/<Domain>/
3. BE Layer         → Nine1.Cart.BL.BE/
   ├── Api/Request/ → RequestEntity
   ├── Api/Response/→ ResponseEntity（如需要）
   └── CustomException/ → Exception + ExceptionTypeEnum
4. Test Layer       → Nine1.Cart.BL.Services.Test/<Domain>/
```

## 新增 API 的完整步驟

依照以下順序逐步建立檔案，不可跳過任何步驟。

---

### Step 1：釐清需求

> ⚠️ **強制規則：在所有必要資訊都確認完畢之前，絕對不可以開始撰寫任何程式碼或進行 Step 2 以後的步驟。**
> 若有任何一項資訊尚未確認，必須先向使用者提問並等待回覆，不得自行假設或補填預設值。

逐一確認以下 8 項資訊。

1. **API 名稱**：這支 API 要做什麼事？（例如：取得購物車、設定配送地址）
2. **所屬 Controller**：要加在哪個 Controller？（CartsController、CheckoutController 等，或需要新建）
3. **Route 路徑**：HTTP 路由（例如：`shipping-set`）
4. **HTTP Method**：POST 或 GET？（本專案大多使用 POST）
5. **Request 欄位**：需要哪些輸入參數？（欄位名稱與型別；`MemberId`、`UnloginId`、`MallId` 已由基底類別提供，不需重複定義）
6. **Response 資料**：回傳什麼資料？（若無特定資料則回傳 `object`）
7. **所屬 Service**：要呼叫哪個 Service？（或需要新建）
8. **跨 API 呼叫**：是否有其他 API 會主動呼叫這支新建的 API？若有，請說明是哪支 API 及呼叫情境。

**當上述 8 項資訊全部確認後，才可進行 Step 2。**

---

### Step 2：建立 RequestEntity

**路徑**：`src/BusinessLogic/Nine1.Cart.BL.BE/Api/Request/<ActionName>RequestEntity.cs`

**規範**：
- 類別名稱必須以 `Entity` 結尾（DTO 命名規範）
- 繼承 `Nine1CartServiceRequestBase`（已包含 `MemberId`、`UnloginId`、`MallId` 等基底欄位）
- 若不需要額外欄位，仍需建立獨立的 RequestEntity 類別
- 加上 `/// <summary>` XML 文件

**範例**：
```csharp
namespace Nine1.Cart.BL.BE.Api.Request;

/// <summary>
/// 設定配送方式的 RequestEntity
/// </summary>
public class ShippingSetRequestEntity : Nine1CartServiceRequestBase
{
    /// <summary>
    /// 購物車識別碼
    /// </summary>
    public string CartUniqueKey { get; set; }

    /// <summary>
    /// 配送方式代碼
    /// </summary>
    public int ShippingTypeId { get; set; }
}
```

---

### Step 3：建立 ResponseEntity（視需要）

**路徑**：`src/BusinessLogic/Nine1.Cart.BL.BE/Api/Response/<ActionName>ResponseEntity.cs`

**規範**：
- 類別名稱必須以 `Entity` 結尾
- 若 API 無需回傳特定資料（使用 `ApiResponseEntity<object>`），可省略此步驟
- 加上 `/// <summary>` XML 文件

**範例**：
```csharp
namespace Nine1.Cart.BL.BE.Api.Response;

/// <summary>
/// 設定配送方式的 ResponseEntity
/// </summary>
public class ShippingSetResponseEntity
{
    /// <summary>
    /// 是否設定成功
    /// </summary>
    public bool Success { get; set; }
}
```

---

### Step 4：建立 ExceptionTypeEnum

**路徑**：`src/BusinessLogic/Nine1.Cart.BL.BE/CustomException/<ActionName>ExceptionTypeEnum.cs`

**規範**：
- 列舉名稱格式：`<ActionName>ExceptionTypeEnum`
- 每個列舉值必須加上 `[ErrorHandling("錯誤訊息說明")]` Attribute
- 加上 `/// <summary>` XML 文件
- **預設產生兩個佔位項目（`ErrorCase1`、`ErrorCase2`）展示正確格式，開發者依業務需求自行替換名稱與訊息；不根據業務情境猜測實際錯誤類型**

**範例**：
```csharp
using Nine1.Cart.Common.Utils.Attribute;

namespace Nine1.Cart.BL.BE.CustomException;

/// <summary>
/// 設定配送方式的錯誤類型
/// </summary>
public enum ShippingSetExceptionTypeEnum
{
    /// <summary>
    /// TODO: 替換為實際錯誤說明
    /// </summary>
    [ErrorHandling("TODO: 替換為實際錯誤訊息")]
    ErrorCase1,

    /// <summary>
    /// TODO: 替換為實際錯誤說明
    /// </summary>
    [ErrorHandling("TODO: 替換為實際錯誤訊息")]
    ErrorCase2,
}
```

---

### Step 5：建立 Exception 類別

**路徑**：`src/BusinessLogic/Nine1.Cart.BL.BE/CustomException/<ActionName>Exception.cs`

**規範**：
- 繼承 `CustomException<TExceptionTypeEnum>`
- 建構子參數：`createExceptionType`、`message = ""`、`data = null`
- 加上 `/// <summary>` XML 文件

**範例**：
```csharp
using Nine1.Cart.Common.Utils.Extension;

namespace Nine1.Cart.BL.BE.CustomException;

/// <summary>
/// 設定配送方式的例外
/// </summary>
public class ShippingSetException : CustomException<ShippingSetExceptionTypeEnum>
{
    /// <summary>
    /// Initializes a new instance of the <see cref="ShippingSetException" /> class.
    /// </summary>
    /// <param name="createExceptionType">錯誤類型</param>
    /// <param name="message">錯誤訊息</param>
    /// <param name="data">附加資料</param>
    public ShippingSetException(ShippingSetExceptionTypeEnum createExceptionType,
                                string message = "",
                                object? data = null)
        : base(createExceptionType, message, data)
    {
    }
}
```

---

### Step 6：在 IService 介面新增方法

**路徑**：`src/BusinessLogic/Nine1.Cart.BL.Services/<Domain>/I<ServiceName>.cs`

**規範**：
- 方法名稱以 `Async` 結尾
- 回傳 `Task` 或 `Task<T>`
- 加上完整的 XML 文件（`<summary>`、`<param>`、`<returns>`、`<exception>`）

**範例（在既有介面新增方法）**：
```csharp
/// <summary>
/// 設定配送方式
/// </summary>
/// <param name="requestEntity">設定配送方式請求</param>
/// <returns>無</returns>
/// <exception cref="ShippingSetException">設定配送方式失敗</exception>
Task ShippingSetAsync(ShippingSetRequestEntity requestEntity);
```

---

#### 若 Service 為全新建立

若 Step 1 確認需要**新建 Service**，則需額外建立以下兩個檔案：

**介面路徑**：`src/BusinessLogic/Nine1.Cart.BL.Services/<Domain>/I<ServiceName>.cs`

```csharp
namespace Nine1.Cart.BL.Services.<Domain>;

/// <summary>
/// TODO: 描述此 Service 的職責
/// </summary>
public interface I<ServiceName>
{
    /// <summary>
    /// 設定配送方式
    /// </summary>
    /// <param name="requestEntity">設定配送方式請求</param>
    /// <returns>無</returns>
    /// <exception cref="ShippingSetException">設定配送方式失敗</exception>
    Task ShippingSetAsync(ShippingSetRequestEntity requestEntity);
}
```

**實作路徑**：`src/BusinessLogic/Nine1.Cart.BL.Services/<Domain>/<ServiceName>.cs`

> 規範：
> - 類別宣告繼承介面：`public class <ServiceName> : I<ServiceName>`
> - 所有相依以 `private readonly` 欄位持有，透過建構子注入
> - 每個欄位加上 `/// <summary>` XML 文件
> - 建構子加上完整 XML 文件（`<summary>`、`<param>`）

```csharp
using Microsoft.Extensions.Logging;

namespace Nine1.Cart.BL.Services.<Domain>;

/// <summary>
/// TODO: 描述此 Service 的職責
/// </summary>
public class <ServiceName> : I<ServiceName>
{
    /// <summary>
    /// ILogger
    /// </summary>
    private readonly ILogger<<ServiceName>> _logger;

    //// TODO: 依實際需求加入其他注入的相依介面欄位

    /// <summary>
    /// Initializes a new instance of the <see cref="<ServiceName>" /> class.
    /// </summary>
    /// <param name="logger">ILogger</param>
    public <ServiceName>(ILogger<<ServiceName>> logger)
    {
        _logger = logger;
        //// TODO: 依實際需求加入其他相依初始化
    }

    //// TODO: 實作介面方法（參考 Step 7）
}
```

> ⚠️ **新建 Service 後必須在 DI 容器中完成註冊**，通常在 `Nine1.Cart.Web.Api` 的 `Program.cs` 或對應的 `ServiceCollectionExtensions` 中加入：
> ```csharp
> services.AddScoped<I<ServiceName>, <ServiceName>>();
> ```

---

### Step 7：在 Service 實作方法

**路徑**：`src/BusinessLogic/Nine1.Cart.BL.Services/<Domain>/<ServiceName>.cs`

**規範**：
- 實作 IService 中新增的方法簽章
- 方法內部展示**正確的錯誤處理格式**（`if` 判斷 + `throw new XxxException(...)`），但判斷條件與錯誤類型皆以 `TODO` 佔位，不根據業務情境補填實際邏輯
- 使用 `////` 作為方法內部的行內說明
- 使用 `== false` 取代 `!` 做布林判斷

**範例**：
```csharp
/// <summary>
/// 設定配送方式
/// </summary>
/// <param name="requestEntity">設定配送方式請求</param>
/// <returns>Task</returns>
public async Task ShippingSetAsync(ShippingSetRequestEntity requestEntity)
{
    //// TODO: 實作業務邏輯，以下為錯誤處理格式範本，請依需求替換

    //// 範例：條件驗證失敗時拋出自訂例外
    var isValid = false; //// TODO: 替換為實際驗證條件
    if (isValid == false)
    {
        throw new ShippingSetException(ShippingSetExceptionTypeEnum.ErrorCase1, "TODO: 替換為錯誤訊息");
    }

    await Task.CompletedTask; //// TODO: 替換為實際非同步操作
}
```

---

### Step 8：在 Controller 新增 Action

**路徑**：`src/Web/Nine1.Cart.Web.Api/Controllers/<ControllerName>.cs`

**規範**：
- 使用 `[HttpPost]` 或 `[HttpGet]`
- 使用 `[Route("route-name")]`，路由命名使用 kebab-case（小寫 + 連字號）
- 回傳型別使用 `ActionResult<ApiResponseEntity<T>>`
- 成功時用 `ApiResponseEntity<T>.Create("成功訊息", data)`
- 失敗時呼叫 `BadRequestInner(ex)`（Controller 內既有的 private 方法）
- 加上完整 XML 文件（`<summary>`、`<param>`、`<returns>`、`<remarks>`）
- `<remarks>` 中記錄所需的 Scope（若有）

#### CartsController vs CheckoutController 差異

| 比較項目 | `CartsController`（`api/carts`） | `CheckoutController`（`api/checkouts`） |
|---|---|---|
| **職責** | 購物車組成：商品新增、刪除、數量調整、促銷設定 | 結帳流程：配送、付款、發票、收件人設定，最終建立訂單 |
| **使用時機** | 下單**前**操作 | 進入結帳**中**操作 |
| **回傳格式** | 統一使用 `ApiResponseEntity<T>.Create(...)` | 混用 `ApiResponseEntity<T>.Create(...)` 與 `Ok(new ApiResponseEntity<T>{...})` |
| **輸入驗證** | 無獨立驗證層，僅靠 `try-catch` 攔截自訂例外 | 多支 API 透過 `[FromServices] IValidator<T>` 注入 FluentValidation，驗證失敗提前回傳 |
| **`BadRequestInner` 特殊處理** | `CartCacheExpired`、`PromotionExpired` → `LogWarning` | 額外處理 `ShoppingCartProcessExpired`、`TradesOrderInvalidTotalPaymentException_InconsistenceCurrencyRate` |

> ⚠️ **新增 API 時的選擇原則**：
> - 若功能屬於**購物車內容操作**（商品、優惠、點數等）→ 加入 `CartsController`，回傳一律用 `ApiResponseEntity<T>.Create(...)`
> - 若功能屬於**結帳流程設定**（配送、付款、發票、收件人等）→ 加入 `CheckoutController`，若有複雜輸入驗證需透過 `[FromServices] IValidator<T>` 注入 FluentValidation

**範例**：
```csharp
/// <summary>
/// 設定配送方式
/// </summary>
/// <param name="requestEntity">設定配送方式請求</param>
/// <returns>無</returns>
/// <remarks>
/// Scope: "carts.user:write"
/// </remarks>
[HttpPost]
[Route("shipping-set")]
public async Task<ActionResult<ApiResponseEntity<object>>> ShippingSet(ShippingSetRequestEntity requestEntity)
{
    try
    {
        await _cartService.ShippingSetAsync(requestEntity);

        return ApiResponseEntity<object>.Create("設定配送方式成功");
    }
    catch (ShippingSetException ex)
    {
        return BadRequestInner(ex);
    }
}
```

---

### Step 9：建立單元測試

**路徑**：`src/Test/Nine1.Cart.BL.Services.Test/<Domain>/<ServiceName>Test.cs`

**規範**：
- 測試類別繼承既有的 Test 類別結構
- 測試方法命名：`<MethodName>_<情境說明>`（例如：`ShippingSetAsync_ShouldThrowException_WhenCartNotFound`）
- 使用 AAA 模式（Arrange / Act / Assert），以 `////` 加上區塊標示
- 使用 `NSubstitute` 建立 Mock
- 使用 `FluentAssertions` 進行斷言
- 使用 `[Fact]` 標記測試方法
- **只建立測試方法殼與 AAA 區塊結構，Arrange / Act / Assert 內部留 `TODO` 等待開發者填入，不根據業務情境假設 Mock 設定或斷言內容**

#### 測試類別骨架（含 `GetService()` 模式）

```csharp
using FluentAssertions;
using NSubstitute;
using Xunit;

namespace Nine1.Cart.BL.Services.Test.<Domain>;

/// <summary>
/// <ServiceName> 單元測試
/// </summary>
public class <ServiceName>Test
{
    //// TODO: 依 Service 建構子的實際相依，宣告對應的 Mock 欄位
    //// 範例：
    //// private readonly ISomeDependency _someDependency;

    /// <summary>
    /// Initializes a new instance of the <see cref="<ServiceName>Test" /> class.
    /// </summary>
    public <ServiceName>Test()
    {
        //// TODO: 初始化 Mock 欄位
        //// 範例：
        //// this._someDependency = Substitute.For<ISomeDependency>();
    }

    /// <summary>
    /// 取得受測 Service 實體
    /// </summary>
    /// <returns>I<ServiceName></returns>
    private I<ServiceName> GetService()
    {
        //// TODO: 傳入與建構子相符的相依參數
        return new <ServiceName>(/* this._someDependency */);
    }

    [Fact]
    public async Task ShippingSetAsync_ShouldSucceed_WhenValid()
    {
        //// Arrange
        //// TODO: 準備測試資料與 Mock 設定
        var sut = this.GetService();

        //// Act
        //// TODO: 呼叫 sut 方法

        //// Assert
        //// TODO: 驗證預期結果

        await Task.CompletedTask; //// 避免 CS1998 警告，實作後請移除
    }
}
```

---

## 完整清單（Checklist）

完成後逐一確認以下項目：

- [ ] `<ActionName>RequestEntity.cs` 已建立，繼承 `Nine1CartServiceRequestBase`，類別名稱以 `Entity` 結尾
- [ ] `<ActionName>ResponseEntity.cs` 已建立（若有回傳資料）
- [ ] `<ActionName>ExceptionTypeEnum.cs` 已建立，含 `[ErrorHandling]` Attribute，以佔位項目展示正確格式
- [ ] `<ActionName>Exception.cs` 已建立，繼承 `CustomException<TEnum>`
- [ ] `I<ServiceName>.cs` 已新增方法宣告，含完整 XML 文件
- [ ] `<ServiceName>.cs` 已新增方法殼，包含正確的錯誤處理格式範本（條件 + `throw new XxxException`），業務內容以 `TODO` 佔位
- [ ] `<ControllerName>.cs` 已新增 Action 殼，使用 `BadRequestInner` 處理例外
- [ ] 單元測試方法殼已建立，包含 AAA 區塊與 `TODO` 佔位
- [ ] 所有公開類別與方法都有 `/// <summary>` XML 文件
- [ ] 每個檔案只有一個類別

## 注意事項

- **只建立程式碼殼**：提供正確的錯誤處理格式與結構，但業務情境內容（判斷條件、錯誤類型名稱、訊息）一律以 `TODO` 佔位，不猜測或補填
- **DTO 命名**：所有 Request/Response 類別名稱必須以 `Entity` 結尾
- **一個檔案一個類別**：禁止在同一個 `.cs` 檔中放多個公開類別
- **行內說明**：方法內部邏輯說明使用 `////`（四個斜線），API 文件使用 `///`（三個斜線）
- **布林比較**：一律用 `== false`，不用 `!`
- **例外處理**：Controller 只 catch 對應的自訂 Exception，不 catch `Exception`
- **相依性注入**：Service 的依賴透過建構子注入，不在方法內 `new` 物件
