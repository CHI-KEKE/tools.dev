---
name: nine1-project-template
description: >
  使用此 Skill 來從 Nine1 專案樣板產生新的 .NET 專案。當使用者說「建立新專案」、「產生專案」、「初始化專案」、「套用樣板」、「用樣板建專案」、「建立 worker」、「建立 NMQ」、「建立 Web API」或提到 Nine1 專案結構時，必須使用此 Skill。
  支援兩種樣板類型：三層式 Web API（ThreeTierCustomWebApi）與 NMQv3 Worker（NMQv3）。
---

# Nine1 Project Template Scaffolding

版本：`v10.0`

此 Skill 協助使用者從 Nine1 樣板產生新的 .NET 專案，目前支援以下兩種樣板：

| 樣板 | shortName | 用途 |
|------|-----------|------|
| `Nine1.ThreeTierCustomWebApiTemplate` | `dotnet.webapi.custom` | 三層式 REST Web API |
| `Nine1.NMQv3Template` | `dotnet.nmqv3.worker` | NMQ v3 Console Worker |

## 樣板位置

樣板已內嵌於此 Skill 目錄內：`C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template/template/`

---

## 執行流程

### 步驟 1：選擇樣板類型

先詢問使用者要建立哪種專案：

- **Web API**（`dotnet.webapi.custom`）→ 三層式架構，適合 RESTful API 服務
- **NMQv3 Worker**（`dotnet.nmqv3.worker`）→ Console Worker，適合消息佇列處理

---

### 步驟 2：收集必要參數

不論哪種樣板，都需要：

1. **專案名稱** (`--name`)
   - 格式：`kebab-case`，例如 `order-management`、`user-service`
   - **不可**包含 `nine1-` 前綴（系統自動加上），若偵測到會自動去除以避免重複（`nine1-order-management` → `order-management`）
   - `-` 在 FQDN 命名中自動轉為 `.`（如 `order-management` → `Nine1.Order.Management`）

2. **專案父目錄** (`--parentDir`)
  - 使用者指定的絕對路徑，提示預設值為 `C:\91app`（可覆寫）
   - 系統將在此目錄下依樣板類型**自動建立**帶後綴的子資料夾：
     - Web API：`Nine1.{CamelCase}.Web.Api`
     - NMQv3 Worker：`Nine1.{CamelCase}.Worker`
   - 例如 name=`order-management`
     - Web API 輸出目錄：`C:\projects\Nine1.OrderManagement.Web.Api`
     - NMQv3 Worker 輸出目錄：`C:\projects\Nine1.OrderManagement.Worker`

3. **資料庫密鑰類型** (`--databaseSecret`)（兩種樣板皆支援）
   - `none`（預設）：不使用資料庫密鑰設定
   - `postgresql`：加入 PostgreSQL 連線密鑰設定
   - `mssql`：加入 MSSQL 連線密鑰設定

4. **K8s Namespace**（兩種樣板皆支援）
   - 目的：替換 `nine1-devops-deployments.QA.json` 與 `nine1-devops-deployments.Prod.json` 內各部署的 `NAMESPACE` 欄位
   - 提供任意形式均可，系統自動辨識並統一派生三環境值：

   | 使用者輸入 | QA namespace | PP namespace | Prod namespace |
   |---|---|---|---|
   | `pp-pokemon-center` | `qa-pokemon-center` | `pp-pokemon-center` | `prod-pokemon-center` |
   | `qa-order-management` | `qa-order-management` | `pp-order-management` | `prod-order-management` |
   | `pokemon-center`（無前綴）| `qa-pokemon-center` | `pp-pokemon-center` | `prod-pokemon-center` |
   | 未提供 | `qa-{name}` | `pp-{name}` | `prod-{name}` |

**僅 Web API 樣板需要額外詢問：**

5. **架構類型** (`--struct`)
   - `module`（預設）：收攏式，子專案依功能歸入 `BusinessLogic/`、`DataAccess/`、`Web/`、`Test/`、`Common/`
   - `flat`：攤平式，所有子專案直接置於 `src/` 底下

6. **Ingress Host 基礎名稱** (`-APIHost`，僅 `scaffold.ps1`)
  - 用途：產生 `charts/*/values-tw-*.yaml` 中 `api.ingress.hosts.host`
  - 輸入格式：不含環境與網域，例如 `litecrm-api-internal`
  - 未提供時預設：`{name}-internal`
  - 依環境自動派生：
    - TW QA：`{host}.qa.91dev.tw`
    - TW PP：`{host}.pp.91app.io`
    - TW Prod：`{host}.91app.io`
  - 需向使用者顯示預設值並請其審核確認

  例：name=`litecrm-api` → host 預設 `litecrm-api-internal`
  - QA host：`litecrm-api-internal.qa.91dev.tw`
  - Prod host：`litecrm-api-internal.91app.io`

未指定時使用預設值並告知使用者。

---

### 步驟 3：初始化 AI 指引（.github）

在建立專案**之前**，自動從 `gitlab.91app.com/b2e/nine1.copilot.instructions` 取得 AI 指引檔案，將其安置至專案的 `.github/` 目錄。

