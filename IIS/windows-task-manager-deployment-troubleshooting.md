# Windows Task Manager — IIS 部署實戰疑難排解記錄

> 專案位置：`C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager`
> 本文件記錄 **QA 環境** 與 **Production 環境** 實際部署過程中真正遇到的問題、根本原因與解決步驟，
> 依照時間順序整理，可作為未來在其他機器重新部署時的檢查清單與除錯依據。
> 另參考：`iis-reverse-proxy-windows-task-manager.md`（原理與標準部署流程）。

---

## 0. 部署環境總覽

| 環境 | 主機網域 | 說明 |
|---|---|---|
| QA | `windows-task-manager.my.91dev.tw` | 部署在 IP `10.51.121.152` 這台機器自己 |
| Production | `windows-task-manager.my.91app.io` | 監控自己這台機器的排程 |

兩個環境都是「**網站部署的機器，同時也是要被監控排程的目標機器**」，這個前提是後面好幾個問題的根本原因，務必先確認清楚。

---

## 1. QA 環境：問題與解法時間軸

### 1.1 setup.ps1 的 Scope 該選 Machine 還是 User？

**現象**：執行 `setup.ps1` 時，Step 3 詢問 `Choose Scope`，不確定該選哪個。

**原因**：
- `User` 層級環境變數只對「目前登入的使用者」生效
- IIS 應用程式集區是用系統服務身分執行，**不是**你登入的使用者帳號
- 若選 `User`，IIS 讀不到這些環境變數

**解法**：**一律選擇 `1) Machine`**（需要以系統管理員身分執行 PowerShell）。

---

### 1.2 Hosting Bundle 版本確認

**檢查指令**：
```powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Where-Object { $_.DisplayName -like "*Hosting Bundle*" -or $_.DisplayName -like "*ASP.NET Core*" } |
  Select-Object DisplayName, DisplayVersion
```

**現象**：機器上只裝了 `Microsoft ASP.NET Core 3.1.32`，但專案 `WindowsTaskManager.csproj` 的 `TargetFramework` 是 `net8.0`，版本不符，會導致啟動失敗（500.30 / 502.5）。

**解法**：安裝 **.NET 8.0 ASP.NET Core Runtime — Windows Hosting Bundle**（不是單純 Runtime）：
```powershell
winget install --id Microsoft.DotNet.HostingBundle.8 -e
iisreset
```
> 實際下載安裝的版本為 **`dotnet-hosting-8.0.29-win.exe`**（.NET 8.0.29）。

---

### 1.3 同一台機器多個 IIS Sites，如何讓網域指到正確站台？

**現象**：QA 主機上有多個既有 Sites，新增的 `WindowsTaskManager` 站台不確定怎麼跟其他站台區隔。

**原因**：IIS 用「IP : Port : Host Header」三者組合判斷請求要導去哪個 Site。

**解法**：使用 **Host Header（網域名稱）** 區隔，讓多個 Site 共用 Port 80：
- 需要內部 DNS 有一筆記錄，把該網域指到這台機器的 IP
- IIS 網站繫結設定 Host name 為 `windows-task-manager.my.91dev.tw`

**驗證方式**：
```powershell
Resolve-DnsName windows-task-manager.my.91dev.tw
```

---

### 1.4 Google OAuth 登入失敗：`redirect_uri_mismatch`（錯誤 400）

**現象**：網站可以開啟，點登入後導向 Google，卻顯示「已封鎖存取權：這個應用程式的要求無效，錯誤 400：redirect_uri_mismatch」。

**原因**：程式碼（`Login.cshtml.cs`）的回呼路徑是 `/LoginCallback`（**不是** ASP.NET Core 預設的 `/signin-google`）：
```csharp
var redirectUrl = Url.Page("/LoginCallback");
var properties = new AuthenticationProperties { RedirectUri = redirectUrl };
return Challenge(properties, GoogleDefaults.AuthenticationScheme);
```
瀏覽器改用 Host Header 網域存取後，實際送給 Google 的 `redirect_uri` 變成：
```
http://windows-task-manager.my.91dev.tw/LoginCallback
```
但 Google Cloud Console 的 OAuth Client 只登記了 `http://localhost:8080/LoginCallback`，兩者不符被拒。

