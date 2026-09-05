# NYP — serviceName 命名規則

> 適用：Nine1 NMQv3 Worker、Web API 專案

---

## serviceName 是什麼？

`serviceName` 是服務在 **AWS 基礎設施（S3、Secrets Manager）上的唯一路徑識別**。

Helm chart 使用此值動態組合 config 與 secret 的讀取路徑，因此它不影響 K8s 資源命名，但直接決定服務啟動時能否讀到正確的設定檔與密鑰。

### 兩大用途

| 用途 | 路徑格式 |
|------|---------|
| **S3 設定檔** | `s3://91app-ap-northeast-1-private-conf/{MARKET}-{ENV}/{serviceName}/{role}/{VERSION}/settings.json` |
| **Secrets Manager** | `/{MARKET}-{ENV}/{serviceName}/{role}/secrets` |

---

## 命名規則

### 推導來源

從 FQDN 推導：**去掉 `Nine1.` 前綴與 role 後綴（Console.NMQv3Worker / Web.Api），dot 換 hyphen**

```
FQDN: Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker
  ↓ 去掉 Nine1.
Regularpurchase.V2.Worker.Console.NMQv3Worker
  ↓ 去掉 role (Console.NMQv3Worker)
Regularpurchase.V2.Worker
  ↓ 去掉尾端 role segment (Worker = 已包含在 role path)，dot → hyphen
Regularpurchase-V2
```

> ⚠️ 注意：`role` 路徑（`/Worker/`）由 values.yaml 的 `worker.role` 欄位決定，
> 因此 serviceName **不應重複包含 role 名稱**。

### 真實專案對照

| 專案 repo | FQDN | serviceName |
|-----------|------|-------------|
| `nine1.promotion.worker` | `Nine1.Promotion.Console.NMQv3Worker` | `Promotion-Service` |
| `nine1.commerce.nmqv3.worker` | `Nine1.Commerce.Nmqv3.Console.NMQv3Worker` | `Commerce-NMQv3` |
| `nine1.regularpurchase.v2.worker` | `Nine1.Regularpurchase.V2.Worker.Console.NMQv3Worker` | `Regularpurchase-V2` |

> 💡 `Promotion` 的 serviceName 是 `Promotion-Service`（帶 `-Service` 後綴），
> 顯示 serviceName 可由團隊**自行決定**，不強制與 FQDN 直接對應。
> 重要的是整個專案內**所有位置保持一致**。

---

## 需對齊的位置

### 1. `values-tw-*.yaml`（每個市場/環境都有一份）

```yaml
# ① serviceName 欄位
serviceName: Regularpurchase-V2

worker:
  role: Worker                       # ② role 決定路徑中的 /Worker/ 段

  configSource:
    files:
      # ③ S3 路徑 = {MARKET}-{ENV}/{serviceName}/{role}/...
      - s3://91app-ap-northeast-1-private-conf/TW-QA/Regularpurchase-V2/Worker/{{CONFIG_VERSION}}/settings.json

  secretSource:
    secrets:
      # ④ Secrets 路徑（一般 secret）
      - key: /TW-QA/Regularpurchase-V2/Worker/secrets
        fileName: secrets.json
      # ⑤ Secrets 路徑（DB secret，格式固定）
      - key: /TW-QA/Regularpurchase-V2/Worker/secrets.db.{db-name}.{db-user}.json
```

### 2. `nine1-devops-deployments.*.json`

```json
{
  "metadata": {
    "name": "Regularpurchase-V2",        // ⑥ pipeline UI 顯示用
    "serviceName": "Regularpurchase-V2"  // ⑦ pipeline 識別用
  }
}
```

### 3. `config/` 目錄結構

config 目錄的結構**直接對應 S3 路徑**，資料夾名稱必須與 serviceName 一致：

```
config/
└── {serviceName}/              ← ⑧ 第一層 = serviceName
    └── {role}/                 ← ⑨ 第二層 = role（Worker）
        ├── QA/
        │   └── TW-QA/
        │       └── settings.TW-QA.json
        ├── PP/
        │   └── TW-PP/
        │       └── settings.TW-PP.json
        ├── Prod/
        │   └── TW-Prod/
        │       └── settings.TW-Prod.json
        ├── schema.json
        └── settings._BASE.json
```

**範例：**
```
config/
└── Regularpurchase-V2/    ← serviceName
    └── Worker/            ← role
        ├── QA/TW-QA/settings.TW-QA.json
        ├── PP/TW-PP/settings.TW-PP.json
        └── Prod/TW-Prod/settings.TW-Prod.json
```

---

## 對齊 Checklist

新建專案或修改 serviceName 時，確認以下 **9 個位置** 全部一致：

| # | 位置 | 欄位/說明 |
|---|------|-----------|
| ① | `values-tw-*.yaml`（每個環境） | `serviceName:` |
| ② | `values-tw-*.yaml`（每個環境） | `worker.role:` |
| ③ | `values-tw-*.yaml`（每個環境） | S3 config 路徑中的 `{serviceName}/{role}` |
| ④ | `values-tw-*.yaml`（每個環境） | Secrets 路徑中的 `{serviceName}/{role}/secrets` |
| ⑤ | `values-tw-*.yaml`（每個環境） | DB secrets 路徑中的 `{serviceName}/{role}/secrets.db.*` |
| ⑥ | `nine1-devops-deployments.QA.json` | `metadata.name` / `metadata.serviceName` |
| ⑦ | `nine1-devops-deployments.Prod.json` | `metadata.name` / `metadata.serviceName` |
| ⑧ | `config/` 目錄 | 第一層資料夾名稱（= serviceName） |
| ⑨ | `config/` 目錄 | 第二層資料夾名稱（= role，通常是 `Worker`） |

---

## 完整範例（regularpurchase.v2.worker）

```
serviceName = Regularpurchase-V2
role        = Worker

S3 path  = s3://.../TW-QA/Regularpurchase-V2/Worker/{VERSION}/settings.json
           s3://.../TW-PP/Regularpurchase-V2/Worker/{VERSION}/settings.json
           s3://.../TW-Prod/Regularpurchase-V2/Worker/{VERSION}/settings.json

Secrets  = /TW-QA/Regularpurchase-V2/Worker/secrets
DB Secret= /TW-QA/Regularpurchase-V2/Worker/secrets.db.regularpurchase-v2-db.regularpurchase-v2-db-user.json

config/
└── Regularpurchase-V2/
    └── Worker/
        ├── QA/TW-QA/settings.TW-QA.json
        ├── PP/TW-PP/settings.TW-PP.json
        └── Prod/TW-Prod/settings.TW-Prod.json

values-tw-qa.yaml  → serviceName: Regularpurchase-V2
values-tw-pp.yaml  → serviceName: Regularpurchase-V2
values-tw-prod.yaml → serviceName: Regularpurchase-V2

nine1-devops-deployments.QA.json  → metadata.serviceName: "Regularpurchase-V2"
nine1-devops-deployments.Prod.json → metadata.serviceName: "Regularpurchase-V2"
```
