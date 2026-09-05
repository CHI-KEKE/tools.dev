---
name: shopback-order-status-report
description: >
  自動化處理 ShopBack 訂單狀態匯報任務。讀取上個月的 ShopBack 訂單報表 Excel（如 tq_process_91APP_HK_2026-03.xlsx），
  提取 order_number 欄位並組合 BigQuery 查詢語法，引導使用者至 GCP 執行查詢並匯出 CSV，
  最後將 BigQuery 結果的 status 回填至報表 status 欄位、real_reason 回填至 reject_reason 欄位，
  輸出更新後的 Excel 檔案。
  當使用者說「處理 ShopBack 訂單」、「ShopBack 訂單狀態回填」、「shopback 匯報」、
  「幫我跑 ShopBack 報表」、「BQ 回填 shopback」、
  「處理 Shopback Daily 單」、「Shopback 每月 Daily 單」時使用此 skill。
---

# ShopBack 訂單狀態匯報 Skill

## Overview

此 Skill 自動化完成 ShopBack 每月訂單狀態匯報的完整流程：
1. 從 ShopBack 訂單報表 Excel 提取訂單編號
2. 組合 BigQuery 查詢語法
3. 將 BigQuery 查詢結果回填至 Excel 報表

---

## 工作流程

### Step 0：檢查 Python 環境

在執行任何 Python 程式前，先確認環境是否就緒：

```powershell
# 檢查 Python 是否安裝
python --version
```

若 Python 未安裝，告知使用者需先手動安裝 Python（https://www.python.org/downloads/），並停止流程。

若 Python 已安裝，接著檢查必要套件：

```powershell
python -c "import pandas, openpyxl; print('OK')"
```

若輸出非 `OK`（代表套件缺失），自動執行全域安裝：

```powershell
pip install pandas openpyxl
```

安裝完成後，再次確認套件可正常載入，才繼續後續步驟。

---

### Step 1：取得 ShopBack 訂單報表

使用 `ask_user` 詢問使用者提供上個月的 ShopBack 訂單報表檔案路徑：

```
請提供上個月的 ShopBack 訂單報表檔案路徑，例如：
📈 tq_process_91APP_HK_2026-03.xlsx
```

取得路徑後，從**檔名**解析報表月份（格式：`YYYY-MM`），例如 `2026-03`。

### Step 2：讀取 order_number 欄位

使用以下 Python 程式讀取 Excel 中的 `order_number` 與 `purchase_date` 欄位：

```python
import pandas as pd
from pathlib import Path
import calendar

excel_path = r"{EXCEL_PATH}"
df = pd.read_excel(excel_path)

# 提取不重複的訂單編號
order_numbers = df['order_number'].dropna().astype(str).str.strip().unique().tolist()

# 格式化為 BigQuery 陣列字串
order_list = ',\n        '.join([f"'{o}'" for o in order_numbers])

print(f"共 {len(order_numbers)} 筆訂單編號")
print(order_list)
```

同時，從 `purchase_date` 欄位推算日期範圍：

```python
# 從 purchase_date 欄位找出最早與最晚訂單日期
df['purchase_date'] = pd.to_datetime(df['purchase_date'])
earliest_date = df['purchase_date'].min()
latest_date = df['purchase_date'].max()

# StartDate = 最早訂單當月 1 日
start_date = f"{earliest_date.year}-{earliest_date.month:02d}-01"

# EndDate = 最晚訂單當月最後一日
last_day = calendar.monthrange(latest_date.year, latest_date.month)[1]
end_date = f"{latest_date.year}-{latest_date.month:02d}-{last_day:02d}"

print(f"最早訂單：{earliest_date.date()}，最晚訂單：{latest_date.date()}")
print(f"日期範圍：{start_date} ~ {end_date}")
```

> **範例**：若 `purchase_date` 最早為 `2025-03-08`，最晚為 `2026-02-22`，
> 則 `StartDate = 2025-03-01`，`EndDate = 2026-02-28`。

### Step 3：組合並顯示 BigQuery 查詢語法

使用以下 Python 程式讀取 `assets/bq_query_template.sql` 並替換佔位符，將完整 SQL 存入變數：

```python
import os

skill_dir = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else r"{SKILL_ASSETS_DIR}"
template_path = os.path.join(skill_dir, 'bq_query_template.sql')

with open(template_path, encoding='utf-8') as f:
    sql_template = f.read()

final_sql = sql_template \
    .replace('{ORDER_NUMBER_LIST}', order_list) \
    .replace('{START_DATE}', start_date) \
    .replace('{END_DATE}', end_date)

print(final_sql)
```

