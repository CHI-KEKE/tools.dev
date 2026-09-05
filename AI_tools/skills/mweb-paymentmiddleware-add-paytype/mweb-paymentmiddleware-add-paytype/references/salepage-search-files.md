# Phase 2: Sale Page & Search Files

## File 1: `PayProfileTypeDefComparer.cs`
**Path:** `WebStore/Frontend/BLV2/SalePages/PayProfileTypeDefComparer.cs`
**Purpose:** 定義商品頁金流方式的排序優先順序。

> 📌 Class 頂端 XML comment 說明：「新增新的金流請增加在 `_sortedPayProfileTypeDef`, `_sortedPayProfileTypeDefTW`」

### 實際結構

此 class 有**兩個 private `List<PayProfileTypeDefEnum>` 欄位**（不是方法）：

| 欄位名稱 | 用途 | 啟用條件 |
|---|---|---|
| `_sortedPayProfileTypeDef` | 海外市場預設排序 | `SettingHelper.DefaultCountry != "TW"` |
| `_sortedPayProfileTypeDefTW` | 台灣市場預設排序 | `SettingHelper.DefaultCountry == "TW"` |

`Compare()` 方法在執行時透過 `SettingHelper.DefaultCountry == "TW"` 決定使用哪個 list。

### Actions

依 Step 1 確認的**目標市場**決定要加哪個 list（或兩個都加）：

| 目標市場 | 要加的 list |
|---|---|
| 僅海外 | `_sortedPayProfileTypeDef` |
| 僅台灣 | `_sortedPayProfileTypeDefTW` |
| 兩者都要 | **兩個都加** |

> ⚠️ 參考現有同 provider 的 paytype 位置（如 `CreditCardInstallment_Razer` 後面），確保新 paytype 插入在同 provider 的群組內。

### Pattern（以 `_sortedPayProfileTypeDef` 海外 list 為例）
```csharp
private readonly List<PayProfileTypeDefEnum> _sortedPayProfileTypeDef = new List<PayProfileTypeDefEnum>()
{
    // ...
    PayProfileTypeDefEnum.CreditCardOnce_Razer,
    PayProfileTypeDefEnum.CreditCardInstallment_Razer,
    PayProfileTypeDefEnum.PayNow_Razer,        // ← 現有項目
    PayProfileTypeDefEnum.NewPayType_Razer,    // ← 新增在同 provider 群組內
    PayProfileTypeDefEnum.OnlineBanking_Razer,
    // ...
};
```

---

## File 2: `GetPayTypeProcessor.cs`
**Path:** `WebStore/Frontend/BLV2/SalePagesV2/SalePageV2Processor/GetPayTypeProcessor.cs`
**Purpose:** Handles payment type display logic for Sale Page V2.

### Actions
Add a new `case` in the switch-case structure:

```csharp
case PayProfileTypeDefEnum.PayNow_Razer:
    item.PayProfileTypeDef = PayProfileTypeDefEnum.PayNow_Razer.ToString();
    item.DisplayString = Translation.Frontend.SalePage.PayNowRazer;
    payTypeList.Add(item);
    break;
```

> 📌 The translation key reference (`Translation.Frontend.SalePage.PayNowRazer`) must match the property added in Phase 7.

---

## File 3: `SearchShopPayTypeEnum.cs`
**Path:** `WebStore/Frontend/BE/Search/SearchShopPayTypeEnum.cs`
**Purpose:** Payment type enum for search/filter functionality.

### Actions
1. Add bit-flag enum value — find next available power-of-2 in this file's own bit space
2. Add `[LocalizableDescription]` attribute referencing the search translation resource

```csharp
/// <summary>
/// Razer PayNow
/// </summary>
[LocalizableDescription(typeof(SearchV2), nameof(Translation.Backend.Webapi.SearchV2.PayNowRazer))]
PayNow_Razer = 9007199254740992,
```

> ⚠️ `SearchShopPayTypeEnum` has its **own independent bit space** — separate from `PayProfileTypeDefEnum` and `StatisticsTypeDefEnum`.

---

## File 4: `SearchService.cs`
**Path:** `WebStore/Frontend/BLV2/Search/SearchService.cs`
**Purpose:** Search service business logic — maps `SearchShopPayTypeEnum` to active pay type list.

### Actions
Add handling for the new payment type in the payment type list processing block. Use `nameof()` for type safety:

```csharp
var razerPayNowType = payTypeList.FirstOrDefault(x => x.TypeDef == nameof(SearchShopPayTypeEnum.PayNow_Razer));
if (razerPayNowType != null)
{
    newPayTypeList.Add(razerPayNowType);
}
```

> 📌 Group the new entry with existing entries for the same provider (e.g., all Razer-related blocks together).
