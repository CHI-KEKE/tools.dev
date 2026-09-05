

## 7 天總呼叫數


```bash

count_over_time(
  {service="prod-coupon-service", container="coupon-web-api"}
  |= "Nine1HttpLog" |= "/api/coupon-items/redeem" [7d]
)
```


## 最高頻會員呼叫次數


```bash
count_over_time(
  {service="prod-coupon-service", container="coupon-web-api"}
  |= "coupon-items/redeem" |= "request："
  |= "7118098"
  [10m]
)
```

## 確認實際會被計數的「核銷失敗」次數（因為程式只在  RedeemInvalidException  時才 +1 次數）



```bash
count_over_time(
  {service="prod-coupon-service", container="coupon-web-api"}
  |= "RedeemInvalidException" [7d]
)
```


