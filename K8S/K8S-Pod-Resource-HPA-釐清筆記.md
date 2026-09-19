# K8S Pod / 資源 / HPA 釐清筆記

## 1. values-hk-prod.yaml 的 CPU / Memory 在設定什麼？

在 `charts/promotion-console-nmqv3worker-group1/values-hk-prod.yaml` 中：

- `worker.resources`：通常對應 **requests**（排程保留的最小資源）。
- `limits`：對應 **上限**（CPU 超過會 throttling、Memory 超過會 OOMKill）。

目前設定（以單一 worker Pod/主要 container 來看）：

- request：`cpu=500m`、`memory=2000Mi`
- limit：`cpu=1000m`、`memory=2000Mi`

> 重點：這些數值是「每個 Pod（更精確是每個 container）」的設定，不是整個服務總量。

---

## 2. HPA 與 Pod 數量

目前 autoscaling 設定：

- `enabled: true`
- `minReplicas: 2`
- `maxReplicas: 4`
- `targetCPUUtilizationPercentage: 90`
- `targetMemoryUtilizationPercentage: 70`

代表 Pod 數會在 **2 ~ 4** 之間自動調整。

---

## 3. 「4 個 Pod = 一次只能跑 4 個 jobs」嗎？

不一定。  
4 個 Pod 只代表最多有 4 個 worker 實例，不等於一定同時只跑 4 個 job。

實際同時 job 數量取決於：

1. 每個 Pod 內 consumer 並行設定（thread/concurrency/prefetch）。
2. Group / Job 的 process 限制（例如 Thread Count、Max Processes）。
3. 當下可用 Pod 數與調度機制。

---

## 4. 依截圖（Group Detail）解讀

截圖重點：

- Group Name: `promotion.group1`
- Thread Count: `5`
- Job: `BookingRewardLoyaltyPointsDispatcherV2`
- Job `Max Processes`: `1`
- Orchestration: `K8S`

解讀：

- `Thread Count=5` 是 group 的總併發上限。
- 但該 job 的 `Max Processes=1`，因此這支 job 最多同時只會有 1 個 process。
- 所以這支 job 的有效同時數 = `min(Group Thread Count, Job Max Processes) = 1`。

---

## 5. 一個 Pod 可能同時跑 2 個 jobs 嗎？

可能。  
K8S 不保證「1 Pod = 1 Job」；是否同時處理多個 job 由 worker/queue 調度與並行設定決定。

---

## 6. HPA 觸發條件怎麼看？

HPA 預設看的是 **整體平均利用率**（對應 workload 內所有 Pod），不是單一 Pod 一過線就一定擴。

概念公式（簡化）：

`desiredReplicas = ceil(currentReplicas × currentMetricValue / desiredMetricValue)`

其中 `currentMetricValue` 為目前平均利用率，`desiredMetricValue` 為目標利用率（例如 Memory 70%）。

### 範例（2 Pods）

- CPU 平均 70%，target 90%：
  - `ceil(2 × 70 / 90) = 2`
- Memory 平均 65%，target 70%：
  - `ceil(2 × 65 / 70) = 2`

=> 維持 2 Pods。

若 CPU 平均 95%、Memory 平均 80%：

- CPU: `ceil(2 × 95 / 90) = 3`
- Memory: `ceil(2 × 80 / 70) = 3`

=> 擴到 3 Pods（仍受 min/max 夾制）。

---

## 7. 為什麼擴容公式長這樣？

因為 HPA 是比例控制：目標是把「每 Pod 平均負載」拉回 target。

- 平均負載是 target 的 2 倍 -> 副本理論上也要約 2 倍。
- 平均負載是 target 的 1/2 -> 副本可縮成約 1/2。

這比固定每次 +1 更快貼近目標。

---

## 8. 「目前副本數 × 平均利用率」是否等於「利用率總和」？

在每個 Pod request 相同時，可以這樣理解，成立。  
更本質上，HPA 是看「總使用量 / 總 request」的加權利用率。

---

## 9. 「不同 Pod request 不同」是什麼意思？

指同一個 HPA 範圍內，Pod（或 container）的 `resources.requests` 不一致。

例：

- Pod A request 500m，實際用 500m -> 100%
- Pod B request 1000m，實際用 500m -> 50%

整體不是單純 `(100% + 50%) / 2`，而是看總量比例：

`(500 + 500) / (500 + 1000) = 66.7%`

---

## 10. 單一 job 很吃記憶體時，HPA 有用嗎？

若單一 job 需要的記憶體已超過單 Pod 可承受上限，**只靠 HPA 通常無效**。  
HPA 解的是「總量/吞吐」，不是「單一工作過大」。

建議方向：

1. 調大單 Pod 記憶體 request/limit（先讓單 job 跑得動）。
2. 將 job 切批/分段，降低單次峰值記憶體。
3. 降低同 Pod 併發，避免重 job 疊加。
4. 將重型 job 分離到獨立 worker group 與資源規格。

---

## 11. 什麼情況最常觸發擴容？

兩種都常見：

1. 工作量很多（job 數量暴增）。
2. 工作內容很重（每個 job 本身耗 CPU/Memory 高）。

只要反映到平均 CPU/Memory 利用率超過 target，就會觸發 scale out。

---

## 12. Job / Container / Pod 的正確對應

一般情況下，不是「1 個 job 對應 1 個 container」。

在此 worker 型架構中可這樣理解：

- Pod：K8S 執行單位。
- Container（worker 程式）：常駐行程，持續從 queue 拉工作。
- Job：worker 程式內被處理的任務，不是 K8S container 實體。

因此「一個 Pod 同時處理多個 job」通常是因為同一個 worker container 內有並行處理能力，  
不是因為 Pod 內新增了多個對應 job 的 container。

---

## 13. 1 個 Pod / 2 個 Pod 在實務上的意義

- 1 個 Pod：可視為 1 個常駐 worker 實例。
- 2 個 Pod：可視為 2 個常駐 worker 實例，同時從同一批 job（queue/group）取件處理。

工作分配由 queue/consumer 調度決定，不保證平均分配到每個 Pod。

---

## 14. 單一 worker 實例可同時處理幾個 job，只看 Thread Count 嗎？

不能只看 Thread Count。

實際同時處理數由多層限制共同決定：

1. Group 層：`Thread Count`（整個 group 的總併發上限）
2. Job 層：`Max Processes`（該 job 的併發上限）
3. Worker 程式層：consumer concurrency / prefetch / thread pool 等設定
4. 執行拓撲層：當下可用 Pod 數量與調度分配結果

因此單 Pod 併發通常不是單一欄位可直接判定，而是上述條件的交集結果。

---

## 15. 單一 Pod 同時跑多個 Job 的資源影響

單一 Pod 確實可能同時處理多個 job。  
當多個 job 在同一 Pod 內並行執行時，會共享同一組 CPU/Memory 配額，因此會互相影響：

1. 某個 job 吃掉較多 CPU，其他 job 可能延遲上升或吞吐下降。
2. CPU 接近/超過 limit 時，可能出現 throttling。
3. 多個記憶體重型 job 疊加時，容易造成 memory 壓力，嚴重時可能 OOMKill。
