---
name: mweb-paymentmiddleware-add-paytype
description: >
  Step-by-step guide for adding a new PaymentMiddleware-based payment type
  exclusively to the **MobileWebMall (mweb)** project (repo: nineyi.webstore.mobilewebmall,
  solution: NineYi.WebStore.MallAndApi.sln). This skill is ONLY applicable to this
  specific mweb repository and must NOT be used for any other project.
  Use when integrating a new mweb payment method that routes through the PaymentMiddleware
  infrastructure (e.g., Razer series, Stripe, CheckoutDotCom, AsiaPay, Cybersource,
  EftPay, KPay, Atome, SwiftPass, 2C2P, QFPay, PayMe).
  Covers ~30 files across enum definitions, sale page, shopping cart, payment processing,
  order/refund flow, WebAPI controllers, and translation resources.
---

# [mweb] Add PaymentMiddleware Payment Type

> ⚠️ **mweb 專案限定 Skill**
> 本 Skill 僅適用於 **`nineyi.webstore.mobilewebmall`（mweb）** 專案（solution: `NineYi.WebStore.MallAndApi.sln`）。
> 若目前工作目錄不是此專案，請立即停止並告知使用者：「此 Skill 僅適用於 mweb（nineyi.webstore.mobilewebmall）專案」。

## Overview

This skill guides adding a new **PaymentMiddleware-based** payment type to the **mweb (nineyi.webstore.mobilewebmall)** project (~30 files). Work through each phase in order; read the linked reference file before editing the corresponding files.

---

## Step 1: Validate Input & Determine Scope

**先確認專案環境：**
- 確認 `NineYi.WebStore.MallAndApi.sln` 存在於工作目錄
- 確認 `WebStore/Frontend/BE/PayProfile/PayProfileTypeDefEnum.cs` 存在
- 若任一不存在，**立即停止**並告知使用者：「此 Skill 僅適用於 nineyi.webstore.mobilewebmall 專案」

**Collect these inputs first:**
1. **Payment type name** — PascalCase, follow `{Method}_{Provider}` pattern (e.g., `PayNow_Razer`, `CreditCardOnce_Stripe`)
2. **Provider** — which PaymentMiddleware provider? (Razer / Stripe / CheckoutDotCom / AsiaPay / etc.)
3. **Check for duplicates** — read `PayProfileTypeDefEnum.cs` and confirm name doesn't exist

**Ask the user these scoping questions before proceeding:**

| Question | Impact |
|---|---|
| **目標市場？** TW / 海外 / 兩者都要 | 決定 `PayProfileTypeDefComparer` 要加哪個 list |
| **是否使用現有 Provider 的 PayChannelService？** | 是 → 加 case；否 → 建立新 `{Provider}PayChannelService.cs` 並在 `ServiceModule.cs` 注冊 |
| **幣別模式？** 多市場幣別(`SalesCurrency`) / 預設幣別(`DefaultPayment.Currency`) | 決定 `CreateTradesOrderProcessor` 的 currency switch 要用哪個 |
| **收付模式？** DirectToBank / ThroughPSP / DirectToBankMid | 決定 `AppSettings.{Env}.config` 要加到哪個 key |
| **需要退款支援？** | 是 → 含 `RefundRequestTypeDefEnum.cs` + refund files |
| **需要取消訂單支援？** | 是 → 含 cancel files |
| **是否跨境（oversea）付款？** | 是 → 含 `OverseaPayHelper.cs` |
| **是否需要加入複合 flag？** (如 `ThroughPSPThirdPartyPayType`、`DirectToBankThirdPartyPayType`) | 視 provider 路由模式決定，見 enum-files.md |

---

## Step 2: Determine Enum Bit-Flag Values

Read these three files and find the **next available power-of-2** in each independent bit space:

- `WebStore/Frontend/BE/PayProfile/PayProfileTypeDefEnum.cs`
- `WebStore/Frontend/BE/PayProfile/StatisticsTypeDefEnum.cs`
- `WebStore/Frontend/BE/Search/SearchShopPayTypeEnum.cs`

> ⚠️ All three enums use **separate bit spaces**. Do NOT reuse the same decimal value across files.

---

## Workflow

### Phase 1 — Core Enum Definitions (2–3 files)
→ Read **[references/enum-files.md](references/enum-files.md)**

| File | Action |
|---|---|
| `WebStore/Frontend/BE/PayProfile/PayProfileTypeDefEnum.cs` | Add enum value; update `All` field |
| `WebStore/Frontend/BE/PayProfile/StatisticsTypeDefEnum.cs` | Add corresponding statistics enum value |
| `ERP/BE/NineYi.ERP.BE/RefundRequest/RefundRequestTypeDefEnum.cs` | Add refund type *(skip if no refund)* |

---

### Phase 2 — Sale Page & Search (4 files)
→ Read **[references/salepage-search-files.md](references/salepage-search-files.md)**

| File | Action |
|---|---|
| `WebStore/Frontend/BLV2/SalePages/PayProfileTypeDefComparer.cs` | 依目標市場加到 `_sortedPayProfileTypeDef`（海外）和/或 `_sortedPayProfileTypeDefTW`（台灣）|
| `WebStore/Frontend/BLV2/SalePagesV2/SalePageV2Processor/GetPayTypeProcessor.cs` | Add switch-case with display string |
| `WebStore/Frontend/BE/Search/SearchShopPayTypeEnum.cs` | Add bit-flag enum with `[LocalizableDescription]` |
| `WebStore/Frontend/BLV2/Search/SearchService.cs` | Add handling in payment type list processing |

