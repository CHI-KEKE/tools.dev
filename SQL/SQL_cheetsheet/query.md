

## DECLARE

```sql
DECLARE @UserName VARCHAR(30); --宣告變數名稱UserName，型態為字串，長度30
DECLARE @SqlVariable decimal(5,2); --總長度5位數，小數點以後佔2位，如123.45
DECLARE @SqlVariable UNIQUEIDENTIFIER; 
```

- @UserName VARCHAR(30) → 字串型態，最多 30 字元。
- DECIMAL(5,2) → 數字總長 5 位，小數點後 2 位，例如 123.45。
- UNIQUEIDENTIFIER 就是C#的 GUID，格式會是這樣 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ，其中每一個 x 是範圍 0-9 或 a-f 的十六進位數字。 例如，6F9619FF-8B86-D011-B42D-00C04FC964FF

## PRINT

```sql
PRINT 'STATEMENT: ' + @statement
```

## SET

```sql
--給予變數初始值
SET @statement = 'SELECT [ProductID] FROM Table'
SET @orderby = ' ORDER BY [ProductID] '
```


## if else

```SQL
/*------- WHERE 的 if 範例 -------------- */
IF (@ProductID IS NULL)
  BEGIN
    SET @where = ' WHERE 1 = 1 '
  END
ELSE
  BEGIN
    --如果資料庫的ProductID是int的話就不用在這邊使用CAST轉型了
    SET @where = ' WHERE [ProductID] = ' + CAST(@ProductID AS varchar) 
  END
```


## UNION ALL

- UNION：會自動執行 DISTINCT，去除重複資料。
- UNION ALL：不會去重複，速度更快！

```sql
SELECT Name FROM TableA
UNION ALL
SELECT Name FROM TableB


SELECT Name FROM TableA
UNION
SELECT Name FROM TableB
```


## CASE WHEN

### 🔹 基本用法
```sql
SELECT CustomerId, FirstName, Country,
  CASE 
    WHEN Country = 'USA' THEN 'Domestic'
    ELSE 'Foreign'
  END AS CustomerType
FROM customers
```

### 🔹 多條件判斷
```sql
SELECT CustomerId, FirstName, State, Country,
  CASE
    WHEN State = 'CA' AND Country = 'USA' THEN 'Local Customer'
    WHEN State <> 'CA' AND Country = 'USA' THEN 'National Customer'
    ELSE 'Foreign'
 END AS CustomerType
FROM customers
```

### 🔹 搭配聚合函數
```sql
SELECT CustomerId, SUM(Total) AS TotalSales,
  CASE 
    WHEN SUM(Total) < 40 THEN 'Normal'
    WHEN SUM(Total) >= 40 THEN 'VIP'
    ELSE 'Undefined'
  END AS CustomerLevel
FROM invoices
GROUP BY CustomerId
```