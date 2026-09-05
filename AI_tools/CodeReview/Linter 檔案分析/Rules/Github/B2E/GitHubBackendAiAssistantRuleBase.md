

```bash
GitHubBackendAiAssistantRuleBase
    ↓ 繼承
GitHubAiAssistantRuleBase
    ↓ 繼承
GitHubRule
    ↓ 繼承
BitbucketRule
    ↓ 繼承
RuleBase
```


## FilterAIAssistType()

IsBackendFile


## 流程


```bash
PR 提交
  ↓
GitHubAiAssistantRuleBase.Check() 開始
  ↓
取得 PR 資訊和檔案列表（8 個檔案）
  ↓
呼叫 GitHubBackendAiAssistantRuleBase.FilterAIAssistType()
  ↓
逐檔案呼叫 IsBackendFile() 判斷
  ↓ 
過濾出 4 個後端檔案（.cs 和 .yaml）
  ↓
回傳過濾結果給父類別
  ↓
父類別逐個處理 4 個後端檔案
  ↓
每個檔案呼叫 1 次 Dify AI
  ↓
建立 4 條評論（每個檔案 1 條）
  ↓
推送評論到 GitHub PR
```


