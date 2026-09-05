---
name: nine1-shopping-create-api-guide
description: 九易（Nine1）Shopping 站台 Web API 在新增一支 API（新增 endpoint / 新增 Controller action / 新增 Controller）或修改既有 action 的回傳格式、exception 處理時必須遵循的規範與產出指引，涵蓋 path（Route）、驗證（Authorize / schemes）、log、exception 格式、request/response 格式與 DTO 命名。只要使用者提到「新增一支 API」、「新增 endpoint」、「新增 Controller」、「新增 action」、「要加路由/Route」、「要加驗證/Authorize」、「要加 log」、「要加 exception handling」、「request/response 格式」、「修改 action 回傳」、「調整 exception 處理」，或需求明顯是在 `c:\91APP\nine1.shopping` 加 API / 改 API，就務必觸發並遵循此 skill；就算使用者沒有明講要照規範，也要主動套用。
allowed-tools:
  - read_file
  - grep_search
  - semantic_search
  - list_dir
  - list_code_usages
  - get_errors
  - insert_edit_into_file
  - replace_string_in_file
  - create_file
  - create_directory
  - runTests
---

# nine1-shopping-create-api-guide

## 目的（Overview）

協助在 `c:\91APP\nine1.shopping`（.NET 8）新增/擴充 Web API 時，產出的 Controller / DTO / exception / log / response 格式與專案既有模式一致，降低 review 成本與線上風險。

## Repo 既有 API 的共同點（必讀）

在 `src/Web/Nine1.Shopping.Web.Api/Controllers/` 多數 API 有以下共同模式（以 `CartsController` / `CheckoutController` 為代表）：

1. **Controller 基本標記**
   - `[ApiController]`
   - `[Route("api/<resource>")]`（原則上一個 Controller 只需一個 `[Route]`；`CheckoutController` 同時標了 `api/checkout` 與 `api/checkouts` 是歷史相容需求，新 Controller 不要仿照）
   - `[OpenApiTag("<tag>", Description = "...")]`
   - **必須繼承 `ControllerBase`**（`ShippingController` 未繼承是歷史遺留，不應仿照）

2. **action 欄位與註解**
   - `///` XML 註解（繁體中文）
   - `/// <remarks>` 常見包含：`Scope: "shopping.<domain>.<role>:<read|write>"`

3. **回傳格式**
   - success：一律使用 `ApiResponseEntity<T>.Create(data: data)` 靜態方法（有些 action 會帶 message：`ApiResponseEntity<T>.Create("訊息", data)`）
   - **不要**用 `new ApiResponseEntity<T> { Code = "Success", ... }` 手動建構（`CheckoutController.SetPay` 等處的寫法為歷史遺留）
   - `ApiResponseEntity<T>.Create(...)` 內部已自動設定 `Code = "Success"`

4. **log / 稽核（常見且強烈建議對齊）**
   - 常見 log `N1-ENV`（有些 action 使用 `_requestDataRetriever.Env`，也有使用 `Request.Headers["N1-ENV"]`）
   - 多數購物車/結帳流程 action 會呼叫：
     - `this.CheckoutHistoryLogInfo(_requestDataRetriever.ShopId, _requestDataRetriever.MemberId, "<route>", "<function>");`
   - `route` 參數通常是**實際對外 path**（例如 `/api/carts/gift-update-qty`）
   - `function` 參數用**繁體中文動作描述**（例如 `更新購物車贈品`）
   - ⚠️ **`CheckoutHistoryLogInfo` 是各 Controller 內的 private method，不是 extension method**。新增 Controller 時必須在 Controller 內自行定義此 private method，可從 `CartsController.cs` 複製：
     ```csharp
     /// <summary>
     /// 印出消費歷程log
     /// </summary>
     private void CheckoutHistoryLogInfo(long shopId, int memberId, string route, string function)
     {
         _logger.LogInformation($"CheckoutHistory_ShopId:{shopId}, MemberId:{memberId}, {route}, {function}");
     }
     ```

