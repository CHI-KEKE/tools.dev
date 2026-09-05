

[2026-07-13 14:11:09.347 +08:00] [WRN] 心跳型任務 \Monitor\Monitor_CheckOrderShippingFee 心跳已停止！距離最後一次執行已 1098955 分鐘（閾值 20 分鐘）。
[2026-07-13 14:11:09.347 +08:00] [INF] 發送告警："HeartbeatStopped" | 任務 \Monitor\Monitor_CheckOrderShippingFee | 預期時間 2024-06-10 10:15:54 | 詳情：心跳已停止，距離最後一次執行已 1098955 分鐘（閾值 20 分鐘）
[2026-07-13 14:11:09.347 +08:00] [ERR] 【心跳型排程停止告警】任務 \Monitor\Monitor_CheckOrderShippingFee 心跳已停止，最後一次執行時間為 "2024-06-10T10:15:54.0000000"（心跳已停止，距離最後一次執行已 1098955 分鐘（閾值 20 分鐘））。
[2026-07-13 14:11:09.347 +08:00] [INF] ----- [心跳已停止，執行時間 2024-06-10 10:15:54，距今1098955分鐘/閾值20分鐘] \Monitor\Monitor_CheckOrderShippingFee -----




![alt text](image.png)



System - Provider [ Name] Microsoft-Windows-TaskScheduler [ Guid] {de7b24ea-73c8-4a09-985d-5bdadcfa9017} EventID 101 Version 0 Level 2 Task 101 Opcode 101 Keywords 0x8000000000000001 - TimeCreated [ SystemTime] 2026-07-13T09:25:53.656499500Z EventRecordID 101492916 Correlation - Execution [ ProcessID] 1592 [ ThreadID] 6940 Channel Microsoft-Windows-TaskScheduler/Operational Computer SG-HK-QA1-SCM2.hk.sg.91app.corp - Security [ UserID] S-1-5-18 - EventData TaskName \Monitor\Monitor_CheckOrderShippingFee UserContext N2\joannelee ResultCode 2147943731 detail 



這個 ResultCode 2147943731 已經可以直接定位原因。

2147943731
= 0x80070533
= Windows Error 1331
= ERROR_ACCOUNT_DISABLED
= The user account is currently disabled.

也就是這個 Task 設定使用：

UserContext: N2\joannelee

但 N2\joannelee 帳號目前被停用（Disabled），所以 Task Scheduler 連程式都無法啟動，因此出現：

Event ID 101
Task Start Failed
Launch Failure
解法

到 Task 的：

Properties → General → Security options

查看目前的執行帳號，然後二選一：

重新啟用 N2\joannelee 帳號。
把 Task 改成一個有效的 Service Account，並重新輸入該帳號密碼。

修改後可以右鍵 Task → Run 手動測試。

另外，你這台機器上如果很多 Task 都是用 N2\joannelee 執行，可能會一起開始失敗。建議用 PowerShell 一次找出所有使用這個帳號的 Task：

Get-ScheduledTask | Where-Object { $_.Principal.UserId -eq 'N2\joannelee' } |
    Select-Object TaskPath, TaskName, State

這樣就能知道這個帳號停用影響了哪些排程。











任務啟動失敗：This user can't sign in because this account is currently disabled.