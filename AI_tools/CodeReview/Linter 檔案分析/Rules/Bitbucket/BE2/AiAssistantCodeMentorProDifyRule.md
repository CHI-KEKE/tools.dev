
## 繼承

```bash
AiAssistantCodeMentorProDifyRule 
    ↓ 繼承
BaseAiAssistantRule 
    ↓ 繼承
BitbucketRule 
    ↓ 繼承
RuleBase
```


## key


app-JIUkO3aaOYo8fkcZrUFTMDrT


## allow

.cs

## ExcludedFileTypes

.typegen.ts


## 實際執行情境

PR 包含的檔案：

1. src/Services/UserService.cs          ✅ 會審查
2. src/Controllers/OrderController.cs   ✅ 會審查
3. src/Models/User.typegen.ts           ❌ 黑名單，跳過
4. src/Helpers/StringHelper.cs          ✅ 會審查
5. src/Scripts/deploy.sh                ❌ 非 .cs，跳過
6. README.md                             ❌ 非 .cs，跳過



## 走 BaseAiAssistantRule 模式
