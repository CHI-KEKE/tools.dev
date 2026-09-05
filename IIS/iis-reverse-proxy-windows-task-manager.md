# IIS 反向代理部署指南：Windows Task Manager

> 專案位置：`C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager`
> 技術棧：ASP.NET Core 8（Razor Pages）+ IIS + ASP.NET Core Module V2（ANCM）

---

## 1. 原理：IIS 到底怎麼「反向代理」ASP.NET Core

這個專案（`WindowsTaskManager.csproj`，`Sdk="Microsoft.NET.Sdk.Web"`）**不是**傳統 ASP.NET（.NET Framework）網站，IIS 不會直接執行裡面的 C# 程式碼。真正執行程式的是內建的 **Kestrel** Web 伺服器，IIS 只是前端外殼，靠一個模組把請求轉交給它。

```
瀏覽器
  │  HTTPS/HTTP request
  ▼
IIS (w3wp.exe 工作進程)
  │  由 ASP.NET Core Module V2 (ANCMv2) 攔截
  ▼
dotnet WindowsTaskManager.dll  → Kestrel → Razor Pages 管線
```

### 關鍵元件

| 元件 | 角色 |
|---|---|
| **IIS** | 對外接收 HTTP/HTTPS 連線、SSL 終止、Port 綁定、App Pool 進程管理 |
| **ANCMv2**（隨 Hosting Bundle 安裝的原生 IIS 模組） | 攔截進站請求，依 `web.config` 指示啟動/管理 `dotnet.exe` 進程，把請求轉交給裡面的 Kestrel |
| **web.config** | 告訴 ANCM 要執行哪個 dll、用什麼 hosting model、注入哪些環境變數 |
| **Kestrel** | 真正處理 HTTP 請求、跑 Razor Pages / Middleware 管線的 Web 伺服器 |

### 兩種 Hosting Model

- **In-Process（本專案採用，效能較好）**：Kestrel 直接被載入到 IIS 的 `w3wp.exe` 進程內執行，ANCM 只負責轉發，沒有額外的 process/port。
- **Out-of-Process**：`dotnet.exe` 另外開一個獨立進程監聽內部 port，IIS 再用真正的反向代理（HTTP）把請求轉發過去。

發佈後 `web.config` 會長這樣（`hostingModel="inprocess"` 就是本專案設定）：

```xml
<aspNetCore processPath="dotnet"
            arguments=".\WindowsTaskManager.dll"
            stdoutLogEnabled="false"
            stdoutLogFile=".\logs\stdout"
            hostingModel="inprocess">
  <environmentVariables>
    <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
  </environmentVariables>
</aspNetCore>
```

> **重點**：在 `src\WindowsTaskManager\web.config` 原始碼裡看到的檔案是 **0 bytes（空檔）**，這是正常現象——它只是 placeholder，真正內容要靠 `dotnet publish` 才會自動產生。

### 環境變數如何影響行為

`Program.cs` 依 `builder.Environment.IsDevelopment()` 判斷要用 Demo 認證還是 Google OAuth：

```csharp
if (builder.Environment.IsDevelopment())
{
    // Development：Demo 認證（自動登入 Demo Admin，方便本機開發）
}
else
{
    // QA / Production：Google OAuth 登入
}
```

這個判斷完全依賴 `ASPNETCORE_ENVIRONMENT` 環境變數，對應讀取 `appsettings.{Environment}.json`（`appsettings.QA.json` / `appsettings.Production.json`）。這也是為什麼 `web.config` 一定要正確設定這個環境變數，否則正式站可能誤跑成 Demo 模式。

---

## 2. 前置需求

### 2.1 目標機器需安裝

- **IIS**（伺服器管理員 → 新增角色與功能 → 勾選 Web 伺服器 (IIS)）
- **.NET 8.0 ASP.NET Core Hosting Bundle**（⚠️ 不是只裝 Runtime，一定要 Hosting Bundle，內含 ANCMv2 模組）
  - 下載：https://dotnet.microsoft.com/download/dotnet/8.0
- 安裝後**重開機或至少 `iisreset`**，讓 ANCM 模組正確註冊進 IIS

驗證模組是否裝好：IIS 管理員 → 站台 → 模組 → 應能看到 `AspNetCoreModuleV2`。

### 2.2 Google OAuth 憑證

