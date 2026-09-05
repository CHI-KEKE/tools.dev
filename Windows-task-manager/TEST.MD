
## FAILED & MISSED Case




✅ 兩個任務已建立成功，觸發時間約在 3 分鐘後（~10:27）：

┌─────────┬─────────────┬────────────────────────────────┐
│ 任務    │ 機制        │ 預期結果                       │
├─────────┼─────────────┼────────────────────────────────┤
│ TypeE-F │ Action      │ 會確實執行並寫入 log，但       │
│ ailure  │ 執行後 exit │ LastTaskResult 非 0 →          │
│         │ /b 1        │ 對應「有跑但失敗」分支         │
├─────────┼─────────────┼────────────────────────────────┤
│ TypeF-M │ RunOnlyIfId │ 觸發時間到，但因為你在操作機器 │
│ issed   │ le（閒置 1  │ 不會閒置，Task Scheduler       │
│         │ 小時才觸發  │ 會跳過該次執行且不會寫 log →   │
│         │ ，逾時 2    │ GetRunTimes                    │
│         │ 小時）      │ 仍回報候選時間，GetHistory     │
│         │             │ 查無紀錄 →                     │
│         │             │ 對應「該跑沒跑（漏排）」分支   │
└─────────┴─────────────┴────────────────────────────────┘

驗證建議：等 3~5 分鐘後，先用  Get-ScheduledTaskInfo -TaskName TypeE-Failure,TypeF-Missed -TaskPath "\WTMTest\"  確認  LastRunTime / LastTaskResult ，並檢查  test-logs\TypeE-Failure.log  有無內容、 TypeF-Missed.log  應該完全沒有內容。之後（等超過 Tolerance 30 分鐘容錯窗）再跑一次 Monitor，應該會分別看到「執行失敗」與「漏排」兩種告警。要現在等待驗證，還是先做其他調整？



## missed 還是有紀錄

找到真正的原因了！不是 Tolerance 設定的問題，而是 Event Log 殘留紀錄造成的假陽性比對。

根本原因

你先前刪除並重建  TypeF-Missed （ Unregister-ScheduledTask  +  Register-ScheduledTask ），但 Windows Event Log 是純文字比對  TaskName  欄位，不會區分「這是舊任務留下的紀錄」還是「新任務的紀錄」。

舊版  TypeF-Missed （重建前）在  10:35:09  曾經成功執行過一次（ return code 0 ），這筆紀錄依然留在  Microsoft-Windows-TaskScheduler/Operational  log 裡：

2026/7/12 10:35:09 | EventID=200 | Task Scheduler launched action ... "\WTMTest\TypeF-Missed"
2026/7/12 10:35:09 | EventID=201 | ... successfully completed ... return code 0

而新任務的候選時間是  10:06:09 ， Tolerance=30  的接受窗是  [09:36:09, 10:36:09] ——舊紀錄的  10:35:09  剛好落在這個窗口內！所以  GetHistory()  查到這筆「無辜」的舊紀錄，誤判成「候選時間 10:06:09 已經成功執行過」，直接下結論、不會走到漏排分支。

改成  Tolerance=2  之所以「有抓到」，是因為接受窗縮小成  [10:04:09, 10:08:09] ，舊紀錄的  10:35:09  已經被排除在窗口外，所以查無紀錄、正確判定漏排——但這其實是巧合對了，不是 Tolerance 設計有問題。

這對你的啟示

1. 這不是程式邏輯的 bug，是測試手法帶來的資料污染——真實場景裡任務通常不會被刪除重建，不會有這種問題。
2. 但這確實暴露一個值得記錄的已知限制：如果任務曾經被刪除重建，舊執行紀錄仍可能落在新候選時間的容錯窗內造成誤判「已執行」。