**解法**：到 Google Cloud Console → API 和服務 → 憑證 → 編輯對應 OAuth Client → 「已授權的重新導向 URI」新增：
```
http://windows-task-manager.my.91dev.tw/LoginCallback
```
> 同一組 Client ID / Secret **可以同時登記多筆 redirect URI**（例如 localhost 測試用 + QA + Production），不需要每個環境都建立新的 OAuth Client。儲存後等 1–2 分鐘生效。

---

### 1.5 排程清單「權限不足：Access is denied (0x80070005)」

**現象**：伺服器卡片顯示「連線異常」，錯誤訊息 `權限不足：Access is denied. (0x80070005 (E_ACCESSDENIED))`。

**設定**：`appsettings.QA.json` 裡 `ServersConfig.Servers[0].IPAddress` 填的是**這台機器自己的實際 IP**（`10.51.121.152`）。

程式碼判斷邏輯（`TaskSchedulerService.cs` / `ServerService.cs`）：
```csharp
if (config.IPAddress == "localhost" || config.IPAddress == "127.0.0.1")
{
    ts = new TaskService();              // 本機模式：直接用執行身分做本機 COM 呼叫
}
else
{
    ts = new TaskService(config.IPAddress, ...);  // 遠端模式：強制走網路驗證
}
```
因為 `IPAddress` 填的是實際 IP（非 `localhost`/`127.0.0.1`），程式會走「遠端」分支，對自己這台機器做**網路方式驗證**。此時若 App Pool 執行身分權限不足（預設 `ApplicationPoolIdentity` 虛擬帳號），網路驗證這一關會直接被拒絕，顯示 `0x80070005`。

**最終採用的解法：`IPAddress` 維持填實際 IP，不改成 `localhost`；改成調整 App Pool 的執行身分（見 1.6）。**

---

### 1.6 最終解法：App Pool Identity 改為 `LocalSystem`

**現象**：即使 `IPAddress` 保持填實際 IP，只要 App Pool 執行身分權限不足，「遠端」驗證分支就會被拒絕（1.5）；就算換其他方式讓連線「不報錯」，任務列舉仍可能因權限不足而「安靜地看不到任務」，回傳總數 0。

**根本解法**：把 IIS Application Pool 的 **Identity 改成 `LocalSystem`**：

IIS 管理員 → Application Pools → 選取該 App Pool → **Advanced Settings** → **Identity** → 改為 `LocalSystem`

```powershell
Import-Module WebAdministration
Set-ItemProperty IIS:\AppPools\WindowsTaskManagerPool -Name processModel.identityType -Value LocalSystem
```

**為什麼這樣可行**：`LocalSystem` 是 Windows 內建最高權限的系統帳號，等同於這台機器的電腦帳戶身分（`NT AUTHORITY\SYSTEM`），在對自己做網路驗證時會以電腦帳戶通過驗證，同時天生擁有完整權限列舉/操作本機所有排程任務，不需要額外加入 Administrators 群組，也不受一般使用者帳號的 Loopback/權限限制影響。

**重要提醒**：變更 Identity 後一定要 Recycle App Pool 讓新設定生效：
```powershell
Restart-WebAppPool -Name "WindowsTaskManagerPool"
```

> **風險提醒**：`LocalSystem` 權限等同系統層級，攻擊面遠高於一般 Administrators 群組成員或最小權限服務帳號。QA / Production 兩個環境最終都是採用這個方式解決，若日後有資安強化需求，可考慮改為建立專屬的最小權限服務帳號 + 明確授權 Task Scheduler 存取，取代 `LocalSystem`。

---

## 2. Production 環境：問題與解法時間軸

### 2.1 appsettings.Production.json 沿用相同做法：IPAddress 維持實際 IP/網域

沿用 1.5／1.6 的最終結論：`ServersConfig.Servers[0].IPAddress` **維持填實際 IP 或網域**（不需要改成 `localhost`），存取權限問題改由 App Pool Identity 設為 `LocalSystem` 解決（見 2.7）。

---

### 2.2 這台 Production 機器發現連 IIS 都還沒安裝

