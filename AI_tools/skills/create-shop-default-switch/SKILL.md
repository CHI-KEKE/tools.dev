---
name: create-shop-default-switch
description: 在 NineYi.Sms 專案中建立新的 ShopDefault 商店功能開關的完整流程，包含列舉值更新、UI 層讀取開關、解析成 ViewBag 傳遞，以及注入相依服務。當使用者說「新增 ShopDefault 開關」、「加 ShopDefault 開關」、「建立每間商店各自的設定開關」，或功能特性為「頻繁切換」、「開放商店自行管理」、「每間商店有獨立設定值」時，一律使用此 skill。ShopStaticSetting 相關開關請改用 create-shop-static-setting-switch skill。
---

# Create Shop Default Switch（ShopDefault 開關）

在 NineYi.Sms 專案中新增一個 **ShopDefault** 商店功能開關的端對端標準流程。

> **ShopStaticSetting 開關（三段式全域或多筆獨立安全開關）請改用 `create-shop-static-setting-switch` skill。**

## 架構概覽

```
ShopDefault（資料庫）
  └─ GroupTypeDef + Key + Value（每間商店各一筆 ShopDefault_ShopId，無 ShopId=0 全域值）
        ↓ 由 IShopDefaultService.Get(shopId, groupTypeDef, key) 讀取（含快取）
        ↓ 依 Value 型別選擇解析方式（bool.TryParse / int.TryParse / 直接使用）
        ↓ 透過 ViewBag 或直接回傳值傳給呼叫端
```

與 ShopStaticSetting 的關鍵差異：

| | ShopDefault | ShopStaticSetting |
|---|---|---|
| **資料筆數** | 每間商店一筆，無全域預設 | 可有 ShopId=0 全域預設 |
| **使用情境** | 頻繁切換、商店自行管理 | 上線安全開關、Pilot 控制 |
| **Service** | `IShopDefaultService` | `IShopStaticSettingService` |
| **Enum** | `ShopDefaultGroupTypeDefEnum` / `ShopDefaultKeyEnum` | `ShopStaticSettingGroupNameEnum` / `ShopStaticSettingKeyEnum` |

---

## 完整實作步驟

### Step 1：確認需求

向使用者確認以下資訊（對話中已有答案則直接沿用）：

1. **GroupTypeDef** — 開關所屬群組，須是 `ShopDefaultGroupTypeDefEnum` 已存在的值（例如 `PromotionEngine`）
2. **Key** — 開關識別名稱，須是 `ShopDefaultKeyEnum` 已存在的值（例如 `DiscountReachPriceWithFreeGift`）
3. **Value 型別** — `bool`、`int` 或其他自訂字串？
4. **使用位置** — 哪個 Controller Action 或 Service 要讀取此開關
5. **ViewBag 名稱**（若在 Controller）

### Step 2：新增 GroupTypeDefEnum（若不存在）

檔案：`BusinessLogic\BE\ShopDefaults\ShopDefaultGroupTypeDefEnum.cs`

> 此 enum 首行有說明「若要新增請加在最後面」，務必遵守。

若 GroupTypeDef 已存在則跳過；否則在 enum 最後新增：

```csharp
/// <summary>
/// {中文說明}
/// </summary>
{GroupTypeDef}
```

### Step 3：新增 KeyEnum 值（若不存在）

檔案：`BusinessLogic\BE\ShopDefaults\ShopDefaultKeyEnum.cs`

> 此 enum 首行同樣說明「若要新增請加在最後面」，務必遵守，否則會影響前端傳入的數字排序。

在 enum 最後（`}` 前）新增，不修改任何現有值：

```csharp
/// <summary>
/// {中文說明}
/// </summary>
{KeyName}
```

### Step 4：新增 ShopDefault 資料

ShopDefault 資料不須撰寫 SQL 語法，請提醒使用者透過系統介面「**新增 SystemDefault**」完成設定即可。

### Step 5：在 Controller 讀取開關（若使用位置為 Controller Action）

#### 5a. 確認 using 引用

檢查並補上缺少的 using：

```csharp
using NineYi.Common.Utility.DataAccess.ShopDefaults;
using NineYi.Sms.BL.BE.ShopDefaults;
```

