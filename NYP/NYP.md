# 🚀## 📖 目錄

  - [☸️ EKS 容器服務](#️-eks-容器服務)
  - [🔧 Kubernetes 三個基本角色](#-kubernetes-三個基本角色)
  - [📋 EKS 資源申請流程](#-eks-資源申請流程)
  - [🚀 GitLab-CI 專案前置作業](#-gitlab-ci-專案前置作業)
  - [❤️ Liveness Probe 存活檢查](#️-liveness-probe-存活檢查)
  - [✅ Readiness Probe 就緒檢查](#-readiness-probe-就緒檢查)
  - [📁 Deployments 內部檔案查看](#-deployments-內部檔案查看)
  - [⚙️ 建置專案時的配置](#️-建置專案時的配置)
  - [📈 HPA 水平自動擴展](#-hpa-水平自動擴展)
  - [⚖️ Scale 手動擴展](#️-scale-手動擴展)
  - [🔐 IRSA 服務帳戶角色關聯](#-irsa-服務帳戶角色關聯)
  - [📚 NYP 文件](#-nyp-文件)
  - [🌍 Translation 服務調整紀錄](#-translation-服務調整紀錄)
  - [🏷️ TAG_ID 標籤管理](#️-tag_id-標籤管理)
  - [📊 Log 查看](#-log-查看)
  - [🌐 Ingress 網路入口](#-ingress-網路入口)
  - [🔍 如何查看部署版本](#-如何查看部署版本)
  - [❌ Pipeline 錯誤處理紀錄](#-pipeline-錯誤處理紀錄)維護文件

<br>

---

## ☸️ EKS 容器服務

Amazon EKS (Elastic Kubernetes Service) 是 AWS 提供的一種托管 Kubernetes 服務，讓你可以更輕鬆地在 AWS 上部署、管理和擴展容器化應用程式。

<br>

CI/CD 是持續整合（Continuous Integration）與持續部署/交付（Continuous Deployment/Delivery）的流程。而 EKS 在這個流程中的角色是：

<br>

| 階段 | 說明 | EKS 的角色 |
|------|------|-----------|
| CI（持續整合） | 專案程式碼 push 到 GitHub/GitLab 後自動觸發建置與測試流程 | 無直接關係，但會用於之後部署 |
| CD（持續部署） | 成功建置後自動部署到實際的執行環境 | ✅ 通常部署的目標就是 EKS！ |
| 執行環境 | 提供穩定、高可用的容器環境 | ✅ EKS 上會跑你打包好的 Docker 映像（如 Web API、後台服務等） |

<br>

### 部署流程

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

CI/CD 是建築流程與機具（自動化蓋房子）

<br>

EKS 是蓋好的基地（地皮 + 建好骨架），負責放你要蓋的房子（容器）

<br>

---

## 🔧 Kubernetes 三個基本角色

### 1. Node（節點 / 工作者）🖥️

可以是一台實體機器（例如你自己的伺服器）或是雲端的虛擬機器（例如 AWS EC2）。

<br>

每個 Node 都是 Kubernetes 的「工人」，負責執行應用程式。

<br>

有時也叫作 Minion（奴隸），因為它聽從主控 Master（Control Plane）的指令。

<br>

**🔧 功能**：
- 幫忙執行 Pod（容器群）
- 管理 CPU、記憶體等資源
- 提供網路、磁碟空間

<br>

### 2. Pod（膠囊 / 容器群）📦

是 Kubernetes 中「最小的可部署單位」。

<br>

一個 Pod 裡面可以裝一個或多個 Container（但大部分情況是一個）。

<br>

**🧠 為什麼需要 Pod？**

因為直接用 Container（容器）太難管理網路，K8S 幫你用 Pod 把容器「包裝起來」變成一個整體。

<br>

Docker 會幫這個 container 分配一個獨立 IP，每個 container 都在自己的網路空間中運作（network namespace）。

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

通常用 Docker 建立容器映像（image），再部署到 Pod 中。

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

---

## 📋 EKS 資源申請流程

### 為專案申請 EKS + Monitoring + KP ServiceAccount 基本權限資源做法

**開申請單**：https://teamroom.91app.biz/issues/23598


強調須建立 NKP ServiceAccount 基本權限

經確認 Translation 在 NKP IRSA 不與 AKSK 的權限相同，調整如下:

僅需要 NY-QA-S3-TranslationService CRUD 權限
不需要 NY-TW-Deny-Not-In-VPC-NAT-TPE-Office-IP


<br>

### 申請將 kubeconfig 設置於 Gitlab Group Variables

**開申請單**：https://teamroom.91app.biz/issues/22565

<br>

<br>

### IAM Role 要有存 secret 的權限

**開申請單**：https://teamroom.91app.biz/issues/24100

<br>

---

## 🚀 GitLab-CI 專案前置作業

### 開新的 GitLab-CI 專案的前置動作

**步驟 1**：BaseSDK 安裝

<br>

**步驟 2**：安裝 N1 CLI

參考文件：http://www.91dev.tw/nineyi.general/v1beta/dev-guide/n1cli/quickstart/

<br>

---

## ❤️ Liveness Probe 存活檢查

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

**📍Readiness Probe 幫你**：

「我還沒準備好喔！先不要把請求導過來」

<br>

**當 Readiness 檢查失敗**：
- K8S 不會把流量導向這個 Pod
- 但不會重啟它（因為它還活著，只是還沒準備好）

<br>

**範例**：yaml 的 secret 節點設定格式有誤

<br>

---

## 📁 Deployments 內部檔案查看

### 如何查看 Deployments 的內部檔案

**路徑**：Deployments > Execute Shell

<br>

**舉例**：查看多語系資訊

```bash
cat ./i18n/Nine1.Cart/backend.entity.cart_processor.shopping_cart_client_pay_type_entity/zh-TW.json
```

<br>

**舉例**：查看配置

```bash
cd config
cat settings.json
```

<br>

**舉例**：測試網路連線與環境變數

```bash
# 打 curl 看連得到外網嗎
curl -I https://www.google.com

# 打 db 連線測試
curl -I your-database-endpoint

# 讀取環境變數
env | grep YOUR_VAR_NAME
```

<br>

---

## ⚙️ 建置專案時的配置

### 1. UI

#### 1.1 需設定 branch 為 protected 才能正常跑 pipeline, 否則可能佈署會吃不到KUBE_CONFIG

**路徑**：settings > repository > protected

<br>

#### 1.2 KUBE_CONFIG_ENV_NAME 設定正確

<br>

### 2. gitlab-ci.yml 設定

#### 2.1 pipeline 版本升級為最新版

<br>

#### 2.2 GLCI__NYS_FQDN 要對齊 sdm.json

**範例**：C:\91APP\Cart\nine1.cart\src\Web\Nine1.Cart.Web.Api\.manifest\sdm.json

<br>

| 設定項目 | 值 |
|----------|-----|
| GLCI__NYS_FQDN | Nine1.Cart.Web.Api |
| sdm.json | Nine1.Cart.Web.Api |

<br>

#### 2.3 RELEASE_NAME 不可以有 dot


RELEASE_NAME , ingressname  要正式一點

<br>

### 3. charts.yaml

#### 3.1 s3 存取 config 路徑需與實際 config 路徑對齊

暫時無須設為 `files: []`

<br>

secret 存取路徑需與實際 secretManager 路徑對齊，暫時無須設為 `files: []`

<br>

#### 3.2 路徑與 gitlanci.yaml Release Name 對齊

<br>

#### 3.3 - charts 下面一層的資料夾要跟 releasename 一樣但小寫

#### 3.4 repository 為 image 名稱

charts : repository: docker-dev.build.91app.io/91app/ny-payment-middleware
![alt text](./Img/image-7.png)

### 4. build-config.sh

#### 4.1 確認 Build BASE_IMAGE 版本是要是 91app proxy 的

**範例**：`docker.build.91app.io/91app/dotnet-sdk-base:8`

<br>

#### 4.2 確認 deploy BASE_IMAGE 版本是正確 aspnet 版本

<br>

### 5. 檔案結構 + DockerFile + deployments + FQDN 設定對齊

#### 5.1 CronJob

**deployments.json 的 APP_ROLE**：scheduler

<br>

**DockerFile**：
```dockerfile
WORKDIR /worker
COPY ./src/Nine1.Promotion.CreateTask .
```

<br>

#### 5.2 WebAPI

**deployments.json 的 APP_ROLE**：api

<br>

**DockerFile**：

Building：
```dockerfile
WORKDIR /src
COPY --from=buildTranslation ./src .
COPY ./workdir/${NYP_JOBNAME}/releng.json .
RUN cat ./releng.json
```

<br>

Deploy：
```dockerfile
WORKDIR /app
COPY --from=dotnet-build-env /out .
```

<br>

**檔案結構**：
```
./src/Web/{{FQDN}}/csproj
./src/sln
```

<br>

#### 5.3 Worker

**deployments.json 的 APP_ROLE**：worker

<br>

**DockerFile**：
```dockerfile
WORKDIR /worker
COPY --from=dotnet-build-env /app/out .
```

<br>

**檔案結構**：
```
./src/sln
```

<br>

#### 5.4 Console

**deployments.json 的 APP_ROLE**：scheduler

<br>

**DockerFile**：

Build：
```dockerfile
COPY ./Nine1.Payment.Middleware.ConsoleApp.sln ./
COPY ./src ./src
```

<br>

Deploy：
```dockerfile
WORKDIR /app
COPY --from=dotnet-build-env /out .
```

<br>

**檔案結構**：
```
./src/{{FQDB}}/csproj
sln
```

<br>

### 6. WebAPI 需在 ./src/Web/{{FQDN}}/.manifest 配置

**必要檔案**：
- releng.json
- sdm.json

<br>

### 7. .dockerignore

要加上：
- `**/settings.*.json`
- `**/secrets.*.json`

<br>

### 8. .gitignore

需配置

<br>

### 9. 專案內設定

可以先用 `launchsettings.json` 來設定依照環境變數執行程式

<br>

專案要配置 Health check endpoint 否則在 rancher 的 recent event 會看到：

```
Readiness probe failed: Get "http://10.50.231.179:50350/_hc": dial tcp 10.50.231.179:50350: connect: connection refused
```

<br>

### 10. releasename 及為 deployment 看到的 name

![alt text](./Img/image-8.png)

<br>

### 11. Schema.json 配置

填 `schema.json` 才會有節點 pipeline 長出來

<br>


---

## 📈 HPA 水平自動擴展

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

<br>

---

## ⚖️ Scale 手動擴展

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

---

## 🔐 IRSA 服務帳戶角色關聯

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

---

## 📚 NYP 文件

**官方文件連結**：https://www.infra.91dev.tw/nkp/

<br>

---

## 🌍 Translation 服務調整紀錄

### 調整內容

**1. 在 yaml 手動移除掉 v2 host 設定 (ingress 中)**

原因是 gitlab ci 沒有真正在使用 ingress yaml 佈署檔案

<br>

**2. Domain 導向設定**

目前 translation domain 有 v1 / v2 都導向相同服務

<br>

但目前只有在使用 v1 的服務，因此 V2 給新的架構使用

<br>

### 配置路徑

**Config 路徑**：
```
91app-ap-northeast-1-private-conf/TW-QA/Translation/API/LATEST-p-5ac80600/settings.TW-QA.json
```

<br>

**Secret 路徑**：
```
/TW-QA/Translation/API/secret
```

<br>

---

## 🏷️ TAG_ID 標籤管理

TAG_ID 是一個用來標記 Docker 映像（image）的『版本標籤』，通常用來唯一識別一個 build 出來的版本。

<br>

📦 每次包裝一個產品（映像檔），你都貼上一張獨一無二的標籤：這是什麼版本、什麼時候做的、出自哪個分支和 commit。

<br>

### TAG_ID 組成範例

```bash
TAG_ID=$(echo $CI_BUILD_REF_NAME | cut -d'/' -f 2)_\
$(cat package.json | jq -r '.version')_\
$(TZ=Asia/Taipei date '+%y%m%d%H%M')_\
$(echo $CI_BUILD_REF | cut -c 1-7)
```

<br>

**生成結果**：`feature-login_1.2.3_2507201012_ab12cd3`

<br>

### TAG_ID 各部分說明

| 部分 | 說明 |
|------|------|
| feature-login | 分支名稱（例如 feature/login，取 / 後面） |
| 1.2.3 | 專案版本（從 package.json 讀出 .version 欄位） |
| 2507201012 | 建構時間：2025年07月20日 10:12（Asia/Taipei 時區） |
| ab12cd3 | Git commit 的前 7 碼，用來追蹤是誰提交的 |

<br>

### ⚠️ 如果不使用 TAG_ID，會有什麼問題？

很多人習慣直接用：

```bash
docker tag my-app:latest
```

<br>

但這會造成：

- ⛔ 看不出來這是哪次 build 的
- ⛔ 不小心覆蓋掉別人的版本
- ⛔ 難以追蹤 bug 來源或復原版本

<br>

---

## 📊 Log 查看

### 1. Rancher Recent Event

可以在 rancher 的 recent event 看到服務為什麼啟動失敗

<br>

### 2. View Log

可以看到 app 已經起來了的詳細記錄

<br>

### 3. 本機連接 Event Log

可以在本機連 event log

<br>

---

## 🌐 Ingress 網路入口

Ingress 是一個資源物件，允許你定義如何將外部的 HTTP 和 HTTPS 流量導向到你的應用程式服務。

<br>

Ingress 提供了一個入口點，將外部的網路請求導向到你的應用程式中的不同服務。
![alt text](./Img/image-5.png)
<br>

### 比喻說明

想像你的 Kubernetes 集群是一個大型商場，裡面有很多家商店（你的應用程式服務）。每家商店都有自己的門口，但是商場入口卻只有一個。Ingress 就像是商場入口的大門警衛，負責引導和控制進出商場的人流。

<br>

---

## 🔍 如何查看部署版本

![alt text](./Img/NYP_version.png)

<br>

---

## ❌ Pipeline 錯誤處理紀錄

### 案例 1：docker auth config / am user / am password 相關權限錯誤

**解決步驟**：

<br>

1. 確認 protected branch 是否已設定，這樣才會去抓 auth config
![alt text](./Img/image-6.png)
<br>

2. 確認 variables 是否有正確設定相關權限參數

<br>

3. 向 [@zhongkuo](https://91app.slack.com/team/U05KFQBPD8E), [@kylechang](https://91app.slack.com/team/U07UPKU0GN6) 確認 ciuser 會 variables 是否正確設定

加 release/* Branch 當 Protected Branch

<br>

### 案例 2：SyncFromServiceBaseUrl 配置問題

**問題描述**：有些 controller 會掛掉讀到 v2 config 但打不通，因為 domain 被搬走了

https://91app.slack.com/archives/G04TVB3KW/p1746421134276869

<br>

**相關連結**：
- QA：https://gitlab.91app.com/translation/NineYi.Translation/-/merge_requests/270/diffs
- PP：https://gitlab.91app.com/translation/NineYi.Translation/-/merge_requests/269

<br>

**Exception 查詢**：[監控面板連結](https://monitoring-dashboard.91app.io/explore?schemaVersion=1&panes=%7B%22ih6%22:%7B%22datasource%22:%22ZIOlfD44k%22,%22queries%22:%5B%7B%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22ZIOlfD44k%22%7D,%22editorMode%22:%22code%22,%22expr%22:%22%7Bservice%3D%5C%22pp-translation%5C%22%7D%20%7C%3D%60Exception%60%22,%22maxLines%22:100,%22queryType%22:%22range%22,%22refId%22:%22A%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=2)

<br>

### 案例 3：GitLab CI 檔案命名問題

**問題描述**：`gitlabci.yaml.bk` 像這樣的其他檔案會導致 pipeline 死掉

<br>

### 案例 4：Image Pull 失敗

**問題描述**：Image pull 不到可能因為 servicename 沒有對應

<br>

### 案例 5：Deprecated Build CI 參數

**錯誤訊息**：
```
ERROR: Job failed: failed to pull image "docker-proxy.build.91app.io/alpine/git:v2.34.2" with specified policies [always]: Error response from daemon: Head "https://docker-proxy.build.91app.io/v2/alpine/git/manifests/v2.34.2": no basic auth credentials (manager.go:237:0s)
```

<br>

**解決方法**：

修正 Deprecated Build CI 參數

<br>

**範例**：

❌ **錯誤寫法**：
```bash
VER_SUFFIX=$(if [ "$(echo $CI_BUILD_REF_NAME | cut -d'/' -f 2)" = "master" ]; then echo ""; else echo "-dev"; fi)
```

<br>

✅ **正確寫法**：
```bash
VER_SUFFIX=$(if [ "$(echo $CI_COMMIT_REF_NAME | cut -d'/' -f 2)" = "master" ]; then echo ""; else echo "-dev"; fi)
```

<br>

**參考資料**：https://gitlab.com/gitlab-org/gitlab/-/issues/352957

<br>