**解法（UI 操作）**：伺服器管理員 (Server Manager) → 管理 → 新增角色及功能 → Server Roles 勾選 **Web Server (IIS)** → Role Services 使用預設勾選（Common HTTP Features、Health and Diagnostics 的 HTTP Logging、Performance、Security、Management Tools 的 IIS Management Console）→ 安裝。

> 精靈最後一頁若沒有勾選「自動重新啟動目的地伺服器」，**不會**自動重開機，可放心安裝。

---

### 2.3 ⚠️ 關鍵坑：Hosting Bundle 裝在 IIS 之前 → ANCM 模組沒有正確註冊

這是本次 Production 部署耗費最多時間排查的問題，完整記錄如下：

**現象**：網站可以連到（IIS 存取記錄有紀錄），但瀏覽器顯示：
```
500 - Internal server error.
There is a problem with the resource you are looking for, and it cannot be displayed.
```
從**外部瀏覽器**看不到細節（IIS 預設 `errorMode="DetailedLocalOnly"`，只有從伺服器本機瀏覽才顯示詳細錯誤）。改在**伺服器本機**瀏覽後，看到詳細錯誤：
```
Error Code   0x8007000d
Module       IIS Web Core
Config File  \\?\D:\windows-task-manager\web.config
```

**排查過程**：
1. 先怀疑是 `web.config` 的 XML 語法問題（例如少了 `stdoutLogFile` 屬性、多寫了重複的 `</aspNetCore>` 結尾標籤），逐一修正後 XML 已完全合法，但錯誤依舊存在。
2. 進一步確認 IIS 是否真的有註冊 `aspNetCore` 這個設定區段（schema）：
   ```powershell
   Test-Path "$env:windir\System32\inetsrv\config\schema\aspnetcore_schema.xml"
   ```
   結果回傳 **`False`** —— 確認 ANCM 模組根本沒有正確整合進 IIS。

**根本原因**：這台機器的操作順序是「先裝 .NET 8 Hosting Bundle → 後裝 IIS 角色」。Hosting Bundle 安裝當下 IIS 還不存在，导致它無法把 `AspNetCoreModuleV2` 模組與 `aspNetCore` 設定 schema 正確登記進 IIS 的 `applicationHost.config`。即使後來重新執行一次 Hosting Bundle 安裝程式，若不是走「修復 (repair)」流程，也不會補回這個註冊動作。

**正確解法：解除安裝後重新安裝 Hosting Bundle（在 IIS 已安裝完成之後）**
```powershell
winget uninstall --id Microsoft.DotNet.HostingBundle.8
winget install --id Microsoft.DotNet.HostingBundle.8 -e
iisreset
```

**驗證修復成功**：
```powershell
Test-Path "$env:windir\System32\inetsrv\config\schema\aspnetcore_schema.xml"
# 應回傳 True
```

> **關鍵教訓**：**IIS 角色必須先安裝完成，Hosting Bundle 一定要在 IIS 裝好「之後」才安裝**，順序顛倒會導致模組沒有正確註冊，且不容易從錯誤訊息直接看出原因（0x8007000d 這個錯誤代碼本身沒有明確指向「模組未註冊」，需要額外用 `Test-Path` 驗證 schema 檔案才能確認）。

---

### 2.4 web.config 編輯過程中的兩個 XML 錯誤（附帶記錄，供對照）

在排查 2.3 的過程中，手動編輯 `web.config` 時曾出現以下兩個問題，雖然不是最終根因，但也會造成同樣的 `0x8007000d`，修正的方式一併記錄：

1. **重複的結尾標籤**：
   ```xml
   </environmentVariables>      </aspNetCore></aspNetCore>    </system.webServer>
   ```
   多寫了一個 `</aspNetCore>`，需要刪除其中一個，確保開始/結尾標籤數量對稱。

2. **`stdoutLogEnabled="true"` 卻沒有搭配 `stdoutLogFile` 屬性**：
   IIS 的 `aspNetCore` schema 規定只要開啟 `stdoutLogEnabled`，就必須同時指定 `stdoutLogFile`，否則設定驗證會失敗。
   ```xml
   <aspNetCore processPath="dotnet"
               arguments=".\WindowsTaskManager.dll"
               stdoutLogEnabled="true"
               stdoutLogFile=".\logs\stdout"
               hostingModel="inprocess">
   ```

