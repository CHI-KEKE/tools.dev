# Phase 1: Core Enum Definition Files

## File 1: `PayProfileTypeDefEnum.cs`
**Path:** `WebStore/Frontend/BE/PayProfile/PayProfileTypeDefEnum.cs`
**Purpose:** Frontend-wide core payment type definition used across the entire order flow.

### Actions
1. Add new enum value — group with same-provider values, maintain provider-group ordering
2. **Update the `All` field** to include the new value — missing this will break system functionality

### Pattern
```csharp
/// <summary>
/// Razer PayNow
/// </summary>
PayNow_Razer = 36028797018963968,
```

**Naming rule:** `{PaymentMethod}_{Provider}` for provider-specific payments.

**To find the next value:** Read all existing enum values, identify the highest power-of-2, multiply by 2.

### Updating the `All` Field
The `All` field is a bitwise OR of every payment type. Append the new value:
```csharp
/// <summary>
/// Any payment type
/// </summary>
All = CreditCardOnce | CreditCardInstallment | ... | ExistingLastType | PayNow_Razer,
```

> ⚠️ **`FakePayType` 絕對不可加入 `All`**，該值有 code comment 明確標示。

### Composite Flag 複合 flag（選擇性更新）

`PayProfileTypeDefEnum` 有以下複合 flag，**需依新 paytype 的路由模式決定是否加入**：

| Composite Flag | 意義 | 何時加 |
|---|---|---|
| `CommonThirdPartyPayType` | 走 CommonThirdPartyPay 路線 | ❌ PaymentMiddleware 路線**不加** |
| `DirectThirdPartyPayType` | 直接第三方 | 視情況 |
| `ThroughPSPThirdPartyPayType` | 透過 PSP | 收付模式為 ThroughPSP → ✅ |
| `DirectToBankThirdPartyPayType` | 直連銀行 | 收付模式為 DirectToBank → ✅ |

**向使用者確認**新 paytype 需加入哪個複合 flag（若有的話）。

---

## File 2: `StatisticsTypeDefEnum.cs`
**Path:** `WebStore/Frontend/BE/PayProfile/StatisticsTypeDefEnum.cs`
**Purpose:** Statistics type definition for reports and data analysis. Maintains 1:1 correspondence with `PayProfileTypeDefEnum`.

### Actions
1. Add enum value with same name as `PayProfileTypeDefEnum` entry
2. Use consistent XML documentation
3. Place in same relative position as in `PayProfileTypeDefEnum`

### Pattern
```csharp
/// <summary>
/// Razer PayNow
/// </summary>
PayNow_Razer = 4503599627370496,
```

> ⚠️ `StatisticsTypeDefEnum` 也有 `CommonThirdPartyPayType` 複合 flag，但**只包含 CommonThirdPartyPayType 路線的 paytype**。PaymentMiddleware 新 paytype **不加入**此複合 flag。

> ⚠️ `StatisticsTypeDefEnum` uses its **own independent bit space** — do NOT copy the value from `PayProfileTypeDefEnum`.

---

## File 3: `RefundRequestTypeDefEnum.cs`
**Path:** `ERP/BE/NineYi.ERP.BE/RefundRequest/RefundRequestTypeDefEnum.cs`
**Purpose:** Defines refund request types corresponding to payment types. Located in ERP project.

> Skip this file if the new payment type **does not support refunds**.

### Actions
1. Add enum value with matching name
2. Maintain same ordering as payment type enums

### Pattern
```csharp
/// <summary>
/// Razer PayNow refund
/// </summary>
PayNow_Razer,
```

Note: This enum does **not** use bit flags — it's a plain sequential enum.
