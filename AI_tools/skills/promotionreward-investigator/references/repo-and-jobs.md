# Repo 與 Job 對照（nine1.promotion.worker）

Repo 本機路徑：`C:\91APP\Promotion\worker\nine1.promotion.worker`（Solution: Nine1.Promotion.Console）

## 專案結構重點

- `src\Nine1.Promotion.Console.NMQv3Worker\Jobs\PromotionReward\` — 各 NMQ Job 的進入點（`IProcess.DoJob`）
- `src\Nine1.Promotion.Console.BL\Services\PromotionReward\LoyaltyPointService.cs` — 給點/回收點數的核心商業邏輯
- `src\Nine1.Promotion.Console.BE\PromotionReward\Enums\RewardStatusEnum.cs` — 主單狀態
- `src\Nine1.Promotion.Console.BE\PromotionReward\Enums\RewardDetailStatusEnum.cs` — 子單狀態
- `src\Nine1.Promotion.Console.NMQv3Worker\DI\PromotionReward\*DIAttribute.cs` — 各 Job 的 DI 註冊（可看出用了哪些 Client/Repository）
- `src\Nine1.Promotion.Console.NMQv3Worker\Program.cs` — JobName → Job 類別的對應表（`map.Add(...)`）

## 關鍵 Job 角色與關係

```
[OrderCreated 事件 / 會員分級計算完成]
        │
        ▼
PromotionRewardBatchDispatcherV2Job  ──(建立 Task, S3Key: .../PromotionRewardBatchDispatcherV2/...)──┐
        │                                                                                              │
[每小時 CronJob 掃描 WaitToReward 補漏]                                                                 │
        │                                                                                              │
BookingRewardLoyaltyPointsDispatcherV2Job ──(建立 Task, S3Key: .../BookingRewardLoyaltyPointsDispatcherV2Job/...)──┤
        │                                                                                              │
        │                                                                                              ▼
        │                                                                          PromotionRewardLoyaltyPointsV2Job (真正給點 Worker)
        │                                                                                              │
        │                                                                          呼叫 loyalty-api GivingPoint
        │                                                                                              │
        │                                                                          更新 DDB 主單/子單狀態 → Reward
        ▼
RecycleLoyaltyPointsV2 / PromotionRewardCouponJob（退點/コupon 對應流程，邏輯類似）
```

- **PromotionRewardBatchDispatcherV2Job**：處理正流程訂單（線上/線下），依 ShopId+MemberId+PromotionEngineId 分組後直接建立 `PromotionRewardLoyaltyPointsV2PriorityLow` Task（S3Key 路徑含 `PromotionRewardBatchDispatcherV2`）。
- **BookingRewardLoyaltyPointsDispatcherV2Job**：**每小時觸發**（K8s CronJob，預設 schedule `1 * * * *`，實際以 `k8s-mcp-kubectl_describe resourceType=cronjob` 查證），撈取 `BookingTimeUTC` 落在 `ExecuteTime-1h ~ ExecuteTime`（取整點）區間、且 `RewardStatus==WaitToReward` 的 DDB 主單，重新分組建立給點 Task（S3Key 路徑含 `BookingRewardLoyaltyPointsDispatcherV2Job`）。**若某筆記錄卡在 WaitToReward 不放，只要它的 BookingTimeUTC 落在某次執行窗口內就會被重複掃到、重複派工。**
  - 查詢邏輯（`BookingRewardLoyaltyPointsDispatcherV2Job.cs`）：
    ```csharp
    var startTime = entity.ExecuteTime.AddHours(-1).ToHour();
    var endTime = entity.ExecuteTime.ToHour();
    var records = await _promotionRewardService.GetPromotionRewardRecordByBookingTimeAsync(startTime, endTime);
    records = records.FindAll(item => item.RewardStatus == nameof(RewardStatusEnum.WaitToReward));
    ```
  - DDB 查詢（`PromotionRewardService.GetPromotionRewardRecordByBookingTimeAsync`）用 GSI `BookingDateUTC-BookingTimeUTC-index`，條件 `BookingDateUTC = startTime.Date AND BookingTimeUTC BETWEEN startTime AND endTime`。
- **PromotionRewardLoyaltyPointsV2Job**：真正執行給點的 Worker。流程（`ProcessRewardStateAsync` → `PromotionRewardProcess` → `LoyaltyPointService.ProcessRewardPointAsync`）：
  1. 從 S3 下載訂單資料，用 `PromotionRewardLocker` 對 DDB key（`{PromotionEngineId}_CrmSalesOrder:{crmSalesOrderId}` 或 `{PromotionEngineId}_{TradesOrderGroupCode}`）取得分散式鎖（重試 3 次，每次間隔 3 秒；3 次都失敗會拋 `ApplicationException("[最終 LOCK 失敗訊息] ...")`）。
  2. 計算應給點數，若 >0 呼叫 `RewardPointAsync` → POST `loyalty-api.internal.{market}.91app.io/LoyaltyPoint/GivingPoint`。
  3. **只有在上一步呼叫成功（`ResultCode==api_0000`）之後**，才會更新子單狀態為 `Reward`、主單 `RewardStatus=Reward`，最後呼叫 `UpdateLoyaltyPointRewardRecordWithHistoryAsync` 寫回 DDB 主表。
  4. **如果第 3 步過程中發生任何未預期中斷（Worker Process 崩潰、DynamoDB 呼叫逾時等），DDB 主單狀態會永遠停留在 WaitToReward，即使給點 API 已經成功呼叫過。** 這是本 skill 最常見的根因模式，詳見 `known-patterns.md`。
- **RecycleLoyaltyPointsV2** / **PromotionRewardCouponJob**：邏輯結構類似（鎖 → 呼叫外部 API → 更新 DDB），可比照上面步驟排查。

## OrderCode 產生規則（給點 API 冪等 key）

`LoyaltyPointService.GenerateCode(tradesOrderGroupCode, promotionEngineId)` 產生格式為 `{訂單代碼}|{promotionEngineId}`（例如 `YSS00121987|10745`）。loyalty-api 以此作為冪等鍵，同一組合重複呼叫會回傳 `ResultCode: api_0004`, `ResultMessage: "訂單編號重複 _ ..."`。
