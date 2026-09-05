# DDB Table 與狀態機

## Table 命名與 Key

| Table                                    | 說明     | Partition Key 格式                                              |
|-------------------------------------------|----------|-------------------------------------------------------------------|
| `{Market}_Prod_Loyalty_PromotionReward`        | 主單     | `{PromotionEngineId}_{TradesOrderGroupCode}` 或 `{PromotionEngineId}_CrmSalesOrder:{crmSalesOrderId}` |
| `{Market}_Prod_Loyalty_PromotionReward_Detail` | 子單（每個給點/回饋明細一筆） | 依明細規則另有複合 key，通常含主單 key + DetailId |

GSI：`BookingDateUTC-BookingTimeUTC-index`（`BookingRewardLoyaltyPointsDispatcherV2Job` 用來抓每小時待補的 WaitToReward 主單，見 `repo-and-jobs.md`）。

## RewardStatusEnum（主單狀態）

| 值 | 意義 |
|---|---|
| WaitToReward | 待給點（尚未成功呼叫給點 API 且完整寫回） |
| Reward | 已給點完成 |
| Unmatch | 不符合活動資格 |
| Cancel | 已取消（例如訂單取消/退貨） |
| Occupy | 名額佔用中（尚未確定是否給點，通常搭配活動名額限制） |
| MatchWithoutQuota | 符合資格但名額已滿，不給點 |

## RewardDetailStatusEnum（子單/明細狀態）

| 值 | 意義 |
|---|---|
| WaitToReward | 待給點 |
| Reward | 已給點 |
| Cancel | 已取消 |
| Recycle | 已回收（退貨扣點等） |
| NoReward | 不給點 |

## 判讀重點

- 主單 `RewardStatus == WaitToReward` 但同時能在 Loki 找到該訂單過去已有 `api_0000` 給點成功紀錄 → **典型的「API 成功但 DDB 沒更新」卡住案例**，而非真的還沒給點。務必先查 log 確認是否已經給過點，不要只看 DDB 目前狀態就下結論。
- 判斷是否有「重複給點」財務風險：只要看 loyalty-api 是否曾經回傳 `api_0004`（訂單編號重複）阻擋——只要有阻擋紀錄，代表沒有真的重複入帳，可以放心排除財務風險疑慮。
