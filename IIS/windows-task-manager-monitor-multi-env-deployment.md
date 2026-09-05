# WindowsTaskManager.Monitor 多環境（HKQA / MYQA）部署設定指南

> 專案：`WindowsTaskManager.Monitor`（Windows 服務，ServiceName：`WindowsTaskManager.Monitor`）
> 本文件整理讓 Monitor 這支背景服務比照 Web 站台，支援 **HKQA / MYQA 雙機部署**所需的完整設定與步驟。
> 前提知識請先參考：`iis-environment-variable-priority-troubleshooting.md`（環境變數優先權 §7 案例）。

---

## 0. 背景說明：Monitor 跟 Web 站台的關鍵差異

| 項目 | WindowsTaskManager（Web） | WindowsTaskManager.Monitor |
|---|---|---|
| 執行方式 | IIS App Pool / w3wp.exe | Windows 服務（`sc.exe` 安裝） |
| Host 類型 | ASP.NET Core `WebApplication` | .NET Generic Host / Worker Service（`Host.CreateApplicationBuilder`） |
| 決定環境的環境變數 | `ASPNETCORE_ENVIRONMENT` | **`DOTNET_ENVIRONMENT`**（Generic Host 不吃 `ASPNETCORE_ENVIRONMENT`） |
| 環境變數設定位置 | App Pool 專屬環境變數（`applicationHost.config`） | 服務專屬登錄檔（`HKLM:\SYSTEM\CurrentControlSet\Services\<服務名稱>\Environment`） |
| 對應設定檔 | `appsettings.HKQA.json` / `appsettings.MYQA.json` | `appsettings.HKQA.json` / `appsettings.MYQA.json`（Monitor 專案下另一份，內容不同） |

兩者都是同一個根本原理：**機器層級環境變數只在「行程被建立時」繼承一次，服務/IIS 若在變數設定前就已啟動，不會自動感知**。所以都改用「該服務/該 App Pool 專屬」的設定方式來避免這個坑。

---

## 1. 程式碼面已完成的變更（免再處理）

1. `src/WindowsTaskManager.Monitor/appsettings.HKQA.json`
   ```json
   {
     "EtlConfig": { "LogRootPath": "E:\\Files\\OsmConsole\\" },
     "SlackOptions": {
       "Market": "HK",
       "Environment": "HKQA",
       "WebsiteBaseUrl": "http://windows-task-manager.hk.91dev.tw"
     }
   }
   ```
2. `src/WindowsTaskManager.Monitor/appsettings.MYQA.json`
   ```json
   {
     "EtlConfig": { "LogRootPath": "E:\\Files\\OsmConsole\\" },
     "SlackOptions": {
       "Market": "MY",
       "Environment": "MYQA",
       "WebsiteBaseUrl": "http://windows-task-manager.my.91dev.tw"
     }
   }
   ```
   > 兩個 SDK（Web / Worker）都會自動把 `appsettings*.json` 當 Content 複製到 publish 輸出目錄，**不需要**在 `.csproj` 額外加設定。
3. `.github/workflows/deploy.yml`：
   - `build` job：Web、Monitor 兩個專案**分開** `dotnet publish` 到 `./publish_output/web`、`./publish_output/monitor`，避免混在同一個資料夾互相覆蓋。
   - 分別上傳成 `dotnet-web-package`、`dotnet-monitor-package` 兩個 artifact。
   - 新增 `deploy-monitor` job（matrix 展開 HKQA/MYQA），流程改成 `Stop-Service -> 複製檔案 -> Start-Service`（若該機器尚未安裝過服務，會自動跳過 Stop/Start，只複製檔案，方便首次導入）。
   - 部署路徑：`$targetPath = "D:\windows-task-manager\worker"`，服務名稱：`$serviceName = "WindowsTaskManager.Monitor"`。

以上都已經在 repo 裡，push 後 workflow 就會自動建置並複製檔案到兩台機器的 `D:\windows-task-manager\worker`。

---

## 2. 機器端要做的事（一次性設定，程式碼管不到）

