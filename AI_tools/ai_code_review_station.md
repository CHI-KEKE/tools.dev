console 站台只能做一件事
改東西很難知道是否有效果
可以追蹤很多事情 comment , commit, pr , hot tables 異動次數
部署
log
google api
mcp
費用 dify api
用 db, slack,google api 紀錄
rules 寫在 db



db 紀錄每個月的費用
標記 pr 處理完的資料
log 處理
今天有異常 用 AI 拉出所有可能導致異常的異動
hottables維護 快取
紀錄每次到底都回覆一些甚麼
今天上的code或知識庫更新是否有作用


AI摘要

MCP 也可以串 AI Codereview



想了一下情景
解決了某個　rule 但很難查
改code 也很難debug 不知道為啥要用cli
改個 code 還要跑那個奇怪的 ci
而且你很難知道哪一個 fail了怎麼查
Api 很難擴充
他是用console 跑的 幾乎只能做一件事情
研究code review 的問題可以由主動轉成被動
甚至可以看誰commit 都在亂寫
可以出一些實驗性的API
費用不知道從哪裡來的