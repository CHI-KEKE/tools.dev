
[2026-07-13 14:11:09.323 +08:00] [WRN] 心跳型任務 \Member\OMO_Member_ETL_UpdateTrialAndLiteMemberDataToCRMDB_Minute 心跳正常但最近一次執行結果失敗，ResultCode=267009。
[2026-07-13 14:11:09.323 +08:00] [INF] 發送告警："Failed" | 任務 \Member\OMO_Member_ETL_UpdateTrialAndLiteMemberDataToCRMDB_Minute | 預期時間 2026-07-13 14:11:06 | 詳情：心跳最近一次執行失敗，ResultCode=267009
[2026-07-13 14:11:09.323 +08:00] [ERR] 【排程執行失敗告警】任務 \Member\OMO_Member_ETL_UpdateTrialAndLiteMemberDataToCRMDB_Minute 於 "2026-07-13T14:11:06.0000000" 前後執行，但結果為失敗（心跳最近一次執行失敗，ResultCode=267009）。
[2026-07-13 14:11:09.323 +08:00] [INF] ----- [執行失敗，執行時間 2026-07-13 14:11:06，ResultCode=267009] \Member\OMO_Member_ETL_UpdateTrialAndLiteMemberDataToCRMDB_Minute -----



看起來是 3 組 flowname 每小時執行

有看到 fail code history 但找無 log