

## OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine



[2026-07-13 17:48:36.042 +08:00] [WRN] 心跳型任務 \Member\OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine 心跳已停止！距離最後一次執行已 969 分鐘（閾值 60 分鐘）。
[2026-07-13 17:48:36.042 +08:00] [INF] 發送告警："HeartbeatStopped" | 任務 \Member\OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine | 預期時間 2026-07-13 01:39:32 | 詳情：心跳已停止，距離最後一次執行已 969 分鐘（閾值 60 分鐘）
[2026-07-13 17:48:36.042 +08:00] [ERR] 【心跳型排程停止告警】任務 \Member\OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine 心跳已停止，最後一次執行時間為 "2026-07-13T01:39:32.0000000"（心跳已停止，距離最後一次執行已 969 分鐘（閾值 60 分鐘））。
[2026-07-13 17:48:36.043 +08:00] [INF] ----- [心跳已停止，執行時間 2026-07-13 01:39:32，距今969分鐘/閾值60分鐘] \Member\OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine -----


#### 執行

log : E:\Files\OsmConsole\0\20260713\Member\118_StoreImport_CrmLoyaltyPointMigrationFlow




PS C:\Windows\system32> Get-ScheduledTaskInfo -TaskPath "\Member\" -TaskName "OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine" | Format-List LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns  


LastRunTime = 2026/7/13 1:39:39
LastTaskResult = 0
NextRunTime = 2026/7/13 17:09:09
NumberOfMissedRuns = 30




 LastRunTime = 2026/7/13 01:39:39 AM 、 LastTaskResult = 0 （成功）——代表任務確實在凌晨 1:39 執行成功過，但 Event Log 裡查不到這筆紀錄。這證實了 History 空白不是任務沒跑過，而是 Operational Log 這層把紀錄弄丟了（被覆蓋滾動 / 任務曾被重建 GUID 不符，這兩個原因之一）。

但真正該關注的是  NumberOfMissedRuns: 30 

這才是重點。這個任務是「每 30 分鐘心跳一次」，從  LastRunTime  凌晨 01:39 到現在 17:09，中間經過約 15.5 小時 ≈ 31 個 30分鐘週期，跟  NumberOfMissedRuns = 30  幾乎完全吻合。

這代表：這個心跳任務從凌晨 1:39 之後就再也沒有真的觸發執行過，Windows Task Scheduler 自己都累積記錄了 30 次錯過的排程。 NextRunTime  顯示今天下午 5:09 PM 才是下一次預定時間——但這只是理論排程表，不代表它真的會順利執行。

這正是你的 Monitor 程式設計要抓的**心跳已停止（HeartbeatStopped）**情境的真實案例！ gap = now(17:09) − LastRunTime(01:39) ≈ 15.5小時 ，遠超過任何合理的心跳閾值（就算是 30分鐘週期×2倍=60分鐘的閾值），應該早就要告警了。

建議你立刻查

1. 這台機器上  WindowsTaskManager.Monitor  服務有沒有把這個任務納入監控範圍（是否被排除規則擋掉、或掃描到但漏判）？
2. 用 GUI 或  Get-ScheduledTask -TaskPath "\Member\" -TaskName "..."  確認任務目前狀態是  Ready  還是卡在  Running （可能卡死佔用導致後續排程被跳過，就是我們之前討論的第三種漏排情境）
3. 檢查該任務綁定的執行帳號/觸發條件（AC電源/網路連線等）是否近期被異動過，導致 Task Scheduler 判定條件不滿足而跳過

