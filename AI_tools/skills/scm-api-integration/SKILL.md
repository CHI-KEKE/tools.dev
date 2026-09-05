---
name: scm-api-integration
description: 當使用者說「要串 SCM API」、「呼叫 SCM API」、「用 SCM API 實作」、「整合 scm.api」、「透過 NineYi.Scm.Api.Client 呼叫」，或描述功能需求時（例如「更新商品頁」、「出貨」、「退貨」、「建立優惠券」等）想知道是否有現成的 SCM API 方法可用，一律使用此 skill。此 skill 會先反射解析本專案目前參考的 Client DLL、列出可用方法，並引導使用者選擇適合的方法，或明確告知需自行在 NineYi.Scm.Api.Client 開發。
---

# SCM API Integration Guide

此 skill 用於協助開發者在 NineYi.Sms 專案中整合 **NineYi.Scm.Api.Client**，確保正確使用現有的 Client 與方法，避免重複開發已有的功能。

---

## 核心工作流程

```
Step 1：解析本專案的 SCM API Client 版本
    ↓
Step 2：理解使用者的功能需求
    ↓
Step 3：在 Client 方法目錄中比對
    ↙                      ↘
找到合適方法              找不到合適方法
    ↓                          ↓
Step 4：詢問使用者選擇        Step 5：告知需在 SCM 開發
    ↓
Step 6：產生整合程式碼
```

---

## Step 1：解析本專案的 SCM API Client 版本

執行以下 PowerShell 指令，取得目前專案參考的 Client 版本：

```powershell
# 取得 V1 最新版本
Get-ChildItem "C:\Repository\nineyi.sms\packages" -Filter "NineYi.Scm.Api.Client.*" -Directory |
    Where-Object { $_.Name -notlike "*V2*" } |
    Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name

# 取得 V2 最新版本
Get-ChildItem "C:\Repository\nineyi.sms\packages" -Filter "NineYi.Scm.Api.ClientV2.*" -Directory |
    Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name
```

同時確認 `BusinessLogic\Services\NineYi.Sms.BL.Services.csproj` 中實際引用的版本：

```powershell
Select-String -Path "BusinessLogic\Services\packages.config" -Pattern "Scm.Api"
```

> **重要**：後續所有方法參考均基於 `references/v1-client-methods.md` 與 `references/v2-client-methods.md` 中的方法清單。如版本差距過大（超過 3 個次版本），建議重新執行反射取得最新方法清單。

---

## Step 2：理解使用者的功能需求

向使用者確認以下資訊（若對話中已明確，則直接沿用）：

1. **操作對象** — 商品頁？SKU？訂單？出貨？優惠券？會員？等
2. **操作動作** — 查詢（Get）、建立（Create）、更新（Update）、刪除（Delete）、上傳圖片？
3. **目標 Service** — 將在哪個 Service 中呼叫 SCM API？

若需求描述不夠明確，可詢問：
> 「請描述您希望透過 SCM API 完成的具體功能，例如：更新商品頁售價、確認出貨單、建立促銷活動等。」

---

## Step 3：在 Client 方法目錄中比對

依需求，對照以下方法目錄進行比對：

- **V1 方法清單**：`references/v1-client-methods.md`
- **V2 方法清單**：`references/v2-client-methods.md`

### 比對原則

| 使用 V1（IScmClient）的時機 | 使用 V2 專責 Client 的時機 |
|---------------------------|--------------------------|
| 該功能在 V2 中沒有對應 Client | 有對應的 V2 專責 Client |
| 現有程式碼已使用 V1 且功能相近 | 新功能開發，V2 較語意清晰 |
| 操作涉及多個 V1 方法的組合 | 操作明確對應單一 V2 Client |

### 常見需求對照表（快速查詢）

