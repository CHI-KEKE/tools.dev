# IIS / ASP.NET Core 環境變數優先權排查記錄：QA 機器一直讀到 appsettings.Development.json

> 專案：`WindowsTaskManager`（App Pool：`WindowsTaskManagerPool`）
> 本文件記錄「機器層級環境變數設定正確，但網站行為仍不對」的完整排查過程與根本原因，
> 可作為日後遇到類似「環境變數設了沒生效」問題的檢查清單。
> 案例一：`ASPNETCORE_ENVIRONMENT` 讀到錯誤環境（§1~6）；案例二：多機（HKQA/MYQA）Google OAuth `Authentication__Google__ClientSecret` 造成 `invalid_client`（§7）。

---

## 1. 現象

QA 機器上網站行為明顯是吃到 `appsettings.Development.json` 的設定值，而不是預期的 `appsettings.QA.json`。

用 PowerShell 確認過機器層級與目前 Process 層級的環境變數，看起來都已經是 `QA`：

```powershell
[System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Machine")   # QA
[System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Process")   # QA
```

設定看起來正確，但網站仍讀取到 Development 設定 —— 代表問題出在「環境變數的優先權層級」，而不是變數本身沒設定。

---

## 2. 排查步驟

### 步驟 1：如何正確設定機器層級環境變數

```powershell
[System.Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "QA", "Machine")
```
> 注意：`Target` 一定要選 `Machine`（需系統管理員權限）。選 `User` 的話，IIS App Pool 是用系統服務身分執行，讀不到使用者層級的環境變數。

### 步驟 2：檢查發佈出來的 `web.config` 是否寫死環境變數

ASP.NET Core 發佈時，若專案 csproj 有 `<EnvironmentName>` 設定，`dotnet publish` 會把值寫死進 `web.config` 的 `<aspNetCore><environmentVariables>` 區塊，這個設定的優先權**高於**機器層級環境變數：

```powershell
Get-Content "D:\windows-task-manager\web.config" -Raw
```

本次確認 `<aspNetCore>` 底下**沒有**額外寫死 `environmentVariables`，排除此可能性。

### 步驟 3：一度懷疑是服務行程的環境變數快照過舊

理論：Windows 服務（IIS 的 WAS / W3SVC）是在開機或服務啟動當下，就把環境變數「快照」進自己的行程記憶體；事後修改機器層級環境變數，服務不會自動感知（不像 `explorer.exe` 會收到 `WM_SETTINGCHANGE` 廣播）。

理論上的解法是 `iisreset`，但這會讓機器上**所有網站**一起重啟，風險太大。因此**先不執行 `iisreset`**，改用更精準的方式繼續排查根因。

### 步驟 4（找到真正根因）：檢查 App Pool 自己有沒有專屬的環境變數設定

IIS 10.0（Windows Server 2019 / 2022）支援在 **App Pool 層級**直接設定環境變數（寫在 `applicationHost.config`），這個設定的優先權**高於**機器層級環境變數，且是 WAS 在啟動該 App Pool 的 `w3wp.exe` 當下直接讀設定檔給值，完全不受服務行程環境快照影響：

```powershell
Get-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables/add[@name='ASPNETCORE_ENVIRONMENT']" -PSPath "MACHINE/WEBROOT/APPHOST" | Select-Object name, value
```

結果發現這個 App Pool **本身就已經被設定 `ASPNETCORE_ENVIRONMENT = Development`** —— 這才是真正的根本原因，跟機器層級環境變數、服務快照都無關。

---

## 3. 解法

直接修改 App Pool 專屬的環境變數值為 `QA`，並只重啟這個 App Pool（不影響機器上其他網站）：

```powershell
Set-WebConfigurationProperty -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables/add[@name='ASPNETCORE_ENVIRONMENT']" -PSPath "MACHINE/WEBROOT/APPHOST" -Name "value" -Value "QA"

Stop-WebAppPool -Name "WindowsTaskManagerPool"
Start-Sleep -Seconds 2
Start-WebAppPool -Name "WindowsTaskManagerPool"
```