此步驟直接使用 `scaffold.ps1` 內建的 Token 與檔案對應規則，不需額外透過環境變數或參數覆寫。

檔案對應來源與目的地規則以 `scaffold.ps1` 內實作為準。

---

### 步驟 4：安裝樣板

```powershell
# Web API 樣板
dotnet new install "C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template/template/Nine1.ThreeTierCustomWebApiTemplate" --force

# NMQv3 Worker 樣板
dotnet new install "C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template/template/Nine1.NMQv3Template" --force
```

> `--force` 確保已安裝的舊版本會被強制更新。

---

### 步驟 5：產生專案

**Web API 樣板：**
```powershell
dotnet new dotnet.webapi.custom `
  --name "<NAME>" `
  --output "<PARENT_DIR>\Nine1.<CamelCase>.Web.Api" `
  --struct <module|flat> `
  --databaseSecret <none|postgresql|mssql>
```

**NMQv3 Worker 樣板：**
```powershell
dotnet new dotnet.nmqv3.worker `
  --name "<NAME>" `
  --output "<PARENT_DIR>\Nine1.<CamelCase>.Worker" `
  --databaseSecret <none|postgresql|mssql>
```

**範例（name=`order-management`，parentDir=`C:\projects`）：**
```powershell
# 實際 --output 自動帶入 C:\projects\Nine1.OrderManagement.Web.Api
dotnet new dotnet.webapi.custom --name "order-management" --output "C:\projects\Nine1.OrderManagement.Web.Api" --struct module --databaseSecret postgresql
```

> `-APIHost` 由 `scaffold.ps1` 在樣板產生後套用至 charts values，不透過 `dotnet new` 參數直接寫入。

---

### 步驟 6：替換 K8s Namespace 與調整 Charts

`dotnet new` 完成後，直接修改輸出目錄根層的兩個部署設定檔，將樣板預設的 namespace 替換為使用者指定值：

```powershell
# 以 order-management 為例（qaNamespace=qa-order-management, prodNamespace=prod-order-management）

# QA 檔：替換所有 NAMESPACE 欄位
$qaFile = "<PARENT_DIR>\Nine1.<CamelCase>.<Web.Api|Worker>\nine1-devops-deployments.QA.json"
$qa = Get-Content $qaFile -Raw | ConvertFrom-Json
$qa.spec.deployments | ForEach-Object { $_.settings.NAMESPACE = "<QA_NAMESPACE>" }
$qa | ConvertTo-Json -Depth 10 | Set-Content $qaFile -Encoding UTF8

# Prod 檔：PP 環境用 pp-{name}，Prod 環境用指定的 prodNamespace
$prodFile = "<PARENT_DIR>\Nine1.<CamelCase>.<Web.Api|Worker>\nine1-devops-deployments.Prod.json"
$prod = Get-Content $prodFile -Raw | ConvertFrom-Json
$prod.spec.deployments | ForEach-Object {
    if ($_.metadata.env -eq 'PP')   { $_.settings.NAMESPACE = "pp-<NAME>" }
    if ($_.metadata.env -eq 'Prod') { $_.settings.NAMESPACE = "<PROD_NAMESPACE>" }
}
$prod | ConvertTo-Json -Depth 10 | Set-Content $prodFile -Encoding UTF8
```

> 替換後向使用者確認，例如：「已設定 QA namespace 為 `qa-order-management`，PP 為 `pp-order-management`，Prod 為 `prod-order-management`」

若為 Web API，另外調整 `charts/{name}-web-api/values-tw-{qa|pp|prod}.yaml`：

- `api.ingress.hosts.host`：改為 `-APIHost` 派生的環境 host
- `canary.customMetrics.query`：加入 `exported_namespace`，且需符合各環境 namespace

```yaml
# QA
query: 'rate(nginx_ingress_controller_requests{namespace="ingress-nginx", ingress="{{ ingress }}",exported_namespace="qa-{name}"}[2m])'

# PP
query: 'rate(nginx_ingress_controller_requests{namespace="ingress-nginx", ingress="{{ ingress }}",exported_namespace="pp-{name}"}[2m])'