| 需求描述 | 推薦 Client | 推薦方法 |
|---------|------------|---------|
| 更新商品頁售價 | V1 `IScmClient` | `UpdatePrice` |
| 更新商品頁狀態（上下架） | V1 `IScmClient` | `UpdateListing` |
| 建立商品頁 | V2 `ISalePageClient` | `CreateMain` |
| 更新商品頁類別 | V2 `ISalePageClient` | `UpdateSalePageCategory` |
| 取得/更新商品頁點數付款 | V2 `ISalePageClient` | `GetSalePagePointsPay` / `UpdateSalePagePointsPay` |
| 更新 SKU 詳細資料 | V1 `IScmClient` | `UpdateSkuDetail` |
| 建立銷售商品 SKU | V2 `ISalePageClient` | `CreateSaleProductSku` |
| 更新 SKU 圖片 | V1 `IScmClient` | `UpdateSKUImage` |
| 取消訂單 | V2 `ISalesOrderClient` | `Cancel` / `CancelOrder` |
| 確認出貨 | V2 `ISalesOrderClient` | `ShipConfirm` |
| 超商配送出貨 | V2 `IStoreClient` | `Shipping` |
| 宅配出貨 | V2 `IHomeDeliveryClient` | `DeliveryShipment` |
| 門市取貨出貨 | V2 `ILocationPickupClient` | `Shipping` |
| 7-11 黑貓配碼 | V2 `ISevenElevenTCatClient` | `AllocateCode` |
| 建立/更新促銷活動 | V2 `IPromotionClient` | `CreatePromotion` / `UpdatePromotion` |
| 退貨訂單處理 | V2 `IReturnGoodsOrderClient` | `Finish` / `Cancel` / `Deny` |
| 退款 | V2 `IRefundRequestClient` | `ReturnSalesOrderFee` |
| 電子票券發送 | V2 `IECouponClient` | `Dispatch` / `Produce` |
| 建立/搜尋品牌 | V2 `IBrandClient` | `CreateBrand` / `SearchBrand` |
| 商店類別管理 | V2 `IShopClient` | `CreateShopCategory` / `ModifyShopCategory` |
| 上傳商店 Logo/Icon | V2 `IShopClient` | `UploadShopLogo` / `UploadShopIcon` |
| 更新會員等級 | V2 `ICrmMemberClient` | `UpdateMemberTierInfo` |
| 鎖定/解鎖會員登入 | V2 `IShopMemberClient` | `LockLogin` / `UnlockLogin` |
| 標籤系統操作 | V2 `ITaggingClient` | 各 CRUD 方法 |
| 短網址 | V2 `IUrlClient` | `Shorten` |
| 多語系內容 | V2 `IMultilingualContentClient` | `UpdateContent` |
| 智慧推薦設定 | V2 `IIntelligentRecommendationClient` | `GetShopSetting` / `UpdateShopSettingByPage` |

---

## Step 4：找到合適方法 — 詢問使用者選擇

若找到一個或多個合適方法，以條列方式呈現，並詢問使用者確認：

```
✅ 找到以下可能適合的 SCM API 方法：

1. [V2] ISalePageClient.UpdateSalePageCategory(SalePageUpdateCategoryEntity)
   → 說明：更新商品頁的商店類別歸屬

2. [V1] IScmClient.GetShopCategory(ShopIdRequestEntity)
   → 說明：取得商店的類別清單

請問您需要的是哪一個？或兩個都需要？
```

使用者確認後，進入 **Step 6** 產生整合程式碼。

---

## Step 5：找不到合適方法 — 明確告知需在 SCM 開發

若在 V1 與 V2 的完整方法清單中均找不到合適的方法，**必須**明確告知使用者：

```
❌ 目前的 NineYi.Scm.Api.Client（V1 + V2）中沒有符合此需求的現成方法。

需要的功能：{使用者描述的功能}

建議流程：
1. 至 NineYi.Scm.Api.Client 套件的原始碼專案中開發新方法
2. 在對應的 Interface（IXxxClient）中新增方法簽名
3. 在實作類別（XxxClient）中實作 HTTP 呼叫邏輯
4. 發版後升級 NineYi.Sms 中的 NuGet 套件版本
5. 回到本專案進行整合

⚠️ 請勿在 NineYi.Sms 中直接呼叫 HttpClient 繞過 SCM API Client，
   所有對 SCM API 的呼叫必須透過 NineYi.Scm.Api.Client 進行。
```

---

## Step 6：產生整合程式碼

確認使用者選擇後，依以下標準模式產生程式碼。

### V1 整合模式（IScmClient）

```csharp
//// 取得 API 認證資訊
var apiProfile = this._supplierService.GetApiProfile(shopId);
var apiUrl = this._configService.GetAppSetting("Domain.ScmApi");

//// 呼叫 SCM API V1
using (IScmClient client = new ScmClientV1(apiProfile.Token, apiProfile.Key, apiProfile.SaltKey, apiUrl))
{
    client.PresnetUsername = this._userName;

    var result = client.{MethodName}(new {EntityType}
    {
        //// 填入對應欄位
    });

    if (result.Status == ApiResultStatusEnum.Success)
    {
        //// 處理成功結果
    }
    else
    {
        //// 處理失敗，記錄錯誤
        this._logger.Error($"SCM API 呼叫失敗：{result.Message}");
    }
}
```

### V2 整合模式（專責 Client）

