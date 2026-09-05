---
name: disable-malaysia-invoice
description: >
  在 C:\91APP\DB\operation repo 中，為指定商店建立關閉馬來西亞電子發票（MalaysiaInvoice）的
  資料夾與 SQL 腳本。當使用者說「關閉電子發票」、「某商店不使用MY電子發票」、
  「新增 SalesOrderMemo」或「Insert ShopStaticSetting」時使用此 skill。
  會收集 VSTS 編號、ShopId、商店名稱，並在 VSTS/ 目錄下自動建立符合規範的資料夾與 SQL 檔案。
---

# Disable Malaysia Invoice

## Overview

此 Skill 適用於 **`C:\91APP\DB\operation`** 專案。  
協助為指定商店在 `WebStoreDB.dbo.ShopStaticSetting` 新增一筆 `MalaysiaInvoice = false` 的設定，
並自動建立符合 repo 命名規範的資料夾與 SQL 腳本。

---

## 工作流程

### Step 1：收集必要資訊

依序使用 `ask_user` 工具詢問（每次只問一個）：

1. VSTS 編號（例：`VSTS602845`）
2. ShopId（例：`200137`）
3. 商店名稱／描述（例：`ELEMIS Singapore`）

### Step 2：建立資料夾

路徑規則：`C:\91APP\DB\operation\VSTS\{VSTS_ID}_Insert_SalesOrderCustomInfo`

```powershell
New-Item -ItemType Directory -Path "C:\91APP\DB\operation\VSTS\{VSTS_ID}_Insert_SalesOrderCustomInfo"
```

### Step 3：產生 SQL 檔案

檔案路徑：`{資料夾}\Step01_Insert_WebStoreDB_ShopStaticSetting_SalesOrderMemo.sql`

參考 `assets/template.sql`，將下列佔位符全部替換後使用 `create` 工具寫入檔案：

| 佔位符 | 替換內容 |
|--------|----------|
| `{VSTS_ID}` | VSTS 編號（例：`VSTS602845`） |
| `{SHOP_ID}` | ShopId 數字（例：`200137`） |
| `{SHOP_DESCRIPTION}` | 商店名稱（例：`ELEMIS Singapore`） |

### Step 4：展示產出結果

使用 `show_file` 展示產生的 SQL 檔案給使用者確認。
