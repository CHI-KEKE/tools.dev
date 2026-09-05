# IIS 基礎知識

## IIS 核心概念

### Site（站台）
IIS 裡的一個獨立網站，有自己的：
- **Binding**：監聽的 IP、Port、Host Header（例如 `api.dev.91dev.tw:80`）
- **Physical Path**：實體資料夾路徑（例如 `C:\91APP\SCMAPIV2\...`）
- **Application Pool**：執行這個站台的 worker process

### Application Pool（應用程式集區）
每個站台有自己的 App Pool，是一個獨立的 w3wp.exe worker process。

**重要：改了程式碼 build 完，IIS 不會自動重載，需要手動 Recycle App Pool。**

```powershell
# Recycle App Pool
powershell.exe -Command "Import-Module WebAdministration; Restart-WebAppPool 'NineYi.Api'"
```

### Virtual Application（虛擬應用程式）
IIS 裡的 URL 路徑對應，**不是實體資料夾**，是設定對應關係：

```
URL 路徑          →  實體資料夾
/             →  C:\91APP\SCMAPIV2\...  (根站台)
/SCM/V1       →  C:\91APP\NineYi.Scm.Api\...
/SCM/V2       →  C:\91APP\NineYi.Scm.ApiV2\...
```

在 IIS Manager 樹狀圖裡，虛擬應用程式會顯示**地球圖示 🌐**，一般資料夾是資料夾圖示。

---

## 常用 PowerShell 指令

### 查詢站台清單
```powershell
powershell.exe -Command "Import-Module WebAdministration; Get-Website | Select-Object Name, State, PhysicalPath"
```

### 查詢虛擬應用程式
```powershell
powershell.exe -Command "Import-Module WebAdministration; Get-WebApplication -Site 'NineYi.Api' | Select-Object Path, PhysicalPath | Format-Table"
```

### 修改虛擬應用程式的 Physical Path
```powershell
powershell.exe -Command "
  Import-Module WebAdministration
  Set-ItemProperty 'IIS:\Sites\NineYi.Api\SCM\V2' -Name physicalPath -Value 'C:\新路徑\WebSite\WebSite'
  Write-Host 'Done'
"
```

### Recycle App Pool
```powershell
powershell.exe -Command "Import-Module WebAdministration; Restart-WebAppPool 'NineYi.Api'"
```

### 查詢站台的 Binding
```powershell
powershell.exe -Command "Import-Module WebAdministration; (Get-Website 'NineYi.Api').Bindings.Collection | Select-Object protocol, bindingInformation"
```

---

## IIS Manager UI 操作

### 查看虛擬應用程式
1. 點選站台（例如 `NineYi.Api`）
2. 右側 Actions 面板 → **View Applications**
3. 可以看到所有虛擬應用程式的路徑與 Physical Path

### 修改虛擬應用程式 Physical Path
1. View Applications 裡找到目標路徑（例如 `/SCM/V2`）
2. 點一下選取 → 右鍵 → **Basic Settings...**
3. 修改 **Physical path** 欄位
4. 按 OK

> ⚠️ 若在樹狀圖裡找不到地球圖示，改用右側的「View Applications」

---

## web.config 繼承問題

### 問題場景
當一個應用程式（子）掛在另一個應用程式（父）底下時，**子會繼承父的 web.config**。

若父子都有相同的模組設定（例如 ELMAH），會發生：
```
無法新增類型 'add'，名稱 'ErrorLog' 重複
```

### 解法：子 web.config 先 remove 再 add
```xml
<modules>
  <remove name="ErrorLog" />
  <add name="ErrorLog" type="Elmah.ErrorLogModule, Elmah" preCondition="managedHandler" />
  <remove name="ErrorMail" />
  <add name="ErrorMail" type="Elmah.ErrorMailModule, Elmah" preCondition="managedHandler" />
</modules>
```

### configSource 衝突
```
configSource 檔 'bin\AppSettings.config' 也使用於它的父代。這是不允許的情況。
```
**原因：** 父子站台指向**同一個實體資料夾**，共用同一個 web.config，導致 configSource 被解析兩次。

**解法：** 父子不能指向同一個實體路徑，需分開。

---

## 本機開發環境（91APP SCMAPIV2）

### 站台對應關係
| 站台 | URL | 實體路徑 |
|------|-----|---------|
| NineYi.Api（根） | `http://api.dev.91dev.tw/` | `C:\91APP\SCMAPIV2\nineyi.scm.apiv2\WebSite\WebSite` |
| /SCM/V1 | `http://api.dev.91dev.tw/SCM/V1/` | `C:\91APP\NineYi.Scm.Api\SCM\Api\WebApi` |
| /SCM/V2 | `http://api.dev.91dev.tw/SCM/V2/` | `C:\91APP\NineYi.Scm.ApiV2\WebSite\WebSite` |

### ⚠️ 本機開發注意事項
- `NineYi.Api` 根站台就是 SCMAPIV2，**不需要帶 `/scm/V2` 前綴**
- 本機打 API 直接用：`http://api.dev.91dev.tw/Promotion/CreatePromotion`
- QA/Prod 才需要帶 `/scm/V2`

### 認證方式（Dev 模式）
本機是 Dev 模式（`AppSettings.config` 裡 `Execmode = Dev`），用 query string 帶 token：
```
http://api.dev.91dev.tw/Promotion/CreatePromotion?t={token}
```

---

## Build SCMAPIV2

SCMAPIV2 是 **.NET Framework 4.6.2**，不能用 `dotnet build`，要用 MSBuild：

```powershell
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
& $msbuild "C:\91APP\SCMAPIV2\nineyi.scm.apiv2\NineYi.Scm.ApiV2.sln" /p:Configuration=Debug /t:Build
```

> Build 完記得 Recycle App Pool，否則 IIS 不會載入新 DLL。
