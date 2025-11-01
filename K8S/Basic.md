








## EKS 容器服務

Amazon EKS (Elastic Kubernetes Service) 是 AWS 提供的一種托管 Kubernetes 服務，讓你可以在 AWS 上部署、管理和擴展容器化應用程式

## 部署流程

CI/CD 是持續整合（Continuous Integration）與持續部署/交付（Continuous Deployment/Delivery）的流程。而 EKS 在這個流程中的角色是：

<br>

| 階段 | 說明 | EKS 的角色 |
|------|------|-----------|
| CI（持續整合） | 專案程式碼 push 到 GitHub/GitLab 後自動觸發建置與測試流程 | 無直接關係，但會用於之後部署 |
| CD（持續部署） | 成功建置後自動部署到實際的執行環境 | ✅ 通常部署的目標就是 EKS！ |
| 執行環境 | 提供穩定、高可用的容器環境 | ✅ EKS 上會跑你打包好的 Docker 映像（如 Web API、後台服務等） |

<br>

1. 開發者 Push 程式碼到 GitHub

<br>

2. GitHub Actions（或 GitLab CI、Jenkins）會自動：
   - 建置專案
   - 執行測試
   - 將映像推送到 ECR（Elastic Container Registry）

<br>

3. 之後會觸發 CD 流程（例如 Argo CD 或 Helm）

<br>

4. 把新的映像部署到 EKS 上的某個 Kubernetes Pod

<br>

### 簡單比喻

CI/CD 是建築流程與機具（自動化蓋房子）, EKS 是蓋好的基地（地皮 + 建好骨架），負責放你要蓋的房子（容器）

<br>

## 2. Kubernetes 三個基本角色

### 1. Node（節點 / 工作者）🖥️

可以是一台實體機器（例如你自己的伺服器）或是雲端的虛擬機器（例如 AWS EC2）。每個 Node 都是 Kubernetes 的「工人」，負責執行應用程式。有時也叫作 Minion（奴隸），因為它聽從主控 Master（Control Plane）的指令。

<br>

**🔧 功能**：
- 幫忙執行 Pod（容器群）
- 管理 CPU、記憶體等資源
- 提供網路、磁碟空間

<br>

### 2. Pod（膠囊 / 容器群）

是 Kubernetes 中「最小的可部署單位」。

<br>

一個 Pod 裡面可以裝一個或多個 Container（但大部分情況是一個）。

<br>

**🧠 為什麼需要 Pod？**

因為直接用 Container（容器）太難管理網路，K8S 幫你用 Pod 把容器「包裝起來」變成一個整體。Docker 會幫這個 container 分配一個獨立 IP，每個 container 都在自己的網路空間中運作（network namespace）。

<br>

你要讓 container A 去找 container B，必須：
- 知道對方的 IP 或名稱
- 自己處理 port mapping、防火牆等

<br>

**🌐 Pod 的特性**：

裡面的容器會共用：
- 同一個 IP 地址
- 同一個網路空間
- 同一個儲存空間（Volume）

<br>

容器彼此就像住在同一個房間，可以用 localhost 互相講話，速度又快又安全。

<br>

### 3. Container（容器）🚢

裡面跑的就是你真正寫好的應用程式，例如：
- Node.js 後端
- MySQL 資料庫
- Python 機器學習模型

<br>

通常用 Docker 建立容器映像（image），再部署到 Pod 中

<br>

**📦 一個容器 = 一個微服務**

每個 Container 就像一台微型電腦，跑著某個功能，例如會員服務、購物車服務、資料庫等。

<br>

### 架構示意圖

```
Kubernetes 節點(Node)
 ├── Pod A
 │    ├── 容器：Node.js API
 │    └── 容器：Sidecar 日誌收集器
 ├── Pod B
 │    └── 容器：MySQL 資料庫
 └── Pod C
      └── 容器：Redis 快取服務
```

<br>

### 元件對照表

| 元件 | 說明 | 類比 |
|------|------|------|
| Node | 實際跑應用程式的機器 | 工廠地點 |
| Pod | 把容器包在一起的基本單位 | 一間機房、一個房間 |
| Container | 應用程式運作的實體 | 機器、冷氣、伺服器 |

<br>



## 9. 📈 HPA 水平自動擴展

HPA 是 Kubernetes 的一個內建功能，可以根據資源使用狀況（如 CPU 或記憶體）自動增加或減少 Pod 數量。就像自動幫你「加人手」或「減少人力」來處理不同流量的情況。

<br>

### 運作範例

假設你有一個後端服務叫 `cart-web-api` 正常情況只需要 2 個 Pod 就夠了

<br>

但有促銷活動或雙 11，一下湧入大量流量，CPU 使用率暴增

<br>

**HPA 自動處理流程**：

1. HPA 偵測到 CPU 使用率 > 80%
2. 自動幫你擴充成 5 個 Pod，來承受高流量
3. 等流量退去後，再降回原本的 2 個 Pod






