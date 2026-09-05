
[2026-07-13 17:48:36.029 +08:00] [WRN] 心跳型任務 \Member\OMO_Member_CRM_ImportCustomOuterCode 心跳已停止！距離最後一次執行已 289 分鐘（閾值 60 分鐘）。
[2026-07-13 17:48:36.029 +08:00] [INF] 發送告警："HeartbeatStopped" | 任務 \Member\OMO_Member_CRM_ImportCustomOuterCode | 預期時間 2026-07-13 13:00:00 | 詳情：心跳已停止，距離最後一次執行已 289 分鐘（閾值 60 分鐘）
[2026-07-13 17:48:36.029 +08:00] [ERR] 【心跳型排程停止告警】任務 \Member\OMO_Member_CRM_ImportCustomOuterCode 心跳已停止，最後一次執行時間為 "2026-07-13T13:00:00.0000000"（心跳已停止，距離最後一次執行已 289 分鐘（閾值 60 分鐘））。
[2026-07-13 17:48:36.029 +08:00] [INF] ----- [心跳已停止，執行時間 2026-07-13 13:00:00，距今289分鐘/閾值60分鐘] \Member\OMO_Member_CRM_ImportCustomOuterCode -----



這個 Task 有 3 個 Daily Trigger。每一條的意思如下：

每天 06:32

06:32 執行
→ 30 分鐘後再執行一次：07:02

因為「每 30 分鐘重複，持續 30 分鐘」。

每天 12:30

12:30 執行
→ 13:00 再執行一次

每天 18:30

18:30 執行
→ 19:00 再執行一次

所以理論上的每日執行時間是：

06:32、07:02
12:30、13:00
18:30、19:00

⚠️ 不過 Windows Task Scheduler 對 「Repeat every 30 minutes for a duration of 30 minutes」的邊界時間有一些細節，結束時間點是否再觸發一次不建議直接假設。如果你是在做排程漏跑監控，最好把這種設定理解成「從起始時間開始，在 30 分鐘的 repetition window 內每 30 分鐘重複」，並用實際 History 或 Task XML 確認邊界行為。
