




### 🏗️ 叢集建置與管理
- [2. 建一個可用、可活下去的 K8s 叢集](#2-建一個可用可活下去的-k8s-叢集)
- [3. 流量暴衝：自動擴 Pod、還要自動長機器](#3-流量暴衝自動擴-pod還要自動長機器)

### 🌐 網路與儲存整合
- [4. 網路與對外服務：VPC、LB、Storage 一條龍](#4-網路與對外服務vpclbstorage-一條龍)

### 🔒 安全與權限
- [5. 安全與權限：從「節點大權」到「Pod 最小權限」](#5-安全與權限從節點大權到pod-最小權限)

### ⬆️ 維運與升級
- [6. 升級與相容性：活著把版本升上去](#6-升級與相容性活著把版本升上去)

### 🎯 選擇建議
- [7. 什麼時候一定要選 EKS？](#7-什麼時候一定要選-eks)

<br>

## 2. 建一個可用、可活下去的 K8s 叢集

情境：新專案要上 K8s，CI/CD 會 kubectl apply 部署 WebAPI。

| 項目   | 沒有 EKS（自建 K8s）                                                                                           | 有 EKS（受管）                                               |
| ---- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| 控制平面 | 你自己準備 3～5 台 VM/EC2 架 **HA 控制平面**（kube-apiserver、etcd、scheduler、controller-manager），要做 etcd 備份、憑證輪替、節點健檢。 | **AWS 托管整個控制平面**（多 AZ 高可用、內建備援），你不碰 etcd、不修 API Server。 |
| 開工時間 | 幾天～幾週（架設、硬化、安全掃描、HA 測試）                                                                                  | 幾十分鐘建好 EKS Cluster + Node Group；直接收 `kubectl`。          |
| 維運風險 | 任一控制平面元件出事 → 你收攤、自己排故。                                                                                   | 控制平面出事是 AWS 的事；你專心在應用與資料面。                              |


## 3. 流量暴衝：自動擴 Pod、還要自動長機器

情境：週年慶流量暴增，HPA 想把副本數從 3 擴到 20，但現有節點不夠放

| 項目          | 沒有 EKS                                                         | 有 EKS                                                                                |
| ----------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Pod 擴張（HPA） | 你得先安裝/維護 Metrics Server、校正 API 權限與資源型別；HPA 才會動。                | 同樣要裝 Metrics Server，但大多數文件與整合是 **EKS 官方範式**，踩雷少很多。                                   |
| 機器擴張（CA）    | 你要自己佈署 **Cluster Autoscaler**，對接雲商 API、權限、ASG/實體機群；版本升級自己顧。    | **EKS + Managed Node Group + CA** 幾乎「貼合使用手冊」：標籤/權限/事件全是既有範本，還能直接用 **Fargate** 無機器擴容。 |
| 缺機器時的表現     | HPA 想長，但沒節點；Pod 卡 Pending，你要自己看 CA 為何不長機器（API 權限/ASG 配額/子網容量）。 | EKS 常見場景的 CA 錯誤訊息都有現成 SOP；**MNG/Fargate** 減少一堆 IaaS 細節。                              |


EKS 把「Pod 擴容 ↔ 節點擴容 ↔ 雲資源權限」三件難事對齊了，節省大量踩雲 API 的時間

## 4. 網路與對外服務：VPC、LB、Storage 一條龍

情境：你要讓 Service 對外（ALB/NLB），要用 EBS/EFS 當 Persistent Volume，還要控流與安全組。

| 項目            | 沒有 EKS                                                                      | 有 EKS                                                                      |
| ------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| CNI（Pod 網路）   | 自己挑/裝 CNI（Calico/Flannel/Cilium），路由、IPAM、SNAT、安控規則都要測。                      | **EKS VPC CNI** 原生打通 VPC，支援 **Security Group for Pods**；在 AWS 網路世界裡「水到渠成」。 |
| Load Balancer | 自己安裝維護 **Ingress Controller / LB Controller**，跟雲商 API 對齊；常被 annotation 版本坑。 | **AWS Load Balancer Controller** 是官方路線，ALB/NLB 行為與註解都標準化，升級路徑清楚。           |
| 儲存            | 自己裝/維護各種 CSI Driver（EBS/EFS/FSx），權限與回收策略自己顧。                                | 官方 **EBS/EFS CSI** 驅動、IRSA 權限模板都有；**StorageClass** 一鍵用。                    |


EKS 把「K8s ↔ AWS 生態」做了原生整合，少量 YAML 就能用到雲端該有的東西。

## 5. 安全與權限：從「節點大權」到「Pod 最小權限」

某個微服務需要讀 S3、寫 SQS；你不想把整機的 EC2 Role 開很大

| 項目          | 沒有 EKS                                                         | 有 EKS                                                                                           |
| ----------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Pod 權限（雲資源） | 通常把 **Node 的 IAM Role** 開很大（所有 Pod 共用），或自己架 Vault/STS 代理，流程複雜。 | 用 **IRSA（IAM Roles for Service Accounts）**：一個 ServiceAccount 對應一個 IAM Role，精準到「這個 Deployment 」。 |
| 叢集身分        | OIDC provider、JWT 驗證、STS 鏈結都要自己串、自己測。                          | EKS 幫你把 OIDC 與叢集對齊；IRSA 文件、Policy 範例一把抓。                                                        |
| 合規與稽核       | 事件、權限分離、雙因子等都要自己設。                                             | IAM 生態＋CloudTrail/GuardDuty/SCP 可直接吃到；**EKS Blueprints** 可落地治理。                                 |

EKS 讓「最小權限到 Pod 粒度」變得自然、可維護，資安/審計都比較站得住腳


## 6. 升級與相容性：活著把版本升上去

Kubernetes 版本汰換（API Deprecation）、安全修補、kubelet/kube-proxy 更新

| 項目     | 沒有 EKS                                     | 有 EKS                                                   |
| ------ | ------------------------------------------ | ------------------------------------------------------- |
| 控制平面升級 | 你自己排：etcd 備份、控制平面逐台升、相容性驗證、回滾路徑；任何一步失手=停擺。 | **EKS 控制平面點選升級**，多 AZ 滾升；你只要管理 **節點版升**（MNG 滾動替換），服務照跑。 |
| 相容性矩陣  | API 相容、CNI/CSI 版本地獄你自己查。                   | EKS 公布對應矩陣與建議路徑；常見控制器（ALB/EBS/EFS/CloudWatch）都跟著官方步調走。  |
| 變更風險   | 你是 SRE＋DBA＋網工＋雲管家                          | 你比較像 **平台工程師**：把重心放在「應用可靠性」而不是「把 etcd 救活」。              |

EKS 把「升級這檔高風險工程」拆成 你控資料面、AWS控控制平面，顯著降低停機與人為失誤風險



## 7. 什麼時候一定要選 EKS？

- 雲原生整合（ALB、EBS/EFS、S3/SQS/SNS、IAM）而且不想每樣都自己對雲 API
- 可預期的升級路徑 與 長期維護（不是玩票性質的 K8s）
- 把權限縮到 Pod 等級（IRSA），以符合資安與合規
- HPA＋Cluster Autoscaler＋（選配）Fargate 的平滑彈性，應對活動/檔期

你的人力要專注在業務功能與 SLO，而不是救控制平面與修 CNI/CSI

# 🚀 Kubernetes 概念指南

<br>

## 📖 目錄

### 📚 歷史演進
- [1. Before K8s 的世界：服務 = 機器](#1-before-k8s-的世界服務--機器)
- [2. Auto Scaling Group (ASG) 是怎麼幫你「自動」擴容的](#2-auto-scaling-group-asg-是怎麼幫你自動擴容的)
- [3. 這樣的 Auto Scaling 有幾個問題（為什麼後來要有 K8s）](#3-這樣的-auto-scaling-有幾個問題為什麼後來要有-k8s)

### 🔄 技術轉變
- [4. Kubernetes 出現後，世界改變了什麼](#4-kubernetes-出現後世界改變了什麼)
- [5. 問題的起點：服務越來越多，機器越來越亂](#5-問題的起點服務越來越多機器越來越亂)
- [6. 容器化解決「可攜性」問題，但留下「協調」問題](#6-容器化解決可攜性問題但留下協調問題)

### 🎯 核心概念
- [7. Kubernetes 是什麼？](#7-kubernetes-是什麼)
- [8. Kubernetes Cluster](#8-kubernetes-cluster)
- [9. 沒有 EKS vs 有 EKS 的對比：誰在管 Cluster？](#9-沒有-eks-vs-有-eks-的對比誰在管-cluster)

<br>

---

## 1. Before K8s 的世界：服務 = 機器

在 Kubernetes 出現之前（約 2010–2015 年這段雲轉型初期），應用的部署邏輯幾乎是這樣的：

| 元件                | 角色                                    |
| ----------------- | ------------------------------------- |
| EC2 / VM          | 實體運行環境                                |
| OS（Ubuntu、CentOS） | 安裝應用與依賴                               |
| App               | 跑在該台機器上，例如 .NET WebAPI、Node.js、Java 等 |

💡 所謂「擴容」就是多開幾台機器（EC2）去跑同一個 App


原本只有一台 EC2 跑 WebAPI，當流量變高時，就多開兩台 EC2，各跑一份 WebAPI，然後用 Elastic Load Balancer (ELB) 分流

```plaintext
Client → ELB → EC2 #1 / EC2 #2 / EC2 #3
```
這是「擴容（Scaling Out）」的原始樣貌

## 2. Auto Scaling Group (ASG) 是怎麼幫你「自動」擴容的

在 AWS 上，我們會設定一個 Auto Scaling Group (ASG)

```plaintext
MinSize = 1
DesiredCapacity = 2
MaxSize = 5
ScalingPolicy: 當 CPU > 70% 時，多開 1 台 EC2
```

- 監控 CloudWatch 指標（CPU、RequestCount 等）
- 達到條件就新增一台 EC2（由 Launch Template 建立）
- 新的 EC2 啟動後，自動掛進 ELB Target Group，開始分攤流量
- 當流量降低時，ASG 會縮容（Terminate 多餘的 EC2）

所以，每多開一份服務 → 會多開一個完整 EC2，這台 EC2 有獨立 OS、記憶體、CPU、開機流程，開一台平均要幾十秒到幾分鐘，也就是說，每一個「Pod」等價於一整台虛擬機。（這在現代 Container 世界看起來非常浪費）


## 3. 這樣的 Auto Scaling 有幾個問題（為什麼後來要有 K8s）

| 問題       | 說明                               |
| -------- | -------------------------------- |
| ⏱️ 開機慢   | EC2 啟動、OS 開機、App 啟動要 1–2 分鐘以上    |
| 💰 資源浪費  | 一台機器跑一個 App，但 CPU 只用 30%，浪費      |
| 🧩 環境不一致 | 每台機器都要裝相同版本的 Runtime、Lib         |
| ⚙️ 難部署   | 新版本要一台台更新、重啟、驗證                  |
| 🧯 難修復   | 某台 EC2 掛了，ASG 會補一台，但應用要重新安裝、啟動   |
| 🔐 權限管理  | 每台 EC2 都要配置 IAM、SecurityGroup、憑證 |


Auto Scaling 解決了「數量」的自動化，但沒解決「部署、環境一致性、資源利用率」這些痛點


## 4. Kubernetes 出現後，世界改變了什麼

Kubernetes 把「擴容」的單位從「EC2」變成了「Pod」

| 對比項目  | Before K8s（Auto Scaling） | K8s 時代（Horizontal Pod Autoscaler） |
| ----- | ------------------------ | --------------------------------- |
| 擴容單位  | 一整台 EC2                  | 一個 Container（Pod）                 |
| 啟動時間  | 幾十秒～幾分鐘                  | 幾秒鐘                               |
| 資源利用  | 低（每台有 OS 開銷）             | 高（多個 Pod 共用 Node）                 |
| 部署環境  | OS + 手動配置                | Container + YAML                  |
| 環境一致性 | 可能不同步                    | 完全一致（Image 保證）                    |
| 網路    | ELB 對 EC2                | Service / Ingress 對 Pod           |
| 回收策略  | Terminate EC2            | 移除 Pod（秒級）                        |


以前 CPU 高 → 多開 EC2（每台跑 webapi.exe）
現在 CPU 高 → K8s 增加 Pod 數（每個 Pod 跑 webapi container）

EKS（AWS 托管 K8s）則讓 Pod 多到放不下時 → 自動多開 EC2 Node

這樣就形成

- EC2 = 運算資源池
- Pod = 你的應用實例
- EKS = 幫你協調兩者的橋樑

| 項目    | 傳統（Before K8s）     | 容器時代（K8s / EKS）                                |
| ----- | ------------------ | ---------------------------------------------- |
| 擴容對象  | EC2 機器             | Pod（容器）                                        |
| 自動化機制 | Auto Scaling Group | Horizontal Pod Autoscaler + Cluster Autoscaler |
| 啟動時間  | 幾分鐘                | 幾秒                                             |
| 部署方式  | AMI / Script       | Container Image + YAML                         |
| 一致性   | 易出錯（手動設定）          | 完全一致（Image 保證）                                 |
| 成本效率  | 高浪費（空跑機器）          | 高利用率（共用 Node 資源）                               |
| 維運成本  | 高：要顧機器、版本、憑證       | 低：EKS 托管控制平面                                   |

Before K8s，「擴容」代表開更多機器（EC2），有了 K8s 之後，「擴容」代表多開幾個 Container（Pod）。

- Auto Scaling Group 幫你多開 EC2
- Kubernetes 幫你多開容器
- EKS 幫你在 AWS 裡同時自動管理兩層（EC2 + Pod）


## 5. 問題的起點：服務越來越多，機器越來越亂

🧱 傳統時代（Before K8s）

以前我們部署應用的方式就是每個服務跑在一台機器上（例如 EC2）。想擴容就多開機器，多跑一份程式，問題是：

- 機器資源利用率低 — 一台 EC2 跑一個服務，常常 CPU 只用 20%，浪費錢。
- 部署麻煩 — 要自己設定環境、依賴、版本。
- 擴展難 — 服務變多時，要人工決定哪台機器跑什麼。
- 維運不穩定 — 某台機器掛了，服務就消失。

於是工程師開始用 Docker 打包應用（Container），讓「程式 + 執行環境」可以跨機器跑


## 6. 容器化解決「可攜性」問題，但留下「協調」問題

Docker 讓一個應用可以快速啟動、隨處執行，但新的問題出現

- 有上百個容器要啟動，你要放哪裡？
- 有的容器掛了，誰重啟？
- 哪個容器該接流量？該擴幾個？
- 哪些機器資源夠？哪些不夠？

這就是**容器編排（Container Orchestration）**的需求。Kubernetes 就是為了解決這個問題誕生的!


## 7. Kubernetes 是什麼？

Kubernetes = 一個自動幫你管理容器的系統

它的核心職責包含

- 調度：決定容器該跑在哪台機器上。
- 監控：持續確認容器是否健康。
- 自癒：容器掛掉自動重建。
- 擴展：根據負載自動加減容器數量。
- 抽象：用 Deployment / Service / Ingress 定義整個應用架構。

簡單說，它是一個「會自動維持理想狀態的機器群控制系統」


## 8. Kubernetes Cluster

Kubernetes Cluster（叢集） = 一整群被 Kubernetes 管理的機器（Node） + 那群「管理它們的控制系統（Control Plane）」

| 區塊                   | 說明                  | 舉例                                   |
| -------------------- | ------------------- | ------------------------------------ |
| 🧠 **Control Plane** | 負責管理與調度所有機器與容器的「大腦」 | API Server、etcd、Scheduler、Controller |
| 💪 **Worker Nodes**  | 實際執行容器的「手腳」         | EC2、VM、實體伺服器                         |


這整個組合（Control Plane + 多台 Worker Node）= Cluster。Kubernetes 這個軟體，必須「安裝在 Cluster 裡」才有意義!

## 9. 沒有 EKS vs 有 EKS 的對比：誰在管 Cluster？

| 類型        | 誰負責建立與維護 Cluster                    |
| --------- | ----------------------------------- |
| ❌ 自建 K8s  | 你：自己架 Control Plane、etcd、Node、憑證、升級 |
| ✅ AWS EKS | AWS：幫你托管整個 Control Plane，你只要準備 Node |


「有 EKS 時，你用的是 Kubernetes，但你不再需要自己養那個 Kubernetes。」


Kubernetes 的哲學是：「不要直接面對機器」

以前我們思考，我要在哪台 EC2 上跑，現在 Kubernetes 幫你抽象化成：

> 我希望這個服務有 3 個副本、永遠健康

你不再關心「在哪一台機器」，而是由「叢集的控制平面」去幫你分配

這就是「Cluster」存在的意義，讓你不再跟單台機器打交道，而是與整個「運算資源池」對話

假設 YAML 裡寫

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapi
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: webapi
        image: 91app/webapi:1.0
```

整個流程是

- 你對「叢集」發出請求：「幫我跑 3 個 webapi 容器。」
- Control Plane 收到後：看目前哪些 Node 有空，派 3 個 Pod 到不同 Node
- 監控它們是否健康，你只關心 Deployment 狀態，而不用管 Node IP 或容器啟動順序

這就是 Kubernetes 與 Kubernetes Cluster 的「分工與存在理由」


| 名稱                     | 意義                     | 為什麼存在                |
| ---------------------- | ---------------------- | -------------------- |
| **Kubernetes（K8s）**    | 一套管理與協調容器的系統           | 解決容器太多、部署難、維運亂的問題    |
| **Kubernetes Cluster** | 一整組由 K8s 管理的機器群（含控制平面） | 提供讓 K8s 能實際運作的環境與資源池 |


K8s 是「管理邏輯」；Cluster 是「承載現實」!

