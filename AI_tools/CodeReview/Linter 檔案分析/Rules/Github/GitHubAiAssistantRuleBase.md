

```bash
GitHubAiAssistantRuleBase
    ↓ 繼承
GitHubRule
    ↓ 繼承  
BitbucketRule
    ↓ 繼承
RuleBase
```


## GetGitHubPullRequest

```json
{
    Title: "Add user authentication feature",
    Body: "This PR implements JWT-based authentication...",
    Number: 123,
    State: "open",
    User: { login: "developer" }
}
```


## 取得 PR 檔案列表

GetGitHubDiffResponse

```json
[
    {
        Filename: "src/Auth/JwtService.cs",
        Status: "modified",
        Additions: 45,
        Deletions: 5,
        Patch: "@@ -10,3 +10,15 @@\n+public string GenerateToken()\n+{\n+    return jwt.Create();\n+}"
    },
    {
        Filename: "src/Controllers/AuthController.cs",
        Status: "added",
        Additions: 120,
        Deletions: 0,
        Patch: "@@ -0,0 +1,120 @@\n+[ApiController]\n+public class AuthController..."
    }
]
```


## IsNeedAIAssist

PR Title 包含 "SyncCode" → 跳過
PR Title 包含 "Revert" → 跳過
PR Title 包含 "CodeFreeze" → 跳過
沒有變更檔案 → 跳過


## FilterAIAssistType 過濾 AI 輔助類型

// 將每個檔案轉換成 JToken
// 使用子類別定義的 AssistType

```json
{
    AIAssistType.Security: [
        JToken { Filename: "src/Auth/JwtService.cs", Patch: "..." },
        JToken { Filename: "src/Controllers/AuthController.cs", Patch: "..." }
    ]
}

```

## 逐檔案處理（關鍵邏輯）


```csharp
foreach (var assistData in assistList)
{
    // assistData.Key = AIAssistType.Security
    // assistData.Value = List<JToken> (檔案列表)
    
    foreach (var fileToken in assistData.Value)
    {
        var file = fileToken.ToObject<GitHubPullRequestFile>();
        
        // 只處理有 patch (diff 資訊) 的檔案
        if (string.IsNullOrEmpty(file.Patch))
            continue;
```


## 組裝單一檔案的 Diff 內容

```csharp
var singleFileList = new List<JToken> { fileToken };
var diffContent = this.HandleGitHubChangeToDiffContent(
    singleFileList, 
    prInfo.Title, 
    prInfo.Body
);

protected virtual string HandleGitHubChangeToDiffContent(
    List<JToken> changes, 
    string title, 
    string description)
{
    var diffContentBuilder = new StringBuilder();
    
    diffContentBuilder.AppendLine($"Pull Request Title: {title}");
    if (!string.IsNullOrEmpty(description))
    {
        diffContentBuilder.AppendLine($"Pull Request Description: {description}");
    }
    
    diffContentBuilder.AppendLine($"{DisplayName} Changes:");
    
    foreach (var change in changes)
    {
        diffContentBuilder.AppendLine(change.ToString());
    }
    
    return diffContentBuilder.ToString();
}


// Pull Request Title: Add user authentication feature
// Pull Request Description: This PR implements JWT-based authentication...
// Security Review Changes:
// {
//   "Filename": "src/Auth/JwtService.cs",
//   "Status": "modified",
//   "Additions": 45,
//   "Deletions": 5,
//   "Patch": "@@ -10,3 +10,15 @@\n+public string GenerateToken()\n+{\n+    return jwt.Create();\n+}"
// }
```



## 建立評論訊息

特殊設計：LineFrom = -1

這是檔案級評論的標記
不指定特定行號，評論會出現在整個檔案上
與 Bitbucket/GitLab 的行級評論區分





## 餵法


一次餵一個檔案，但只包含 Diff 資訊（不是完整檔案內容）


```csharp
foreach (var assistData in assistList)
{
    // 為每個檔案建立個別的評論
    foreach (var fileToken in assistData.Value)  // ← 逐檔案迴圈
    {
        var file = fileToken.ToObject<GitHubPullRequestFile>();
        
        // 只處理有 patch (diff 資訊) 的檔案
        if (string.IsNullOrEmpty(file.Patch))
        {
            continue;
        }


class GitHubPullRequestFile 
{
    public string Filename { get; set; }      // "src/Services/UserService.cs"
    public string Status { get; set; }        // "modified" / "added" / "deleted"
    public int Additions { get; set; }        // 45
    public int Deletions { get; set; }        // 5
    public string Patch { get; set; }         // ← 只有 Diff 內容，不是完整檔案
    // "@@ -10,3 +10,15 @@\n+public string GenerateToken()\n..."
}
```



✅ 只有 Diff 資訊
```bash
@@ -10,3 +10,15 @@
 public class UserService
 {
+    private readonly ILogger _logger;
+
     public UserService()

@@ -40,3 +42,6 @@
     public User GetUser(int id)
     {
-        return _repository.Find(id);
+        var user = _repository.Find(id);
+        if (user == null)
+            throw new Exception("User not found");
+        return user;
     }
```