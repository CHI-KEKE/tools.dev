# NYP — FQDN & RELEASE_NAME 命名規則

> 適用：Nine1 NMQv3 Worker、Web API 專案

---

## FQDN（Fully Qualified Domain Name）

### 定義

FQDN 是 .NET 專案的**完整命名空間根**，也是 CI pipeline 用來定位建置目錄的唯一識別。

### 命名規則

| 樣板 | 格式 | 範例 |
|------|------|------|
| NMQv3 Worker | `Nine1.{Name}.Console.NMQv3Worker` | `Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker` |
| Web API | `Nine1.{Name}.Web.Api` | `Nine1.Order.Management.Web.Api` |

其中 `{Name}` 由輸入的 kebab-case 專案名稱轉換：
- `regularpurchase-v2-worker` → `Regularpurchase.V2.Worker`
- `order-management` → `Order.Management`

### 需對齊的位置

| 位置 | 欄位 | 範例值 |
|------|------|--------|
| `.gitlab-ci.yml` | `GLCI__NYS_FQDN` | `"Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker"` |
| `src/.manifest/sdm.json` | `FQDN` | `"Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker"` |
| `src/` 資料夾名稱 | 目錄名 | `Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker/` |
| `.sln` 內 project path | project 名稱 & 路徑 | `"Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker"` |
| `.csproj` 檔名 | 檔案名稱 | `Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker.csproj` |
| 所有 `.cs` 檔 | `namespace` | `namespace Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker;` |
| 所有 `.cs` 檔 | `using` | `using Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker.Job;` |
| `Dockerfile` | `ARG NYS_FQDN` / `WORKDIR` | build 時 cd 進 `/src/${NYS_FQDN}` |

---

## RELEASE_NAME

### 定義

RELEASE_NAME 是 **Helm release 的唯一識別名稱**，決定 K8s 中所有資源（Deployment、Service、HPA 等）的命名。

### 命名規則（從 FQDN 推導）

```
FQDN            去掉 Nine1.    全小寫 + dot→hyphen
Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker
  → Regularpurchase.V2.Worker.Console.NMQv3Worker
  → regularpurchase-v2-worker-console-nmqv3worker
```

| 專案 | FQDN | RELEASE_NAME |
|------|------|--------------|
| regularpurchase.v2.worker | `Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker` | `regularpurchase-v2-worker-console-nmqv3worker` |
| promotion.worker | `Nine1.Promotion.Console.NMQv3Worker` | `promotion-console-nmqv3worker` |
| commerce.nmqv3.worker | `Nine1.Commerce.Nmqv3.Console.NMQv3Worker` | `commerce-nmqv3-console-nmqv3worker` |

### 需對齊的位置

| 位置 | 欄位 | 格式 |
|------|------|------|
| `.gitlab-ci.yml` | `RELEASE_NAME` | `"{release-name}"` |
| `nine1-devops-deployments.QA.json` | `roles[].RELEASE_NAME` | `"{release-name}"` |
| `nine1-devops-deployments.Prod.json` | `roles[].RELEASE_NAME` | `"{release-name}"` |
| `charts/` 目錄名稱 | 資料夾名 | `charts/{release-name}/` |
| `values-tw-*.yaml` | `fullnameOverride` | `{release-name}` |
| `values-tw-*.yaml` | `image.repository` | `docker*.91app.io/91app/nine1-{release-name}` |
| `src/.manifest/sdm.json` | `ServiceId` | `"nine1-{release-name}"` ← 見下方說明 |

---

## serviceName（附帶說明）

`serviceName` 決定 **S3 config 路徑** 與 **Secrets Manager 路徑**，與 RELEASE_NAME 不同。

### 命名規則

- 取 FQDN 的服務段，**去掉 role 部分**（Console.NMQv3Worker / Web.Api）
- dot 換成 hyphen，保留 PascalCase

```
Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker
  → 服務段: Regularpurchase.V2.Worker（去掉 Console.NMQv3Worker）
  → 去掉 role Worker: Regularpurchase.V2
  → dot→hyphen: Regularpurchase-V2
```

| 專案 | serviceName |
|------|------------|
| regularpurchase.v2.worker | `Regularpurchase-V2` |
| promotion.worker | `Promotion` |
| commerce.nmqv3.worker | `Commerce-NMQv3` |

### 需對齊的位置

| 位置 | 欄位 |
|------|------|
| `values-tw-*.yaml` | `serviceName` |
| `nine1-devops-deployments.*.json` | `metadata.name` / `metadata.serviceName` |
| `config/` 目錄第一層 | 資料夾名稱（= serviceName）|
| `values-tw-*.yaml` | S3 路徑：`.../TW-{ENV}/{serviceName}/Worker/...` |
| `values-tw-*.yaml` | Secrets 路徑：`/{ENV}/{serviceName}/Worker/secrets` |

---

## sdm.json 說明

`.manifest/sdm.json` 是 **SDM（Service Discovery Manager）** 的服務登錄 manifest，CI pipeline 執行時會讀取此檔並向 SDM 系統註冊服務。

```json
{
    "ServiceId": "nine1-regularpurchase-v2-worker-console-nmqv3worker",
    "DisplayName": "RegularpurchaseV2Worker Console NMQv3 Worker",
    "FQDN": "Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker",
    "InitialDate": "2026/05/22",
    "ContactEmail": "upd@91app.com"
}
```

### ServiceId 推導規則

```
RELEASE_NAME:  regularpurchase-v2-worker-console-nmqv3worker
                 ↓ 加前綴 nine1-
ServiceId:     nine1-regularpurchase-v2-worker-console-nmqv3worker
```

### 為什麼 RELEASE_NAME 改了 ServiceId 也必須改

`ServiceId` 是服務在 SDM 系統的**唯一識別鍵**。外部系統（監控、告警、服務依賴圖）都靠這個 key 查找服務。  
若 ServiceId 與 RELEASE_NAME 不一致，SDM 登錄的 key 跟 K8s deploy 的 release 對不上，會導致：

- 監控 dashboard 找不到對應服務
- 告警無法對應到正確的 on-call 團隊
- 服務依賴追蹤斷鏈

---

## 完整範例對照（regularpurchase.v2.worker）

```
FQDN        = Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker
RELEASE_NAME = regularpurchase-v2-worker-console-nmqv3worker
ServiceId   = nine1-regularpurchase-v2-worker-console-nmqv3worker
serviceName = Regularpurchase-V2

chart dir   = charts/regularpurchase-v2-worker-console-nmqv3worker/
config dir  = config/Regularpurchase-V2/Worker/
S3 path     = s3://.../TW-QA/Regularpurchase-V2/Worker/{VERSION}/settings.json
image repo  = docker-dev.build.91app.io/91app/nine1-regularpurchase-v2-worker-console-nmqv3worker
```
