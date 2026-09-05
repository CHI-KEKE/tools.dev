# Phase 4: Payment Processing Files

## File 1: `GetPayProcessDataProcessor.cs`
**Path:** `WebStore/Frontend/BLV2/PayProcesses/Processors/GetPayProcessDataProcessor.cs`
**Purpose:** Retrieves payment processing data; routes to the correct processor.

### Actions
Add to **two switch-case structures** in this file:

**1. PaymentMiddleware determination switch-case**
```csharp
case nameof(PayProfileTypeDefEnum.PayNow_Razer):
case nameof(PayProfileTypeDefEnum.OnlineBanking_Razer):
    //// PaymentMiddleware routing
    break;
```

**2. Payment properties switch-case** (sets properties like `IsThirdParty`, `PayApiUrl`, etc.)
```csharp
case nameof(PayProfileTypeDefEnum.PayNow_Razer):
    //// Set payment-specific properties
    break;
```

> 📌 Read the existing Razer entries to understand the expected property assignments for new Razer types.

---

## File 2: `ThirdPartyPayApiProcessor.cs`
**Path:** `WebStore/Frontend/BLV2/PayProcesses/Processors/ThirdPartyPayApiProcessor.cs`
**Purpose:** Invokes the third-party payment API.

### Actions
Add the new payment type to the third-party payment switch-case:

```csharp
case PayProfileTypeDefEnum.PayNow_Razer:
case PayProfileTypeDefEnum.OnlineBanking_Razer:
    //// Execute PaymentMiddleware API call
    break;
```

---

## File 3: `CreateTradesOrderProcessor.cs`
**Path:** `WebStore/Frontend/BLV2/PayProcesses/Processors/CreateTradesOrderProcessor.cs`
**Purpose:** Creates the trades order; handles payment-type-specific order creation logic.

### Actions
Add to **3個 switch-case**（非 2 個）：

**1. 第三方付款判斷 switch（約行 241）**
```csharp
case PayProfileTypeDefEnum.NewPayType_Razer:
    //// Mark as third-party
    break;
```

**2. 退款資訊 switch（約行 618）** *(if refund supported)*
```csharp
case PayProfileTypeDefEnum.NewPayType_Razer:
    //// Set refund info fields
    break;
```

**3. 幣別設定 switch（約行 1107）**

依 Step 1 確認的**幣別模式**選擇：

```csharp
// 模式 A：多市場幣別（SalesCurrency，目前 Razer 系列使用）
case PayProfileTypeDefEnum.NewPayType_Razer:
    var shopSalesMarketSetting = this._marketModuleAgentService
        .GetShopSalesMarketSettingsWithoutDefaultSettings(TGCode, shopId);
    currency = shopSalesMarketSetting.SalesCurrency;
    break;

// 模式 B：預設幣別（大多數其他 provider 使用）
case PayProfileTypeDefEnum.NewPayType_Razer:
    currency = ConfigService.GetAppSetting("DefaultPayment.Currency");
    break;
```

---

## File 4: `PaymentMiddlewareService.cs` *(conditional)*
**Path:** `WebStore/Frontend/BLV2/ThirdPartyPay/PaymentMiddlewareService.cs`
**Purpose:** Handles currency and market settings for PaymentMiddleware payments.

> Skip this file if the new payment type does **not** require multi-currency or multi-market support.

### Actions
Add to **two methods**:

**`GetSalesCurrency()`**
```csharp
case PayProfileTypeDefEnum.CreditCardOnce_Razer:
case PayProfileTypeDefEnum.GrabPay_Razer:
case PayProfileTypeDefEnum.PayNow_Razer:    // ← add here
    var shopSalesMarketSetting = this._marketModuleAgentService
        .GetShopSalesMarketSettingsWithoutDefaultSettings(TGCode, shopId);
    return shopSalesMarketSetting.SalesCurrency;
```

**`GetSalesMarket()`**
```csharp
case PayProfileTypeDefEnum.PayNow_Razer:    // ← add here
    // return corresponding market code
    break;
```

---

## File 5: `{Provider}PayChannelService.cs`
**Path:** `WebStore/Frontend/BLV2/PayChannel/{Provider}PayChannelService.cs`
**Purpose:** 在 `GetPayExtendInfo()` 內部透過私有 `GetChannel()` 方法決定送給 PaymentMiddleware API 的 `txn_channel` 值。

> ⚠️ **不存在 `GetPaymentMethodCode()` 這個公開方法。** 實際做法是在 `GetPayExtendInfo()` 內的私有 `GetChannel()` 裡加 `case`。

### If provider already has a PayChannelService（加到現有 service）:

以 Razer 為例，在 `RazerPayChannelService.cs` 的 `GetChannel()` 加新 case：
```csharp
private string GetChannel(PayProfileTypeDefEnum payProfileTypeDef)
{
    switch (payProfileTypeDef)
    {
        case PayProfileTypeDefEnum.CreditCardOnce_Razer:
            return "CREDIT";
        case PayProfileTypeDefEnum.PayNow_Razer:
            return "PAYNOW";
        case PayProfileTypeDefEnum.NewPayType_Razer:
            return "NEW_CHANNEL_CODE";    // ← 必須符合 provider API spec 的 channel code
        // ...
    }
}
```

> 📌 Channel code **必須完全符合** provider API 文件的規格。

### If this is a new provider（建立新 service）:
- 在 `WebStore/Frontend/BLV2/PayChannel/` 建立 `{Provider}PayChannelService.cs`
- 參考 `RazerPayChannelService.cs` 的實作模式
- **在 `ServiceModule.cs` 注冊**（見下方 File 6）
- 將新檔案加到 `.csproj` `<ItemGroup>`（依字母順序）

---

## File 6: `ServiceModule.cs` *(僅新 provider 才需要)*
**Path:** `WebStore/Frontend/BLV2/Modules/ServiceModule.cs`
**Purpose:** Autofac DI 注冊中心，PayChannelService 透過 Named 注冊支援路由。

> ⚠️ **同 provider 新增 paytype 完全不需要修改此檔案。**
> `PayChannelServiceResolver` 的路由邏輯：`PayNow_Razer` → split by `_` → 取第二段 `Razer` → `ResolveNamed<IPayChannelService>("Razer")` → 自動路由到 `RazerPayChannelService`。

### 只有建立全新 provider 時才加（約行 347-359）:
```csharp
builder.RegisterType<NewProviderPayChannelService>()
       .Named<IPayChannelService>(NewProviderPayChannelService.PayChannel);
```

---

## 關於 Fail 機制（G7 補充）

> ℹ️ **PaymentMiddleware 路線不使用 `TradesOrderResultEnum` 的 `{PayType}ReserveFail / ConfirmFail / StatusFail` 模式。**

PaymentMiddleware 有自己獨立的失敗 enum：

| Enum | 位置 | 值 |
|---|---|---|
| `PaymentStatusDefEnum` | `WebStore/Frontend/BE/PaymentMiddleware/PaymentStatusDefEnum.cs` | `Success=1, Fail=2, Redirect=3, Pending=4` |

所有 PaymentMiddleware paytype 失敗時統一回傳 `PaymentStatusDefEnum.Fail`，**新增 paytype 完全不需要修改任何 Fail 相關 enum**。

`TradesOrderResultEnum` 的 `XxxFail` 系列只屬於 CommonThirdPartyPayType 路線（RazerPay、OpenWallet、FamilyMartOnlinePay 等）。
