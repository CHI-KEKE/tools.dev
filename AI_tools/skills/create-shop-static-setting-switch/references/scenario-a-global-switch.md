# 情境 A：三段式全域開關

**適用場景**：Pilot 商店少、最終會全店開放的安全開關。  
1 筆資料（`ShopId=0`），Value 格式為 `{bool}|{shopIds}|{rangeIds}`。

情境 A 的 Value 三段格式說明：

| 格式 | 意義 |
|------|------|
| `true\|none\|none` | 全部開啟 |
| `false\|none\|none` | 全部關閉 |
| `true\|12765\|none` | 僅 shopId=12765 開啟 |
| `true\|8,233\|30-40` | 單店清單 + 範圍店同時判斷 |

---

## Step 4A：建立 SQL 腳本

在 `c:\91APP\nineyi.database.operation\VSTS\VSTS{VSTS票號}\` 建立 `Step01_Insert_ShopStaticSetting.sql`。

使用 `templates/scenario-a-insert.sql` 範本，填入以下變數：

| 變數 | 說明 |
|------|------|
| `{GroupName}` | 開關群組名稱 |
| `{Key}` | 開關識別名稱 |
| `{bool}` | `true` 或 `false` |
| `{shopIds}` | 商店 ID 清單（逗號分隔）或 `none` |
| `{rangeIds}` | 商店範圍（例如 `30-40`）或 `none` |
| `{Description}` | 中文說明文字 |
| `{VSTS票號}` | VSTS 票號（不含前綴 VSTS） |

---

## Step 5A：在 Controller 讀取開關（若使用位置為 Controller Action）

### 5a. 確認 using 引用

檢查並補上缺少的 using：

```csharp
using NineYi.Sms.BL.BE.ShopStaticSettings;
using NineYi.Sms.BL.Services.ShopStaticSettings;
using NineYi.Sms.Utilities.Helpers;
```

### 5b. 注入 IShopStaticSettingService

若 Controller 尚未有 `_shopStaticSettingService`，補上欄位與建構函式參數：

```csharp
/// <summary>
/// IShopStaticSettingService
/// </summary>
private readonly IShopStaticSettingService _shopStaticSettingService;
```

建構函式加入 `IShopStaticSettingService shopStaticSettingService` 並指派。Autofac 已自動掃描，不需修改 DI 設定。

### 5c. Action 中讀取開關

```csharp
//// 讀取「{中文功能說明}」開關，優先取商店個別設定，若無則 fallback 至 ShopId=0 全域預設值
var {camelCaseKey}Setting = this._shopStaticSettingService.GetShopStaticSettingByGroupNameKeyOrDefault(
    shopId,
    ShopStaticSettingGroupNameEnum.{GroupName},
    ShopStaticSettingKeyEnum.{Key});

//// 解析三段式開關字串（true|shopIds|rangeIds），判斷此商店是否啟用
this.ViewBag.{ViewBagName} = {camelCaseKey}Setting != null
    && SettingHelper.GetIsEnabledInSettingByShopId(shopId, {camelCaseKey}Setting.Value);
```

---

## Step 6A：在 Service 讀取開關（若使用位置為 Service）

注入 `IShopStaticSettingService`（同 Step 5b 模式），然後讀取與解析：

```csharp
//// 讀取「{中文功能說明}」開關，優先取商店個別設定，若無則 fallback 至 ShopId=0 全域預設值
var setting = this._shopStaticSettingService.GetShopStaticSettingByGroupNameKeyOrDefault(
    shopId, ShopStaticSettingGroupNameEnum.{GroupName}, ShopStaticSettingKeyEnum.{Key});

//// 解析三段式開關字串（true|shopIds|rangeIds），判斷此商店是否啟用
bool is{FeatureName} = setting != null
    && SettingHelper.GetIsEnabledInSettingByShopId(shopId, setting.Value);
```

---

## 完成確認清單（情境 A）

**共用步驟：**
- [ ] `ShopStaticSettingGroupNameEnum` 已包含所需 GroupName
- [ ] `ShopStaticSettingKeyEnum` 已新增對應 Key 值，且放在最後
- [ ] SQL 腳本已建立於正確 VSTS 目錄
- [ ] Controller/Service 已加入必要 `using` 引用（含 `NineYi.Sms.Utilities.Helpers`）
- [ ] `IShopStaticSettingService` 已注入（欄位 + 建構函式）

**情境 A 專屬：**
- [ ] SQL Value 符合三段格式 `{bool}|{shopIds}|{rangeIds}`
- [ ] SQL 只有 1 筆，`ShopId=0`
- [ ] 讀取使用 `GetShopStaticSettingByGroupNameKeyOrDefault`
- [ ] 解析使用 `SettingHelper.GetIsEnabledInSettingByShopId`
