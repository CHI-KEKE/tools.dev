---
name: disable-malaysia-invoice
description: >
  當使用者表達「關閉電子發票」、「停用電子發票」、「不使用電子發票」、「disable invoice」、「某商店不使用MY電子發票」、「關閉馬來西亞電子發票」、「MalaysiaInvoice IsEnable false」等意圖時，使用此 skill。
  在 C:\91APP\DB\operation repo 中，為指定商店建立關閉馬來西亞電子發票（MalaysiaInvoice）的資料夾與 SQL 腳本。
  會收集 VSTS 編號、ShopId、商店名稱，並在 VSTS/ 目錄下自動建立符合規範的資料夾與 SQL 檔案。
  注意：此 skill 僅限電子發票關閉用途，不適用其他 SalesOrderMemo 或 ShopStaticSetting 操作。
---

# Disable Malaysia Invoice Skill

> 此 Skill 適用於 **`C:\91APP\DB\operation`** 專案。
> 為指定商店新增 `ShopStaticSetting` 設定，將 `MalaysiaInvoice` 的 `IsEnable` 設為 `false`，關閉 MY 電子發票功能。

---

## 工作流程

### Step 1：收集必要資訊

依序使用 ask_user 工具詢問（**每次只問一個**，等使用者回答後再問下一個）：

1. **VSTS 編號** — 純數字或含 VSTS 前綴（例：`602845` 或 `VSTS602845`）
2. **ShopId** — 純數字（例：`200137`）
3. **商店名稱／描述** — 作為 SQL 注解說明（例：`ELEMIS Singapore`）
4. **資料夾名稱** — VSTS 目錄下的子資料夾名稱（例：`VSTS602845_Insert_SalesOrderCustomInfo`）

收集完成後，組合以下變數備用：

| 變數 | 來源 | 範例 |
|------|------|------|
| `{VSTS_ID}` | 統一加 VSTS 前綴 | `VSTS602845` |
| `{SHOP_ID}` | 使用者輸入 | `200137` |
| `{SHOP_DESCRIPTION}` | 使用者輸入 | `ELEMIS Singapore` |
| `{FOLDER_NAME}` | 使用者輸入 | `VSTS602845_Insert_SalesOrderCustomInfo` |

---

### Step 2：預覽 SQL 並請使用者確認

根據 `assets/template.sql`，將佔位符替換後**展示完整 SQL 預覽**給使用者確認：

```
📋 即將產生的 SQL 預覽：

  資料夾：VSTS/{FOLDER_NAME}/
  檔案名：Step01_Insert_WebStoreDB_ShopStaticSetting_SalesOrderMemo.sql

  [SQL 內容完整顯示]
```

詢問：「以上資訊正確嗎？確認後將建立資料夾與 SQL 檔案。」

> ⚠️ **使用者確認前不建立任何檔案。**

---

### Step 3：建立資料夾與 SQL 檔案

使用者確認後執行：

```powershell
$repoRoot   = "C:\91APP\DB\operation"
$folderPath = "$repoRoot\VSTS\{FOLDER_NAME}"
$sqlFile    = "$folderPath\Step01_Insert_WebStoreDB_ShopStaticSetting_SalesOrderMemo.sql"

New-Item -ItemType Directory -Path $folderPath -Force
```

將替換好的 SQL 內容寫入 `$sqlFile`（參照 `assets/template.sql`，替換 `{VSTS_ID}`、`{SHOP_ID}`、`{SHOP_DESCRIPTION}`）。

完成後顯示：

```
✅ 完成！

  資料夾：VSTS/{FOLDER_NAME}/
  SQL 檔：Step01_Insert_WebStoreDB_ShopStaticSetting_SalesOrderMemo.sql

⚠️ 提醒：
  - 執行前請先確認 SELECT 是否已有回傳資料（有則通知 PR owner）
  - 請自行建立 branch、commit、push 並開啟 PR

📎 範例 PR（請比對你的異動是否與此一致）：
  https://bitbucket.org/nineyi/nineyi.database.operation/pull-requests/25413/diff
```


