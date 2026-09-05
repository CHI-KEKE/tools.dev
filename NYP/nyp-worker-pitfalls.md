# NYP — Worker 專案建立踩坑紀錄

> 適用：Nine1 NMQv3 Worker 新專案建立流程
> 紀錄來源：`nine1.regularpurchase.v2.worker` 建立過程

---

## 坑 1｜K8s 資源名稱不能有 dot（`.`）

**症狀：**
```
spec.template.spec.containers[0].name: Invalid value:
"regularpurchase.v2.worker-console-nmqv3worker": must not contain dots
```

**根因：**
Helm 自動生成 K8s 資源名稱（container name、deployment name）時，會以 `RELEASE_NAME` 為基礎組合。
若 `RELEASE_NAME` 含有 dot，K8s 會直接拒絕。

**Helm fullname 組合規則（無 override 時）：**
```
fullname = Release.Name + "-" + Chart.Name
           （若 Release.Name 已含 Chart.Name 則只用 Release.Name）
```

| 來源 | 值 |
|------|---|
| `Release.Name` | `RELEASE_NAME`（`.gitlab-ci.yml` 定義） |
| `Chart.Name` | Nine1 共用 chart 名稱（集中在 nine1.devops.gitlab） |

**解法：**
1. `RELEASE_NAME` 本身必須是全小寫 hyphen（治本）
2. 在 `values.yaml` 加 `fullnameOverride` 強制覆蓋（治標）

```yaml
fullnameOverride: regularpurchase-v2-worker-console-nmqv3worker
```

---

## 坑 2｜image.repository 不能有大寫

**症狀：**
批次替換腳本執行後，`image.repository` 變成大寫開頭（如 `Docker-dev.build.91app.io/...`）

**根因：**
PowerShell `-replace` 預設大小寫 **insensitive**，用全域 regex 替換時誤傷 image repository 的值。

**解法：**
- 不能用模糊全域正則
- 各個欄位**分開精確替換**

```yaml
# 正確格式
image:
  repository: docker-dev.build.91app.io/91app/nine1-{release-name}  # QA
  repository: docker.build.91app.io/91app/nine1-{release-name}      # PP/Prod
```

---

## 坑 3｜RELEASE_NAME 必須全小寫 hyphen

**症狀：**
`.gitlab-ci.yml` 和 deployment JSON 裡的 `RELEASE_NAME` 有 dot 或大小寫混用，導致 CI 錯誤。

**正確格式：**
```
FQDN:         Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker
                ↓ 去掉 Nine1. + 全小寫 + dot→hyphen
RELEASE_NAME: regularpurchase-v2-worker-console-nmqv3worker
```

**需對齊的位置：**

| 位置 | 欄位 |
|------|------|
| `.gitlab-ci.yml` | `RELEASE_NAME` |
| `nine1-devops-deployments.QA.json` | 各 role 的 `RELEASE_NAME` |
| `nine1-devops-deployments.Prod.json` | 各 role 的 `RELEASE_NAME` |
| `charts/` 目錄名稱 | 資料夾名 = RELEASE_NAME |
| `values-*.yaml` | `fullnameOverride` |
| `values-*.yaml` | `image.repository` 中的服務名稱段 |
| `src/.manifest/sdm.json` | `ServiceId` = `nine1-{RELEASE_NAME}` |

---

## 坑 4｜serviceName 不應包含 role 名稱（避免路徑重複）

**症狀：**
S3/Secrets 路徑變成 `.../Regularpurchase-V2-Worker/Worker/...`（Worker 重複出現）

**根因：**
`serviceName` 本身帶了 `Worker`，而 S3 路徑又疊加了 `worker.role: Worker`。

```
路徑格式：{MARKET}-{ENV}/{serviceName}/{role}/{VERSION}/settings.json

❌ 錯誤：TW-QA/Regularpurchase-V2-Worker/Worker/latest/settings.json
✅ 正確：TW-QA/Regularpurchase-V2/Worker/latest/settings.json
```

**解法：**
`serviceName` 只保留業務名稱，`role` 由 `worker.role` 欄位單獨提供，兩者不重疊。

---

## 坑 5｜HK/MY 共用同一個 KUBE_CONFIG_ENV_NAME

**症狀：**
HK/MY 各自設了不同的 `KUBE_CONFIG_HK_QA` / `KUBE_CONFIG_MY_QA`，導致 CI 找不到對應的 kubeconfig。

**正確規則（參考 promotion worker 確認）：**

| 環境 | KUBE_CONFIG_ENV_NAME |
|------|----------------------|
| TW QA | `KUBE_CONFIG_TW_QA` |
| TW PP | `KUBE_CONFIG_TW_PP` |
| TW Prod | `KUBE_CONFIG_TW_PROD` |
| HK QA | `KUBE_CONFIG_HK_MY_QA` |
| MY QA | `KUBE_CONFIG_HK_MY_QA` ← 與 HK 共用 |

---

## 坑 6｜HK/MY 的 NAMESPACE 前綴不同

**症狀：**
複製 TW 的格式，NAMESPACE 直接套 `qa-xxx`，但 HK/MY 有專屬前綴。

