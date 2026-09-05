---
name: create-shop-static-setting-switch
description: 在 NineYi.Sms 專案中建立新的商店功能開關（ShopStaticSetting）的完整流程，包含 SQL 資料插入、列舉值更新、UI 層讀取開關、解析成 ViewBag 傳遞，以及注入相依服務。當使用者說「新增開關」、「加開關」、「建立 ShopStaticSetting」、「加功能開關」，或需要在 Controller/Service 讀取三層式開關設定（true|shopIds|rangeIds）時，一律使用此 skill。ShopDefault 相關開關請改用 create-shop-default-switch skill。
---

# Create Shop Static Setting Switch（ShopStaticSetting 開關）

在 NineYi.Sms 專案中新增一個 **ShopStaticSetting** 商店功能開關的端對端標準流程。

> **ShopDefault 開關（頻繁切換、商店自行管理）請改用 `create-shop-default-switch` skill。**

## 情境比較

| | 情境 A：三段式全域開關 | 情境 B：多筆獨立開關 |
|---|---|---|
| **SQL 結構** | 1 筆，`ShopId=0`，Value 為三段格式 | 多筆，每間商店一筆 + 1 筆 `ShopId=0` |
| **Value 格式** | `true\|shopIds\|rangeIds` | `true` / `false`（或其他自訂值） |
| **解析方式** | `SettingHelper.GetIsEnabledInSettingByShopId` | `bool.TryParse` |
| **適用場景** | Pilot 商店少、最終會全店開放的安全開關 | Pilot 商店較多、個別商店需獨立控制的開關 |

## 架構概覽

```
ShopStaticSetting（資料庫）
  └─ GroupName + Key + Value
        ↓ 由 ShopStaticSettingService 讀取（含快取）
        ↓ 依情境選擇解析方式（SettingHelper 或 bool.TryParse）
        ↓ 透過 ViewBag 或直接回傳 bool 傳給呼叫端
```

## Operating Sequence

> ‼️ **步驟 1 與步驟 2 之間有必要的使用者互動暫停點，不得合併或跳過。**

1. 載入 `references/common-steps.md`。
2. **【第一輪提問 — 單獨詢問情境，必須暫停等待回覆】**  
   執行 `common-steps.md` Step 1「第一優先：單獨詢問情境選擇」，只問情境 A 或 B，不附帶任何其他問題。等待使用者回覆後才能繼續。
3. **【第二輪提問 — 確認 GroupName 及收集其他細節，必須暫停等待回覆】**  
   根據上下文推斷 GroupName，但必須在此輪明確列出讓使用者確認，逐步收集 Key、Value、Description、VSTS 票號、使用位置、ViewBag 名稱。等待使用者回覆後才能繼續。
4. 確認情境與所有細節後，依情境載入對應的詳細文件，再執行 Step 2（GroupName）、Step 3（KeyEnum）及後續實作：
   - **情境 A** → 載入 `references/scenario-a-global-switch.md` 與 `templates/scenario-a-insert.sql`
   - **情境 B** → 載入 `references/scenario-b-per-shop-switch.md` 與 `templates/scenario-b-insert.sql`
5. 遇到不確定的錯誤或邊界狀況時，載入 `references/common-pitfalls.md`。

## Reference Map

- `references/common-steps.md`
  - Step 1a（第一輪）：**單獨**詢問情境 A 或 B，等待使用者回覆後才繼續
  - Step 1b（第二輪）：確認 GroupName（推斷後必須明確向使用者確認）+ 收集 Key、Value、Description、VSTS 票號、使用位置、ViewBag 名稱
  - Step 2：新增 `ShopStaticSettingGroupNameEnum` 值
  - Step 3：新增 `ShopStaticSettingKeyEnum` 值
- `references/scenario-a-global-switch.md`
  - 情境 A 專屬：SQL 腳本（1 筆全域）、Controller 讀取、Service 讀取、完成確認清單
- `references/scenario-b-per-shop-switch.md`
  - 情境 B 專屬：SQL 腳本（多筆）、Controller 讀取、Service 讀取、完成確認清單
- `references/common-pitfalls.md`
  - 常見錯誤與注意事項（共用，兩種情境皆適用）
- `templates/scenario-a-insert.sql`
  - 情境 A SQL 範本（可直接複製填入）
- `templates/scenario-b-insert.sql`
  - 情境 B SQL 範本（可直接複製填入）