5. **錯誤處理**
   - action 內使用 `try/catch`
   - catch 目標以 domain exception 為主（例如 `CartCreateException`, `ExceededTimesLimiterException`...）
   - 使用私有 helper：`BadRequestInner(ex, _requestDataRetriever.ShopId, _requestDataRetriever.MemberId)`
   - `BadRequestInner` 會做結構化 log（ShopId / Code / Message / MemberId）並回傳 `exception.ExtractErrorResponse()`
   - ⚠️ **`BadRequestInner` 同樣是各 Controller 內的 private method**。新增 Controller 時必須在 Controller 內自行定義，可從 `CartsController.cs` 複製：
     ```csharp
     /// <summary>
     /// 錯誤訊息回傳的中繼處理Method => 加Log用的
     /// </summary>
     private BadRequestObjectResult BadRequestInner<T>(CustomException<T> exception, long shopId = 0, int memberId = 0)
         where T : Enum
     {
         _logger.LogError("Api發生錯誤，ShopId:{ShopId}, Code:{Code}, Message:{Message}, MemberId:{MemberId}",
                          shopId,
                          exception.ExceptionType.ToString(),
                          exception.Message,
                          memberId);
         return BadRequest(exception.ExtractErrorResponse());
     }
     ```

6. **`ProducesResponseType` 標記**
   - 新 API **建議**加上 `[ProducesResponseType(typeof(ApiResponseEntity<T>), 200)]` 和 `[ProducesResponseType(typeof(ApiErrorResponseExtendsEntity<object>), 400)]` 以改善 Swagger 文件品質
   - 400 的錯誤型別統一使用 `ApiErrorResponseExtendsEntity<object>`（繼承自 `Nine1.BaseSDK` 的 `ApiErrorResponseEntity<T>`）；`SettingController` 使用的 `ApiErrorResponseEntity<object>` 為舊版型別，新 API 不應使用
   - 既有 Controller 並非全部 action 都有加 `ProducesResponseType`，但新增 API 時建議補上

7. **`ResponseCache` 標記**
   - 若 GET action 回傳的資料不適合快取（例如購物車內容、會員相關資料），應加上 `[ResponseCache(Location = ResponseCacheLocation.None, NoStore = true)]`

> 決策點：如果新增的 API 屬於「購物車 / 結帳 / 金流 / 促購」主流程，預設要帶 `CheckoutHistoryLogInfo`；若是純查詢或系統狀態類，至少要維持 error log 與必要的資訊 log。

## ⚠️ 既有 Controller 已知的不一致（不應參考的反模式）

以下為專案中已知的歷史遺留寫法，**新 API 不應仿照**：

1. **`SettingController.cs`**：使用 `catch (Exception ex)` + 手動建構 `ApiErrorResponseEntity<object>` + `StatusCode(400, ...)`，不符合 domain exception + `BadRequestInner(...)` 的標準模式
2. **`ShippingController.cs`**：未繼承 `ControllerBase`，且無 try/catch、無 log
3. **`CheckoutController.SetPay` / `SetPayPromotion`**：使用 `new ApiResponseEntity<T> { Code = "Success", ... }` 手動建構，應改用 `ApiResponseEntity<T>.Create(...)`
4. **`CheckoutController`**：同時標了兩個 `[Route]`（`api/checkout` 與 `api/checkouts`），新 Controller 原則上只需一個
5. **`PaymentController`**：部分 action 缺少 try/catch 和 log，不適合作為主流程 API 的參考範本

## Preconditions（前置條件 / 必要輸入）

在開始改檔前，先確認以下資訊是否齊全；若缺少就先發問、不要猜：

1. **API 類型**：新增 Controller？還是既有 Controller 新增 action？
2. **HTTP 定義**：method、path（`api/...`）、route param、query、body
3. **授權/驗證**：是否需要 `[Authorize]`？若需要，scope/權限慣例是什麼（若專案採用）？
4. **身分資料來源**：ShopId / MemberId 是否都要？是否來自 `IRequestDataRetriever`？是否依 header 切換 scheme？
5. **request/response DTO**：
   - request / response 的欄位（最少：必要欄位、型別、是否可空）
   - DTO 是否已存在？若不存在，要新增哪些 `*Entity`？
6. **錯誤情境**：預期會拋哪些 domain exception？是否已有既有 exception 型別可用？
7. **log/稽核**：是否需要 `CheckoutHistoryLogInfo`？`route` 與 `function` 字串要填什麼？是否涉及敏感資料需遮罩？
8. **測試**：是否需要單元測試（xUnit + NSubstitute）？若不需要，原因是什麼？

## Workflow Steps（建立一支 API 的標準流程）

你必須依序執行：

