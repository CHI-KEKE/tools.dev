# 🏗️ NYP Pipeline 專案檔案結構說明

> 說明 nine1 gitlab pipeline 如何透過「慣例即設定」決定 build / deploy 所需的檔案位置。

## 📖 目錄

1. [核心概念：FQDN 是一切的基礎](#1-核心概念fqdn-是一切的基礎)
2. [完整目錄結構](#2-完整目錄結構)
3. [各檔案說明](#3-各檔案說明)
4. [Pipeline 執行流程](#4-pipeline-執行流程)
5. [關鍵命名規則速查](#5-關鍵命名規則速查)
6. [新專案建立 Checklist](#6-新專案建立-checklist)

<br>

---

## 1. 核心概念：FQDN 是一切的基礎

Pipeline **不讓你手寫複雜的 CI script**，而是說：

> 「只要你的 repo **照這個格式放檔案**，我就知道怎麼幫你 build / deploy。」

一切的核心就是 **`NYS_FQDN`**（服務識別名稱），在 `.gitlab-ci.yml` 中設定，所有資料夾都圍繞著它命名。

```yaml
# .gitlab-ci.yml
variables:
  GLCI__NYS_FQDN: "NineYi.Ai.CodeReview.Api"   # ← 這個值決定所有資料夾名稱
  GLCI__NYS_MODULE: "Web"
```

<br>

---

## 2. 完整目錄結構

```
your-repo/
│
├── .gitlab-ci.yml                         ← 宣告 FQDN、pipeline 版本
├── Dockerfile                             ← Pipeline 會傳 FQDN、Port 等參數進來
│
├── pipeline/                              ← 🔨 「怎麼 Build」的設定區
│   ├── build-config.sh                    ← 全域設定：.NET 版本、Port、image 來源
│   └── {NYS_FQDN}/                        ← 資料夾名稱 = FQDN（固定規則）
│       ├── env/
│       │   └── local.env                  ← 本機環境變數（先放空的）
│       ├── secret/
│       │   └── local.skv                  ← 本機 secrets（先放空的）
│       ├── sim/
│       │   └── local.sim.json             ← 本機模擬設定
│       ├── templates/
│       │   └── EMPTY                      ← NYP 工具要求此資料夾存在
│       └── workflow/
│           └── EMPTY                      ← NYP 工具要求此資料夾存在
│
├── src/
│   └── {NYS_FQDN}/                        ← 主程式資料夾（名稱也是 FQDN）
│       ├── .manifest/
│       │   ├── releng.json                ← 版號資訊（pipeline build 版本號用）
│       │   └── sdm.json                   ← 服務識別資訊（ServiceId、DisplayName）
│       └── {NYS_FQDN}.csproj
│   └── {NYS_FQDN}.sln                     ← SLN 命名需與 FQDN 一致（Dockerfile 用）
│
├── charts/
│   └── {release-name}/                    ← Helm chart values（K8s 部署設定）
│       ├── values-tw-qa.yaml
│       └── values-tw-prod.yaml
│
├── nine1-devops-deployments.QA.json       ← 「部署到哪個 QA 環境」的定義
└── nine1-devops-deployments.Prod.json     ← 「部署到哪個 Prod 環境」的定義（無 Prod 可省略）
```

<br>

---

## 3. 各檔案說明

### `pipeline/build-config.sh`

NYP build 工具啟動時第一個讀的設定檔。

```bash
DOTNET_BUILD_BASE_IMAGE="docker.build.91app.io/91app/dotnet-sdk-base:8"
DOTNET_RUNTIME_BASE_IMAGE="mcr.microsoft.com/dotnet/aspnet:8.0"
NYS_BUILD_DOCKERFILE="Dockerfile"
NYS_ENVNAME_PREFIX="MYSERVICE_"
NYS_DOCKER_EXPORT_PORT="8080"    # 對應 charts values 的 servicePort
```

<br>

### `pipeline/{FQDN}/sim/local.sim.json`

本機模擬環境的識別資訊。

```json
{
    "InstanceId": "nine1-my-service",
    "Market": "Local",
    "DataCenter": "ny-tpe-1",
    "InitialDate": "2025/01/01",
    "ContactEmail": "rd5@91app.com"
}
```

<br>

### `src/{FQDN}/.manifest/releng.json`

服務的版號資訊。**若 pipeline 的 `version:prepare` 正常運作則此檔只是備用**，但 NYP 工具可能會檢查它是否存在。

```json
{
    "Versioning": "1.0.0",
    "BuildType": "dev",
    "BuildId": "{signed in build time}",
    "HashCode": "{signed in build time}"
}
```

<br>

### `src/{FQDN}/.manifest/sdm.json`

服務的識別資訊。`ServiceId` 會對應到 Docker image 名稱。

```json
{
    "ServiceId": "nine1-my-service-api",     // = image name
    "DisplayName": "my-service-api",
    "FQDN": "NineYi.My.Service.Api",         // 必須與 GLCI__NYS_FQDN 一致
    "InitialDate": "2025/01/01",
    "ContactEmail": "rd5@91app.com"
}
```

<br>

### `nine1-devops-deployments.QA.json`

Pipeline 讀這個檔案來知道要部署到哪個 K8s namespace。

```json
{
    "apiVersion": "nine1-devops/v1",
    "kind": "deployment",
    "metadata": {
        "name": "MyService",
        "serviceName": "MyService",
        "type": "HelmChart"
    },
    "spec": {
        "deployments": [
            {
                "metadata": { "name": "tw-qa", "market": "TW", "env": "QA" },
                "settings": {
                    "NAMESPACE": "qa-my-service",
                    "KUBE_CONFIG_ENV_NAME": "KUBE_CONFIG_TW_QA",
                    "HELM_VALUES_FILE_NAME": "values-tw-qa",
                    "IS_DRY_RUN": "false",
                    "IS_MANUAL_DEPLOY": "true"
                },
                "roles": [{
                    "name": "Web.Api",
                    "APP_ROLE": "api",
                    "RELEASE_NAME": "my-service-api",
                    "versions": { "app": "latest", "config": "latest", "secret": "v1.0.0" }
                }]
            }
        ]
    }
}
```

<br>

---

## 4. Pipeline 執行流程

```
git push master
      │
      ▼
① version:prepare
      產生版號：LATEST-p202604221417-abc1234
      │
      ▼
② dev:build
      下載 NYP 工具（from Nexus）
      讀 pipeline/build-config.sh → 知道用什麼 image、Port
      docker build（把版號、FQDN、Port 傳入 Dockerfile）
      push image 到 docker registry
      │
      ▼
③ dev:prepare-deploy
      讀 nine1-devops-deployments.QA.json
      → 知道要部署到哪個 namespace、用哪個 values 檔
      → 動態產生 helm deploy yaml
      │
      ▼
④ dev:trigger-deploy
      helm upgrade --install
      → image 部署到 K8s
```

**Branch 觸發規則：**

| Branch 格式 | 觸發流程 |
|-------------|----------|
| `master` | build → 部署到 QA |
| `dev-YYYYMMDD` | build → 部署到 QA |
| `feature/QA3` | build → 部署到 QA3（對應 deployments.QA.json 中 env: QA3） |
| `release/YYYYMMDD` | build → 部署到 Prod（需有 deployments.Prod.json） |

<br>

---

## 5. 關鍵命名規則速查

| 位置 | 規則 | 範例 |
|------|------|------|
| `.gitlab-ci.yml` `GLCI__NYS_FQDN` | 與 csproj 名稱一致 | `NineYi.Ai.CodeReview.Api` |
| `pipeline/{FQDN}/` | 資料夾名稱 = FQDN | `pipeline/NineYi.Ai.CodeReview.Api/` |
| `src/{FQDN}.sln` | SLN 檔名 = FQDN（Dockerfile 用 `${NYS_FQDN}.sln` 找） | `src/NineYi.Ai.CodeReview.Api.sln` |
| `src/{FQDN}/.manifest/` | 資料夾名稱 = FQDN | `src/NineYi.Ai.CodeReview.Api/.manifest/` |
| `charts/{release-name}/` | release name = Helm release 名稱（不可含 `.`） | `charts/ai-codereview-api/` |
| `sdm.json` `ServiceId` | 對應 Docker image 名稱（kebab-case） | `nine1-ai-codereview-api` |

<br>

---

## 6. 新專案建立 Checklist

### 🔧 必要檔案

- [ ] `.gitlab-ci.yml` — 設定 `GLCI__NYS_FQDN`、`GLCI__NYS_MODULE`
- [ ] `Dockerfile` — 使用 `${NYS_FQDN}`、`${NYS_PORT}` 參數
- [ ] `pipeline/build-config.sh` — .NET 版本、Port
- [ ] `pipeline/{FQDN}/env/local.env` — 空檔
- [ ] `pipeline/{FQDN}/secret/local.skv` — 空檔
- [ ] `pipeline/{FQDN}/sim/local.sim.json` — 本機識別資訊
- [ ] `pipeline/{FQDN}/templates/EMPTY` — 空檔
- [ ] `pipeline/{FQDN}/workflow/EMPTY` — 空檔
- [ ] `src/{FQDN}.sln` — SLN 命名需與 FQDN 一致
- [ ] `src/{FQDN}/.manifest/releng.json`
- [ ] `src/{FQDN}/.manifest/sdm.json`
- [ ] `charts/{release-name}/values-tw-qa.yaml`
- [ ] `nine1-devops-deployments.QA.json`
- [ ] `.n1spec.yaml` — 內容為 `version: v1beta`

### 📋 設定對齊檢查

- [ ] `GLCI__NYS_FQDN` = `sdm.json` 的 `FQDN` = `pipeline/` 和 `src/` 的資料夾名稱 = `.sln` 檔名
- [ ] `charts/` 資料夾名稱 = `deployments.json` 的 `RELEASE_NAME`（不可含 `.`）
- [ ] `build-config.sh` 的 `NYS_DOCKER_EXPORT_PORT` = `charts values` 的 `servicePort`
- [ ] `build-config.sh` 的 `DOTNET_BUILD_BASE_IMAGE` 使用 91app proxy（`docker.build.91app.io/...`）
- [ ] GitLab branch `master`、`release/*` 設為 Protected（否則吃不到 KUBE_CONFIG）

<br>

---

## 參考資料

- 官方使用說明：`C:\91APP\Deploy\nine1.devops.gitlab\nine1 gitlab pipeline (phase 1.5) 使用說明.md`
- DevOps Pipeline Repo：`C:\91APP\Deploy\nine1.devops.gitlab`
- 範例專案（購物車）：`C:\91APP\Cart\cart2\nine1.cart`
- 範例專案（AI CodeReview）：`C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review.V2`
