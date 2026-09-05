# 🔌 NYP WebAPI Port 設定與 Nine1.BaseSDK 整合指南

> 說明 91APP NYP Pipeline WebAPI 服務的標準 Port 設定（5566）、`Nine1.BaseSDK.AspNetCore` 的用途，以及常見的 Port 不一致問題排查方式。

## 📖 目錄

1. [標準 Port 規範](#1-標準-port-規範)
2. [為什麼預設是 8080？](#2-為什麼預設是-8080)
3. [Nine1.BaseSDK.AspNetCore](#3-nine1basesdkaspnetcore)
4. [完整 Port 設定位置一覽](#4-完整-port-設定位置一覽)
5. [Port 不一致的症狀與排查](#5-port-不一致的症狀與排查)
6. [新專案 Port 設定 Checklist](#6-新專案-port-設定-checklist)

<br>

---

## 1. 標準 Port 規範

**91APP NYP Pipeline 所有 WebAPI 服務統一使用 Port `5566`。**

```
App 監聽 5566 → Docker EXPOSE 5566 → K8s Service 5566 → Ingress → 外部流量
```

這個規範來自 `Nine1.BaseSDK.AspNetCore`（91APP 標準 SDK），以及 `nine1-project-template` 樣板的預設值。

<br>

---

## 2. 為什麼預設是 8080？

### 根本原因：`aspnet:8.0` Base Image

91APP 使用的 Docker runtime base image 是：

```dockerfile
FROM docker-proxy.build.91app.io/dotnet/aspnet:8.0
```

這個 image 內建以下環境變數：

```
ASPNETCORE_HTTP_PORTS=8080
```

若專案**沒有引用 `Nine1.BaseSDK.AspNetCore`** 且**沒有明確設定 Port**，ASP.NET Core 就會使用 8080。

### 優先級順序（高 → 低）

| 優先級 | 設定方式 | 值 |
|--------|---------|-----|
| 1（最高）| `ASPNETCORE_URLS` 環境變數 | `http://+:5566` |
| 2 | `UseUrls()` 程式碼 | — |
| 3 | Kestrel Endpoints（appsettings.json） | `"Url": "http://*:5566"` |
| 4 | `Nine1.BaseSDK.AspNetCore` 內部設定 | 5566 |
| 5（最低）| `ASPNETCORE_HTTP_PORTS`（base image 預設）| 8080 |

> ⚠️ **實務建議**：即使有 BaseSDK，仍建議在 `values-*.yaml` 明確設定 `ASPNETCORE_URLS`，避免環境差異造成 Port 不一致。

<br>

---

## 3. Nine1.BaseSDK.AspNetCore

### 什麼是 BaseSDK？

`Nine1.BaseSDK.AspNetCore` 是 91APP 封裝的標準 ASP.NET Core 擴充套件，提供：

- 標準 Port 5566 設定
- Health Check 路由（`/_hc`、`/_hc/startup`）
- Config / Secrets 載入整合
- 標準 middleware pipeline

### 安裝方式

**Step 1：新增 `src/nuget.config`**（指向 91APP 私有 NuGet）

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <solution>
    <add key="disableSourceControlIntegration" value="true" />
  </solution>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="Nine1.Nuget.Release"
      value="https://entry.build.91app.io/repository/nineyi-release-nuget-hosted/" />
    <add key="Nine1.Nuget.Develop"
      value="https://entry.build.91app.io/repository/nineyi-develop-nuget-hosted/" />
    <add key="Nine1.Nuget.Group"
      value="https://entry.build.91app.io/repository/nineyi-release-nuget/index.json" />
  </packageSources>
</configuration>
```

> ⚠️ `nuget.config` 必須放在 **`src/` 目錄下**（與 `.sln` 同層），否則 `dotnet restore` 找不到私有 NuGet。

**Step 2：在 Web API `.csproj` 引用 SDK**

```xml
<PackageReference Include="Nine1.BaseSDK.AspNetCore" Version="1.3.0" />
```

> .NET 8 對應版本為 `1.3.0`，.NET 10 對應 `10.0.0`。

**Step 3：執行 restore**

```bash
dotnet restore
```

<br>

---

## 4. 完整 Port 設定位置一覽

一個 WebAPI 服務共有 **4 個地方**需要一致設定 Port：

| 檔案 | 設定內容 | 5566 範例 |
|------|---------|-----------|
| `pipeline/build-config.sh` | Docker EXPOSE port | `NYS_DOCKER_EXPORT_PORT="5566"` |
| `charts/*/values-*.yaml` | K8s Service port + 探針 port | `servicePort: 5566` |
| `charts/*/values-*.yaml` | 強制 app 監聽的環境變數 | `ASPNETCORE_URLS: "http://+:5566"` |
| `src/Web/<FQDN>/Properties/launchSettings.json` | 本機開發 port（不影響 K8s） | `"applicationUrl": "http://localhost:5566"` |

### `values-*.yaml` environmentVariables 範例

```yaml
api:
  environmentVariables:
    ASPNETCORE_ENVIRONMENT: "Staging"
    ASPNETCORE_URLS: "http://+:5566"   # ← 最高優先級，確保不被 base image 8080 覆蓋

  servicePort: 5566
```

<br>

---

## 5. Port 不一致的症狀與排查

### 症狀：Pod 一直重啟，Canary 卡在 Progressing

```
Warning  Unhealthy  kubelet  Startup probe failed:
  Get "http://10.x.x.x:5566/_hc/startup": dial tcp: connect: connection refused
```

K8s Probe 打 5566，但 App 實際監聽 8080 → Connection refused → 重啟循環。

### 排查步驟

```bash
# 1. 看 Pod log，確認實際監聽 port
kubectl logs <pod-name> -n <namespace> | grep "Now listening"

# 2. 看 Probe 打哪個 port
kubectl describe pod <pod-name> -n <namespace> | grep -A5 "Startup\|Liveness\|Readiness"

# 3. 看 initContainer 是否正常
kubectl logs <pod-name> -n <namespace> -c aws-config-loader
```

### 常見根因

| 根因 | 說明 |
|------|------|
| 沒有 `ASPNETCORE_URLS` | base image `ASPNETCORE_HTTP_PORTS=8080` 搶先 |
| 沒有 `Nine1.BaseSDK.AspNetCore` | 缺少 91APP 標準 Port 設定 |
| 沒有 `nuget.config` | BaseSDK 裝不起來 |
| `servicePort` 與 app 監聽 port 不同 | Probe target port 錯誤 |

<br>

---

## 6. 新專案 Port 設定 Checklist

新建或接手 WebAPI 專案時，確認以下項目：

- [ ] `src/nuget.config` 存在，包含 `entry.build.91app.io` NuGet 來源
- [ ] `*.csproj` 已引用 `Nine1.BaseSDK.AspNetCore`（.NET 8 → v1.3.0）
- [ ] `pipeline/build-config.sh`：`NYS_DOCKER_EXPORT_PORT="5566"`
- [ ] `charts/values-*.yaml`：`servicePort: 5566`
- [ ] `charts/values-*.yaml`：`ASPNETCORE_URLS: "http://+:5566"` 已設定
- [ ] `launchSettings.json`：`http://localhost:5566`（本機開發用）
- [ ] `dotnet build` 成功，無 error

<br>

---

## 相關文件

- [NYP Pipeline 結構說明](./NYP_Pipeline_Structure.md)
- [NYP Folder Structure Troubleshooting](./NYP_Folder_Structure_Troubleshooting.md)