**正確規則：**

| 環境 | NAMESPACE 格式 |
|------|----------------|
| TW QA | `qa-{service-slug}` |
| HK QA | `hk-qa-{service-slug}` |
| MY QA | `my-qa-{service-slug}` |
| PP | `pp-{service-slug}` |
| Prod | `prod-{service-slug}` |

---

## 坑 7｜sdm.json 的 ServiceId 要同步更新

**症狀：**
RELEASE_NAME 改了，但 `src/.manifest/sdm.json` 的 `ServiceId` 還是舊的 dot 格式。

**ServiceId 規則：**
```
ServiceId = "nine1-" + RELEASE_NAME
```

```json
{
    "ServiceId": "nine1-regularpurchase-v2-worker-console-nmqv3worker",
    "FQDN": "Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker"
}
```

**為什麼要連動：**
SDM（Service Discovery Manager）用 `ServiceId` 作為服務的唯一識別鍵，外部系統（監控、告警、服務依賴圖）都靠這個 key 查找服務。若與 RELEASE_NAME 不一致，會導致 SDM 登錄的 key 跟 K8s deploy 的 release 對不上。

---

## 坑 8｜CI pipeline config 路徑與目錄結構不匹配

**症狀：**
```
=== s3 bucket: s3://91app-ap-northeast-1-private-conf/
aws: [ERROR]: The user-provided path workdir/artifacts does not exist.
```

**根因：**
Pipeline 以 `config/{serviceName}/{role}/` 為基礎目錄打包 artifacts。若本地 config 目錄結構與這個 pattern 不符，pipeline 找不到目錄 → artifacts 不生成。

**正確結構（經 INFRA 確認）：**
```
config/
└── {serviceName}/
    └── {role}/        ← pipeline 以此為基礎目錄
        ├── QA/
        ├── PP/
        └── Prod/
```

> 若 role 有版本號，應直接寫進 role 名稱（如 `Worker-V2`），而非在 Worker 前後插入額外層級。

---

## 坑 9｜CI build 失敗：缺少 using directives

**症狀：**
```
error CS1061: 'IConfiguration' does not contain a definition for 'GetConnectionString'
error CS0103: The name 'ServerVersion' does not exist in the current context
error CS1061: 'DbContextOptionsBuilder' does not contain a definition for 'UseMySql'
```

**根因：**
`Program.cs` 加了 EF Core 的呼叫但缺少對應的 `using`。

**解法：**
```csharp
using Microsoft.EntityFrameworkCore;       // UseMySql, DbContextOptionsBuilder
using Microsoft.Extensions.Configuration; // GetConnectionString
```

---

## 坑 10｜本機 .NET SDK 版本不符

**症狀：**
本機 build 失敗，`net10.0` 不支援。

**根因：**
Nine1 新專案使用 `net10.0`，但本機只裝了 SDK 9.0.x。

**解法：**
安裝 .NET 10 SDK → https://dotnet.microsoft.com/en-us/download/dotnet/10.0

---

## 坑 11｜master branch 為 protected，不能直接 push

**症狀：**
`git push origin master` 被拒絕。

**解法：**
所有修改須透過 **feature branch + MR** 流程，不能直接 push master。

---

## 坑 12｜K8s namespace RBAC 權限（需 INFRA 申請）

**症狀：**
```
secrets is forbidden: User "u-xxx" cannot list resource "secrets"
in namespace "qa-regular-purchase-service"
```

**根因：**
新建立的 namespace 沒有對應的 RBAC RoleBinding，CI service account 無法操作 secrets。

**解法：**
向 INFRA 團隊申請為新 namespace 建立 RoleBinding。

---

## 快速核對表：新建 Worker 必查項目

| # | 檢查點 | 規則 |
|---|--------|------|
| ☐ | `RELEASE_NAME` | 全小寫 hyphen，無 dot |
| ☐ | `GLCI__NYS_FQDN` | `Nine1.{Name}.Console.NMQv3Worker` |
| ☐ | `fullnameOverride`（所有 values.yaml） | = RELEASE_NAME |
| ☐ | `image.repository` | 全小寫，`docker[-dev].build.91app.io/91app/nine1-{release-name}` |
| ☐ | `serviceName` | 業務名稱，不含 role |
| ☐ | `worker.role` | 單獨定義，不與 serviceName 重疊 |
| ☐ | `config/` 目錄結構 | `{serviceName}/{role}/` 兩層 |
| ☐ | S3/Secrets 路徑 | `{serviceName}/{role}/` 對齊 config 目錄 |
| ☐ | `sdm.json` ServiceId | `nine1-{RELEASE_NAME}` |
| ☐ | HK/MY `KUBE_CONFIG_ENV_NAME` | 共用 `KUBE_CONFIG_HK_MY_QA` |
| ☐ | HK/MY NAMESPACE 前綴 | `hk-qa-` / `my-qa-` |
| ☐ | `nine1-devops-deployments.*.json` | RELEASE_NAME、NAMESPACE、serviceName 三者對齊 |