#### 5b. 確認 IShopDefaultService 已注入

`IShopDefaultService` 由 `NineYi.Common.Utility.DataAccess.ShopDefaults` 套件提供，若 Controller 尚未有 `_shopDefaultService`，補上欄位與建構函式參數：

```csharp
/// <summary>
/// IShopDefaultService
/// </summary>
private readonly IShopDefaultService _shopDefaultService;
```

建構函式加入 `IShopDefaultService shopDefaultService` 並指派。Autofac 已自動掃描，不需修改 DI 設定。

#### 5c. Action 中讀取開關

**Value 為 bool 型別：**

```csharp
//// 讀取「{中文功能說明}」商店設定；若商店無此設定則 setting 為 null，預設視為關閉
var {camelCaseKey}Setting = this._shopDefaultService.Get(
    shopId,
    nameof(ShopDefaultGroupTypeDefEnum.{GroupTypeDef}),
    nameof(ShopDefaultKeyEnum.{Key}));

bool is{FeatureName}Enabled = false;
if ({camelCaseKey}Setting != null)
{
    bool.TryParse({camelCaseKey}Setting.ShopDefault_Value, out is{FeatureName}Enabled);
}
this.ViewBag.{ViewBagName} = is{FeatureName}Enabled;
```

**Value 為 int 型別：**

```csharp
var {camelCaseKey}Setting = this._shopDefaultService.Get(
    shopId,
    nameof(ShopDefaultGroupTypeDefEnum.{GroupTypeDef}),
    nameof(ShopDefaultKeyEnum.{Key}));

int {camelCaseKey}Value = 0;
if ({camelCaseKey}Setting != null)
{
    int.TryParse({camelCaseKey}Setting.ShopDefault_Value, out {camelCaseKey}Value);
}
this.ViewBag.{ViewBagName} = {camelCaseKey}Value;
```

**注意：** `Get()` 的 GroupTypeDef 與 Key 參數傳入字串，建議使用 `nameof()` 避免拼字錯誤。部分舊程式使用 `.ToString()` 也可行，但 `nameof()` 在編譯期即可發現錯誤。

### Step 6：在 Service 讀取開關（若使用位置為 Service）

注入 `IShopDefaultService`（同 Step 5b 模式），然後：

```csharp
//// 讀取「{中文功能說明}」商店設定
var setting = this._shopDefaultService.Get(
    shopId,
    nameof(ShopDefaultGroupTypeDefEnum.{GroupTypeDef}),
    nameof(ShopDefaultKeyEnum.{Key}));

bool is{FeatureName}Enabled = false;
if (setting != null)
{
    bool.TryParse(setting.ShopDefault_Value, out is{FeatureName}Enabled);
}
```

---

## 完成確認清單

- [ ] `ShopDefaultGroupTypeDefEnum` 已包含所需 GroupTypeDef，且新增在最後
- [ ] `ShopDefaultKeyEnum` 已包含所需 Key，且新增在最後
- [ ] 已透過系統介面「新增 SystemDefault」完成資料設定
- [ ] Controller/Service 已加入必要 `using` 引用
- [ ] `IShopDefaultService` 已注入（欄位 + 建構函式）
- [ ] 讀取使用 `_shopDefaultService.Get(shopId, nameof(...), nameof(...))`
- [ ] 解析依 Value 型別選擇 `bool.TryParse` / `int.TryParse`，並設定合理預設值
- [ ] `setting` 做 null 檢查，避免 NullReferenceException

---

## 常見錯誤與注意事項

- **不要使用 async/await**，此專案全部使用同步方法
- `ShopDefault` 沒有 ShopId=0 的全域預設值；若商店無此設定，`Get()` 會回傳 `null`，讀取前務必做 null 檢查
- GroupTypeDef 與 Key 參數建議用 `nameof()` 傳入，避免字串拼字錯誤且可在 rename refactor 時一併更新
- `ShopDefaultKeyEnum` 的數字順序影響前端行為，**絕對不能插入或調整現有值的順序，只能加在最後**
- **ShopStaticSetting 開關**（安全開關、三段式全域控制）不屬於本 skill 範疇，請改用 `create-shop-static-setting-switch` skill