```sql
-- 加減時間
DATEADD(DAY, 1, @firstDayOfMonth)

-- 拼接年月份
DATEFROMPARTS(YEAR(GETDATE()), 1, 1)

-- 取得特定部位 例如 年
YEAR(GETDATE())

-- 轉換時間格式
CONVERT(CHAR(7), datetime, 120)

--差多久
DATEDIFF(DAY, OrderSlaveFlow_CreatedDateTime, OrderSlaveFlow_ShippingOrderSlaveDateTime)

--轉成天
CAST(OrderDate AS DATE)

--interval
DATEADD(MINUTE, DATEDIFF(MINUTE, 0, Task_CreatedDatetime), 0) AS MinuteInterval

 -- yyyy-MM
CONVERT(char(7), TradesOrderThirdPartyPayment_DateTime, 120) AS [Month]

-- yyyy-MM-dd
CONVERT(char(10), TradesOrderThirdPartyPayment_DateTime, 120) AS [Date]

--0~23
DATEPART(HOUR, TradesOrderThirdPartyPayment_DateTime) AS [Hour]
```