---

### Phase 3 — Shopping Cart (3 files)
→ Read **[references/shopping-cart-files.md](references/shopping-cart-files.md)**

| File | Action |
|---|---|
| `WebStore/Frontend/BE/ShoppingCartV2/ShoppingCartClientPayTypeGroupEntity.cs` | Add `DisplayName` switch-case |
| `WebStore/Frontend/BLV2/ShoppingCartsV2/StatisticsTypeDefComparer.cs` | Add to both sorted lists |
| `WebStore/Frontend/BLV2/ShoppingCartsV2/ShoppingCartV2Processor/PickupShoppingCartCheckoutTypeV2Processor.cs` | Add to third-party pay switch-case |

---

### Phase 4 — Payment Processing (3–5 files)
→ Read **[references/payment-process-files.md](references/payment-process-files.md)**

| File | Action |
|---|---|
| `WebStore/Frontend/BLV2/PayProcesses/Processors/GetPayProcessDataProcessor.cs` | Add to two switch-cases |
| `WebStore/Frontend/BLV2/PayProcesses/Processors/ThirdPartyPayApiProcessor.cs` | Add to third-party switch-case |
| `WebStore/Frontend/BLV2/PayProcesses/Processors/CreateTradesOrderProcessor.cs` | Add to **3個** switch-cases（第三方判斷 / 退款資訊 / 幣別設定） |
| `WebStore/Frontend/BLV2/ThirdPartyPay/PaymentMiddlewareService.cs` | Add currency/market support *(if multi-currency)* |
| `WebStore/Frontend/BLV2/PayChannel/{Provider}PayChannelService.cs` | 在 `GetPayExtendInfo()` 內的 `GetChannel()` 加 case *(or create new)* |
| `WebStore/Frontend/BLV2/Modules/ServiceModule.cs` | 僅**新 provider** 時需在此注冊 Named DI |

---

### Phase 5 — Order & Refund (4–6 files)
→ Read **[references/order-refund-files.md](references/order-refund-files.md)**

| File | Action |
|---|---|
| `WebStore/Frontend/BE/MemberTradesOrder/MemberTradesOrderGroupEntity.cs` | Add `DisplayName` switch-case |
| `WebStore/Frontend/BE/MemberTradesOrder/MemberTradesOrderGroupPayInfoForDetailEntity.cs` | Add `GetPayProfileDisplayName()` case |
| `WebStore/Frontend/BLV2/MemberTradesOrders/MemberTradesOrderProcessor/GetMemberTradesOrderRefundProcessor.cs` | Add to refund type condition *(if refund)* |
| `WebStore/Frontend/BLV2/MemberTradesOrders/MemberTradesOrderService.cs` | Add to refund info determination *(if refund)* |
| `WebStore/Frontend/BLV2/CancelRequest/CancelRequestService.cs` | Add to third-party cancel list *(if cancel)* |
| `WebStore/Frontend/BLV2/Utilities/OverseaPayHelper.cs` | Add to oversea pay list *(if oversea)* |

---

### Phase 6 — WebAPI Controllers (4 files)
→ Read **[references/controller-translation-files.md](references/controller-translation-files.md)**

| File | Action |
|---|---|
| `WebStore/Frontend/MobileWebMallV2/Controllers/GlobalPayController.cs` | Add display name switch-case |
| `WebStore/WebAPI/Controllers/TradesOrderLiteController.cs` | Add third-party payment conditions |
| `WebStore/WebAPI/Controllers/TradesOrderV2Controller.cs` | Add third-party payment conditions |
| `WebStore/WebAPI/Controllers/CancelRequestV2Controller.cs` | Add to supported cancel types *(if cancel)* |

---

### Phase 7 — Translation Resources (7 files)
→ Read **[references/controller-translation-files.md](references/controller-translation-files.md)**

Add a `GetString()` property to each AutoGenerated translation file. Translation key naming convention: `{snake_case_payment_name}` (e.g., `pay_now_razer`).

---

### Phase 8 — Configuration (optional)

依 Step 1 確認的**收付模式**，將新 paytype 加到對應的 config key。設定位於 `WebStore/WebAPI/` 專案下：

```
WebStore/WebAPI/AppSettings.Debug.MY.config
WebStore/WebAPI/AppSettings.QA.MY.config
WebStore/WebAPI/AppSettings.Prod.MY.config
（以及其他市場的對應 config）
```

| 收付模式 | Config Key |
|---|---|
| DirectToBank | `Dev.PayType.DirectToBank` |
| ThroughPSP | `Dev.PayType.ThroughPSP` |
| DirectToBankMid | `Dev.PayType.DirectToBankMid` |

範例（DirectToBank）：
```xml
<add key="Dev.PayType.DirectToBank" value="...,CreditCardOnce_Razer,PayNow_Razer,NewPayType_Razer" />
```

---

## Final Verification

1. Compile: `msbuild NineYi.WebStore.MallAndApi.sln /p:Configuration=Debug`
2. Confirm `PayProfileTypeDefEnum.All` includes the new type
3. Confirm all three enum bit values are unique in their respective enums
4. Confirm all 7 translation files have the corresponding property added
5. Search for similar existing payment type name (e.g., `OnlineBanking_Razer`) across the codebase to catch any missed locations
