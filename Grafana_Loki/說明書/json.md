## | json 的運作邏輯

- 解析 (Parsing)： Loki 會掃描日誌內容，尋找符合 JSON 格式的字串
- 提取 (Extraction)： 它會自動將 JSON 裡的每個 key 提取出來，變成一個可以操作的 Label (標籤)
- 對應 (Mapping)： 在你的例子中，JobName 原本只是文字的一部分，使用 | json 後，Grafana 就知道 SyncLiveCommentStatus 是 JobName 這個欄位的值


## 例

原始
```json
{
  "time": "2026-02-12T05:36:39.824208072Z",
  "stream": "stdout",
  "_ts": "2026-02-12T05:36:39.8240847Z",
  "_msg": "Started new worker process, process id: 83190",
  "_lvl": "Information",
  "_srctx": "NMQ.Core.Router.ProcessPool.WorkerProcessPool",
  "_lt": "Common",
  "_hid": "nine1-live-buy-worker-console-nmqv3worker-754888f5b9-p9jjp",
  "_props": {
    "TaskId": "694a1bf0-db4c-4aad-8d09-61837401bd26",
    "SourceId": "",
    "JobName": "ProcessLotteryParticipant",
    "GroupName": "91app-live.group1",
    "CorrelationId": "694a1bf0-db4c-4aad-8d09-61837401bd26",
    "LogRootPath": "c:\\logs"
  },
  "source": "nine1-live-buy-worker-console-nmqv3worker-754888f5b9-p9jjp",
  "kube_namespace": "prod-91app-live",
  "kube_container_name": "nine1-live-buy-worker-console-nmqv3worker"
}
```

如果不加 | json，你只能用關鍵字搜尋（例如：|= "SyncLive"）。 但加了之後，你可以進行更精確的進階查詢，例如過濾特定工作

```bash
{service="prod-91app-live"}
| json
| _props_JobName = "SyncLiveCommentStatus"
```

統計數量： 你可以針對不同的 JobName 畫出圓餅圖或趨勢圖，因為現在 JobName 已經是一個獨立的維度了。

小撇步： > 有時候 JSON 層級很深，你可以指定提取路徑，例如 | json my_field="data.user.id"。