**額外提醒**：`.\logs` 資料夾 IIS **不會自動建立**，需手動建立並給予寫入權限：
```powershell
New-Item -ItemType Directory -Path "D:\windows-task-manager\logs" -Force
icacls "D:\windows-task-manager\logs" /grant "IIS AppPool\WindowsTaskManagerProdPool:(OI)(CI)F"
```

---

### 2.5 IIS 預設只在「本機」顯示詳細錯誤

**現象**：即使在 `web.config` 加上 `ASPNETCORE_DETAILEDERRORS=true`，外部瀏覽器仍只顯示通用的「500 - Internal server error」訊息。

**原因**：IIS 的 `httpErrors` 預設 `errorMode="DetailedLocalOnly"`——只有「從伺服器本機瀏覽」才會顯示詳細錯誤內容，遠端一律顯示通用訊息（避免對外洩漏堆疊資訊，這是安全機制）。

**解法**：診斷時改用 **遠端桌面連進主機、在主機本機瀏覽器**開啟網址（`http://localhost` 或實際網域），才能看到詳細錯誤頁面（含 `Error Code`、`Module`、`Config File` 等資訊）。

---

### 2.6 如何確認外部請求真的有打到這台機器（而非 DNS/繫結問題）

排查 500 錯誤前，建議先排除「根本沒連到這台機器」的可能性：

1. **確認 DNS 解析**：`Resolve-DnsName <網域>` 比對是否為本機 IP
2. **查 IIS 存取記錄**：`C:\inetpub\logs\LogFiles\W3SVC<id>\`，確認有無對應時間的請求紀錄
3. **放置測試檔案**：在 `wwwroot` 底下建立一個含 hostname 的 txt 檔，外部瀏覽器直接開啟驗證
4. **本機模擬外部 Host Header**：
   ```powershell
   Invoke-WebRequest -Uri "http://localhost" -Headers @{Host="<網域>"} -UseBasicParsing
   ```

---

### 2.7 最終解法：App Pool Identity 改為 LocalSystem（跟 QA 一致）

沿用 1.6 的結論，Production 的 `ServersConfig.Servers[].IPAddress` **維持填實際 IP/網域**，把 App Pool Identity 改為 `LocalSystem` 解決存取權限問題：
```powershell
Set-ItemProperty IIS:\AppPools\WindowsTaskManagerProdPool -Name processModel.identityType -Value LocalSystem
Restart-WebAppPool -Name "WindowsTaskManagerProdPool"
```
> QA 與 Production 兩個環境最終都是以此方式解決存取問題，未改用 `localhost` 設定。

---

## 3. 完整正確部署 SOP（去蕪存菁版，供下次直接照做）

1. **安裝 IIS 角色**（伺服器管理員 → 新增角色及功能 → Web Server (IIS)）
2. **確認 IIS 安裝完成後，才安裝 .NET 8 ASP.NET Core Hosting Bundle**
   ```powershell
   winget install --id Microsoft.DotNet.HostingBundle.8 -e
   iisreset
   ```
3. **驗證 ANCM 模組正確註冊**：
   ```powershell
   Test-Path "$env:windir\System32\inetsrv\config\schema\aspnetcore_schema.xml"   # 應為 True
   ```
4. **`dotnet publish`** 專案，並將 `publish` 資料夾複製到目標主機
5. **確認 appsettings.{Environment}.json 裡 `ServersConfig.Servers[].IPAddress`**：填實際 IP 或網域即可（不需要改成 `localhost`），存取權限問題改由步驟 7 的 App Pool Identity 設定解決
6. **建立 Application Pool**：.NET CLR Version = No Managed Code，Start Mode = AlwaysRunning
7. **將 App Pool Identity 改為 `LocalSystem`**（讓 App Pool 有權限做網路自我驗證並列舉本機排程任務）：
   ```powershell
   Set-ItemProperty IIS:\AppPools\<PoolName> -Name processModel.identityType -Value LocalSystem
   ```
   > 風險提醒：`LocalSystem` 權限等同系統層級，若有資安強化需求，可評估改用最小權限服務帳號並明確授權 Task Scheduler 存取。
8. **建立網站**：Physical Path 指向 publish 資料夾，Binding 用 **Host Header** 綁定對應網域（同機多站台不衝突）
9. **建立 logs 資料夾並給寫入權限**：
   ```powershell
   New-Item -ItemType Directory -Path "<publish路徑>\logs" -Force
   icacls "<publish路徑>\logs" /grant "IIS AppPool\<PoolName>:(OI)(CI)F"
   icacls "<publish路徑>" /grant "IIS AppPool\<PoolName>:(OI)(CI)RX"
   ```
10. **確認 web.config**：`stdoutLogEnabled` 若為 `true` 必須搭配 `stdoutLogFile`；標籤需完整配對，避免手動編輯造成 XML 錯誤
11. **執行 `setup.ps1`**（系統管理員身分），Scope 選 `Machine`
12. **Google OAuth**：到 Google Cloud Console 新增對應網域的 `/LoginCallback` 回呼 URL（可與其他環境共用同一組 Client）
13. **Recycle App Pool 讓所有設定生效**：
    ```powershell
    Restart-WebAppPool -Name "<PoolName>"
    ```
14. **驗證**：
    - DNS 解析正確指向本機
    - IIS 存取記錄有進站紀錄
    - 網站首頁可開啟，登入流程正常
    - 伺服器卡片顯示「連線正常」且任務數量非 0、非隨機亂數

---

## 4. 安全性提醒

1. **appsettings.*.json 內若填入帳密／Client Secret，不應提交進版控**，考慮加入 `.gitignore` 或改用機器層級環境變數（`setup.ps1` 提供的方式）
2. **診斷用的 `ASPNETCORE_DETAILEDERRORS=true` 與 IIS `httpErrors errorMode="Detailed"` 僅供臨時排查使用，確認問題後務必移除**，避免正式站長期對外暴露詳細例外堆疊
3. **一旦任何密碼／Client Secret 曾經明碼出現在聊天記錄、Log、Email 等非受控管道，應盡快到來源（如 Google Cloud Console）重新產生（Reset）新的一組**，視為已外洩處理
4. **App Pool Identity 選用 `LocalSystem` 屬於權限最大化做法**，QA 與 Production 兩環境目前皆採用此方式解決存取問題；日後如有資安強化需求，建議評估改為「加入 Administrators 群組」或更精細的最小權限帳號設計

---

## 5. 常用診斷指令速查

```powershell
# 確認 Hosting Bundle / ASP.NET Core 版本
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Where-Object { $_.DisplayName -like "*Hosting Bundle*" -or $_.DisplayName -like "*ASP.NET Core*" } |
  Select-Object DisplayName, DisplayVersion