1. **找既有範例並對齊模式（必做）**
   - 從 `src/Web/Nine1.Shopping.Web.Api/Controllers/` 找到相似的 Controller/action 作為參考
   - 依場景選擇參考範本：
     - **購物車/結帳主流程**（必須 log + CheckoutHistory + BadRequestInner）：`CartsController.cs`、`CheckoutController.cs`
     - **促購相關**：`PromotionRuleController.cs`
     - **純查詢/輔助服務**（至少 error log）：`LocationController.cs`
   - ⛔ **不建議參考**（模式不一致或有歷史遺留）：
     - `SettingController.cs`（`catch (Exception)` + 手動 `ApiErrorResponseEntity`）
     - `PaymentController.cs`（部分 action 缺 try/catch 和 log）
     - `ShippingController.cs`（未繼承 `ControllerBase`）
   - 優先比對：Route、`OpenApiTag`、`[Authorize]`、`Scope` remarks、回傳 `ApiResponseEntity<T>`、`CheckoutHistoryLogInfo`、`BadRequestInner(...)`

2. **定義 DTO 與回傳結構**
   - request/response DTO 類別名稱一律以 `Entity` 結尾
   - success 回傳一律使用 `ApiResponseEntity<T>.Create(data: data)` 靜態方法（必要時加 message，對齊同類型 API）
   - **不要**用 `new ApiResponseEntity<T> { ... }` 手動建構

3. **落實 log / 稽核 / exception handling**
   - action 內要有 `try/catch`
   - 在 try 區塊依序：
     - log `N1-ENV`（優先使用 `_requestDataRetriever.Env`；若需求指定 header，讀 `Request.Headers["N1-ENV"]`）
     - （主流程預設）呼叫 `CheckoutHistoryLogInfo(shopId, memberId, "<route>", "<function>")`
     - 呼叫 service
     - 回傳 `ApiResponseEntity<T>.Create(...)`
   - catch domain exception（列出具體 exception 型別，避免 `catch (Exception)`）→ `BadRequestInner(...)`

4. **完成後自我檢查 + 編譯錯誤檢查**
   - 檢視新增/修改檔案是否有編譯錯誤
   - 若有單元測試需求，新增或更新測試

## Action 範本（貼上後再依需求調整）

> 注意：這是結構範本，實際 exception 型別、route/function/scope、request/response 都要依需求與既有 API 調整。

- `remarks`：請填 scope（若該領域 Controller 有 scope 慣例）
- `CheckoutHistoryLogInfo`：若屬主流程請必加，並使用實際 path（含 `/api/...`）

```csharp
/// <summary>
/// <功能描述：繁體中文>
/// </summary>
/// <param name="requestEntity">...</param>
/// <returns>...</returns>
/// <remarks>
/// Scope: "shopping.<domain>.<role>:<read|write>"
/// </remarks>
[HttpPost]
[Route("<action>")]
[Authorize]
[ProducesResponseType(typeof(ApiResponseEntity<<ResponseEntity>>), 200)]
[ProducesResponseType(typeof(ApiErrorResponseExtendsEntity<object>), 400)]
public async Task<ActionResult<ApiResponseEntity<<ResponseEntity>>>> <ActionName>(<RequestEntity> requestEntity)
{
    try
    {
        //// 記錄環境，協助追查
        _logger.LogInformation($"Request.Headers[N1-ENV]:{_requestDataRetriever.Env}");

        //// 主流程 API：記錄 CheckoutHistory（route 請填實際 path）
        this.CheckoutHistoryLogInfo(_requestDataRetriever.ShopId, _requestDataRetriever.MemberId, "/api/<resource>/<action>", "<功能描述：繁體中文>");

        //// 呼叫服務層處理商業邏輯
        var data = await _service.<MethodAsync>(requestEntity);

        //// 回傳標準格式
        return ApiResponseEntity<<ResponseEntity>>.Create(data: data);
    }
    catch (<DomainException1> ex)
    {
        return BadRequestInner(ex, _requestDataRetriever.ShopId, _requestDataRetriever.MemberId);
    }
    catch (<DomainException2> ex)
    {
        return BadRequestInner(ex, _requestDataRetriever.ShopId, _requestDataRetriever.MemberId);
    }
}
```

## Hard Constraints（硬限制：違反就視為未完成）

- 所有 **public** 類別/方法/屬性：必須有 `///` XML 註解（繁體中文）
- 方法本體每個主要邏輯區塊：至少一個 `////` inline 註解（這是新 API 的標準，既有 action 尚未全面補上，但新增的程式碼必須遵守）
- boolean 判斷：一律用 `x == false`，不要用 `!x`
- 一個檔案只放一個類別（必要時用 nested class）
- DTO 類別名稱必須以 `Entity` 結尾
- 不要在類別內直接 `new` 依賴，使用 constructor 相依性注入
- 新增 Controller 必須繼承 `ControllerBase`
- success 回傳一律使用 `ApiResponseEntity<T>.Create(...)` 靜態方法，不要用 `new ApiResponseEntity<T> { ... }` 手動建構
- 400 錯誤回應型別統一使用 `ApiErrorResponseExtendsEntity<object>`，不要使用舊版 `ApiErrorResponseEntity<object>`

