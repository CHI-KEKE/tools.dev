# Phase 3: Shopping Cart Files

## File 1: `ShoppingCartClientPayTypeGroupEntity.cs`
**Path:** `WebStore/Frontend/BE/ShoppingCartV2/ShoppingCartClientPayTypeGroupEntity.cs`
**Purpose:** Shopping cart client payment type group entity — controls display name in cart UI.

### Actions
Add a new `case` in the `DisplayName` property switch-case:

```csharp
case nameof(StatisticsTypeDefEnum.PayNow_Razer):
{
    return Translation.Backend.Entity.ShoppingCartClientPayTypeGroup.PayNowRazer;
}
```

> 📌 Key is `nameof(StatisticsTypeDefEnum.{NewType})`, not `PayProfileTypeDefEnum`.

---

## File 2: `StatisticsTypeDefComparer.cs`
**Path:** `WebStore/Frontend/BLV2/ShoppingCartsV2/StatisticsTypeDefComparer.cs`
**Purpose:** Defines sorting order for statistics-based payment types in shopping cart views.

### Actions
Add to **both** sorting lists in the file, keeping same-provider types grouped:

**`GetOrderedForShoppingCart()`**
```csharp
private static IEnumerable<StatisticsTypeDefEnum> GetOrderedForShoppingCart()
{
    return new List<StatisticsTypeDefEnum>
    {
        // ...
        StatisticsTypeDefEnum.CreditCardInstallment_Razer,
        StatisticsTypeDefEnum.PayNow_Razer,        // ← add here
        StatisticsTypeDefEnum.OnlineBanking_Razer,
        // ...
    };
}
```

**Also add to the second list** (typically `GetOrderedForStatistics()` or similar) — read the file to confirm the second method name.

---

## File 3: `PickupShoppingCartCheckoutTypeV2Processor.cs`
**Path:** `WebStore/Frontend/BLV2/ShoppingCartsV2/ShoppingCartV2Processor/PickupShoppingCartCheckoutTypeV2Processor.cs`
**Purpose:** Handles checkout type determination for convenience store pickup flow.

### Actions
Add the new payment type to the third-party payment switch-case:

```csharp
case StatisticsTypeDefEnum.PayNow_Razer:
case StatisticsTypeDefEnum.OnlineBanking_Razer:
    //// Third-party payment — convenience store pickup not applicable
    break;
```

> 📌 Group with existing cases for the same provider.