### 2.1 HKQA 機器（服務已存在，只需要「補設定」環境變數）

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WindowsTaskManager.Monitor" -Name Environment -PropertyType MultiString -Value @("DOTNET_ENVIRONMENT=HKQA") -Force; Restart-Service -Name "WindowsTaskManager.Monitor"
```

驗證：
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WindowsTaskManager.Monitor" -Name Environment | Select-Object -ExpandProperty Environment
```

### 2.2 MYQA 機器（服務尚未安裝過，需完整走一次安裝流程）

**步驟 1：先讓 workflow 把檔案送到機器上**
Push 一次程式碼（或手動觸發 `workflow_dispatch`），確認 `deploy-monitor` job 針對 MYQA 那筆成功執行完（因為服務還不存在，該筆會自動跳過 Stop/Start，只複製檔案），完成後 `D:\windows-task-manager\worker` 底下應該會出現 `WindowsTaskManager.Monitor.exe` 等檔案。

**步驟 2：安裝成 Windows 服務**（帳戶比照 HKQA，使用 `LocalSystem`）
```powershell
sc.exe create "WindowsTaskManager.Monitor" binPath= "D:\windows-task-manager\worker\WindowsTaskManager.Monitor.exe" start= auto obj= LocalSystem
```

**步驟 3：設定服務專屬環境變數**（決定讀取 `appsettings.MYQA.json`）
```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WindowsTaskManager.Monitor" -Name Environment -PropertyType MultiString -Value @("DOTNET_ENVIRONMENT=MYQA") -Force
```

**步驟 4：啟動並驗證**
```powershell
Start-Service -Name "WindowsTaskManager.Monitor"; Get-Service -Name "WindowsTaskManager.Monitor"
```

安裝完成後，之後每次 push 部署，`deploy-monitor` job 都會偵測到服務已存在，改用正常的 `Stop-Service -> 複製 -> Start-Service` 流程。

---

## 3. 驗證方式

1. **確認服務狀態**：
   ```powershell
   Get-Service -Name "WindowsTaskManager.Monitor"
   ```
2. **確認實際生效的環境**：查看服務登入紀錄檔（Serilog 輸出），確認 log 檔頭或 Slack 告警訊息中帶的 Market/Environment 是否正確（HKQA 應為 `HK`/`HKQA`，MYQA 應為 `MY`/`MYQA`）：
   ```powershell
   Get-Content "D:\windows-task-manager\worker\logs\monitor-$(Get-Date -Format yyyyMMdd).log" -Tail 50
   ```
3. **確認 Slack 告警訊息**：若有觸發測試告警，訊息內的網址（`WebsiteBaseUrl`）跟市場標示應對應該台機器（HKQA → hk 網域，MYQA → my 網域）。

---

## 4. 常見問題排查

| 現象 | 可能原因 | 解法 |
|---|---|---|
| 服務啟動後設定還是舊的 / 沒切換 | 登錄檔 `Environment` 值沒設定成功，或設定後沒重啟服務 | 重新執行 §2 的登錄檔指令 + `Restart-Service` |
| `Stop-Service`/`sc.exe create` 顯示服務不存在 | 該機器第一次導入，服務還沒裝 | 依 §2.2 走完整安裝流程 |
| `deploy-monitor` job 執行失敗，找不到 `D:\windows-task-manager\worker` 路徑內容 | `deploy-monitor` job 還沒成功跑過一次 | 檢查 GitHub Actions 該台機器（self-hosted runner label `hkqa`/`myqa`）是否上線，重新觸發 workflow |
| appsettings 沒切換，仍讀到預設值 | 服務登錄檔 `Environment` 用的變數名稱打錯（例如誤用 `ASPNETCORE_ENVIRONMENT`） | Monitor 是 Generic Host，必須用 **`DOTNET_ENVIRONMENT`**，不是 `ASPNETCORE_ENVIRONMENT` |

---

## 5. 相關文件

- `iis-environment-variable-priority-troubleshooting.md` — 環境變數優先權與服務快照問題的完整原理（§7 為本次 Monitor 案例的前置知識）
- `windows-task-manager-deployment-troubleshooting.md` — QA / Production 完整部署疑難排解記錄
