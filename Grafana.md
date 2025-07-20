# 📊 Grafana 查詢語法指南

<br>

## 📖 目錄
  - [🔍 關鍵字相關查詢](#-關鍵字相關查詢)
  - [🛠️ Promotion Backend API 相關](#️-promotion-backend-api-相關)
  - [🎯 Promotion Frontend API 相關](#-promotion-frontend-api-相關)
  - [⚙️ Promotion Worker 系列](#️-promotion-worker-系列)
  - [🏪 CommerceCloud Worker](#-commercecloud-worker)
  - [📄 格式相關語法](#-格式相關語法)
  - [❌ 錯誤提示查詢](#-錯誤提示查詢)

<br>

---

## 🔍 關鍵字相關查詢

**TraceId 查詢**：

```
|= `2c652230-17ad-496e-b8d4-090fb8ec7ed0`
```

**請求內容查詢**：

```
|=`Request content: {\\\"promotionRules\\\`
```

**API 請求追蹤**：

```
\"POST\" https://promotion-api-internal.qa1.hk.91dev.tw/api/promotion-rules/rule-record
```

**請求與回應追蹤**：

<br>

```
"request - traceId
End processing HTTP request after 815.1365ms - 500
Response Status:
Response Data:
::Received data :
Response Status:
request - traceId:  | 
response - traceId:  |
```

<br>

---

## 🛠️ Promotion Backend API 相關

**建立活動規則**：

```
api/promotion-rules/create
```

**驗證錯誤回應範例**：

```
"_msg": "response - traceId:  | {\"errorCode\":\"ValidationException\",\"message\":\" 訂單完成後給點不支援給點效期為「指定到期年 / 月 / 日」\",\"detailErrors\":
[{\"errorCode\":\"NotEqualValidator\",\"message\":\" 訂單完成後給點不支援給點效期為「指定到期年 / 月 / 日」\",\"data\":{\"entity.PeriodType.RewardPointPeriodType\":[\" 訂單完成後給點不支援給點效期為「指定到期年 / 月 / 日」\"]}}]}"
```

**常用 API 端點**：

- `api/promotion-rules/update` - 更新活動規則
- `api/promotion-rules/delete` - 刪除活動規則
- `api/promotion-rules/salepage-list` - 銷售頁列表
- `api/promotion-rules/productsku-outerid-list` - 商品料號外部ID列表
- `api/promotion-rules/productsku-outerid-count` - 商品料號外部ID計數
- `api/promotion-rules/salepage-update` - 銷售頁更新
- `api/promotion-rules/productsku-outerid-update` - 商品料號外部ID更新
- `promotion-rules/category-update` - 分類更新
- `api/promotion-rules/rule-record` - 活動規則記錄

<br>

---

## 🎯 Promotion Frontend API 相關

**購物車計算**：

```
/api/cart-calculate
/api/carts/create
2 Calculate Data:
```

**購物籃計算**：

```
/api/basket-calculate 
2 Basket Data: 
CalculateByProcessGroup
RuleList Count: 1
```

**銷售頁服務呼叫**：

```
Start processing HTTP request \"POST\" https://salepage-service-api-internal.qa1.hk.91dev.tw/api/salepage-collections:match\
.GetMatchedSalepageCollectionFromCustomRuleAsync() 回傳結果為空
```

**S3 資料處理流程**：


```
S3 取得商品與商品料號的標籤對應關係, 開始
S3 檔案 SaleProducts 節點為空
比對活動圈選料號結果為空
S3 取得門市資訊, 開始
S3 取得門市資訊, 結束
```

<br>

**活動規則處理**：

```
RuleId: 5728, Type: RewardReachPriceWithRatePoint, Priority: 90000 -> 90000
活動序號 \"\" GetPromotionListAsync() 回傳結果為空
"PromotionRuleIds\":[6886]
"CartExtendInfoItemGroup\":82774
```


---

## ⚙️ Promotion Worker 系列

**忠誠度點數相關**：

```
PromotionRewardLoyaltyPointsV2
RecycleLoyaltyPointsV2
```

<br>

---

## 🏪 CommerceCloud Worker

**角標封存作業**：

<br>

```
角標封存job 關鍵字
正在處理角標ID
```

<br>

---

## 📄 格式相關語法

**JSON 格式查詢**：

```
|json
|line_format "{{._msg}}"
```

<br>

**任務ID 查詢**：

```
| _props_TaskId = `ba742916-6b34-44d2-83e7-fb89426cb9ca`
```

<br>

**追蹤ID 查詢**：

```
_tid
Root=1-67dbdc15-1fbb2f51540973ad1a5bea5a
```

<br>

**工作名稱查詢**：

```
|_props_JobName = `RecycleLoyaltyPointsV2`
```

<br>

---

## ❌ 錯誤提示查詢

**服務暫時不可用**：

<br>

```
<head><title>503 Service Temporarily Unavailable</title></head>
unable to resolve service
```

<br>

**稽核錯誤**：

```
|= `稽核時發生錯誤`
```

<br>
