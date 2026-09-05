
## 適用 repo

NineYi.Databases

## key

app-VX2NYs4cLOP2q4g5Rz9NG5kg


## 使用類型

custom attribute


## GetDiffStatInfo

Bitbucket 提供的 API，回傳 PR 中每個檔案的變更統計
包含：檔案路徑、新增/刪除行數、檔案內容的 API 連結

```json
{
  "values": [
    {
      "new": {
        "path": "Databases/Schema/dbo.Users.sql",
        "links": {
          "self": {
            "href": "https://api.bitbucket.org/.../raw/abc123"
          }
        }
      }
    },
    {
      "new": {
        "path": "Databases/StoredProcedures/sp_GetOrders.sql",
        "links": {
          "self": {
            "href": "https://api.bitbucket.org/.../raw/def456"
          }
        }
      }
    }
  ]
}
```

## 驗證所有檔案都有 RawContent API

確保每個變更的檔案都能取得完整內容
避免部分檔案缺少 API 連結導致審查不完整
如果有任何檔案缺少 Href，整個規則就不執行

## 逐檔案處理

```csharp
foreach (var fileStatEntity in diffstatInfo.Values)
{
    // 處理每個檔案
}
```



##　具體情境


#### PR 包含的檔案

Databases/Schema/dbo.Orders.sql - 建立新資料表
Databases/StoredProcedures/sp_GetUserOrders.sql - 新增預存程序
Databases/Views/vw_ActiveUsers.sql - 修改檢視表



#### 取得 DiffStat

```csharp
diffstatInfo.Values = [
    { path: "Databases/Schema/dbo.Orders.sql", href: "https://api/.../abc123" },
    { path: "Databases/StoredProcedures/sp_GetUserOrders.sql", href: "https://api/.../def456" },
    { path: "Databases/Views/vw_ActiveUsers.sql", href: "https://api/.../ghi789" }
]
```

####  驗證通過（所有檔案都有 href）

#### 處理第一個檔案

```csharp
// 取得內容
path = "Databases/Schema/dbo.Orders.sql"
rawContent = "CREATE TABLE [dbo].[Orders] ..."

// AI 分析
difySuggestion = "
1. ⚠️ OrderDate 欄位應設定為 NOT NULL
2. 💡 建議在 UserId 加上外鍵約束
3. ✅ 索引設定合理
"

// 組裝訊息
messageList.Add({
    Path: "Databases/Schema/dbo.Orders.sql",
    Message: "🤖 **AI Code Review** \n \r 
             1. ⚠️ OrderDate 欄位應設定為 NOT NULL
             2. 💡 建議在 UserId 加上外鍵約束
             3. ✅ 索引設定合理"
})
```


#### 推送評論到 Bitbucket

3 個檔案各自有 1 條 inline 評論, 評論會顯示在檔案名稱旁邊