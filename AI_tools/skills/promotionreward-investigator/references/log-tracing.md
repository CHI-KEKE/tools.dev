# Loki Log Tracing 技巧（NMQ Worker 專用）

## 1. Nested JSON 解包

NMQv3Worker 的 log 常見兩種形態：
- **一般業務 log**：outer envelope 直接就是這行 log（`_msg` 是純文字）。
- **NMQ Router 轉發 log**（`_srctx: NMQ.Core.Router.ProcessPool.WorkerProcessPool`）：outer 的 `_msg` 欄位本身是**一整行內層 JSON 字串**（有時疊 2 層以上），內層才是真正的 `_msg`/`_lvl`/`_srctx`/`_props`（含 `StatusCode`/`Uri`/`ElapsedMilliseconds` 等 HTTP 呼叫細節）。

必須用遞迴解包再讀取欄位，否則會拿到一整包轉義過的 JSON 字串當作訊息內容。範例 PowerShell：

```powershell
$json = Get-Content '<loki查詢輸出暫存檔>' -Raw | ConvertFrom-Json
$rows = $json.data | ForEach-Object { $_.line | ConvertFrom-Json } | Sort-Object time

function Unwrap($obj) {
  $cur = $obj
  for ($i=0; $i -lt 5; $i++) {
    if ($cur._msg -is [string] -and $cur._msg -match '^\{.*\}$') {
      try { $cur = $cur._msg | ConvertFrom-Json } catch { break }
    } else { break }
  }
  return $cur
}

$lines = foreach ($r in $rows) {
  $u = Unwrap $r
  $extra = if ($u._props.StatusCode) { "status=$($u._props.StatusCode) uri=$($u._props.Uri)" } else { "" }
  "$($r.time) | $($u._lvl) | $($u._srctx) | $($u._msg) | $extra"
}
$lines | Out-File '<輸出檔>' -Encoding utf8
```

輸出後用 `grep`/`view -view_range` 分段讀取（單一 Task 完整生命週期常有數十~上百行，內含很長的 MetricsLogEntity/Exception JSON 字串，建議先過濾掉超長行：`Where-Object { $_.Length -lt 400 }` 只看精簡摘要行，需要細節再回頭查完整行）。

## 2. `query_loki_logs` 的 limit 陷阱

不論 `limit` 參數填多少，實際回傳筆數常被固定封頂在 **100 筆左右**。查詢前後一定要檢查回傳資料的**第一筆/最後一筆時間戳**：
- 若時間跨度明顯小於預期（例如整個 burst 只涵蓋幾十毫秒~幾秒，但已知這顆 Task 應該跑了數秒到數十秒），代表資料被截斷，需要用更窄的 `startRfc3339`/`endRfc3339` 分段重查，把完整生命週期串起來。

## 3. CorrelationId 不等於 TaskId 的陷阱

`NMQ.Core.Router.ProcessPool.WorkerProcessPool` 這類底層轉發 log 的 `_props.CorrelationId`，代表的是 **RabbitMQ 訊息投遞/worker 輪詢週期的關聯 ID**，不一定等於當下正在執行的業務 TaskId（尤其在同一輪詢批次內處理多顆 Task 時）。

**正確作法**：
- 用 TaskId 全字串（`|= "<TaskId>"`）去搜整行 log 內容，而不是只靠 `CorrelationId` label 篩選。
- 業務層 log（`Nine1.Promotion.Console.NMQv3Worker.Jobs.PromotionReward.*`）內的 `_props.CorrelationId` 才會等於該次 `ProcessRewardStateAsync` 執行對應的 TaskId（例如 `RabbitMQWorker AckMsgOk` 的 `_props.CorrelationId`）。

## 4. 回溯訂單重複阻擋（api_0004）的原始成功呼叫

流程：
1. 從失敗 log 抓出訂單代碼（`取得線下訂單代碼組合 : XXXXXXX`）或 `ddb Key : {PromotionEngineId}_CrmSalesOrder:{crmSalesOrderId}`。
2. 用該訂單代碼字串（例如 `YSS00121987`）在 **48~72 小時** 的寬時間窗查詢，把所有出現過這個訂單代碼的 log 全部撈出。
3. 依時間排序，找到最早一筆 `"ResultCode":"api_0000"` + `給點完成 TransactionCode:...` 的成功紀錄。
4. 檢查該筆成功紀錄後續幾秒內是否有：
   - `Fatal` log（例如 `the task state is not 'ready' or 'pause'`，代表 Worker Process 當掉重啟）
   - 明顯的 log 空白時間段（例如給點成功後 5~10 秒內完全沒有任何 log，可能是 DynamoDB 呼叫延遲/卡住）
   - 任何 DynamoDB 相關 Exception
5. 這段「成功呼叫後、DDB 狀態更新前」的空窗，就是根因所在（詳見 `known-patterns.md`）。

## 5. 讀取 DDB 記錄快照

不需要額外查 DynamoDB API，Loki log 本身在 `[DynamoDB Record]Get item from table:"..." key:"..." item:"{...}"` 這類 log 中就會把完整記錄 JSON dump 出來（`_props.Item`），可直接讀取確認 `RewardStatus`/`GivingPoints`/`RewardHistoryList` 等欄位目前的實際狀態。
