
## 呼叫

`exec` 是用來**Stored Procedure**的關鍵字，就像呼叫一個方法一樣，可以傳入參數（@SearchString、@Category）

```sql
exec dbo.SearchHtml @SearchString ='%關鍵字%',@Category = 2
```

## 建立

```sql
CREATE PROCEDURE 預存程序名稱
	-- 可以傳入的變數定義寫在這裡
	@SearchString nvarchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT * FROM table
END
```