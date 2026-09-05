# Phase 2 — Factory & Service 設定

> 讀完本文件後再開始修改對應檔案。

---

## 檔案 1：ShopSecretSettingFactory.cs

**路徑：** `BusinessLogic/Services/ThirdPartyServices/Payments/ShopSecretSettings/ShopSecretSettingFactory.cs`

**⚠️ 執行前請先與使用者確認：**
> 「新 PayType `{Name}` 要共用哪個 ShopSecretSetting class？
> 例如：Razer 系列 → `RazerMSShopSecretSetting`；AsiaPay 系列 → `AsiaPayShopSecretSetting`。
> 若是全新 Provider 沒有現有 class，此 Skill 無法繼續，需先手動建立。」

**動作：**  
在 `GetInstance()` 方法的 switch block 加入新 case，依 Provider 群組歸位。

**範例（共用現有 Provider）：**
```csharp
case PayProfileTypeEnum.PayNow_Razer:   // 與其他 Razer PayType 合併為一個 case 群組
    return new RazerMSShopSecretSetting();
```

**注意：**
- 若新 PayType 與現有 PayType 共用同一 Provider（如 Razer），**加入同一 case 群組**（`case PayProfileTypeEnum.X: case PayProfileTypeEnum.Y: return new RazerMSShopSecretSetting();`）
- 若是全新 Provider，建立對應的 `{Provider}ShopSecretSetting()` instance（需手動建立 class）

**驗證：**
- [ ] 與使用者確認的 ShopSecretSetting class 一致
- [ ] case 已加入，依 Provider 邏輯分組
- [ ] 無重複 case

---

## 檔案 2：ThirdPartyServicesService.cs

**路徑：** `BusinessLogic/Services/ThirdPartyServices/ThirdPartyServicesService.cs`

此檔案有 **4 個子區塊**需確認 / 更新：

---

### 2.1 ProfileShopDefaultGroupMapping

在 static constructor 加入 mapping entry：

```csharp
ProfileShopDefaultGroupMapping = new Dictionary<string, string>
{
    // ... 既有 mapping ...
    { nameof(PayProfileTypeEnum.PayNow_Razer), "RazerMS" },
    // ...
};
```

**命名規則（ShopDefaultGroup）：**
| Provider | ShopDefaultGroup |
|----------|-----------------|
| Razer 系列 | `"RazerMS"` |
| AsiaPay 系列 | `"AsiaPay"` |
| Stripe | `"Stripe"` |
| LinePay | `"LinePay"` |
| 其他 | 依既有 pattern |

---

### 2.2 PayProfileTypeExclusion（Razer / AsiaPay 互斥，視需要）

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 是否需要與其他 Provider 互斥？
> 讀取 `ThirdPartyServicesService.cs` 目前的 PayProfileTypeExclusion，
> 列出現有的 AsiaPay 或 Razer PayType 清單，請確認排斥清單是否完整？」

**重要：Razer ↔ AsiaPay 系列互相排斥。**  
若新增 Razer PayType，需在此加入排斥所有 AsiaPay PayType；反之亦然。

```csharp
PayProfileTypeExclusion = new Dictionary<string, IEnumerable<string>>
{
    // ... 既有排斥設定 ...
    { nameof(PayProfileTypeEnum.PayNow_Razer), new HashSet<string>{
        nameof(PayProfileTypeEnum.CreditCardOnce_AsiaPay),
        nameof(PayProfileTypeEnum.OnlineBanking_AsiaPay),
        nameof(PayProfileTypeEnum.TNG_AsiaPay),
        nameof(PayProfileTypeEnum.Boost_AsiaPay),
        nameof(PayProfileTypeEnum.GrabPay_AsiaPay)
    }},
};
```

**驗證：**
- [ ] 已與使用者確認排斥清單完整
- [ ] 若為 Razer → 排斥所有 AsiaPay
- [ ] 若為 AsiaPay → 排斥所有 Razer
- [ ] 參考同 Provider 既有 PayType 的排斥設定（如 `OnlineBanking_Razer`）

---

### 2.3 HiddenSettingPayProfileTypes（非主要入口，視需要）

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 是主要設定入口（如 `CreditCardOnce_Razer`），
> 還是 sub-type（如 `PayNow_Razer`、`GrabPay_Razer`）？
> Sub-type → 加入 HiddenSettingPayProfileTypes（不在 UI 獨立顯示）；
> 主要入口 → 不加。」

**Razer 系列規則：** 除 `CreditCardOnce_Razer` 外，其餘 Razer PayType 通常都要加入 Hidden list，避免出現在設定 UI 的獨立入口。

