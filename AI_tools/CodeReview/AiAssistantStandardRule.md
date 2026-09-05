
## 逐個 diff 送到 dify


AiAssistantStandardRule => BaseAiAssistantRule => BitbucketRule => RuleBase => IRule
通常只會 override IsSupportedFile





- AiAssistantCodeMentorProDifyRule
- AiAssistantCustomRule
- AiAssistantExceptionDifyRule
- AiAssistantFrontEndCustomRule
- AiAssistantFrontEndStandardRule
- AiAssistantInformationSecurityDifyRule
- AiAssistantNineYiNmqDifyRule
- AiAssistantNineYiSmsFrontEndDifyRule
- AiAssistantNineYiWebStoreFrontEndDifyRule
- AiAssistantPerformanceDifyRule
- AiAssistantStandardRule



## GitLabAiAssistantRuleBase

如果有 5 個 .cs 檔案，呼叫 Dify 5 次 ✅

```csharp
public override void Check()
{
    var assistList = this.FilterAIAssistType(apiResponse);
    
    // 👇 第一層迴圈：按檔案類型分組（例如：Backend、Frontend）
    foreach (var assistData in assistList)
    {
        // 👇 第二層迴圈：逐個檔案處理 ⭐ 關鍵證據
        foreach (var change in assistData.Value)  
        {
            // 👇 只處理「單一檔案」
            var singleFileList = new List<Change> { change };  // ⭐ 關鍵：只放一個檔案
            
            // 👇 把這「單一檔案」組裝成 diff 內容
            var diffContent = this.HandleGitLabChangeToDiffContent(
                singleFileList,  // ⭐ 關鍵：傳入只有一個檔案的 List
                apiResponse.Title, 
                apiResponse.Description
            );
            
            // 👇 呼叫 Dify API（每個檔案呼叫一次）
            var difyMessageResponse = this.GetDifyResponseMessage(assistData.Key, diffContent);
            
            // 👇 建立評論（每個檔案一個評論）
            responseMessage.Add(new BitbucketCommentMessage()
            {
                Path = change.NewPath,  // ⭐ 關鍵：評論綁定在單一檔案上
                LineFrom = -1,
                Message = $"🤖 **AI Code Review ({DisplayName})** \n\n {difyMessageResponse}"
            });
        }
    }
}
```

- 外層迴圈：把所有檔案按類型分組（例如：.cs 檔案、.js 檔案）
- 內層迴圈：逐個檔案處理
- 關鍵點：var singleFileList = new List<Change> { change };
- 這行程式碼明確建立了一個只包含一個檔案的 List
- 然後把這個 List 傳給 HandleGitLabChangeToDiffContent



## AiAssistantStandardForGitlabRule

AiAssistantStandardForGitlabRule >> GitLabAiAssistantRuleBase

AiAssistantStandardForGitlabRule 繼承但 override IsNeedAIAssist / FilterAIAssistType / Check 

| 項目 | 基底類別 (GitLabAiAssistantRuleBase) | 子類別 (AiAssistantStandardForGitlabRule) |
|---|---|---|
| IsNeedAIAssist | 基本檢查（空變更、系統關鍵字） | 更嚴格（分支規則、Release 排除） |
| FilterAIAssistType | 簡單分類（所有檔案同類型） | 精細分類（.cs/.ts/.py/.sql 分開） |
| Check 迴圈 | 雙層迴圈（逐檔案） | 單層迴圈（批次處理） |
| Dify 呼叫 | 每個檔案一次 | 每個類型一次 |
| AI Key | 單一固定 Key | 動態選擇 Key |
| 評論位置 | 檔案級評論 | MR 級評論 |
| 適用場景 | 通用規則 | 企業級多語言



## GitLabBackendAiAssistantRuleBase

>> GitLabAiAssistantRuleBase


override IsNeedAIAssist / FilterAIAssistType


## GitLabFrontendAiAssistantRuleBase


>> GitLabAiAssistantRuleBase


override FilterAIAssistType / IsFrontendFile