```csharp
//// 取得 API 認證資訊
var apiProfile = this._supplierService.GetApiProfile(shopId);
var apiUrl = this._configService.GetAppSetting("Domain.ScmApi");

//// 呼叫 SCM API V2（_userName 直接傳入建構子）
using (I{ClientName} client = new {ClientName}(apiProfile.Token, apiProfile.Key, apiProfile.SaltKey, apiUrl, this._userName))
{
    var result = client.{MethodName}(new {EntityType}
    {
        //// 填入對應欄位
    });

    if (result.Status == ApiResultStatusEnum.Success)
    {
        //// 處理成功結果
    }
    else
    {
        //// 處理失敗，記錄錯誤
        this._logger.Error($"SCM API 呼叫失敗：{result.Message}");
    }
}
```

### 必要的 Using 引用

```csharp
// V1
using NineYi.Scm.Api.Client.V1;

// V2（依使用的 Client 命名空間）
using NineYi.Scm.Api.Client.V2;
using NineYi.Scm.Api.Client.V2.SalePageGroup;
using NineYi.Scm.Api.Client.V2.SalePageSpecCharts;
using NineYi.Scm.Api.Client.V2.Brands;
using NineYi.Scm.Api.Client.V2.ProductBadges;
using NineYi.Scm.Api.Client.V2.IntelligentRecommendation;
using NineYi.Scm.Api.Client.V2.MultilingualContent;
using NineYi.Scm.Api.Client.V2.LogisticsCenterAgents;
using NineYi.Scm.Api.Client.V2.NMS;
using NineYi.Scm.Api.Client.V2.Stripes;

// Models
using NineYi.Scm.Api.Models;
using NineYi.Scm.Api.Models.SalePages;
using NineYi.Scm.Api.Models.SalePages.Enums;
```

---

## 架構規範

### Client 使用規則

1. **必須使用 `using` 語句包裹 Client**：Client 實作 `IDisposable`，必須確保釋放資源
2. **不使用 async/await**：此專案全部使用同步方法，Client 也提供同步 API
3. **優先使用 V2 Client**：若 V2 有對應的專責 Client，優先使用 V2
4. **保持現有程式碼一致性**：若所在 Service 已使用 V1，維持一致除非有明確升級需求
5. **必須設定 `PresnetUsername`**（注意：DLL 原始拼法為 `Presnet`，非 `Present`）：
   - **標準做法（參考 SalePageService）**：在 Service 建構子中呼叫 `GetCurrentUser()`，將 `OperatorUserName` 存入 `private readonly string _userName`，user 為 null 時給 `string.Empty`
   - **V1**：建立 Client 後設定 `client.PresnetUsername = this._userName;`
   - **V2**：將 `this._userName` 作為建構子第五個參數直接傳入，例如 `new SalePageClient(token, key, saltKey, apiUrl, this._userName)`
   - **禁止**：略過此設定，SCM 端需此欄位追蹤操作來源

### 注入規範

Client 為 `using` 建立的一次性物件，**不透過 DI 注入**，但所需的 `IConfigService`、`ISupplierService` 等依賴必須在 Service 建構子中注入：

```csharp
public class YourService : IYourService
{
    private readonly IConfigService _configService;
    private readonly ISupplierService _supplierService;
    private readonly IUserService _userService;
    private readonly ILogger _logger;
    private string _apiRootUrl;
    private readonly string _userName;  // 操作者帳號，在建構子取得

    public YourService(
        IConfigService configService,
        ISupplierService supplierService,
        IUserService userService,
        ILogger logger)
    {
        this._configService = configService;
        this._supplierService = supplierService;
        this._userService = userService;
        this._logger = logger;
        this._apiRootUrl = this._configService.GetAppSetting("Domain.ScmApi");

        //// 在建構子取得登入使用者帳號，null 時給 string.Empty（背景排程情境）
        var userItem = this._userService.GetCurrentUser();
        this._userName = userItem == null ? string.Empty : userItem.OperatorUserName;
    }
}
```

---

## 完成確認清單

- [ ] 確認使用的 Client 版本為本專案參考的最新版
- [ ] 確認使用 `using` 語句包裹 Client（確保 Dispose）
- [ ] 確認未使用 async/await（使用同步方法）
- [ ] 確認 using namespace 已加入
- [ ] 確認 `IConfigService`、`ISupplierService`（或對應認證服務）已在建構子中注入
- [ ] **確認 `PresnetUsername` 已設定**：
  - V1：`client.PresnetUsername = this._userName;`
  - V2：`_userName` 作為建構子第五個參數傳入
  - `_userName` 來源：建構子中 `GetCurrentUser()?.OperatorUserName`，null 時為 `string.Empty`
- [ ] 確認 `result.Status` 回傳值有做判斷與錯誤處理
- [ ] 若方法不存在，已明確告知使用者需至 NineYi.Scm.Api.Client 開發

---

## 參考資料

- **V1 完整方法清單**：`references/v1-client-methods.md`
- **V2 完整方法清單**：`references/v2-client-methods.md`
- **現有整合範例**：`BusinessLogic\Services\SalePages\SalePageService.cs`
