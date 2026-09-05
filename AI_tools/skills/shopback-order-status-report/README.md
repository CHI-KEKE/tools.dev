# shopback-order-status-report Skill

> **📋 任務說明**
> 本 Skill 適用於每月 ShopBack 訂單狀態匯報作業，自動化完成從讀取報表、產生 BQ 查詢、到回填結果的完整流程。

---

## 簡介

每月需對 ShopBack 提交訂單審核報表，流程包含：

1. 從 ShopBack 提供的訂單 Excel 提取訂單編號
2. 至 GCP BigQuery 查詢各訂單的狀態與原因
3. 將查詢結果回填至 Excel 的 `status` 與 `reject_reason` 欄位

此 Skill 將上述流程自動化，減少手動複製貼上的錯誤。

---

## 如何觸發

在 GitHub Copilot CLI 中說：

```
幫我處理 ShopBack 訂單狀態匯報
```
或
```
ShopBack 訂單狀態回填
```
或
```
幫我跑 shopback 報表
```
或
```
處理 Shopback Daily 單
```
或
```
Shopback 每月 Daily 單
```

---

## 互動流程模擬

```
👤 使用者：
幫我處理 ShopBack 訂單狀態匯報

🤖 Copilot：
請提供上個月的 ShopBack 訂單報表檔案路徑，例如：
📈 tq_process_91APP_HK_2026-03.xlsx

👤 C:\Users\jill\Downloads\tq_process_91APP_HK_2026-03.xlsx

🤖 [自動執行]
✅ 讀取 Excel，共找到 84 筆訂單編號
✅ 日期範圍：2025-04-01 ~ 2026-03-31

[顯示完整 BigQuery SQL]

請至 GCP BigQuery Console 執行以上 SQL，查詢完成後
點擊「儲存結果」→「CSV（本機檔案）」下載，完成後提供 CSV 路徑。

👤 C:\Users\jill\Downloads\bquxjob_6704656a_19d8606eb0d.csv

🤖 [自動執行]
✅ ShopBack 訂單狀態回填完成！

📊 處理摘要：
  - 輸出檔案：tq_process_91APP_HK_2026-03_updated.xlsx
  - 總訂單數：84
  - 成功回填：84
  - 未找到對應：0
```

---

## 欄位對應

| BigQuery 結果欄位 | 回填至 Excel 欄位 |
|-------------------|-------------------|
| `status` | `status` |
| `real_reason` | `reject_reason` |

---

## 前置需求

Skill 執行前會自動檢查 Python 環境：

1. 確認 Python 已安裝（若未安裝需手動至 https://www.python.org/downloads/ 安裝）
2. 確認 `pandas` 與 `openpyxl` 套件可用，若缺少則自動執行：

```bash
pip install pandas openpyxl
```

---

## Skill 檔案結構

```
shopback-order-status-report/
├── SKILL.md                    # 主控文件（6 Step workflow）
├── README.md                   # 本文件
├── assets/
│   └── bq_query_template.sql   # BigQuery SQL 範本（含佔位符）
└── evals/
    └── evals.json              # 評估測試案例
```

---

## BigQuery 資料表

```
target-audience-001.hk_dp_order_data.LineItemOrderSummary_Online
```

> 日期範圍自動從 Excel 的 `purchase_date` 欄位推算：StartDate 為最早訂單當月 1 日，EndDate 為最晚訂單當月最後一日
> 例如最早訂單 `2025-03-08`，最晚訂單 `2026-02-22`
> → StartDate: `2025-03-01`，EndDate: `2026-02-28`
