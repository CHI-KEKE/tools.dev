

Converting null literal or possible null value to non-nullable type


你正在把「可能是 null 的東西」,指派給「宣告成不可為 null 的型別」


IEnumerable<PromotionRewardHistoryBaseEntity> rewardHistories = dynamicReward?.RewardHistoryList as IEnumerable<PromotionRewardHistoryBaseEntity>;


=> 

IEnumerable<PromotionRewardHistoryBaseEntity>? rewardHistories = dynamicReward?.RewardHistoryList as IEnumerable<PromotionRewardHistoryBaseEntity>;