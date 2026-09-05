# 情境 B：多筆獨立開關

**適用場景**：Pilot 商店較多、個別商店需獨立控制的開關。  
多筆資料：每間 Pilot 商店各一筆（`Value='true'`）+ 1 筆全域預設（`ShopId=0`，`Value='false'`）。

---

## Step 4B：建立 SQL 腳本

在 `c:\91APP\nineyi.database.operation\VSTS\VSTS{VSTS票號}\` 建立 `Step01_Insert_ShopStaticSetting.sql`。

使用 `templates/scenario-b-insert.sql` 範本，填入以下變數：

| 變數 | 說明 |
|------|------|
| `{GroupName}` | 開關群組名稱 |
| `{Key}` | 開關識別名稱 |
| `{Description}` | 中文說明文字 |
| `{VSTS票號}` | VSTS 票號（不含前綴 VSTS） |
| `{ShopId}` | Pilot 商店 ID（每間商店複製一個 INSERT 區塊） |

> Pilot 商店區塊（`ShopId={ShopId}`）依實際商店數量重複複製，每間商店一個 INSERT。

---

## Step 5B：在 Controller 讀取開關（若使用位置為 Controller Action）

### 5a. 確認 using 引用

檢查並補上缺少的 using：

```csharp
using NineYi.Sms.BL.BE.ShopStaticSettings;
using NineYi.Sms.BL.Services.ShopStaticSettings;
```

> 情境 B **不需要** `using NineYi.Sms.Utilities.Helpers`。

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
//// 讀取「{中文功能說明}」商店個別開關，優先取商店個別設定，若無則 fallback 至 ShopId=0 全域預設值
var {camelCaseKey}Setting = this._shopStaticSettingService.GetShopStaticSettingByGroupNameKeyOrDefault(
    shopId,
    ShopStaticSettingGroupNameEnum.{GroupName},
    ShopStaticSettingKeyEnum.{Key});

//// 解析 true/false 字串，此商店若無設定則預設關閉
bool is{FeatureName} = false;
if ({camelCaseKey}Setting != null)
{
    bool.TryParse({camelCaseKey}Setting.Value, out is{FeatureName});
}

this.ViewBag.{ViewBagName} = is{FeatureName};
```

---

## Step 6B：在 Service 讀取開關（若使用位置為 Service）

注入 `IShopStaticSettingService`（同 Step 5b 模式），然後讀取與解析：

```csharp
//// 讀取「{中文功能說明}」商店個別開關，優先取商店個別設定，若無則 fallback 至 ShopId=0 全域預設值
var setting = this._shopStaticSettingService.GetShopStaticSettingByGroupNameKeyOrDefault(
    shopId, ShopStaticSettingGroupNameEnum.{GroupName}, ShopStaticSettingKeyEnum.{Key});

//// 解析 true/false 字串，此商店若無設定則預設關閉
bool is{FeatureName} = false;
if (setting != null)
{
    bool.TryParse(setting.Value, out is{FeatureName});
}
```

---

## 完成確認清單（情境 B）

**共用步驟：**
- [ ] `ShopStaticSettingGroupNameEnum` 已包含所需 GroupName
- [ ] `ShopStaticSettingKeyEnum` 已新增對應 Key 值，且放在最後
- [ ] SQL 腳本已建立於正確 VSTS 目錄
- [ ] Controller/Service 已加入必要 `using` 引用
- [ ] `IShopStaticSettingService` 已注入（欄位 + 建構函式）

**情境 B 專屬：**
- [ ] SQL 含全域預設（`ShopId=0`，`Value='false'`）
- [ ] SQL 含各 Pilot 商店筆數（每間商店一筆，`Value='true'`）
- [ ] 讀取使用 `GetShopStaticSettingByGroupNameKeyOrDefault`
- [ ] 解析使用 `bool.TryParse`，預設值為 `false`
- [ ] **未**引用 `SettingHelper`（情境 B 不需要）