## Auth / Headers 慣例（內嵌）

### 何時加 `[Authorize]`

- 需要會員身分/授權才可存取的 endpoint
- 注意：在 shopping 專案中，即使 action 有 `[Authorize]`，仍可能因為 Cookie validator allowlist（例如 P1GuestAllowlist / UnloginAllowlist）而允許「訪客」通過；新增 API 若要支援訪客，除了 `[Authorize]` 決策外，也要同步確認環境設定 allowlist。

### authentication scheme

- 專案使用 multi scheme（cookie / partner api）
- `MultiAuthSchemes` 會依 header `N1InternalMemberId` 決定使用 `NineYiCookies` 或 `PartnerApi`

### Scope

- 若 Controller action 有定義 scope 慣例，可在 XML remarks 標註（常見：`Scope: "shopping.<domain>.<role>:<read|write>"`）

### Header

- 常見：`N1-ENV`（常被 log，常見來源：`_requestDataRetriever.Env` 或 `Request.Headers["N1-ENV"]`）
- internal member id：查 `RequestDataNameDefinition.Header`（常見：`N1InternalMemberId`）

## Response 與 Exception 規範（內嵌）

### 成功回應

- 一律 `ApiResponseEntity<T>`
- 使用專案既有 helper：`ApiResponseEntity<T>.Create(data: data)` 靜態方法（必要時加 message）
- `Create(...)` 內部自動設定 `Code = "Success"`，不需手動指定
- **不要**用 `new ApiResponseEntity<T> { Code = "Success", ... }` 手動建構

### 錯誤回應

- domain exception：優先使用既有的 `CustomException<TEnum>` 模式
- Controller 捕捉後：使用既有 `BadRequestInner(...)` 回傳 `BadRequestObjectResult`
- `ProducesResponseType` 的 400 型別統一使用 `ApiErrorResponseExtendsEntity<object>`
- **不要**使用舊版 `ApiErrorResponseEntity<object>`（`SettingController` 的用法為歷史遺留）

### 注意

- 不要吞 exception
- 需要重新拋出時用 `throw;` 保留 stacktrace
- 避免 log 敏感資料或整個 entity

## Controller Patterns（內嵌）

- Controllers 位置：`src/Web/Nine1.Shopping.Web.Api/Controllers/`
- Controller 基本結構：
  - **必須繼承 `ControllerBase`**
  - `[ApiController]`
  - `[Route("api/<resource>")]`（原則上一個 Controller 只需一個 `[Route]`）
  - `[OpenApiTag("<tag>", Description = "...")]`
  - constructor 使用相依性注入（不要在類別內 `new`）
- 新增 Controller 時必須在內部自行定義以下 private method（目前尚未抽成共用 extension method）：
  - `CheckoutHistoryLogInfo`（若屬主流程）
  - `BadRequestInner`（若需要 domain exception 處理）
  - 這兩個 method 可從 `CartsController.cs` 複製
- Action 概念：
  - `try`：log header →（必要時）CheckoutHistory log → 呼叫 service → `ApiResponseEntity<T>.Create(data: data)`
  - `catch`：捕捉 domain exception → `BadRequestInner(ex, shopId, memberId)`
- 禁止事項：
  - 不要用 `!x`，要用 `x == false`
  - 不要在 Controller 寫太多商業邏輯（交給 service）
  - 不要用 `new ApiResponseEntity<T> { ... }` 手動建構（使用 `.Create(...)` 靜態方法）
  - 不要用 `catch (Exception)` 通吃所有例外（應捕捉具體 domain exception）

## Implementation Rules（實作規範：必須遵守）

### 1) 專案結構與責任切分

- Controller 只負責：輸入驗證、呼叫 service、回傳標準 response、處理已知 exception、打 log
- 商業邏輯放到 BL Services / domain service

### 2) Route / OpenAPI 標記

- Controller 需標註：`[ApiController]` 與 `[Route("api/<resource>")]`
- 需加上 `OpenApiTag`，tag/description 與資源一致
- action route 命名對齊既有專案（先找相近 Controller 模仿）

### 3) 標準回傳格式

- success：`ApiResponseEntity<T>.Create(data: data)`
- T 通常為 `*Entity`

### 4) log 與錯誤處理