> 若該 App Pool 原本**沒有**設定過 `ASPNETCORE_ENVIRONMENT`（新機器 / 新 Pool 第一次設定），改用 `Add-WebConfiguration` 新增：
> ```powershell
> Add-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables" -PSPath "MACHINE/WEBROOT/APPHOST" -Value @{name="ASPNETCORE_ENVIRONMENT"; value="QA"}
> Stop-WebAppPool -Name "WindowsTaskManagerPool"; Start-Sleep -Seconds 2; Start-WebAppPool -Name "WindowsTaskManagerPool"
> ```
> 若已存在同名項目再執行 `Add-WebConfiguration`，會出現：
> ```
> Cannot add duplicate collection entry of type 'add' with unique key attribute 'name' set to 'ASPNETCORE_ENVIRONMENT'
> ```
> 這個錯誤訊息正是判斷「該用 `Add` 還是 `Set`」的關鍵訊號，也是本次能定位到 App Pool 已有既存設定的關鍵線索。

**驗證**：重新查詢確認值已變成 `QA`，並重新整理網站確認實際讀取的是 `appsettings.QA.json` 的內容。

---

## 4. ASP.NET Core 環境變數優先權總結

依優先權由高到低：

1. **App Pool 專屬環境變數**（`applicationHost.config` 裡的 `environmentVariables`）— 優先權最高，且最容易被忽略
2. **`web.config` 內寫死的 `<aspNetCore><environmentVariables>`**（來自 csproj 的 `<EnvironmentName>`）
3. **機器層級環境變數**（`SetEnvironmentVariable` + `Target=Machine`）
4. 使用者層級環境變數（IIS 服務身分讀不到，通常無效）

---

## 5. 排查優先順序建議（教訓）

往後遇到「環境變數設對了，但網站行為不對」，建議依下列順序檢查，**不要一開始就跳去 `iisreset`**（會影響全機所有網站）：

1. 機器層級環境變數是否真的設定成功
2. 發佈出來的 `web.config` 有沒有寫死環境變數
3. **App Pool 專屬環境變數**（最容易被忽略，本次案例的根本原因）
4. 真的都排除了，才考慮 `iisreset` 或重開機（服務環境快照問題）

---

## 6. 常用診斷指令速查

```powershell
# 查詢機器層級環境變數
[System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Machine")

# 查詢 App Pool 專屬環境變數（優先權最高）
Get-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='<PoolName>']/environmentVariables/add[@name='ASPNETCORE_ENVIRONMENT']" -PSPath "MACHINE/WEBROOT/APPHOST" | Select-Object name, value

# 修改 App Pool 專屬環境變數（已存在時使用 Set）
Set-WebConfigurationProperty -Filter "/system.applicationHost/applicationPools/add[@name='<PoolName>']/environmentVariables/add[@name='ASPNETCORE_ENVIRONMENT']" -PSPath "MACHINE/WEBROOT/APPHOST" -Name "value" -Value "<Environment>"

# 新增 App Pool 專屬環境變數（尚未存在時使用 Add）
Add-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='<PoolName>']/environmentVariables" -PSPath "MACHINE/WEBROOT/APPHOST" -Value @{name="ASPNETCORE_ENVIRONMENT"; value="<Environment>"}

# 只重啟單一 App Pool（不影響其他網站）
Stop-WebAppPool -Name "<PoolName>"; Start-Sleep -Seconds 2; Start-WebAppPool -Name "<PoolName>"

# 檢查發佈出來的 web.config 有沒有寫死環境變數
Get-Content "<發佈路徑>\web.config" -Raw
```

---

## 7. 案例二：多機（HKQA / MYQA）環境下 Google OAuth `invalid_client`

### 7.1 現象

專案擴充成同時部署到 **HKQA**、**MYQA** 兩台機器後，`appsettings.HKQA.json` / `appsettings.MYQA.json` 內的 `Authentication.Google.ClientId` / `ClientSecret` 皆刻意留空，改用環境變數在執行期間覆蓋機敏資訊：

```
Authentication__Google__ClientId
Authentication__Google__ClientSecret
```

MYQA 機器登入 Google 時，log 出現：

