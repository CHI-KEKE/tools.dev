# 1. PR Token 消耗排行

## 對應 LogQL

topk(
  15,
  sum by (_props_Repo, _props_PR) (
    sum_over_time(
      {service="qa-ai-code-review"}
      |= "Dify result:"
      | json
      | unwrap _props_Tokens
      | __error__=""
      [$__range]
    )
  )
)

## 語法與 Transformation 對照

| LogQL 語法 | 產生內容 | 對應 Transformation |
|---|---|---|
| sum by (_props_Repo, _props_PR) | _props_Repo、_props_PR labels | Labels to fields |
| unwrap _props_Tokens | 將 _props_Tokens 轉成數值 | 最終成為 Value 欄位 |
| sum_over_time(...) | 計算期間 Token 總量 | 最終成為 Value 欄位 |
| topk(15, ...) | 保留 Token 最高的 15 個 PR | 不需要 Transformation |
| Value | 各 PR Token 總量 | Sort by、Organize fields |

## Transformation 設定

### Transformation 1：Labels to fields

對應：

sum by (_props_Repo, _props_PR)

設定：

Mode: Columns

轉換前概念：

{_props_Repo="repo-a", _props_PR="123"}  150000

轉換後：

| _props_Repo | _props_PR | Value |
|---|---:|---:|
| repo-a | 123 | 150000 |

### Transformation 2：Merge series/tables

對應：

topk(15, ...)

topk 會回傳最多 15 個 Loki series。如果 Grafana 將它們拆成多個 frame，就用這個 Transformation 合併成一張表。

Transformation: Merge series/tables

如果 Labels to fields 後已經是一張完整表格，就不用加入。

### Transformation 3：Organize fields by name

對應欄位：

_props_Repo
_props_PR
unwrap _props_Tokens → Value

設定：

| 原始欄位 | 顯示名稱 |
|---|---|
| _props_Repo | Repository |
| _props_PR | PR |
| Value | Tokens |

隱藏：

Time

### Transformation 4：Sort by

對應：

sum_over_time(... unwrap _props_Tokens ...)

產生的 Value 欄位。

設定：

Field: Tokens
Order: Descending

雖然 topk 已選出前 15 名，但 Grafana 不一定按照數值順序顯示，所以再用 Sort by 排序。

———

# 2. PR Dify 呼叫次數排行

## 對應 LogQL

topk(
  15,
  sum by (_props_Repo, _props_PR) (
    count_over_time(
      {service="qa-ai-code-review"}
      |= "Dify result:"
      | json
      [$__range]
    )
  )
)

## 語法與 Transformation 對照

| LogQL 語法 | 產生內容 | 對應 Transformation |
|---|---|---|
| sum by (_props_Repo, _props_PR) | Repository、PR labels | Labels to fields |
| count_over_time(...) | 每個 PR 的 Dify 呼叫數 | Value 欄位 |
| topk(15, ...) | 呼叫次數最高的 15 個 PR | 不需要 Transformation |
| Value | Dify 呼叫總次數 | Sort by |

## Transformation 設定

### ① Labels to fields

對應：

sum by (_props_Repo, _props_PR)

Mode: Columns

### ② Merge series/tables

對應 topk 回傳的多個 series：

topk(15, ...)

只有資料被拆成多張表時才需要。

### ③ Organize fields by name

| 原始欄位 | 顯示名稱 |
|---|---|
| _props_Repo | Repository |
| _props_PR | PR |
| Value | Dify Calls |

隱藏：

Time

### ④ Sort by

對應：

count_over_time(...)

產生的 Value。

Field: Dify Calls
Order: Descending

———

# 3. Review Request 總次數

## 對應 LogQL

sum(
  count_over_time(
    {service="qa-ai-code-review"}
    |= "Start review:"
    [$__range]
  )
)

## 語法與 Transformation 對照

| LogQL 語法 | 產生內容 | 對應 Transformation |
|---|---|---|
| count_over_time(...) | 各 log stream 的 review 次數 | 由 LogQL 計算 |
| sum(...) | 所有 stream 的總次數 | 回傳單一 Value |
| 單一 Value | Review request 總數 | 不需要 Transformation |

## Transformation

無

因為：

sum(count_over_time(...))

已經回傳單一數值，直接使用 Stat：

Show: Calculate
Calculation: Last not null

———

# 4. Rule Token 消耗排行

## 對應 LogQL

topk(
  15,
  sum by (_props_Rule) (
    sum_over_time(
      {service="qa-ai-code-review"}
      |= "Dify result:"
      | json
      | unwrap _props_Tokens
      | __error__=""
      [$__range]
    )
  )
)

