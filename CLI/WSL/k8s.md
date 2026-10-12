
## k3d



wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash



## kubectl

sudo snap install kubectl --classic


sudo        → 用管理員權限執行
snap        → 套件管理工具
install     → 安裝
kubectl     → 要安裝的軟體
--classic   → 給這個程式較傳統、較寬鬆的系統存取權限


Windows        winget install ...
Ubuntu/Debian  apt install ...
Ubuntu Snap    snap install ...
Node.js        npm install ...
.NET           dotnet tool install ...


kubectl version --client


k3d version


## 建立 cluster


k3d cluster create mycluster




ERRO[0000] Failed to get nodes for cluster 'mycluster': docker failed to get containers with labels 'map[k3d.cluster:mycluster]': failed to list containers: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?


k3d
 │
 │ 想叫 Docker 建 Container
 ▼
Docker daemon
 ❌ 連不到



打開 docker desktop


成功執行 Create後會跑


k3d cluster create mycluster
           │
           ▼
      Docker Desktop
           │
      ┌────┴─────┐
      ▼          ▼
 Docker Network  Docker Volume
      │
      ▼
rancher/k3s Image
      │
      ▼
Docker Container
k3d-mycluster-server-0
      │
      ▼
   K3s Server
      │
      ▼
Kubernetes Cluster


執行完


k3d cluster list

mycluster
│
├── Server Node × 1   ✅
│
├── Agent Node  × 0
│
└── Load Balancer     ✅



Server 可以理解成這個 Kubernetes Cluster 的管理節點
1/1 預期有 1 個 Server，目前有 1 個正常運作。
AGENTS = 0/0 Agent 可以先理解成主要負責跑工作負載的 Worker Node


例如公司正式 Kubernetes Cluster 可能長這樣：

Kubernetes Cluster
│
├── Server / Control Plane
│      └── 管理整個 Cluster
│
├── Agent / Worker 1
│      ├── Pod
│      └── Pod
│
├── Agent / Worker 2
│      ├── Pod
│      └── Pod
│
└── Agent / Worker 3
       └── Pod


這不代表現在不能跑 Pod。單一 Server 本身也可以執行 workload，所以學習 Kubernetes 完全夠用


LOADBALANCER = true
k3d 還幫你建立了一個 Load Balancer。
它主要負責讓外部流量可以進入這個 k3d Cluster。




yoyo@LAPTOP-0174OQR8:~$ docker ps
CONTAINER ID   IMAGE                            COMMAND                  CREATED         STATUS         PORTS                             NAMES
555aac6f72b9   ghcr.io/k3d-io/k3d-proxy:5.9.0   "/bin/sh -c nginx-pr…"   6 minutes ago   Up 6 minutes   80/tcp, 0.0.0.0:39047->6443/tcp   k3d-mycluster-serverlb
62ec26537a7c   rancher/k3s:v1.35.5-k3s1         "/bin/k3d-entrypoint…"   7 minutes ago   Up 6 minutes                                     k3d-mycluster-server-0
yoyo@LAPTOP-0174OQR8:~$ kubectl get nodes
NAME                     STATUS   ROLES           AGE     VERSION
k3d-mycluster-server-0   Ready    control-plane   7m19s   v1.35.5+k3s1



Windows 11
│
└── Docker Desktop
     │
     ├── Container ①
     │   k3d-mycluster-serverlb
     │   Image: k3d-proxy
     │   用途：Load Balancer / Proxy
     │
     └── Container ②
         k3d-mycluster-server-0
         Image: rancher/k3s
              │
              │ 裡面跑 K3s
              ▼
        Kubernetes Node
        k3d-mycluster-server-0
              │
              └── control-plane


同一個名字出現在兩邊。原因是 k3d 使用 Docker Container 來模擬 Kubernetes Node。


因此站在 Docker 的角度：
它是一個 Container。

站在 Kubernetes 的角度：
它是一個 Node。

這也是 k3d 很重要的一個設計。



ROLES
control-plane

這個角色負責管理 Kubernetes Cluster。
例如之後你執行：
kubectl create deployment ...

大概會經過：
你
│
│ kubectl
▼
Kubernetes API Server
│
▼
Control Plane
│
│ 決定應該如何建立
▼
Scheduler
│
│ 決定 Pod 放哪個 Node
▼
Node
│
▼
Pod

你的 Cluster 現在只有一個 Node：
mycluster
│
└── k3d-mycluster-server-0
        │
        ├── Role: control-plane
        │
        └── 也可以跑 Pod

所以之後我們建立 Pod，它大概率就會跑在：
k3d-mycluster-server-0

v1.35.5+k3s1 又代表什麼？
VERSION
v1.35.5+k3s1

可以拆成：
v1.35.5
   ↑
Kubernetes 版本

+k3s1
   ↑
K3s 的 build/version 標記

這也跟你剛才 Docker image：
rancher/k3s:v1.35.5-k3s1



