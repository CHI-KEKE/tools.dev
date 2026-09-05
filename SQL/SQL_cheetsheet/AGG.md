

```sql
SUM(CASE WHEN d.ProductID = 776 THEN d.OrderQty ELSE 0 END) AS Product_776_qty
```