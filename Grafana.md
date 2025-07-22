# 📊 Grafana 查詢語法指南

<br>

## 📖 目錄
  - [🔍 關鍵字相關查詢](#-關鍵字相關查詢)
  - [🛠️ Promotion Backend API 相關](#️-promotion-backend-api-相關)
  - [🎯 Promotion Frontend API 相關](#-promotion-frontend-api-相關)
  - [⚙️ Promotion Worker 系列](#️-promotion-worker-系列)
  - [🏪 CommerceCloud Worker](#-commercecloud-worker)
  - [🚨 NMQ 本身的異常紀錄](#-nmq-本身的異常紀錄)
  - [📊 監控 Dashboard](#-監控-dashboard)
  - [🔧 資源監控](#-資源監控)
  - [📥 匯出 Log 的方法](#-匯出-log-的方法)
  - [🔨 Builder Mode](#-builder-mode)
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

Response Data
```JSON

{
  "Shop": {
    "Id": 2,
    "Tags": [
      "EnableAddOns"
    ]
  },
  "User": {
    "Id": "33132",
    "Tags": [
      "AllUserScope",
      "CrmShopMemberCard:5"
    ],
    "OuterId": "tina20241018",
    "ShopMemberCode": "syKJM0lLY09hSeIEGA6U2Q=="
  },
  "Shipping": {
    "ShippingProfileTypeDef": "Oversea",
    "ShippingAreaId": 0,
    "CountryProfileId": 1,
    "LocationId": 0
  },
  "Payment": {
    "PayProfileTypeDef": "CreditCardOnce_Stripe"
  },
  "Channel": "Web",
  "CurrencyDecimalDigits": 2,
  "SalepageSkuList": [
    {
      "SalepageId": 61041,
      "SkuId": 84791,
      "Price": 20,
      "SuggestPrice": 25,
      "Qty": 10,
      "Flags": [],
      "OuterId": "",
      "Tags": null,
      "OptionalTypeDef": "",
      "OptionalTypeId": 0,
      "CartExtendInfoItemGroup": 0,
      "CartExtendInfoItemType": "Major",
      "PointsPayPair": null,
      "CartExtendInfos": [],
      "CartId": 43561
    }
  ],
  "FeeList": [
    {
      "Id": 409,
      "Type": "ShippingFee",
      "Price": 30,
      "Payment": 0,
      "ExtendInfo": {
        "ShippingProfileTypeDef": "Oversea",
        "IsDomesticWeightPricing": false,
        "TemperatureTypeDef": "Normal",
        "ShippingType": "409",
        "ShippingAreaId": 1,
        "IsLocal": false
      }
    }
  ],
  "Promotion": {
    "Code": null,
    "PromoCodePoolGroupId": null,
    "SelectedDesignatePaymentPromotionId": 0
  },
  "CouponSetting": {
    "MultipleRedeem": {
      "Discount": {
        "IsMultiple": true,
        "Qty": 10
      },
      "Gift": {
        "IsMultiple": true,
        "Qty": 9999
      },
      "Shipping": {
        "IsMultiple": false,
        "Qty": 1
      }
    },
    "CouponList": [],
    "Options": {
      "IsVerbose": false,
      "IsCouponPreSelect": false,
      "IncludeRecordDetail": false
    },
    "LoyaltyPoint": {
      "CheckoutPoint": 0,
      "CheckoutDiscountPrice": 190,
      "IsSelected": false,
      "IsSetDiscountPrice": false,
      "TotalPoint": 865483
    }
  }
}

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

**關鍵字**：

```
PromotionRewardLoyaltyPointsV2
RecycleLoyaltyPointsV2

|=`Request content: {\\\"promotionRules\\\`

::Received data

```

**BY TS 看 Recycle 跑幾次要對應 promotionId**

```
{service="hk-qa-promotion-service"}
|json
|_props_JobName = `RecycleLoyaltyPointsV2`
|=`TS250710P000006`
|=`items:\"[]\`
|=`訂單編號:TS250710P000006，回饋活動序號：7541`
```

**by TaskId**
```
{service="hk-qa-promotion-service"}
|json
| _props_TaskId = `ec72d512-a629-4478-b8b3-5e7275da2b98`
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

## 🚨 NMQ 本身的異常紀錄

### 1. Job 無法啟動，出現 [null]

**可能原因**：可能沒有加 Job 進 Dashboard 會沒上程式碼

<br>

**正常 log 範例示意圖**：
![alt text](./image-9.png)
<br>

### 2. NMQ 卡住 Ready

**解決方法**：到 Rancher 對該 Group 執行 Redeploy

<br>

---

## 📊 監控 Dashboard

### 1. PromotionService

**URL**：https://monitoring-dashboard.91app.io/d/kJHAWhwVk/promotion-service-monitor?orgId=2

![alt text](./image-10.png)

<br>

**LOKI LOG**:https://monitoring-dashboard.91app.io/d/3dSbCsL4k/shoppingcart-loki-log?orgId=2&var-Level=All&var-Message=&var-RequestPath=%2Fapi%2Fpromotion-rules%2Fcreate&var-RequestId=&var-Class=&var-Loki=RjRcuuN4k&var-MarketENV=HK-Prod&var-Cluster=dfHnWT74z&var-tid=&from=now-12h&to=now&var-ExceptionType=&var-Source=&var-ErrorCode=&var-Service=prod-promotion-service&refresh=30s

![alt text](./image-11.png)

<br>

### 2. ShoppingCart

**ShoppingCart Loki Log**：https://monitoring-dashboard.91app.io/d/3dSbCsL4k/shoppingcart-loki-log?orgId=2&refresh=30s&var-MarketENV=TW-Prod&var-Service=prod-promotion-service&var-Message=&var-Class=&var-RequestPath=%2Fapi%2Fpromotion-rules%2Fsalepage-update&var-RequestId=&var-Level=Error&var-Loki=ZIOlfD44k&var-Cluster=hxdP8t7Vz&var-tid=&var-ExceptionType=System.ArgumentNullException&var-Source=&var-ErrorCode=&from=now-3h&to=now

![alt text](./image-12.png)

<br>

**篩選方式範例**：
- Service：`prod-cart-service`
- Level：`Error`
- ExceptionType：`System.ArgumentException`

![alt text](./image-14.png)



<br>

---

## 🔧 資源監控

### 1. API Pod Memory

**URL**：https://monitoring-dashboard.91app.io/d/kJHAWhwVk/promotion-service-monitor?orgId=2&refresh=10s&from=now-24h&to=now&viewPanel=182


![alt text](./image-15.png)

<br>

### 2. 哪一支 API 高峰

```
sum by(_props_RequestPath) ( count_over_time(
{service="prod-promotion-service",container="promotion-web-api"}
| json
|  line_format "{{._props_RequestPath}}" [1m])
)
```
![alt text](./image-16.png)

![alt text](./image-17.png)

<br>

### 3. Job 處理狀況

**關鍵字**：
```
group9005
SendTemplateMailShopMemberPresent
```

![alt text](./image-18.png)

<br>

---

## 📥 匯出 Log 的方法

**操作步驟**：Query inspector > Data > CSV

<br>

小技巧

```
{service="prod-promotion-service"}
|json
| _props_TaskId = `2a5661bb-6e78-4d4a-850e-b05b4c6c4435`
```

直接包 csv 出來
![alt text](./image-20.png)

---

## 🔨 Builder Mode

可以選擇 **Builder Mode** 或 **Code Mode**

![alt text](./image-19.png)

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
