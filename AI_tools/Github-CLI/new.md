
## 進入

copilot --banner


## mcp


C:\Users\Allen Lin\.copilot

mcp-config.json




## 



  ⚡Allen Lin ❯❯ where.exe copilot
C:\nvm4w\nodejs\copilot
C:\nvm4w\nodejs\copilot.cmd


  ⚡Allen Lin ❯❯ Get-Command copilot | Format-List Source,Definition,Path,CommandType


Source      : C:\nvm4w\nodejs\copilot.ps1
Definition  : C:\nvm4w\nodejs\copilot.ps1
Path        : C:\nvm4w\nodejs\copilot.ps1
CommandType : ExternalScript


## 問題


為什麼 PAT 一直過期???
Allen Lin [UPD] 林宥辰  [2:12 PM]
笑死直接放棄

● MCP server 一直失敗。我改用 PowerShell 直接呼叫 REST API
  來讀取：

● Fetch work item 603617 via REST API (shell)
  │ $pat = "4Tcm3e6mumvGUS9VEFBb3iZzWJPgmL9yv92IjegK6NHyu16PFz
  │ 8tJQQJ99CDACAAAAAwwk81AAASAZDO17Ei"
  │ $base64 = [Convert]::ToBase64String([Text.Encoding]::ASCII
  │ .GetBytes(":$pat"))
  │ $headers = @{ Authorization = "Basic $base64"; …
  └ 46 lines...

● 成功讀取！以下是 #603617 的需求解析：





有時候會忘記曾經提醒她的事情