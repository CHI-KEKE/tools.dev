


Database name 'WebStoreDB' ignored, referencing object in tempdb. Msg 468, Level 16, State 9, Line 248 Cannot resolve the collation conflict between "SQL_Latin1_General_CP850_CI_AS" and "SQL_Latin1_General_CP1_CI_AS" in the equal to operation. Completion time: 2026-02-03T13:48:15.2664554+08:00


你在 JOIN / ON / = 比較「來自不同 DB 的字串欄位」，
而這兩個 DB 的 collation 不一樣。


InfoDB.dbo.Area.Area_Name
👉 SQL_Latin1_General_CP1_CI_AS

WebStoreDB.dbo.AdministrativeRegion.AdministrativeRegion_City
👉 SQL_Latin1_General_CP850_CI_AS

SQL Server：

「我不知道要用哪一套語系規則來比字串，請你講清楚」