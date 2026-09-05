
```bash
GitLabAiAssistantRuleBase
    ↓ 繼承
GitLabRule
    ↓ 繼承
RuleBase
```

## GetGitLabDiffResponse

實際回傳範例

```json
{
  "Title": "Add user authentication",
  "Description": "Implements JWT-based authentication...",
  "Changes": [
    {
      "NewPath": "src/Auth/JwtService.cs",
      "OldPath": "src/Auth/JwtService.cs",
      "Diff": "@@ -10,3 +10,15 @@\n+public string GenerateToken()\n+{\n+    return jwt.Create();\n+}",
      "NewFile": false,
      "RenamedFile": false,
      "DeletedFile": false
    },
    {
      "NewPath": "src/Controllers/AuthController.cs",
      "OldPath": null,
      "Diff": "@@ -0,0 +1,120 @@\n+[ApiController]\n+public class AuthController...",
      "NewFile": true,
      "RenamedFile": false,
      "DeletedFile": false
    }
  ]
}

```

## IsNeedAIAssist

- MR Title 包含 "SyncCode" → 跳過
- MR Title 包含 "Revert" → 跳過
- 沒有變更檔案 → 跳過


## FilterAIAssistType

// 將所有變更加入清單
// 只有當有變更時才加入結果


```json
{
    AIAssistType.Security: [
        Change { NewPath: "src/Auth/JwtService.cs", Diff: "..." },
        Change { NewPath: "src/Controllers/AuthController.cs", Diff: "..." }
    ]
}
```


## 逐檔案處理

## HandleGitLabChangeToDiffContent

```bash
# Title: Add user authentication
# Description: Implements JWT-based authentication for API endpoints
Security Review Changes:
+++src/Auth/JwtService.cs
@@ -10,3 +10,15 @@
public class JwtService
{

private readonly IConfiguration _config;
public string GenerateToken()
{
```

## 比較

GitHub：直接使用 JSON 格式（JToken.ToString()）
GitLab：手動組裝成 Markdown 格式，並移除刪除的行


## 呼叫 Dify AI


## 建立評論訊息

```csharp
responseMessage.Add(new BitbucketCommentMessage()
{
    Path = change.NewPath,  // "src/Auth/JwtService.cs"
    LineFrom = -1,          // ← 特殊標記：檔案級評論
    LineTo = 0,
    Message = $"🤖 **AI Code Review ({DisplayName})** \n\n {difyMessageResponse}"
});
```

LineFrom = -1：表示這是檔案級評論
LineTo = 0：無實際意義
Path：指定檔案路徑




## PushMessage

```json
[
    {
        Path: "src/Auth/JwtService.cs",
        LineFrom: -1,
        Message: "🤖 **AI Code Review (Security Review)** \n\n 
                 1. ⚠️ JWT Secret 應使用環境變數
                 2. 💡 建議加上 Token 過期時間驗證"
    },
    {
        Path: "src/Controllers/AuthController.cs",
        LineFrom: -1,
        Message: "🤖 **AI Code Review (Security Review)** \n\n 
                 1. ✅ 有進行輸入驗證
                 2. ⚠️ 建議加上 Rate Limiting"
    }
]
```