## 10. ⚖️ Scale 手動擴展

Scale 是一個手動調整 Pod 數量的操作方式。你可以直接告訴 Kubernetes：

<br>

- 「我現在想要有 5 個 Pod 就好」
- 「把這個服務調到 10 個 Pod！」

<br>

這是立即執行、強制指定的數量，與系統監控指標無關。

<br>

### ⚠️ 注意：HPA 會覆蓋 scale 的手動設定

如果你同時設定了 HPA，又手動用 scale 調整 Pod 數量，那 HPA 會：

<br>

在下一次監控週期（預設 15 秒）內**「打回原形」**，依照它自己的邏輯重新設定 Pod 數量。

<br>




## 11. 🔐 IRSA 服務帳戶角色關聯

IRSA 是讓 Kubernetes 裡的 Pod 可以「直接拿到 AWS IAM 權限」的一種安全做法。

<br>

而且這個權限是獨立的、不用再跟其他 Pod 共用，幫助你達成「最小權限原則（Least Privilege）」。

<br>

### 在 EKS 沒有 IRSA 之前

如果你想讓 Pod 存取 AWS 資源（例如 S3、DynamoDB、SQS），你會這樣做：

<br>

1. 把 IAM Role 綁在 EC2 Node（也就是 Kubernetes 的 Worker Node）上
2. 這樣上面跑的所有 Pod 都會自動繼承這個角色的權限

<br>

**❌ 問題**：所有 Pod 都能拿到相同的 IAM 權限！

<br>

就像你把所有辦公室的人都給了「總經理的門禁卡」一樣，風險超高！

<br>

### ✅ IRSA 的優勢

IRSA 讓你可以：

<br>

- 針對「某個特定 Pod（或 Service Account）」
- 指定它要用的 IAM Role
- 其他 Pod 都不會拿到這個權限

<br>




## 5. ❤️ Liveness Probe 存活檢查

**📌 意義**：這個容器是否「還活著」，沒死掉？

<br>

假如你的應用程式卡住、死鎖、無限迴圈，K8S 就可以根據 Liveness 檢查決定：「喔你死了，我幫你重啟一下。」

<br>

**📍典型狀況**：

Web API 執行到一半死掉，但沒整個 crash（K8S 看不出來）

<br>

Liveness 檢查會定期打某個 endpoint，發現 timeout 或回傳錯誤，就會自動重啟這個 container

<br>

---

## 6. ✅ Readiness Probe 就緒檢查

**📌 意義**：這個容器準備好了嗎？可以對外提供服務了嗎？

<br>

一個應用啟動時可能需要：
- 連資料庫
- 加載設定檔
- 等第三方 API 回應

<br>

在這段期間內，其實「你不能讓流量進來」，因為會出錯。

<br>

**📍Readiness Probe 幫你**：

「我還沒準備好喔！先不要把請求導過來」

<br>

**當 Readiness 檢查失敗**：
- K8S 不會把流量導向這個 Pod
- 但不會重啟它（因為它還活著，只是還沒準備好）

<br>

**範例**：yaml 的 secret 節點設定格式有誤






## 22. 🖥️ Node 節點架構

### AWS 環境中的 Node 概念

在 AWS 上，Rancher 所管理的 Kubernetes 叢集通常架在 EKS（Elastic Kubernetes Service）上，而每個 Node（節點）通常就是一台 EC2 instance。

<br>

### Kubernetes 元件與 AWS 對應關係

| Kubernetes 元件 | AWS 實體對應 | 功能說明 |
|-----------------|--------------|----------|
| **Node** | 一台 EC2 | 用來執行 Pod。是叢集的運算單位。 |
| **Pod** | Container 群組 | 實際運行服務的容器（例如你的 C# 微服務）。 |
| **Deployment** | Pod 管理器 | 控制要啟動幾個 Pod、版本滾動更新等。 |
| **HPA** | Pod 數量調節器 | 根據負載自動改變 Deployment 的 replicas。 |
| **Cluster Autoscaler (CA)** | Node 管理器 | 當 Node 資源不足時，自動新增 EC2。 |

<br>

### 實際架構範例

**3 台 Node = 3 台 EC2**

每台 EC2 上可能同時跑 10～30 個 Pod（依你設定的 CPU/Memory Request 而定）

<br>

**資源分布示意圖**：
```
EC2-1 (Node-1)          EC2-2 (Node-2)          EC2-3 (Node-3)
├── Pod: Web API        ├── Pod: Worker         ├── Pod: Database
├── Pod: Cache          ├── Pod: Queue          ├── Pod: Monitor  
├── Pod: Logger         ├── Pod: Scheduler      ├── Pod: Backup
└── ... (共 15 個 Pod)   └── ... (共 12 個 Pod)   └── ... (共 18 個 Pod)
```

<br>

---

## 23. 📊 CPU 使用率分析

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