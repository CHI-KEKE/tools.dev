# 已知根因模式

## 模式一：GivingPoint API 成功、但 DDB 狀態更新前 Worker 中斷 → 主單永遠卡在 WaitToReward

**現象特徵**：
- 某訂單多次觸發給點流程（可能由 `PromotionRewardBatchDispatcherV2Job` 首次觸發，之後被 `BookingRewardLoyaltyPointsDispatcherV2Job` 每小時重複重派）。
- 每次重派的 Task 最終都在呼叫 `GivingPoint` API 時收到 `ResultCode: api_0004`（訂單編號重複）而失敗。
- 但往回追溯可以在 Loki 找到一筆更早的呼叫，回傳 `ResultCode: api_0000` 且有 `TransactionCode`，代表**點數其實已經真的給過了**。
- 該筆成功呼叫之後緊接著（通常數秒內）出現：
  - `Fatal` log：`According to the response from APIGetTaskInfoAsync, the task state is not 'ready' or 'pause'`
  - 隨後 NMQ worker process 重啟/崩潰的痕跡（log 突然中斷，之後是全新的 process 啟動 log）
- 直接查 DDB 記錄（`[DynamoDB Record]Get item...` log 或現場查詢）確認主單 `RewardStatus` 仍為 `WaitToReward`，`GivingPoints` 為 0 或未更新，即使已過了很長時間（可能數天）。

**根因**：`LoyaltyPointService.ProcessRewardPointAsync` 的邏輯是「先呼叫外部 GivingPoint API → 成功後才更新 DDB 狀態」，兩步之間沒有交易保護（no atomic transaction / no compensation）。若 Worker Process 在這個空窗期當機（例如收到 NMQ 平台的健康檢查/心跳判斷 Task 狀態異常而強制中止），API 呼叫的副作用（真實給點）已經發生，但本地 DDB 狀態沒能寫回，導致：
1. 訂單財務上正確拿到點數（無重複給點風險，因為 loyalty-api 本身有冪等保護）。
2. 但系統誤以為還沒給點，之後每小時的 `BookingRewardLoyaltyPointsDispatcherV2Job` 掃描都會重新撈到這筆 `WaitToReward` 記錄並重新派工，造成持續重複告警/重複嘗試（每次都被 api_0004 擋下，形成噪音）。

**影響評估要點（寫報告時務必包含）**：
- 明確說明「沒有重複扣點/重複給點的財務風險」（因為每次重試都被 api_0004 擋下）。
- 說明噪音的來源與頻率（每小時一次，直到人工修正 DDB 記錄或訂單被取消為止）。

**建議修復方向**：
- 短期：人工修正該筆 DDB 主單記錄的 `RewardStatus` 為 `Reward`（並補上正確的 `GivingPoints`/`TransactionCode`），阻止後續重複重派。
- 中期：在 `ProcessRewardPointAsync` 呼叫外部 API 成功後，若後續 DDB 更新失敗，應有補償機制（例如：先在 DDB 寫入「API 已呼叫，等待確認」的中繼狀態，或用 API 回傳的 `TransactionCode` 做 idempotent 重試/補寫，而不是整段流程從頭重來）。
- 建議進一步排查此類 Worker Process Fatal 中斷的根本原因（NMQ 平台健康檢查邏輯、Task 執行逾時設定等），評估是否可預防或至少讓崩潰前已完成必要的 DDB 寫入。

## 模式二：純粹的重複給點阻擋（無前置失敗）

**現象特徵**：單一 Task 直接收到 `api_0004`，且往回查沒有找到很久以前的成功紀錄（例如同一批次內兩個 Job 幾乎同時觸發，皆嘗試給同一筆訂單點數）。

**根因**：屬正常的併發保護行為（loyalty-api 冪等鍵擋下重複請求），非系統故障。

**建議**：說明這是保護機制正常運作；若想避免無謂重試消耗資源，可考慮讓呼叫端在收到 `api_0004` 時直接判定為終態（不可重試），不要當作暫時性錯誤繼續重試 3 次。