## 語法與 Transformation 對照

| LogQL 語法 | 產生內容 | 對應 Transformation |
|---|---|---|
| sum by (_props_Rule) | _props_Rule label | Labels to fields |
| unwrap _props_Tokens | Token 數值 | Value 欄位 |
| sum_over_time(...) | 每個 Rule 的 Token 總量 | Value 欄位 |
| topk(15, ...) | Token 最高的 15 個 Rule | 不需要 Transformation |
| _props_Rule | Rule 名稱 | Bar gauge 的 Display name |
| Value | Token 總量 | Bar gauge 的 bar value |

## 使用 Bar gauge 時

### Transformation

無

### Query Legend

對應：

sum by (_props_Rule)

設定：

{{_props_Rule}}

### Display name

也可以設定：

${__field.labels._props_Rule}

### Value

對應：

sum_over_time(... unwrap _props_Tokens ...)

設定：

Show: Calculate
Calculation: Last not null
Unit: short
Decimals: 0

## 使用 Table 時

如果需要確保排序，設定：

Labels to fields
→ Merge series/tables（必要時）
→ Organize fields by name
→ Sort by

### Labels to fields 對應

sum by (_props_Rule)

### Organize fields

| 原始欄位 | 顯示名稱 |
|---|---|
| _props_Rule | Rule |
| Value | Tokens |

### Sort by 對應

sum_over_time(... unwrap _props_Tokens ...)

Field: Tokens
Order: Descending

———

# 5. Test 目錄 Token 消耗

## 對應 LogQL

sum(
  sum_over_time(
    {service="qa-ai-code-review"}
    |= "Dify result:"
    | json
    | _props_File=~"(?i)(^|.*/)(test|tests|unittests|integrationtests)/.*"
    | unwrap _props_Tokens
    | __error__=""
    [$__range]
  )
)

## 語法與 Transformation 對照

| LogQL 語法 | 產生內容 | 對應 Transformation |
|---|---|---|
| _props_File=~"..." | 只保留 Test 目錄檔案 | LogQL 已完成篩選 |
| unwrap _props_Tokens | Token 數值 | Value |
| sum_over_time(...) | 每個 stream 的 Token 總量 | LogQL 已完成計算 |
| 外層 sum(...) | 全部 Test Token 總量 | 單一 Value |
| 單一 Value | Test Token 總量 | 不需要 Transformation |

## Transformation

無

直接使用 Stat：

Show: Calculate
Calculation: Last not null
Display name: Test Directory Tokens
Unit: short
Decimals: 0

———

# 6. Test Token 占比

## 對應 LogQL

100 *
sum(
  sum_over_time(
    {service="qa-ai-code-review"}
    |= "Dify result:"
    | json
    | _props_File=~"(?i)(^|.*/)(test|tests|unittests|integrationtests)/.*"
    | unwrap _props_Tokens
    | __error__=""
    [$__range]
  )
)
/
sum(
  sum_over_time(
    {service="qa-ai-code-review"}
    |= "Dify result:"
    | json
    | unwrap _props_Tokens
    | __error__=""
    [$__range]
  )
)

## 語法與 Transformation 對照

| LogQL 語法 | 用途 |
|---|---|
| 第一個 sum(...) | Test 目錄 Token |
| 第二個 sum(...) | 全部 Token |
| / | Test Token ÷ 全部 Token |
| 100 * | 轉換成百分比 |
| 最終結果 | 單一百分比 Value |

## Transformation

無

因為比例已經在 LogQL 內算完。

Visualization：

Stat 或 Gauge

設定：

Unit: Percent (0-100)
Decimals: 1
Min: 0
Max: 100

———

## Transformation 快速對照

| Transformation | 對應 LogQL 結果 |
|---|---|
| Labels to fields | sum by (...) 產生的 labels |
| Merge series/tables | topk(...) 回傳的多個 series/frame |
| Organize fields by name | labels 與 Value 欄位 |
| Sort by | sum_over_time 或 count_over_time 產生的 Value |
| Add field from calculation | 多個 Query 結果要在 Grafana 內運算時使用 |
| Reduce | Range query 有多個時間點時壓成單一值；目前使用 Instant，通常不需要 |

最簡單的判斷是：

sum by (...)       → Labels to fields
topk(...)          → 可能需要 Merge
unwrap + sum       → Value / Tokens
count_over_time    → Value / Calls
外層 sum(...)      → 單一值，不需 Transformation