# 共用步驟（Step 1–3）

這些步驟不受情境 A/B 影響，無論哪種情境都必須執行。

---

## Step 1：確認情境與需求

> ⚠️ **必須先問情境選擇，再詢問其他細節。情境 A 與情境 B 的 SQL 結構和解析方式完全不同，未確認情境前不得開始實作。**

### 第一優先：單獨詢問情境選擇

在對話中尚未明確說明時，必須先問：
> 「請問這個開關要使用情境 A（三段式全域，Value 格式為 `true|shopIds|rangeIds`）還是情境 B（多筆獨立，每間商店各一筆 `true`/`false`）？」

### 確認情境後，收集以下資訊

> ⚠️ **GroupName 可從上下文（如 Controller 名稱、Action 名稱、Service 名稱）推斷，但推斷結果必須向使用者明確確認後才能使用，不得直接採用。**

1. **GroupName** — 開關所屬群組，須是 `ShopStaticSettingGroupNameEnum` 已存在的值（例如 `PromotionEngine`）；可從上下文推斷合理值，但必須與使用者確認
2. **Key** — 開關識別名稱（例如 `EnablePayShippingMultipleGiftSetting`）
3. **初始 Value**
   - 情境 A：三段格式（例如 `true|12765|none`）
   - 情境 B：`true` 或 `false` 或其他自訂字串
4. **Description** — 資料庫欄位說明文字（中文），前綴 `N` 用於 SQL
5. **VSTS 票號** — SQL 的 CreatedUser/UpdatedUser 欄位
6. **使用位置** — 哪個 Controller Action 或 Service 要讀取此開關
7. **ViewBag 名稱**（若在 Controller）— 例如 `IsEnablePayShippingMultipleGiftSetting`

---

## Step 2：新增 GroupName（若不存在）

檔案：`BusinessLogic\BE\ShopStaticSettings\ShopStaticSettingGroupNameEnum.cs`

若 GroupName 已存在則跳過；否則在 enum 最後新增：

```csharp
/// <summary>
/// {中文說明}
/// </summary>
{GroupName}
```

---

## Step 3：新增 KeyEnum 值

檔案：`BusinessLogic\BE\ShopStaticSettings\ShopStaticSettingKeyEnum.cs`

在 enum 最後（`}` 前）新增，不修改任何現有值：

```csharp
/// <summary>
/// {中文說明}
/// </summary>
{KeyName}
```
