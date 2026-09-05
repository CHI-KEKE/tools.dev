

## Commerce CPU Throttled


https://91app.slack.com/archives/C3DB30C3T/p1757819609258729

<br>

#### CPU Throttling

在 Kubernetes、Docker、或 EC2 這類虛擬化環境中，每個容器或 Pod 通常會設有

- cpu.request（保證給你的資源）
- cpu.limit（最多能用多少）

如果程式的運算需求超過 cpu.limit，Linux cgroup 機制就會暫時凍結這個容器的執行緒，等下一個時間片再放行。這個動作稱為 CPU Throttling（節流）

<br>

#### Throttled 比例 > 50% 代表什麼？

假如
```yaml
resources:
  requests:
    cpu: 500m   # 保證有 0.5 核心
  limits:
    cpu: 1      # 最多能用 1 核心
```

你要用 CPU 的時間裡，有一半以上的時間在「被迫等 CPU」，當你的程式實際需要 > 1 核心 的計算力時，Kubernetes 不會讓它「真的吃到更多」，而是透過 Linux cgroup 的「CPU quota 機制」去強制限制它


| 類型               | 現象                 | 對應處理建議                                |
| ---------------- | ------------------ | ------------------------------------- |
| ⚙️ CPU limit 設太低 | Pod 想用更多 CPU 但被限制  | ↑ 調高 `cpu.limit` 或改用 `Guaranteed QoS` |
| 🧮 程式 CPU-bound  | 內部演算法/序列化太重、無非同步釋放 | 優化程式邏輯（如改成 parallel I/O、減少重複計算）       |
| 🧱 node 資源緊繃     | 該 node 上容器太多、資源競爭  | 調度分散 Pod 或升級 Node 規格                  |

<br>

#### 「被限制」的實際行為

每 100 毫秒是一個時間片（period），Pod 被分配的「quota」是這段期間允許執行的 CPU 時間。例如 `cpu.limit = 1` → `quota = 100ms`

當程式在這 `100ms` 內把 `quota` 用光了 → 系統會讓它「強制停下來」，直到下一個 period 才能繼續。這個「強制停下來」的時間，就記在 CPU throttled time。
