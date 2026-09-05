

## ❤️ Liveness Probe 存活檢查

這個容器是否「還活著」，沒死掉？

<br>

假如你的應用程式卡住、死鎖、無限迴圈，K8S 就可以根據 Liveness 檢查決定：「喔你死了，我幫你重啟一下。」

<br>

**📍典型狀況**：

Web API 執行到一半死掉，但沒整個 crash（K8S 看不出來）

<br>

Liveness 檢查會定期打某個 endpoint，發現 timeout 或回傳錯誤，就會自動重啟這個 container

<br>

---

## ✅ Readiness Probe 就緒檢查

**📌 意義**：這個容器準備好了嗎？可以對外提供服務了嗎？

<br>

一個應用啟動時可能需要：
- 連資料庫
- 加載設定檔
- 等第三方 API 回應

<br>

在這段期間內，其實「你不能讓流量進來」，因為會出錯。

<br>

Readiness Probe 幫你：「我還沒準備好喔！先不要把請求導過來」

<br>

**當 Readiness 檢查失敗**：
- K8S 不會把流量導向這個 Pod
- 但不會重啟它（因為它還活著，只是還沒準備好）

<br>

**範例**：yaml 的 secret 節點設定格式有誤

---

## 📊 CPU 使用率分析

### CPU 衝到 150% 是什麼意思

當你看到：**Pod CPU usage = 150%**

<br>

這代表：
- 該 Pod 已超過自己設定的 CPU request 值
- CPU 正在「搶用」Node 上的其他可用 CPU 時間

<br>

### CPU 資源配置範例

```yaml
resources:
  requests:
    cpu: "500m"   # 請求 0.5 顆 vCPU
  limits:
    cpu: "1"      # 最多用 1 顆 vCPU
```

<br>

**使用率計算**：

如果你看到使用率 150%，代表：
- 實際用量 = 0.75 顆 vCPU（= 150% of 0.5）
- 也可能已逼近 limit（甚至超過，取決於 cgroup 限制方式）

<br>

### HPA 自動擴容機制

**擴容計算公式**：

```
desiredReplicas = currentReplicas × (currentCPU / targetCPU)
= 3 × (150 / 70) ≈ 6.4 → 取整為 6
```

<br>

**處理流程**：

1. **加開 HPA** → 增加 replicas 數量（開新 Pod）
2. **等新 Pod 起來** → 負載分散後，平均 CPU 通常會回到 70% 左右
3. **觀察結果** → CPU 使用率下降、系統變穩定

<br>

### HPA 負載分散原理

**HPA 的本質**：

❌ **不是**：「幫你降 CPU」  
✅ **而是**：「幫你分攤工作量」

<br>

**分攤效果**：

- **原本**：3 個 Pod 撐著所有流量（平均 150%）
- **現在**：6 個 Pod 分攤（負載平均掉）
- **結果**：每個 Pod 的 CPU 掉到大約 75%

<br>

👉 **CPU 降低是因為更多實體在幫你分工**

<br>

### 常見陷阱與注意事項

| 陷阱 | 說明 |
|------|------|
| **1️⃣ Pod 增加不代表馬上降載** | 新 Pod 啟動需要 10~60 秒，冷啟動期間負載仍高。 |
| **2️⃣ Node 不夠會導致 Pending** | 如果 3 台 EC2 沒空間放更多 Pod，就會 Pending。這時要靠 Cluster Autoscaler。 |
| **3️⃣ CPU 過高的根本原因** | 有時不是流量，而是程式 bug（死迴圈、Task 重試、I/O 阻塞）。這時加 HPA 只是在掩蓋問題。 |

<br>

### HPA 系統層面分析

| 層面 | 說明 |
|------|------|
| **Deployment** | 被 HPA 控制的對象。Deployment 會被 HPA 改變 `replicas` 數量。 |
| **Metrics Server** | HPA 會透過它取得 Pod 的 CPU/Memory 使用率。 |
| **Cluster 資源壓力** | 自動擴容可能導致節點（Node）壓力增加，需搭配 Cluster Autoscaler 才能自動加 Node。 |
| **流量應變能力** | 當突發流量時，Pod 數會自動擴張以應對高負載。 |

<br>

### HPA 設定參數說明

| 設定項目 | 意義 | 備註 |
|----------|------|------|
| **Min Replicas** | 系統最低維持的 Pod 數量 | 避免縮太小導致冷啟動延遲 |
| **Max Replicas** | 系統允許的最大 Pod 數量 | 控制擴張上限，防止資源暴衝 |
| **CPU Target (%)** | Pod 平均 CPU 使用率門檻 | 例如設定 70%，超過就擴容 |
| **Memory Target (MiB)** | Pod 平均記憶體門檻 | 通常輔助 CPU 一起設定 |
| **Metrics Source** | 監控來源（Metrics Server / Prometheus Adapter） | 高階環境可能使用自訂指標，例如 QPS、延遲等 |

<br>