```csharp
HiddenSettingPayProfileTypes = new List<string> {
    nameof(PayProfileTypeEnum.CreditCardInstallment_Razer),
    nameof(PayProfileTypeEnum.OnlineBanking_Razer),
    nameof(PayProfileTypeEnum.TNG_Razer),
    nameof(PayProfileTypeEnum.Boost_Razer),
    nameof(PayProfileTypeEnum.GrabPay_Razer),
    nameof(PayProfileTypeEnum.PayNow_Razer),  // ← 加入此行
    // AsiaPay sub-types ...
};
```

**判斷原則：**
- 主要入口 PayType（如 `CreditCardOnce_Razer`）→ **不加**
- 衍生 sub-type → **加入**

---

### 2.4 SalesMarketSupportedPayProfiles（銷售市場限定，視需要）

> 💡 **注意：銷售市場（SalesMarket）≠ 環境市場**
> - **環境市場**：SMS 系統部署在哪個國家（TW站、HK站...）
> - **銷售市場限定**：此金流是否只允許特定 SalesMarket 的商店開通
>   - 若**無限制**（所有市場均支援）→ **不加入此 dict，跳過此區塊**
>   - 若**有限制**（如只限 HK 商店）→ 加入對應 SalesMarket key

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 是否有銷售市場限定？
> 例如：「此金流只開放給 HK 銷售市場的商店使用」→ 需加入 `SalesMarketSupportedPayProfiles`。
> 若所有市場的商店都可以開通此金流，請回答「無限制」，本區塊跳過。
> ⚠️ 此處的「銷售市場」與系統部署的環境市場不同！」

若新 PayType 只在特定市場開放：

```csharp
SalesMarketSupportedPayProfiles = new Dictionary<string, IEnumerable<string>>
{
    { nameof(SalesMarketEnum.SG), new HashSet<string>{
        nameof(PayProfileTypeEnum.CreditCardOnce_Razer),
        nameof(PayProfileTypeEnum.GrabPay_Razer),
        nameof(PayProfileTypeEnum.PayNow_Razer),  // ← 加入此行
    }},
    // 其他市場...
};
```

**驗證：**
- [ ] 已與使用者確認市場範圍（單一 or 多市場）
- [ ] 使用 `nameof()` 確保型別安全
- [ ] 市場設定與需求一致
- [ ] 4 個子區塊均已確認

---

## 檔案 3：RazerMSShopSecretSetting.cs（僅 Razer 系列）

**路徑：** `BusinessLogic/Services/ThirdPartyServices/Payments/ShopSecretSettings/PayTypeSettings/RazerMSShopSecretSetting.cs`

> ⚠️ **僅在新增 Razer 系列 PayType 時需要修改此檔。AsiaPay 或其他 Provider 請確認是否有對應的 ShopSecretSetting 需更新。**

**⚠️ 執行前請先與使用者確認：**
> 「新增的翻譯 key 命名為 `PaymentMethod{PayTypeName}`（如 `PaymentMethodPayNowRazer`），確認命名是否正確？
> 此 key 之後需手動加入翻譯資源，此 Skill 不處理翻譯檔本身。」

### 3.1 更新 `_payTypeDisplayNameDic`

```csharp
private readonly IEnumerable<string> _payTypeDisplayNameDic = new string[] {
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodCreditCardRazer,
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodCreditCardInstallmentRazer,
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodOnlinebankRazer,
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodTouchNGoRazer,
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodBoostRazer,
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodGrabPayRazer,
    Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodPayNowRazer,  // ← 加入此行
};
```

**翻譯 key 命名格式：** `PaymentMethod{PayTypeName}`（如 `PaymentMethodPayNowRazer`）

> 注意：翻譯文字本身需手動加入 `.resx` 或翻譯資料庫，此 Skill 不處理翻譯檔。

### 3.2 更新 `SalesMarketSupportedPayMethods`（市場限定時）

```csharp
private readonly IReadOnlyDictionary<string, IEnumerable<string>> SalesMarketSupportedPayMethods =
    new Dictionary<string, IEnumerable<string>>
    {
        { nameof(SalesMarketEnum.SG), new HashSet<string>{
            Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodCreditCardRazer,
            Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodGrabPayRazer,
            Translations.Backend.Service.SimpleShopSecretPaymentServiceSetting.PaymentMethodPayNowRazer,  // ← 加入
        }},
    };
```

**驗證：**
- [ ] `_payTypeDisplayNameDic` 已加入新翻譯 key
- [ ] `SalesMarketSupportedPayMethods` 市場設定正確
