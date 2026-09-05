# 調查報告輸出格式

固定分三段：**現象 / 根因 / 建議**。若過程中出現判斷分岔（例如無法確定是否為財務風險、需要更長時間範圍才能下結論），**先跟使用者確認方向，不要自行假設後直接產出結論**。

## 通用開頭

簡述已透過 MCP 實際查證的資料來源（哪個 Loki datasource、哪個 k8s context/namespace、是否讀了原始碼），非憑空推測。

## 報告結構

```
## 現象
- TaskId / JobName / ShopId+MemberId+PromotionEngineId / 訂單代碼
- 觸發告警或使用者回報的具體描述

## 根因
- 完整時間軸表：
  | 時間 | TaskId | 建立來源(Dispatcher) | 事件 |
- 關鍵 log 證據（GivingPoint API 呼叫結果、Fatal/Exception、DDB 記錄快照）
- DDB 目前實際狀態（RewardStatus/RewardDetailStatus/GivingPoints）
- 明確結論：屬於「模式一：API 成功但 DDB 未更新」還是「模式二：純重複阻擋」還是其他（見 known-patterns.md）

## 影響評估
- 是否有重複給點/扣點的財務風險（有 api_0004 阻擋紀錄 = 無風險，需明確講）
- 噪音/重複告警的頻率與原因（例如 CronJob 每小時重派一次）

## 建議
- 短期：是否需要人工修正 DDB 記錄（附上 table 名稱、key）
- 中期：流程/程式碼改善建議
```

## 語氣與用詞

- 使用臺灣繁體中文，語氣專業但精簡。
- 每個結論都要附上查證依據（實際查到的 log 內容片段/時間戳/欄位值），避免空泛推測。
- 若受限於 Loki limit 或資料保留期限而無法完全查證，需誠實說明查證範圍的邊界。
