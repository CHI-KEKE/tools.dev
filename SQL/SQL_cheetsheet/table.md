

## CTE

使用 CTE 查詢完的當下就會從記憶體中消失，可以減少重覆計算所耗的 I/O、CPU 和執行時間，如果同樣的查詢需使用很多次時，非常適合使用 CTE，例如分頁

```SQL  
with cte_name (品牌,國家) as (select name,address from Customers)
select * from cte_name
```


## temp


```sql
DROP TABLE #CustomerDiscount, #OrdersToBill;
CREATE TABLE #TEMP(
  NAME CHAR(20),
  ID   CHAR(10)
) 

SELECT ob.CustomerId, SUM(ob.TotalAmount * p.DiscountRate) AS DiscountTotal
INTO #CustomerDiscount
FROM #OrdersToBill ob

-- table variable
DECLARE @SkuIds TABLE (SkuId INT PRIMARY KEY);
INSERT INTO @SkuIds VALUES (101),(102),(103);

SELECT s.SkuId, s.StockQty
FROM dbo.Stock s
JOIN @SkuIds i ON i.SkuId = s.SkuId;


INSERT INTO #TEMP VALUES('TOM','A123456789')
INSERT INTO ##TEMP VALUES('ARIC','G123212343')
INSERT INTO @TEMP  VALUES ('BILL','M123465324')
```