# Phase 3 — DI 注冊 & 驗證

> 讀完本文件後再開始修改對應檔案。

---

## 檔案 1：ServiceModule.cs

**路徑：** `CrossLayer/Modules/BL/ServiceModule.cs`

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 要使用哪個 SettingService 進行 DI 注冊？
> - 大多數 Razer / AsiaPay 使用 `SimpleShopSecretPaymentSettingService`
> - Stripe → `StripeSettingService`；LinePay → `LinePaySettingService`
> 確認使用 `{SettingServiceType}`？」

**動作：**  
在 `ThirdPartyServicesSettings()` 方法中加入 Autofac keyed 注冊。

**一般 Razer / AsiaPay 使用 `SimpleShopSecretPaymentSettingService`：**
```csharp
builder.RegisterType<SimpleShopSecretPaymentSettingService>()
    .Keyed<IThirdPartyServiceSettingService>(nameof(PayProfileTypeEnum.PayNow_Razer));
```

**特殊 Provider 使用各自的 SettingService：**
```csharp
// Stripe
builder.RegisterType<StripeSettingService>()
    .Keyed<IThirdPartyServiceSettingService>(nameof(PayProfileTypeEnum.CreditCardOnce_Stripe));

// LinePay
builder.RegisterType<LinePaySettingService>()
    .Keyed<IThirdPartyServiceSettingService>(nameof(PayProfileTypeEnum.LinePay));
```

**插入位置：** 依 Provider 邏輯分組，Razer 系列放在一起，AsiaPay 系列放在一起。

**驗證：**
- [ ] 使用 `nameof()` 確保型別安全
- [ ] 使用正確的 SettingService class（不確定時，參考同 Provider 既有 PayType）
- [ ] 確認在 `ThirdPartyServicesSettings()` 方法內
- [ ] 無重複注冊

---

## 檔案 2：SalePageCreateRequestEntityValidator.cs

**路徑：** `CrossLayer/Validators/SalePages/SalePageCreateRequestEntityValidator.cs`

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 是否支援數位商品銷售？
> - 若支援 → 加入 `payTypeList`（大多數第三方金流均支援）
> - 若不支援（如 COD、ATM）→ 跳過此步驟」

**動作：**  
找到 `payTypeList` 定義（用於驗證數位商品付款支援），加入新 PayType。

**範例：**
```csharp
List<string> payTypeList = new List<string>
{
    PayProfileTypeEnum.CreditCardOnce.ToString(),
    PayProfileTypeEnum.ATM.ToString(),
    // ... 其他既有 PayType ...
    nameof(PayProfileTypeEnum.OnlineBanking_Razer),
    nameof(PayProfileTypeEnum.TNG_Razer),
    nameof(PayProfileTypeEnum.GrabPay_Razer),
    nameof(PayProfileTypeEnum.Boost_Razer),
    nameof(PayProfileTypeEnum.PayNow_Razer),  // ← 加入此行
    nameof(PayProfileTypeEnum.CreditCardOnce_AsiaPay),
    // ...
};
```

**命名慣例：**
- 新 PayType 使用 `nameof()` 格式
- 舊有 PayType 可能使用 `.ToString()` 格式，維持既有一致性即可

**判斷：**
- 若新 PayType **不支援**數位商品（如 COD），可**跳過此步驟**
- 大多數第三方 PaymentMiddleware PayType 均需加入此 list

**插入位置：** 依 Provider 群組邏輯排列（Razer 系列一起，AsiaPay 系列一起）

**驗證：**
- [ ] 新 PayType 已加入 `payTypeList`
- [ ] 命名方式與周圍 entry 一致（`nameof()` 或 `.ToString()`）
- [ ] 插入位置合理

---

## 檔案 3：ReturnGoodsOrderService.cs（條件性）

**路徑：** `BusinessLogic/Services/ReturnGoodsOrders/ReturnGoodsOrderService.cs`

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 在退貨流程中，是否需要向顧客蒐集匯款退款資訊（如銀行帳號）？
>
> **需要蒐集** → 加入 `IsRefundInfoCollectingEnabled()` switch-case，並在 AppSettings 設定 `PayChannel.{PayType}.CollectRefundInfo.Days`
>
> **不需要蒐集**（直接退刷，如 Razer / AsiaPay 系列）→ 跳過此檔，`default: return false` 已自動處理
>
> 目前已在清單中的 PayType：CheckoutDotCom、PayMe、EftPay 系列、SwiftPass、Cybersource、QFPay、GooglePay/ApplePay（HK）、LinePay、EasyWallet」

### 若需要加入（條件成立）

**動作：** 在 `IsRefundInfoCollectingEnabled()` switch-case 加入新 case

**標準退款蒐集模式（依天數判斷）：**
```csharp
case PayProfileTypeEnum.{NewPayTypeName}:
    var days = int.Parse(this._configService.GetAppSetting(
        $"PayChannel.{payType}.CollectRefundInfo.Days"));
    return this._staticMethodHelper.DateTimeNow > orderDateTime.AddDays(days);
```

**固定天數模式（如 LinePay）：**
```csharp
case PayProfileTypeEnum.{NewPayTypeName}:
    return this._staticMethodHelper.DateTimeNow > orderDateTime.AddDays(60);
```

**市場條件模式（如 GooglePay/ApplePay 只在 HK）：**
```csharp
case PayProfileTypeEnum.{NewPayTypeName}:
    if (SettingHelper.DefaultCountry == "{Market}")
    {
        var days = this._configService.GetAppSetting(
            $"PayChannel.{payType}.CollectRefundInfo.Days", "60");
        return this._staticMethodHelper.DateTimeNow > orderDateTime.AddDays(int.Parse(days));
    }
    else
    {
        return false;
    }
```

### 同步設定 AppSettings（條件成立時必做）

若選擇「標準退款蒐集模式」，需同步在 AppSettings config 加入：

```xml
<!-- WebStore/WebAPI/AppSettings.{Env}.{Market}.config -->
<add key="PayChannel.{NewPayTypeName}.CollectRefundInfo.Days" value="60" />
```

> ⚠️ 請與使用者確認天數（通常為 60 天，視 Provider 合約而定）。AppSettings 的修改**在此 Skill 範圍內**，請同步完成。

**驗證：**
- [ ] 已與使用者確認是否需要蒐集退款資訊
- [ ] switch-case 已加入（或確認跳過）
- [ ] AppSettings config 已同步設定（如需要）
- [ ] 天數已與使用者確認
