| line_format 就是決定你在螢幕上**「最後看到的那一行長什麼樣子」**。


| line_format "{{._msg}}" 的意思是： 「隱藏原始的所有日誌內容，只顯示 _msg 這個欄位的值。」


通常生產環境的日誌（尤其是 JSON 格式）會包含非常多雜訊，例如： {"timestamp": "2026-02-12", "level": "info", "service": "auth", "_msg": "User logged in", "ip": "127.0.0.1", "traceId": "abc12345"}

如果你直接看，眼睛會很花。用了這行指令後

解析： | json 先把上面的內容拆成 timestamp, level, _msg 等欄位。
重組： | line_format "{{._msg}}" 告訴 Grafana：「我只想看訊息主體就好。」


## 例子

假設你的原始日誌長這樣： {"JobName": "SyncLiveCommentStatus", "_msg": "Successfully processed 10 comments", "threadId": 101}

加上這段語法後：

- | json：把 JobName 和 _msg 抓出來。
- |_props_JobName = "SyncLiveCommentStatus"：只留下這類工作。
- | line_format "{{._msg}}"
  
處理前 (原始狀態),處理後 (螢幕顯示)
"{""JobName"": ""SyncLiveCommentStatus"", ""_msg"": ""Successfully processed 10 comments"", ""threadId"": 101}",Successfully processed 10 comments


## 進階玩法

也可以把多個欄位組合在一起，變成好讀的句子。例如： | line_format "任務 {{._props_JobName}} 執行的結果是：{{._msg}}"



任務 SyncLiveCommentStatus 執行的結果是：Successfully processed 10 comments