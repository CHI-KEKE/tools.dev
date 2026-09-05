# 常見錯誤與注意事項

適用情境 A 與情境 B，遇到邊界狀況或不確定行為時參考本文件。

---

## 架構原則

- **不要在 Service 層直接操作 DbContext**，一律透過 `IShopStaticSettingRepository`
- **不要使用 async/await**，此專案全部使用同步方法
- Autofac 已自動掃描服務，新增 `IShopStaticSettingService` 注入後不需手動修改 DI 設定

## Enum 相關

- 若 Key 尚未加入 `ShopStaticSettingKeyEnum`，編譯時會失敗——**務必先新增列舉值，再在程式碼中使用**
- GroupName 若尚未存在 `ShopStaticSettingGroupNameEnum`，同樣需先新增

## 讀取與 Fallback

- `GetShopStaticSettingByGroupNameKeyOrDefault` 內部已自動執行兩段查詢：
  1. 先查詢指定 `shopId` 的設定
  2. 若無，fallback 至 `ShopId=0` 的全域預設值
- **不需要手動實作兩段查詢邏輯**，無論情境 A 或情境 B 皆如此

## 解析方式

- **情境 A**：必須使用 `SettingHelper.GetIsEnabledInSettingByShopId`，此方法同時處理三段式字串的解析與商店範圍判斷
- **情境 B**：直接使用 `bool.TryParse`，**不需要** `SettingHelper`；誤用 `SettingHelper` 會導致行為錯誤

## SQL

- Description 欄位前綴 `N` 確保支援中文（NVARCHAR）：`N'{Description}'`
- CreatedUser / UpdatedUser 填入 `'VSTS{VSTS票號}'` 格式
- 執行 INSERT 前建議先執行 SELECT 確認資料不存在，避免重複插入

## 邊界狀況

- 若 `setting` 為 `null`（資料庫無此 Key），情境 A 的 `&&` 短路求值會直接回傳 `false`，行為安全
- 情境 B 若 `bool.TryParse` 失敗（Value 非 `true`/`false`），`out` 變數保持 `false`，同樣安全

## 適用範圍提醒

- **ShopDefault 開關**（頻繁切換、允許商店自行管理的設定）不屬於本 skill 範疇，請改用 `create-shop-default-switch` skill