# 確認 ANCM 模組是否正確註冊進 IIS
Test-Path "$env:windir\System32\inetsrv\config\schema\aspnetcore_schema.xml"

# 確認目前環境變數（Machine 層級）
[System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Machine")
[System.Environment]::GetEnvironmentVariable("Authentication__Google__ClientId", "Machine")

# 確認 App Pool Identity 目前設定
Get-ItemProperty IIS:\AppPools\<PoolName> -Name processModel.identityType

# 設定 App Pool Identity 為 LocalSystem
Set-ItemProperty IIS:\AppPools\<PoolName> -Name processModel.identityType -Value LocalSystem

# Recycle App Pool
Restart-WebAppPool -Name "<PoolName>"

# 確認 DNS 解析
Resolve-DnsName <網域>

# 查最新的 IIS 存取記錄
Get-ChildItem "C:\inetpub\logs\LogFiles" -Recurse -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# 本機模擬外部 Host Header 請求
Invoke-WebRequest -Uri "http://localhost" -Headers @{Host="<網域>"} -UseBasicParsing

# 查詢實際排程任務（跟 App 顯示結果比對）
Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft\*" } | Select-Object TaskName, TaskPath, State
```

---

## 6. 相關文件

- `iis-reverse-proxy-windows-task-manager.md` — 原理說明與標準部署流程（本文件為其補充的「實戰疑難排解記錄」）
- 專案內：`DEPLOYMENT-IIS.md`、`ENVIRONMENT-CONFIGURATION.md`、`AUTHENTICATION.md`、`README.md`
