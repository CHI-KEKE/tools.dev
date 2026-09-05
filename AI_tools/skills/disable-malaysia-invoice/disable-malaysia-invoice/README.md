# disable-malaysia-invoice Skill

> **📁 Repo 限定**
> 本 Skill 僅適用於 **`C:\91APP\DB\operation`** 專案。

---

## 簡介

此 Skill 協助 DB 開發人員在 `WebStoreDB.dbo.ShopStaticSetting` 為指定商店新增一筆
`MalaysiaInvoice IsEnable = false` 的設定，表示該商店**不使用馬來西亞電子發票**。

一次完整的作業會自動完成：
- 建立符合 repo 規範的資料夾（`VSTS\{VSTS_ID}_Insert_SalesOrderCustomInfo`）
- 產生包含 SELECT / INSERT / VERIFY 三段的 SQL 腳本

---

## 如何觸發

在 GitHub Copilot CLI 中說：

```
建立關閉電子發票的 SQL 語法
```
或
```
幫我新增一間商店不使用 MY 電子發票
```

Copilot 會自動辨識並載入此 Skill。

---

## 互動流程模擬

```
👤 使用者：
建立關閉電子發票的 SQL 語法

🤖 Copilot：
請問這個 VSTS 的編號是？

👤 VSTS603001

🤖 請問要關閉電子發票的 ShopId 是？

👤 200200

🤖 請問這間商店的名稱或描述是？

👤 OSIM Thailand

🤖 [自動執行]
✅ 建立資料夾：VSTS\VSTS603001_Insert_SalesOrderCustomInfo\
✅ 產生 SQL：Step01_Insert_WebStoreDB_ShopStaticSetting_SalesOrderMemo.sql

[展示 SQL 內容供確認]
```

---

## Skill 檔案結構

```
disable-malaysia-invoice/
├── SKILL.md          # 主控文件（4 Step workflow）
├── README.md         # 本文件
├── assets/
│   └── template.sql  # SQL 模板（含 {VSTS_ID} / {SHOP_ID} / {SHOP_DESCRIPTION} 佔位符）
└── evals/
    └── evals.json    # 評估測試案例
```