```
OAuth token endpoint failure: invalid_client; Description=The provided client secret is invalid.
```

而 **HKQA 用同一組 ClientId/ClientSecret 登入正常**，代表憑證本身沒問題，問題出在 MYQA 這台機器沒有正確把值傳給程式。

### 7.2 排查步驟

1. **確認機器層級環境變數是否存在、長度是否正確**（避免複製貼上多了空白或被截斷）：
   ```powershell
   ([System.Environment]::GetEnvironmentVariable("Authentication__Google__ClientSecret","Machine")).Length
   ```
   本次結果為 `35`，跟正確值字元數一致，先排除「值本身壞掉」的可能。

2. **確認沒有 User 層級變數蓋掉 Machine 層級**（User 層級在某些帳戶情境下也會被合併進行程環境）：
   ```powershell
   [System.Environment]::GetEnvironmentVariable("Authentication__Google__ClientSecret","User")
   ```
   結果為空，排除。

3. **改用 App Pool 專屬環境變數**（同 §1~§4 的根本解法，優先權最高、不受服務環境快照影響）：
   ```powershell
   Add-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables" -PSPath "MACHINE/WEBROOT/APPHOST" -Value @{name="Authentication__Google__ClientId"; value="<ClientId>"}
   Add-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables" -PSPath "MACHINE/WEBROOT/APPHOST" -Value @{name="Authentication__Google__ClientSecret"; value="<ClientSecret>"}
   Stop-WebAppPool -Name "WindowsTaskManagerPool"; Start-Sleep -Seconds 2; Start-WebAppPool -Name "WindowsTaskManagerPool"
   ```
   若出現 `Cannot add duplicate collection entry...`，代表 App Pool 底下**已經有**這個項目了（可能之前手動加過），改用 `Get-WebConfiguration` 確認現有值，再視情況用 `Set-WebConfigurationProperty` 修正：
   ```powershell
   Get-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables/add" -PSPath "MACHINE/WEBROOT/APPHOST" | Select-Object name, value

   Set-WebConfigurationProperty -Filter "/system.applicationHost/applicationPools/add[@name='WindowsTaskManagerPool']/environmentVariables/add[@name='Authentication__Google__ClientSecret']" -PSPath "MACHINE/WEBROOT/APPHOST" -Name "value" -Value "<ClientSecret>"
   ```

4. **確認 App Pool 目前狀態並啟動**（若前面指令曾因例外導致 Pool 停在 Stopped 狀態）：
   ```powershell
   Start-WebAppPool -Name "WindowsTaskManagerPool"
   ```

### 7.3 根本原因

跟 §1 的 `ASPNETCORE_ENVIRONMENT` 案例**同一個底層機制**：機器層級環境變數只在「行程被建立時」繼承一次，`w3wp.exe` 是由 **WAS 服務**衍生出來的子行程，WAS 本身早在開機/上次啟動時就把環境變數快照住了，之後改機器層級變數、單純重啟 App Pool 都不會讓新行程拿到新值，只有 `iisreset` 或重開機才會刷新。

**只要是跨機器共用、且不方便 `iisreset` 全機重啟的機敏設定（ClientId/ClientSecret 之類），一律改用「App Pool 專屬環境變數」，不要依賴機器層級環境變數。**

### 7.4 額外提醒：Secret 若曾經 commit 進 git，視為已外洩

本次是從 git history 中找回舊的 `ClientId`/`ClientSecret`（曾在早期 commit 明文寫在 `appsettings.json`，後續才改成留空 + 環境變數注入）。即使檔案後來改乾淨了，**只要曾經 commit 過，這組 Secret 就該視為外洩**，建議：
- 到 Google Cloud Console 確認/輪替（Rotate）一組新的 ClientSecret
- 之後永遠只透過 App Pool / 機器環境變數注入，不再寫進任何會被 commit 的檔案

---

## 8. 相關文件

- `windows-task-manager-deployment-troubleshooting.md` — QA / Production 完整部署疑難排解記錄
- `iis-reverse-proxy-windows-task-manager.md` — 原理說明與標準部署流程
