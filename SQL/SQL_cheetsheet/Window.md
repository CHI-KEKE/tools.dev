

```sql
-- Rank
RANK() OVER (PARTITION BY CustomerId ORDER BY OrderDate DESC) AS RankNo
```