# Prod
query: 'rate(nginx_ingress_controller_requests{namespace="ingress-nginx", ingress="{{ ingress }}",exported_namespace="prod-{name}"}[2m])'
```

---

### 步驟 7：顯示摘要

產生完成後向使用者顯示：

**命名轉換結果**（以 `order-management` 為例）：

| 格式 | 結果 |
|------|------|
| FQDN | `Nine1.Order.Management` |
| CamelCase | `Nine1.OrderManagement` |
| kebab-case | `nine1-order-management` |
| SNAKE_UPPER | `NINE1_ORDER_MANAGEMENT` |

**產生的目錄結構：**

*Web API — module 架構：*
```
C:\projects\Nine1.OrderManagement.Web.Api\
├── src/
│   ├── BusinessLogic/
│   │   ├── Nine1.<Name>.BL.BE/
│   │   └── Nine1.<Name>.BL.Services/
│   ├── DataAccess/
│   │   ├── Nine1.<Name>.DA.DB/
│   │   └── Nine1.<Name>.DA.Repositories/
│   ├── Web/
│   │   └── Nine1.<Name>.Web.Api/
│   ├── Test/
│   │   └── Nine1.<Name>.BL.Services.Test/
│   ├── Common/
│   │   └── Nine1.<Name>.Common.Utils/
│   ├── Nine1.<Name>.Web.Api.sln
│   └── Nine1.<Name>.Web.Api.code-workspace
├── charts/, config/, pipeline/
├── Dockerfile, Taskfile.yml, .gitlab-ci.yml
```

*Web API — flat 架構：*
```
C:\projects\Nine1.OrderManagement.Web.Api\
├── src/
│   ├── Nine1.<Name>.BL.BE/
│   ├── Nine1.<Name>.BL.Services/
│   ├── Nine1.<Name>.BL.Services.Test/
│   ├── Nine1.<Name>.Common.Utils/
│   ├── Nine1.<Name>.DA.DB/
│   ├── Nine1.<Name>.DA.Repositories/
│   ├── Nine1.<Name>.Web.Api/
│   ├── Nine1.<Name>.Web.Api.sln
│   └── Nine1.<Name>.Web.Api.code-workspace
├── charts/, config/, pipeline/
├── Dockerfile, Taskfile.yml
```

*NMQv3 Worker：*
```
C:\projects\Nine1.OrderConsumer.Worker\
├── src/
│   ├── Nine1.<Name>.Console.NMQv3Worker/
│   ├── Nine1.<Name>.Console.NMQv3Worker.Test/
│   ├── Nine1.<Name>.Console.NMQv3Worker.sln
│   └── nuget.config
├── charts/, config/, pipeline/
├── Dockerfile, .gitlab-ci.yml
```

**後續建議步驟：**
- 開啟 `.sln` 或 `.code-workspace` 進行開發
- 確認資料庫連線設定（`appsettings.Development.json`）
- 確認 `nine1-devops-deployments.QA.json` 與 `nine1-devops-deployments.Prod.json` 的 namespace 設定

---

## 快速使用腳本（可選）

```powershell
# Web API（自訂 namespace，帶環境前綴）
C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template\scripts\scaffold.ps1 `
  -TemplateType webapi `
  -Name "pokemon" `
  -ParentDir "C:\projects" `
  -Struct module `
  -Namespace "pp-pokemon-center"
# → QA=qa-pokemon-center, PP=pp-pokemon-center, Prod=prod-pokemon-center
# → 產生於 C:\projects\Nine1.Pokemon.Web.Api

# Web API（使用預設 namespace）
C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template\scripts\scaffold.ps1 `
  -TemplateType webapi `
  -Name "order-management" `
  -ParentDir "C:\projects"
# → QA=qa-order-management, PP=pp-order-management, Prod=prod-order-management

# Web API（指定 APIHost，要求先審核預設）
C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template\scripts\scaffold.ps1 `
  -TemplateType webapi `
  -Name "litecrm-api" `
  -ParentDir "C:\projects" `
  -APIHost "litecrm-api-internal"
# → QA host=litecrm-api-internal.qa.91dev.tw
# → PP host=litecrm-api-internal.pp.91app.io
# → Prod host=litecrm-api-internal.91app.io

# NMQv3 Worker
C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template\scripts\scaffold.ps1 `
  -TemplateType nmqv3 `
  -Name "order-consumer" `
  -ParentDir "C:\projects"
# → 產生於 C:\projects\Nine1.OrderConsumer.Worker
```

---

## 命名規則說明

兩種樣板皆使用相同的命名轉換規則（均以使用者輸入的 `--name` 為基礎）：

| Symbol | 範例（輸入 `my-order`） | 說明 |
|--------|------------------------|------|
| `ORIGIN_NAME_W_LOWER` | `my-order` | 原始 kebab-case |
| `N1_FQDN_SUFFIX` | `My.Order` | FQDN 後綴 |
| `N1_FQDN` | `Nine1.My.Order` | 完整 FQDN |
| `CAMEL_CASE` | `MyOrder` | Camel Case |
| `N1_CAMEL_CASE` | `Nine1.MyOrder` | 含前綴 Camel |
| `SNAKE_NAME_W_UPPER` | `MY_ORDER` | 大寫底線 |
| `N1_ID` | `nine1-my-order` | 小寫 kebab 含前綴 |

---

## 錯誤處理

- 若 `dotnet` 未安裝：提示前往 https://dotnet.microsoft.com/download 安裝
- 若輸出目錄已存在：詢問是否覆蓋或更換目錄
- 若樣板安裝失敗：確認路徑正確，改用絕對路徑重試
- 若名稱含特殊字元或空格：提示改用 kebab-case 格式

---

## 前置需求

- .NET SDK 10.0 或以上版本（確認：`dotnet --version`）
- 存取 `C:\91APP\AI_Devs\skills\nine1.copilot.instructions\src\.github\skills\nine1-project-template/template/` 樣板目錄的權限