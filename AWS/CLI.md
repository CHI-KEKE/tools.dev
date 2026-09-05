
● Write AWS credentials and config files (shell)
  │ 
  │ $credDir = "$env:USERPROFILE\.aws"
  │ if (!(Test-Path $credDir)) { New-Item -ItemType Directory -Path $credDir | Out-Null }
  │ 
  │ $creds = @"…
  └ 17 lines…

● 設定完成！已建立：

   - ~\.aws\credentials — Access Key / Secret Key
   - ~\.aws\config — region: ap-southeast-1, output: json
   - Profile: default


## 執行確認身分


aws sts get-caller-identity

## 讀ddb