- action 內使用 `try/catch`
- catch domain exception（例如 `CustomException<TEnum>` 的具體型別）後回傳 `BadRequestInner(...)`
- log 避免輸出敏感資料（必要時 mask）

## Examples（Good / Bad）

### Good（正確方向）

- 先找既有 Controller 範例對齊路由與回傳格式
- action 結構清楚：
  - log `N1-ENV`
  - （主流程）`CheckoutHistoryLogInfo(shopId, memberId, route, function)`
  - 呼叫 service
  - `ApiResponseEntity<T>.Create(data: data)`
  - catch 已知 domain exception → `BadRequestInner(...)`

### Bad（常見錯誤）

- 只寫 `Request.Headers["N1-ENV"]` 但不處理 header 不存在的情況（優先使用 `_requestDataRetriever.Env`）
- `CheckoutHistoryLogInfo` 的 route 填錯（必須是實際對外 `/api/...` path）
- 直接回傳裸物件或 `IActionResult` 未包 `ApiResponseEntity<T>`
- 用 `new ApiResponseEntity<T> { Code = "Success", ... }` 手動建構（應使用 `ApiResponseEntity<T>.Create(...)`）
- 把商業邏輯塞在 Controller（導致難測試、難維護）
- `catch (Exception)` 後吞掉或回傳模糊訊息（參考 `SettingController.cs` 的做法是反模式，不應仿照）
- DTO 未以 `Entity` 結尾
- 用 `!flag` 而非 `flag == false`
- public 類別/方法沒有 XML 註解，或方法內沒有 `////` 區塊註解
- 新增 Controller 時未繼承 `ControllerBase`（不要仿照 `ShippingController`）
- 新增 Controller 時忘記定義 `BadRequestInner` 和 `CheckoutHistoryLogInfo` private method（它們不是 extension method）
- 400 的 `ProducesResponseType` 使用舊版 `ApiErrorResponseEntity<object>` 而非 `ApiErrorResponseExtendsEntity<object>`

## Output contract（你必須產出的回覆格式）

回覆時請固定列出：

1. **將修改/新增的檔案清單**（用反引號包路徑）
2. **每個檔案的變更摘要**（條列）
3. **已套用的規範核對**（Route/Authorize/log/exception/response/DTO 命名/XML 註解/`////`）
4. 若需求資訊不足：列出你還缺的問題，等待使用者補齊再動手改檔。

> 除非使用者明確要求，否則不要在回覆直接貼大量程式碼；請直接修改 workspace 檔案。

## DoD Quality Checklist（完成定義 / 上線前自我檢查）

- [ ] 已找到至少 1 個相似 Controller/action 範例並對齊（Route、OpenApiTag、Scope remarks、response、exception pattern）；且未參考已知反模式的 Controller（`SettingController` / `ShippingController` / `PaymentController`）
- [ ] Route / method / action 命名符合既有慣例
- [ ] 新增 Controller 有繼承 `ControllerBase`
- [ ] 若需要驗證：已加上 `[Authorize]`，且 Scope remarks（若有慣例）一致
- [ ] success 回傳使用 `ApiResponseEntity<T>.Create(...)`（未使用 `new` 手動建構）
- [ ] error 使用 domain exception + `BadRequestInner(...)`（非 `catch (Exception)` 通吃）
- [ ] 已加入必要 log（含 `N1-ENV`、並避免敏感資訊）
- [ ] 若屬主流程：已加入 `CheckoutHistoryLogInfo(shopId, memberId, route, function)`，且 route 為實際 `/api/...` path、function 為繁體中文動作描述
- [ ] 若新增 Controller：已自行定義 `CheckoutHistoryLogInfo` 和 `BadRequestInner` private method（它們不是 extension method）
- [ ] 若需支援訪客：已確認 CookieAuthenticationValidator allowlist（Allowlist / P1GuestAllowlist / UnloginAllowlist）並說明是否需調整設定
- [ ] 若 GET action 資料不適合快取：已加上 `[ResponseCache(Location = ResponseCacheLocation.None, NoStore = true)]`
- [ ] DTO 皆以 `Entity` 結尾
- [ ] public XML 註解齊全，method body 主要區塊有 `////`
- [ ] boolean 判斷無 `!x`（使用 `x == false`）
- [ ] `ProducesResponseType` 的 400 使用 `ApiErrorResponseExtendsEntity<object>`（非舊版 `ApiErrorResponseEntity<object>`）
- [ ] 相關檔案無新增編譯錯誤；需要時已補測試（或說明不補的原因）
