# Phase 5: Order & Refund Files

## File 1: `MemberTradesOrderGroupEntity.cs`
**Path:** `WebStore/Frontend/BE/MemberTradesOrder/MemberTradesOrderGroupEntity.cs`
**Purpose:** Member order group entity — controls payment type display name in order history/detail views.

### Actions
Add a new `case` in the `DisplayName` property switch-case:

```csharp
case PayProfileTypeDefEnum.PayNow_Razer:
    displayName = NineYi.WebStore.Translation.Backend.Entity.MemberTradesOrderGroup.PayNowRazer;
    break;
```

---

## File 2: `MemberTradesOrderGroupPayInfoForDetailEntity.cs`
**Path:** `WebStore/Frontend/BE/MemberTradesOrder/MemberTradesOrderGroupPayInfoForDetailEntity.cs`
**Purpose:** Member order group payment info detail entity — controls display in payment info detail section.

### Actions
Add a new `case` in the `GetPayProfileDisplayName()` method switch-case:

```csharp
case PayProfileTypeDefEnum.PayNow_Razer:
    return Translation.Backend.Entity.MemberTradesOrderGroupPayInfoForDetail.PayNowRazer;
```

---

## File 3: `GetMemberTradesOrderRefundProcessor.cs` *(if refund supported)*
**Path:** `WebStore/Frontend/BLV2/MemberTradesOrders/MemberTradesOrderProcessor/GetMemberTradesOrderRefundProcessor.cs`
**Purpose:** Determines whether a refund requires bank account information.

> Skip if the new payment type does **not** support refunds.

### Actions
Add the new refund type to the `CheckRefundInfo()` condition chain. PaymentMiddleware payments use direct refund (原路退回) — no bank data needed:

```csharp
if (refundType == RefundRequestTypeDefEnum.CreditCardOnce_Razer ||
    refundType == RefundRequestTypeDefEnum.CreditCardInstallment_Razer ||
    refundType == RefundRequestTypeDefEnum.PayNow_Razer ||      // ← add here
    refundType == RefundRequestTypeDefEnum.OnlineBanking_Razer ||
    // ...
   )
{
    //// PaymentMiddleware refund — direct refund, no bank info required
    return true;
}
```

---

## File 4: `MemberTradesOrderService.cs` *(if refund supported)*
**Path:** `WebStore/Frontend/BLV2/MemberTradesOrders/MemberTradesOrderService.cs`
**Purpose:** Member order service — determines refund info collection logic.

> Skip if the new payment type does **not** support refunds.

### Actions
Add to the refund info determination condition. PaymentMiddleware refunds do not collect extra bank info:

```csharp
|| (payProfileTypeDef == PayProfileTypeDefEnum.PayNow_Razer &&
    refundInfo != null &&
    refundInfo.RefundRequest_TypeDef == nameof(RefundRequestTypeDefEnum.PayNow_Razer))
    //// PayNow_Razer refund — does not collect bank info
```

---

## File 5: `CancelRequestService.cs` *(if cancel supported)*
**Path:** `WebStore/Frontend/BLV2/CancelRequest/CancelRequestService.cs`
**Purpose:** Cancel request service — determines which payment types support third-party cancellation.

> Skip if the new payment type does **not** support order cancellation.

### Actions
Add the new payment type to the third-party pay types list:

```csharp
var thirdPartyPayTypes = new List<PayProfileTypeDefEnum>
{
    PayProfileTypeDefEnum.CreditCardOnce_Razer,
    PayProfileTypeDefEnum.CreditCardInstallment_Razer,
    PayProfileTypeDefEnum.PayNow_Razer,          // ← add here
    PayProfileTypeDefEnum.OnlineBanking_Razer,
    // ...
};
```

---

## File 6: `OverseaPayHelper.cs` *(if oversea payment)*
**Path:** `WebStore/Frontend/BLV2/Utilities/OverseaPayHelper.cs`
**Purpose:** Helper that identifies cross-border/oversea payment types.

> Skip if this is **not** an oversea (cross-border) payment type.

### Actions
Add the new payment type to the oversea pay types list. Use `nameof()` for type safety:

```csharp
private static readonly List<string> OverseaPayTypes = new List<string>
{
    nameof(PayProfileTypeDefEnum.CreditCardOnce_Razer),
    nameof(PayProfileTypeDefEnum.CreditCardInstallment_Razer),
    nameof(PayProfileTypeDefEnum.PayNow_Razer),    // ← add here
    nameof(PayProfileTypeDefEnum.OnlineBanking_Razer),
    // ...
};
```