> ⚠️ **重要**：取得 `final_sql` 字串後，**必須將完整 SQL 以 markdown ` ```sql ` 程式碼區塊格式直接輸出在回應中**，讓使用者可以完整複製。不可只說「SQL 已產生」而省略內容。

| 佔位符 | 替換內容 | 範例 |
|--------|----------|------|
| `{ORDER_NUMBER_LIST}` | 逗號分隔的訂單編號陣列 | `'TG260308A00143',\n        'TG260308Y00113'` |
| `{START_DATE}` | 查詢起始日期 | `2025-04-01` |
| `{END_DATE}` | 查詢結束日期 | `2026-03-31` |

SQL 顯示完畢後，請使用者執行以下操作：

```
✅ BigQuery SQL 已產生，請依下列步驟操作：

1. 前往 GCP BigQuery Console：https://console.cloud.google.com/bigquery
2. 在查詢編輯器貼上上方 SQL
3. 點擊「執行」
4. 查詢完成後，點擊「儲存結果」→ 選擇「本機下載 - CSV」下載
```

### Step 4：取得 BigQuery 查詢結果

使用 `ask_user` 詢問使用者提供下載的 CSV 檔案路徑：

```
請提供 BigQuery 查詢結果的 CSV 檔案路徑，例如：
📄 bquxjob_6704656a_19d8606eb0d.csv
```

### Step 5：回填 status 與 reject_reason

使用以下 Python 程式合併資料並回填：

```python
import pandas as pd
from pathlib import Path

excel_path = r"{EXCEL_PATH}"
csv_path = r"{CSV_PATH}"

# 讀取原始 Excel
sb_df = pd.read_excel(excel_path)
sb_df['order_number'] = sb_df['order_number'].astype(str).str.strip()

# 讀取 BigQuery 結果
bq_df = pd.read_csv(csv_path)
bq_df['order_number'] = bq_df['order_number'].astype(str).str.strip()

# 只保留需要的欄位
bq_subset = bq_df[['order_number', 'status', 'real_reason']].copy()
bq_subset = bq_subset.rename(columns={'real_reason': 'reject_reason_new'})

# 合併
merged = sb_df.merge(bq_subset, on='order_number', how='left')

# 回填：BQ status → 報表 status
if 'status' in sb_df.columns:
    merged['status'] = merged['status_y'].fillna(merged['status_x'])
    merged = merged.drop(columns=['status_x', 'status_y'])
else:
    merged = merged.rename(columns={'status': 'status'})

# 回填：BQ real_reason → 報表 reject_reason
if 'reject_reason' in sb_df.columns:
    merged['reject_reason'] = merged['reject_reason_new'].fillna(merged['reject_reason'])
else:
    merged['reject_reason'] = merged['reject_reason_new']
merged = merged.drop(columns=['reject_reason_new'])

# 輸出更新後的 Excel
output_path = str(Path(excel_path).with_stem(Path(excel_path).stem + '_updated'))
merged.to_excel(output_path, index=False)
print(f"✅ 已產生更新後的報表：{output_path}")
print(f"   共處理 {len(merged)} 筆訂單")
matched = merged['status'].notna().sum()
print(f"   成功回填 {matched} 筆")
```

### Step 6：顯示完成摘要

輸出處理結果摘要：

```
✅ ShopBack 訂單狀態回填完成！

📊 處理摘要：
  - 原始報表：{EXCEL_PATH}
  - BQ 查詢結果：{CSV_PATH}
  - 輸出檔案：{OUTPUT_PATH}
  - 總訂單數：{TOTAL}
  - 成功回填：{MATCHED}
  - 未找到對應：{UNMATCHED}
```

---

## 欄位對應說明

| BigQuery 結果欄位 | 回填至 ShopBack 報表欄位 |
|-------------------|--------------------------|
| `status` | `status` |
| `real_reason` | `reject_reason` |

---

## 注意事項

- Excel 第一列必須為欄位標題，包含 `order_number`、`purchase_date`、`status`、`reject_reason` 欄位
- BigQuery 查詢使用 `target-audience-001.hk_dp_order_data.LineItemOrderSummary_Online` 資料表
- 日期範圍從 Excel 的 `purchase_date` 欄位自動推算：StartDate 為最早訂單當月 1 日，EndDate 為最晚訂單當月最後一日
- 若訂單在 BQ 中找不到，保留原 Excel 欄位值不覆蓋
- 若 Python 或相關套件（`pandas`、`openpyxl`）尚未安裝，Skill 將在 Step 0 自動檢查並執行全域安裝