到 [Google Cloud Console](https://console.cloud.google.com/) 取得：
- Client ID
- Client Secret
- 設定授權回呼 URL：`https://your-domain.com/LoginCallback`

---

## 3. 一步步部署流程

### 步驟 1：建置與發佈（在開發機執行）

```powershell
cd "C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager"

# QA 環境
dotnet publish src\WindowsTaskManager\WindowsTaskManager.csproj -c Release -o publish-qa

# Production 環境
dotnet publish src\WindowsTaskManager\WindowsTaskManager.csproj -c Release -o publish-prod
```

發佈完成後，資料夾內會有真正產生內容的 `web.config`（而不是原始碼裡那個空檔）。

### 步驟 2：把 publish 資料夾複製到目標機器

複製整個 `publish-prod`（或 `publish-qa`）到目標機，例如：

```
D:\WebSites\windows-task-manager-prod\
```

### 步驟 3：編輯 web.config，加上環境變數

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet"
                  arguments=".\WindowsTaskManager.dll"
                  stdoutLogEnabled="false"
                  stdoutLogFile=".\logs\stdout"
                  hostingModel="inprocess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
          <environmentVariable name="Authentication__Google__ClientId" value="your-prod-client-id" />
          <environmentVariable name="Authentication__Google__ClientSecret" value="your-prod-client-secret" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
```

> ⚠️ **安全提醒**：`web.config` 含機敏資料，不要提交到版控。可改用步驟 3-Alt 的機器層級環境變數做法。

#### 步驟 3-Alt：不想把機敏資料寫進 web.config？用 Windows 環境變數

專案內已附 `setup.ps1`，用互動式精靈設定 Machine 層級環境變數：

```powershell
# 以系統管理員身份執行
.\setup.ps1
```

或手動設定：

```powershell
[System.Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Production", "Machine")
[System.Environment]::SetEnvironmentVariable("Authentication__Google__ClientId", "your-client-id", "Machine")
[System.Environment]::SetEnvironmentVariable("Authentication__Google__ClientSecret", "your-client-secret", "Machine")
iisreset
```

此時 `web.config` 內只需保留（或省略）環境設定：

```xml
<environmentVariables>
  <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
</environmentVariables>
```

### 步驟 4：建立應用程式集區（App Pool）

IIS 管理員 → 應用程式集區 → 新增應用程式集區：

| 設定項 | 值 |
|---|---|
| 名稱 | `WindowsTaskManager-Prod` |
| .NET CLR 版本 | **無受控碼**（No Managed Code）— 因為程式碼由 `dotnet.exe` 執行，不吃 IIS 的 .NET Framework CLR |
| 受控管線模式 | 整合式 |

### 步驟 5：建立 IIS 網站

IIS 管理員 → 網站 → 加入網站：

| 設定項 | 值 |
|---|---|
| 網站名稱 | Windows Task Manager (Production) |
| 應用程式集區 | 步驟 4 建立的 `WindowsTaskManager-Prod` |
| 實體路徑 | `D:\WebSites\windows-task-manager-prod` |
| 繫結 | 依需求設定 HTTP/HTTPS，Host name 建議對齊 `appsettings.Production.json` 內設定的網域 |

### 步驟 6：設定資料夾權限

```powershell
New-Item -Path "D:\WebSites\windows-task-manager-prod\logs" -ItemType Directory -Force

icacls "D:\WebSites\windows-task-manager-prod" /grant "IIS AppPool\WindowsTaskManager-Prod:(OI)(CI)RX" /T
icacls "D:\WebSites\windows-task-manager-prod\logs" /grant "IIS AppPool\WindowsTaskManager-Prod:(OI)(CI)M" /T
```

### 步驟 7：Google OAuth 回呼網址

到 Google Cloud Console，把授權回呼 URL 設定為與繫結網域一致：

```
https://windows-task-manager.hk.91dev.tw/LoginCallback
```

（此網域取自 `appsettings.Production.json` 內 `ServersConfig.Servers[0].IPAddress` 設定，僅供參考，請依實際繫結網域調整）

### 步驟 8：重啟並驗證

```powershell
iisreset
```

打開瀏覽器造訪網站網址，檢查：

- ✅ 顯示 Google 登入按鈕（**不應該**自動以 Demo Admin 登入）
- ✅ 點擊後導向 Google OAuth 頁面
- ✅ 登入成功後正確返回應用程式並顯示 Google 帳號名稱
- ✅ 角色權限正確套用

---

## 4. 故障排除

| 問題 | 可能原因 | 解決方式 |
|---|---|---|
| 仍顯示 "Demo Admin" | `ASPNETCORE_ENVIRONMENT` 未正確設定 | 檢查 web.config / 機器環境變數是否為 `Production` 或 `QA`，`iisreset` 後重新確認 |
| Google OAuth 登入失敗 | ClientId/ClientSecret 錯誤，或回呼網址不符 | 核對 Google Cloud Console 設定的回呼 URL 與實際網域是否一致 |
| 503 Service Unavailable | App Pool 停止、Hosting Bundle 未裝、權限不足 | 檢查 App Pool 狀態、確認已安裝 ASP.NET Core Hosting Bundle、檢查檔案權限 |
| 環境變數設定後未生效 | IIS 未重啟、快取問題 | `iisreset /stop` → `iisreset /start`，或 `Restart-WebAppPool -Name "<AppPoolName>"` |
| 502.5 - Process Failure | dll 路徑錯、Runtime 版本不符 | 開啟 `stdoutLogEnabled="true"` 查看 `logs\stdout_*.log`，確認 .NET 8 Runtime 已安裝 |

### 除錯：啟用詳細日誌

```xml
<aspNetCore processPath="dotnet"
            arguments=".\WindowsTaskManager.dll"
            stdoutLogEnabled="true"
            stdoutLogFile=".\logs\stdout"
            hostingModel="inprocess">
```

日誌位置：`publish-prod\logs\stdout_*.log`，除錯完記得關閉（`stdoutLogEnabled="false"`），並在裡面尋找：

```
Hosting environment: Production
```

---

## 5. 安全性建議

### QA 環境
- 使用測試專用的 Google OAuth 專案
- 限制授權網域
- 建議使用 HTTPS
- 可暫時啟用 stdout 日誌以便除錯

### Production 環境
- 使用獨立的 Google OAuth 專案
- 嚴格限制授權網域為正式網域
- 強制使用 HTTPS
- 停用 stdout 日誌
- 定期更新 OAuth 憑證
- 稽核日誌保留至少 90 天
- 機敏資料建議改用機器層級環境變數或 Azure Key Vault，不寫進 web.config

---

## 6. 自動化部署腳本範例

```powershell
# deploy-prod.ps1
param(
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$TargetPath = "D:\WebSites\windows-task-manager-prod"
)

Write-Host "Publishing..." -ForegroundColor Cyan
dotnet publish src\WindowsTaskManager\WindowsTaskManager.csproj -c Release -o publish-prod

Write-Host "Updating web.config..." -ForegroundColor Cyan
$webConfigPath = "publish-prod\web.config"
$webConfig = [xml](Get-Content $webConfigPath)

$envVars = $webConfig.configuration.location.'system.webServer'.aspNetCore.environmentVariables
if (-not $envVars) {
    $envVars = $webConfig.CreateElement("environmentVariables")
    $webConfig.configuration.location.'system.webServer'.aspNetCore.AppendChild($envVars)
}

$envVars.InnerXml = @"
<environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
<environmentVariable name="Authentication__Google__ClientId" value="$ClientId" />
<environmentVariable name="Authentication__Google__ClientSecret" value="$ClientSecret" />
"@

$webConfig.Save($webConfigPath)

Write-Host "Copying files to $TargetPath..." -ForegroundColor Cyan
Copy-Item -Path "publish-prod\*" -Destination $TargetPath -Recurse -Force

Write-Host "Restarting application pool..." -ForegroundColor Cyan
Restart-WebAppPool -Name "WindowsTaskManager-Prod"

Write-Host "Deployment completed!" -ForegroundColor Green
```

使用方式：

```powershell
.\deploy-prod.ps1 -ClientId "your-client-id" -ClientSecret "your-client-secret"
```

---

## 7. 常用檢查指令速查

```powershell
# 查詢站台清單
powershell.exe -Command "Import-Module WebAdministration; Get-Website | Select-Object Name, State, PhysicalPath"

# 查詢應用程式集區狀態
Get-WebAppPoolState -Name "WindowsTaskManager-Prod"

# Recycle App Pool（改設定/換 dll 後手動觸發）
Restart-WebAppPool -Name "WindowsTaskManager-Prod"

# 完整重啟 IIS
iisreset

# 尾看 stdout 日誌
Get-Content "D:\WebSites\windows-task-manager-prod\logs\stdout_*.log" -Tail 50
```

---

## 8. 相關文件

- 專案內：`DEPLOYMENT-IIS.md`、`ENVIRONMENT-CONFIGURATION.md`、`AUTHENTICATION.md`、`README.md`
- `tools.dev\IIS\iis-basics.md` — IIS Site / App Pool / Virtual Application 基礎概念
- `tools.dev\Windows-task-manager\` — 本專案其他分析與測試文件
