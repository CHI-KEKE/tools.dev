



### Build：編譯，不等於部署

Build 的核心是：**MSBuild 讀取 `.sln` / `.csproj`，找出專案間的先後順序，載入專案指定的建置規則，再編譯、複製輸出。** 規則也可能包含產生程式碼、處理資源檔及執行自訂工作。Build 成功表示指定條件下能編譯，**不保證測試通過、網站已啟動或目標環境可部署**。

#### `dotnet build` 與 Visual Studio `MSBuild.exe` 是什麼關係？

兩者都使用 **MSBuild 建置技術**，不是兩套毫無關係的語言編譯器；差別是**由哪個執行環境啟動，以及該環境具備哪些建置元件**：

| 指令入口 | 使用的建置環境 | 對這兩個專案的意義 |
| --- | --- | --- |
| `dotnet build` | .NET SDK 內的 MSBuild；一般 SDK 專案預設先 restore | 可載入 Livebuy 指定的 `Microsoft.NET.Sdk.Web` 規則 |
| Visual Studio 的 `MSBuild.exe` | Visual Studio 提供的 .NET Framework 版 MSBuild 與安裝的建置元件 | 可使用 SCM ApiV2 傳統 ASP.NET Web Application 所依賴的網站編譯工具 |

`Microsoft.NET.Sdk.Web` 是**專案 SDK，不是一般 NuGet 套件，也不是 Web Server**。Livebuy API 的 `.csproj` 第一行指定它，目標框架是 `net8.0`；`dotnet build` 啟動 SDK 內的 MSBuild，MSBuild 再載入該 SDK 的屬性與 targets，依 `ProjectReference` 建置相依專案，最後產生 API 的組件。`dotnet build` 大致相當於 `dotnet msbuild -restore`，所以還原通常包含在這次操作中。

```text
Livebuy .csproj：Sdk="Microsoft.NET.Sdk.Web" + TargetFramework=net8.0
    → dotnet build
    → .NET SDK 內的 MSBuild 載入 Web SDK 規則
    → restore（需要時）→ 建置相依專案 → 編譯 API
```

SCM ApiV2 的 Web 入口則是舊式 `.csproj`，目標 `v4.6.2`，匯入 `Microsoft.WebApplication.targets`，並使用 `System.Web`、`Global.asax`。這個網站模型**執行時**由 IIS／IIS Express 承載；它選擇 Visual Studio `MSBuild.exe` 的直接原因，則是**建置時**需要傳統 ASP.NET 的 Web Application targets 與 .NET Framework 版 ASP.NET 編譯工具，並非「凡是用 IIS 就必須用 `MSBuild.exe`」。Microsoft 對用 `dotnet` 建置這類網站的 `MSB4249` 錯誤有明確說明。

這裡要分清**專案型態**與**直接的工具限制**。採用傳統 ASP.NET Web Application 是上游原因：它需要網站專屬的編譯、內容處理等行為；`.csproj` 因此匯入 `Microsoft.WebApplication.targets` 等規則。這些規則及其使用的 .NET Framework 版 ASP.NET 編譯工具，才是目前不能直接用 `dotnet build` 取代的技術原因。專案檔沒有一個單純寫著「只能用 VS MSBuild」的開關。

```text
傳統 ASP.NET Web Application（專案型態）
    → 需要網站專屬建置行為
    → .csproj 匯入 WebApplication.targets 等規則
    → 規則需要 Visual Studio／.NET Framework 版建置工具
```

所以**刪掉 `WebApplication.targets` 的匯入，不等於完成工具轉換**：如果原本的網站編譯或內容處理行為隨之消失，即使某次編譯成功，也不能據此認定網站能照常啟動與發布。要改用另一套建置入口，必須先找出並保留或替代這些行為，再實際驗證。

```text
SCM ApiV2 .csproj：傳統 ASP.NET Web Application + TargetFrameworkVersion=v4.6.2
    → Visual Studio MSBuild.exe 載入 Microsoft.WebApplication.targets 等規則
    → 建置相依專案 → 編譯網站組件與處理網站內容
    → 網站另由 IIS／IIS Express 載入；build 本身不會啟動 IIS
```

因此，對**目前包含 Web 入口的整個 SCM ApiV2 solution**，不能把 `dotnet build` 當成 Visual Studio `MSBuild.exe` 的直接替代：前面還有 `packages.config` 還原差異，後面有傳統 ASP.NET 網站編譯差異。它可能先在還原或專案評估階段失敗；即使套件已備齊，也可能在網站建置階段失敗。這不表示 .NET Framework 類別庫一律不能用 `dotnet build`，也不表示 Visual Studio `MSBuild.exe` 不能建置 SDK 格式專案；要看**具體專案需要的 targets 與建置元件**。

```powershell
# Livebuy：在 C:\91APP\AI_Devs\liveby\nine1.live.buy\src
dotnet build .\Nine1.Livebuy.Web.Api.sln
dotnet build .\Nine1.Livebuy.Web.Api.sln -c Release

# SCM ApiV2：在 C:\91APP\SCMAPIV2\nineyi.scm.apiv2
nuget restore .\NineYi.Scm.ApiV2.sln
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
& $msbuild .\NineYi.Scm.ApiV2.sln -p:Configuration=Debug
```

常見編譯產物在 `bin\<Configuration>\<TargetFramework>\`，包含 DLL、可能的 EXE、PDB、`.deps.json`、`.runtimeconfig.json` 等；`obj\` 放中間產物與還原資訊。**這是 SDK 專案的常見版面，不是每個舊式專案的固定路徑**：SCM ApiV2 Web 專案明定輸出到 `bin\`。實際檔案與路徑以專案設定為準。

`Debug` / `Release` 是建置組態；`Release` 常用於發布，但組態不等同「開發機 / 正式機」。未指定時應以實際 SDK 與專案設定確認預設值。以上指令是既有工作紀錄與建置路徑示範，**尚未在此處實際執行**。

#### 模擬一次完整 build：Livebuy 與 SCM ApiV2 各做了什麼？

以下依兩個專案的**實際 `.sln` / `.csproj` 設定**走讀，但**沒有執行指令**。這是概念上的先後關係：MSBuild 可能平行建置獨立專案；若輸入與輸出未變，也可能略過部分工作。因此不要把編號當成實際日誌逐行順序。

**Livebuy：假設在 `src` 執行 `dotnet build .\Nine1.Livebuy.Web.Api.sln`**

1. **讀指令與 solution**：`dotnet` 啟動 .NET SDK 內的 MSBuild。因為輸入是 `.sln`，它看見 Web API、類別庫和 solution 中的測試專案；建置測試專案不等於執行測試。
2. **評估專案**：Web API 的 `.csproj` 指定 `Microsoft.NET.Sdk.Web` 和 `net8.0`。MSBuild 載入 Web SDK 規則，讀取 `PackageReference`、`ProjectReference`、文件檔與內容檔設定。
3. **準備依賴**：`dotnet build` 預設執行需要的 restore。例如 `AWSSDK.S3` 所需套件若本機缺少，可能連線至 NuGet 來源；編譯時依 `obj\project.assets.json` 使用解析結果。
4. **安排與執行建置**：先取得 API 所參考的 `BL.Services`、`DA.Repositories` 等專案輸出，並為每個專案準備要編譯的原始碼和參考組件。增量建置可能略過已是最新狀態的工作。
5. **編譯並整理輸出**：C# 編譯器檢查程式碼並產生組件；專案還設定產生 XML 文件，並將指定的前端 `dist` 內容複製到輸出的 `wwwroot`。是否有內容可複製及實際路徑，以這次建置結果為準。
6. **回報成功或錯誤**：缺套件、參考或程式碼錯誤會使相關階段失敗。成功只表示建置完成，`Program.cs` 的 `app.Run()` 尚未執行，API 也尚未開始接受請求。

**SCM ApiV2：假設先完成 `nuget restore`，再執行 Visual Studio `MSBuild.exe .\NineYi.Scm.ApiV2.sln -p:Configuration=Debug`**

1. **讀指令與 solution**：Visual Studio 的 MSBuild 讀取 WebSite、BusinessLogic、DataAccess、測試等專案，以及 Debug 組態下要建置的項目；這一步同樣不會執行測試。
2. **評估舊式專案**：WebSite `.csproj` 指定 `v4.6.2`、`OutputPath=bin\`，明列原始碼、DLL 參考、內容檔與 `ProjectReference`，並匯入 `Microsoft.WebApplication.targets` 等建置規則。
3. **檢查材料與建置相依專案**：專案以 `HintPath` 到 solution 的 `packages` 目錄找 DLL；若必要的 NuGet build imports 不存在，原專案的 `EnsureNuGetPackageBuildImports` target 會報錯。MSBuild 依專案參考取得其他類別庫的輸出。
4. **編譯網站組件**：以 .NET Framework 4.6.2 的參考組件及專案列出的 `.cs` 為輸入，編譯出 WebSite DLL，放到設定的 `bin\`。這一步不會呼叫 `Global.asax` 的 `Application_Start()`。
5. **處理網站專屬工作**：此專案有 Web Application targets、SlowCheetah，以及條件成立時執行的 `AfterBuild` 設定檔轉換；實際存在 `Web.Debug.config`、`AppSettings.Debug.config`、`ConnectionStrings.Debug.config`。轉換是否執行及輸出是否正確，要看實際組態與建置日誌。專案的 `MvcBuildViews=false`，不能把這次 build 理解成已驗證所有 MVC View。
6. **回報成功或錯誤**：build 成功後只是取得網站建置產物；之後 IIS／IIS Express 載入網站時，ASP.NET 才會進入 `Global.asax` 的啟動流程。

#### Build 與「編譯」的差異：C# 到 DLL 中間發生什麼？

**Build 是總工程；編譯是其中把原始碼轉成組件的一道工序。** 前述 restore、決定建置順序、處理資源與內容檔、設定轉換、複製輸出，都屬於 build，並非 C# 編譯器本身負責。MSBuild 在需要編譯時，把 `.cs` 檔、目標框架的參考組件、NuGet 和其他專案的參考，交給 C# 編譯器。

| 編譯階段 | 具體在做什麼 | 用兩個專案理解 |
| --- | --- | --- |
| 讀取與解析 | 將 `.cs` 內容辨識成類別、方法、運算式等語法結構 | 讀到 Livebuy 的 `WebApplication.CreateBuilder(args)`；讀到 SCM 的 `WebApiApplication : System.Web.HttpApplication` |
| 語意與型別檢查 | 確認名稱、型別、方法、參數和參考組件能對上；錯誤會在此報出 | Livebuy 要找得到 ASP.NET Core 的 `WebApplication`；SCM 要找得到 .NET Framework 的 `System.Web.HttpApplication` |
| 產生組件 | 將程式碼轉成 IL（中介語言），連同類別、方法與參考的中繼資料寫進 DLL；視設定產生 PDB 供除錯 | 兩者都可得到 DLL，但各自針對不同目標框架，不能只看副檔名判斷可否互換 |

**DLL 裡的一般受控程式碼主要是 IL，並非按下 build 時就全部變成目標 CPU 的機器碼。** 等程式真的啟動、Runtime 載入組件並執行方法時，通常由 JIT 將需要的 IL 轉成機器碼。因此 Livebuy 的 `app.Run()`、SCM 的 `Application_Start()` 在 build 階段都只是被編譯，沒有真的執行。特定發布方式可能另做預先編譯；此處描述兩個專案的一般 build 流程。

### Run：啟動入口、網站宿主與實際請求

#### 「誰提供啟動入口、誰承載網站」是什麼意思？

**啟動入口**是「程式從哪段程式碼開始執行」；**網站宿主**是「哪個持續運行的程序接收 HTTP 請求，並讓網站程式處理它」。DLL 只是組件的檔案形式，不能只看副檔名判斷能否 `dotnet run`。

| 問題 | Livebuy API | SCM ApiV2 WebSite |
| --- | --- | --- |
| 程式從哪裡開始？ | `Program.cs` 建立 `WebApplication`，最後呼叫 `app.Run()` | 由 IIS／ASP.NET 載入網站；網站初始化時呼叫 `Global.asax.cs` 的 `Application_Start()` |
| 誰接收 HTTP 請求？ | `dotnet run` 啟動應用程式後，ASP.NET Core 的 Web Server（一般為 Kestrel）在程序內監聽 | IIS Express（本機開發）或 IIS（部署環境）先接收，再交給傳統 ASP.NET 管線 |
| 可以直接用 `dotnet run` 嗎？ | 可以，指定 Web API 的 `.csproj` | 目前的 WebSite 是 `OutputType=Library`，不能把它當成可直接啟動的程式 |

注意：`dotnet run` **針對單一可執行專案**，不會像 `dotnet build` 一樣把 `.sln` 當成要執行的程式。`dotnet run` 是開發時的啟動方式；正式部署應使用 publish 產物與適合的宿主設定。

#### 1. 模擬 Livebuy 執行 `dotnet run`

假設目前在 `C:\91APP\AI_Devs\liveby\nine1.live.buy\src`：

```powershell
dotnet run --project .\Web\Nine1.Livebuy.Web.Api\Nine1.Livebuy.Web.Api.csproj --launch-profile Nine1.Livebuy.Web.Api
```

1. `dotnet run` 找到指定的 **Web API 專案**。必要時執行 restore、build，並取得其專案參考的輸出；它不會執行整個 solution 的測試。
2. 讀取 `Properties\launchSettings.json` 的 `Nine1.Livebuy.Web.Api` profile：其中指定 `http://localhost:5566`、`ASPNETCORE_ENVIRONMENT=Development`、`N1_MARKET=HK` 等開發環境設定。這是檔案中的設定，實際使用的位址仍以啟動日誌為準。
3. 啟動編譯後的應用程式，進入 `Program.cs`。`WebApplication.CreateBuilder(args)` 建立宿主與設定；程式接著註冊服務，`builder.Build()` 建立應用程式，設定中介軟體與路由。
4. 執行 `app.Run()`：Web Server 開始監聽 HTTP 請求，程序保持運行。請求進來後才走中介軟體與 Controller。**Build 時只把 `app.Run()` 編譯進組件，不會執行它。**
5. 即使 build 成功，啟動仍可能因設定、埠號或外部服務等執行時條件失敗；兩者的成功條件不同。

#### 2. IIS Express 是什麼？它是一個 App 嗎？

**是。IIS Express 是會實際運行的 Web Server 程序（`iisexpress.exe`）**，可把它理解成偏向本機開發與測試的輕量版 IIS。Visual Studio 可啟動它並指定網站目錄與監聽位址。它負責**接收 HTTP 流量、依網站設定選擇處理管線、將請求交給 ASP.NET 網站程式並送回回應**。它能承載 ASP.NET 網站，但不是只為 SCM ApiV2 寫的專用 App，也不是 C# 編譯器；建置仍由 MSBuild 負責。

SCM ApiV2 Web 專案記錄了 `UseIISExpress=true` 與 `http://localhost:2558/`。這是專案中的本機設定，實際位址可能被本機 Visual Studio 設定覆蓋。正式環境通常由 IIS 承載；兩者都是網站宿主，但 **IIS Express 主要用於開發與測試**。

#### 3. 模擬 SCM ApiV2 從啟動到回應一個請求

以下假設在 Visual Studio 啟動 SCM ApiV2 WebSite，然後送出 `GET http://localhost:2558/Health/Check`。這是**根據程式碼推演，沒有實際啟動或送出請求**。

1. **先備妥網站**：還原 `packages.config` 套件，再由 Visual Studio MSBuild 建置 WebSite 與相依專案，網站組件輸出到 `bin\`。建置本身不會呼叫 `Application_Start()`。
2. **啟動 IIS Express**：Visual Studio 啟動 `iisexpress.exe`，指向 WebSite 目錄並監聽本機位址。此時是 Web Server 程序在等待流量，並不是直接執行 WebSite DLL。
3. **第一個請求促使 ASP.NET 初始化網站**：IIS Express 讀取網站設定，ASP.NET 載入 `bin\` 的組件。一般本機情境中，網站首次收到請求時執行 `Global.asax.cs` 的 `Application_Start()`；這是**每次網站啟動一次**，不是每個請求都執行。
4. **依程式碼順序準備共用設定**：`ConfigSetting.Load(...)` 依 `Execmode` 載入設定；`CurrencySetting.Initialize()` 建立國別與幣別對應；`AutofacConfig.Register(...)` 建立依賴注入容器，登記 Controller 與服務；接著登記 FluentValidation 與 JSON 轉換設定。現有 `AppSettings.config` 的 `Execmode` 是 `Dev`，因此會走相應的開發模式分支。
5. **登記處理規則**：註冊 Areas、Web API 路由與 Handler、MVC Filter／路由、前端 bundles，並依設定處理 Application Insights 與 Bulk Insert 授權。這些動作是在**準備處理請求的規則**，尚未執行 `HealthController.Check()`。
6. **進入這次請求**：`Application_BeginRequest()` 設定 NLog request ID 與 UI 語系；這個方法是**每個請求**都會執行。Web API 的 Attribute Routing 將 `/Health/Check` 對應到 `HealthController.Check()`，請求也會經過已登記的 handlers 與 filters。
7. **產生回應**：`Check()` 回傳 `Ok("Healthy")`；回應再經相關 Handler 交給 IIS Express 送回呼叫端。最終回應格式可能受 `UnifiedResultHandler` 影響，不能只憑 Controller 的字串推定。

**速記：Livebuy 是 `dotnet run → Program.cs → app.Run() → Web Server 監聽`；SCM ApiV2 是 `Visual Studio → IIS Express → ASP.NET 載入網站 → Application_Start() → 接受請求`。** 後者的 `Application_Start()` 是網站初始化回呼，不是可供 `dotnet run` 啟動的獨立程序入口。

### Test：執行測試

```powershell
# 在測試專案目錄，或明確指定測試 .csproj
dotnet test --filter "FullyQualifiedName~GetShoppingCartSalePageGiftProcessorTest"
```

`test` 必要時建置，再交給測試執行器。上例的 `~` 表示「包含」，因此可能匹配多個測試，不保證只執行一個方法。在 solution 目錄與單一測試專案目錄執行，測試範圍也可能不同。

### Publish：準備交付目錄

```powershell
dotnet publish .\WindowsTaskManager.csproj -c Release -o C:\91APP\AI_Devs\taskmanager\deploy-ui
```

Publish 會編譯並整理應用程式、相依套件及執行設定，供複製到目標機器或交給部署流程。常見檔案包括應用程式 DLL、`.deps.json`、`.runtimeconfig.json`、相依 DLL 及設定為發布內容的檔案。是否有 EXE、`appsettings.json`、`user-roles.json`，取決於專案設定，不能只憑指令保證。`-o` 指定輸出目錄；未指定時使用 SDK 的預設 publish 目錄。

有些專案的 build 輸出也能啟動，但 publish 是準備**可交付內容**的標準操作。發布成功不等於部署完成：目標環境仍須有正確設定、權限、Runtime 等條件。

| 發布方式 | 指令重點 | 目標機器 |
| --- | --- | --- |
| 依賴框架（framework-dependent） | `--self-contained false` | 需安裝相容 Runtime；仍可能產生啟動 EXE |
| 獨立部署（self-contained） | `-r win-x64 --self-contained true` | 產物包含指定平台所需的 .NET Runtime，檔案較大 |

`-r win-x64` 指定 Windows x64 RID；**指定 RID 與是否獨立部署是兩個不同選擇**，建議以 `--self-contained true/false` 明確表達。獨立部署仍需考慮作業系統及其他原生依賴。

#### Livebuy API：從 Pipeline 發動到容器啟動

這裡以 repo 目前的 `.gitlab-ci.yml`、`pipeline/build-config.sh`、`Dockerfile` 為依據，按檔案描述的流程走一次；**這是靜態分析，沒有實際執行發佈或部署**。

1. **發動：** GitLab CI 讀取 `.gitlab-ci.yml`。這個檔案引用 `nine1.devops.gitlab` 的共用 Pipeline 範本，並設定站台識別為 `Nine1.Livebuy.Web.Api`。因此 CI 工作的完整觸發條件、映像推送及叢集部署細節，還要看外部範本；不能只靠此 repo 宣稱它們每次都會發生。
2. **選擇建置方式：** `pipeline/build-config.sh` 指定 repo 根目錄的 `Dockerfile`，並提供 .NET 8 SDK 建置映像、ASP.NET 8 Runtime 映像等設定。Docker 進入多階段建置：先用 Node 建置前端，也用另一個階段處理翻譯檔。
3. **真正執行 .NET Publish：** Dockerfile 的 .NET 建置階段在 `/src` 執行 `dotnet restore`，接著執行 `dotnet publish -c ${DOTNET_BUILD_CONFIG} -o /out`。此時會還原相依、建置程式，並將發佈檔案整理到**建置容器內的** `/out`；`DOTNET_BUILD_CONFIG` 是建置時傳入的組態。這一步不會讓 API 開始接收流量。
4. **補齊容器需要的檔案：** Dockerfile 再把 `.manifest`、`releng.json` 放進 `/out/.manifest`，把前端的 `dist` 放到 `/out/wwwroot`。因此最後交付的內容不只有 `dotnet publish` 的原始輸出，還包含後續複製進去的檔案。
5. **製作可執行映像：** 最後一階段改用 ASP.NET Runtime 映像，把 `/out` 複製到 `/app`，並設定 `CMD dotnet /app/${NYS_FQDN}.dll`。Docker 映像建置完成，表示程式與執行環境已封裝；**容器真正被啟動時**，這條 `CMD` 才會執行，Livebuy 的 `Program.cs` 才會建立並啟動網站。
6. **交給部署流程：** 映像之後是否推送到 registry、由哪個工作部署到 Kubernetes、如何驗證站台可用，取決於引入的共用 Pipeline 範本與部署設定；這些步驟不在目前檢視到的 repo 內完整展開。因此要把「`dotnet publish` 成功」、「Docker 映像建置完成」和「站台已對外服務」視為三個不同完成點。

速記：`GitLab CI → 共用範本選擇 Docker 建置 → dotnet restore → dotnet publish 到 /out → 補入前端／中繼資料 → 封裝 Runtime 映像 → 部署並啟動容器（外部範本決定）`。

#### SCM ApiV2：從 Jenkins 發動到 IIS 網站

SCM ApiV2 的路徑和 Livebuy 不同。它是 .NET Framework 4.6.2 的傳統 ASP.NET Web Application；`Microsoft.WebApplication.targets` 提供 Web 專案建置／發佈流程，`.pubxml` 提供本次發佈的參數。**`.pubxml` 不是發佈引擎，發佈也不需要開啟 Visual Studio IDE；執行它的是具備 Web 建置元件的 Visual Studio 系列 `MSBuild.exe`。**以下依 `Jenkinsfile`、`JenkinsfileDeploy`、`build.ps1`、`build.cake` 和 QA 發佈設定檔說明，同樣沒有實際執行。

1. **發動：** `Jenkinsfile` 指定在標記為 `msbuild` 的節點執行。符合條件時，Build 階段呼叫 `./build.ps1 -Target Build`；`JenkinsfileDeploy` 也提供另一條帶市場、部署批次等參數的路徑。`build.ps1` 是 Cake 啟動器，最後交由 `build.cake` 執行指定任務。
2. **還原與建置：** Cake 的 `Build` 任務先依賴 `Nuget Restore`，對 solution 執行 `NuGetRestore(...)`；之後執行 `Msbuild` 任務。這也對應網站專案的 `packages.config` 與傳統 NuGet 套件還原方式。
3. **建置時同時發佈：** `Msbuild` 任務對 `NineYi.Scm.ApiV2.sln` 呼叫 MSBuild，設定 `DeployOnBuild=true`、`PublishProfile=NineYi.Scm.ApiV2.QA.Deploy.pubxml`、建置組態，以及 `publishUrl`。MSBuild 編譯各專案後，依 Web Application targets 啟動網站發佈流程；QA profile 指定 `WebPublishMethod=FileSystem`，也有額外納入 `bin/*.xml` 的規則。`publishUrl` 由 Cake 依環境組成，通常落在 `D:\Archives\<MachineKey>\NineYi.Scm.ApiV2`，因此此階段的「發佈完成」是**網站檔案已整理到指定目錄**。
4. **準備環境檔與交付物：** `build.cake` 另外定義 `Copy Config`，可將基底 `AppSettings` 複製並套用環境／市場轉換；`Deploy Artifact` 任務會接著封存網站目錄並上傳 artifact。**但目前看到的兩份 Jenkinsfile 只明確呼叫 Build、Test、Deploy，沒有直接呼叫 `Deploy Artifact`。** 因此 artifact 由哪個外部工作產生、是否會在每次流程執行，不能只由這些檔案確認。
5. **部署到機器：** Jenkins 的 Deploy 階段呼叫 Cake 的 `Deploy` 任務。`Deploy to machines` 會依環境與市場下載 artifact、解壓縮，再對符合市場的目標機器呼叫 `Deploy(...)`，目標是該機器的網站共享路徑。這個 `Deploy` 函式來自外部 Cake 函式庫；備份、複製及 IIS 操作的更細節，需要追該函式庫或執行紀錄才能確認。
6. **網站開始服務：** 當檔案已部署、IIS 網站與應用程式集區設定正確，IIS 的工作行程才會載入網站組件，ASP.NET 才會在網站啟動／請求到來時執行 `Global.asax` 的初始化流程。**MSBuild 發佈成功不代表 IIS 已載入新版，也不代表健康檢查已通過。**

速記：`Jenkins → build.ps1／Cake → NuGet restore → VS MSBuild 建置＋FileSystem 發佈 → artifact／環境設定（需核對外部串接）→ 部署到 IIS 機器 → IIS 載入網站並接收請求`。

這兩條流程最重要的差別：**Livebuy 把 `dotnet publish` 產物放入 ASP.NET Runtime 容器映像，由容器啟動程式；SCM ApiV2 用 VS MSBuild 的 Web 發佈流程整理網站檔案，再由 IIS 承載網站。**

## 四、新舊專案如何選工具

「新舊」不能只看程式碼年代。先打開 `.csproj`，檢查**專案格式、目標框架、套件管理方式、建置所需工具**。

| 專案特徵 | 常用入口 | Restore 注意事項 |
| --- | --- | --- |
| SDK 格式，例如 `Project Sdk="Microsoft.NET.Sdk"` | `dotnet build` / `dotnet publish` | build 預設會還原 |
| 舊式 .NET Framework 專案，尤其依賴 Visual Studio 專屬 targets | Visual Studio 的 `MSBuild.exe` | `PackageReference` 可用 MSBuild restore；`packages.config` 需確認工具與參數 |
| SDK 格式但目標是 .NET Framework | 按實際工具相容性判斷 | 不能只因 `net48` 就斷定 `dotnet build` 不可用 |

舊式專案常依賴 Visual Studio 建置元件、參考組件、targets 或特定工具鏈。這是工具相容性問題，不代表「.NET Framework 完全不能用 CLI」。反過來，`dotnet msbuild` 也不是任意舊式 Visual Studio 專案的等價替代。

```powershell
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"

# PackageReference 專案：還原後建置
& $msbuild .\nineyi.scm.apiv2.sln -t:Restore
& $msbuild .\nineyi.scm.apiv2.sln -p:Configuration=Debug

# packages.config：支援的 MSBuild 版本可明確啟用還原
& $msbuild .\nineyi.scm.apiv2.sln -t:Restore -p:RestorePackagesConfig=true
```

上面是工具用法示範；**SCM ApiV2 的 Web 專案實際包含 `packages.config`，其既有 `build.cake` 以 `NuGetRestore(...)` 還原 solution**。若專案要求 Visual Studio Developer Command Prompt、特定 Visual Studio 版本或 .NET Framework targeting pack，也須先備妥。

## 五、既有工作指令

### Livebuy：建置、執行、篩選測試

```powershell
# 在 C:\91APP\AI_Devs\liveby\nine1.live.buy\src
dotnet build .\Nine1.Livebuy.Web.Api.sln

# 在 C:\91APP\AI_Devs\liveby\nine1.live.buy\src\Web\Nine1.Livebuy.Web.Api
dotnet run

# 在對應測試專案目錄，或明確指定測試 .csproj
dotnet test --filter "FullyQualifiedName~GetShoppingCartSalePageGiftProcessorTest"
```

只顯示包含 `error` 的輸出：

```powershell
dotnet build 2>&1 | Select-String -Pattern "\s*error\s" -CaseSensitive:$false
```

這只是**顯示過濾**，可能漏掉未包含 `error` 的失敗資訊。排錯時應檢查完整輸出及建置結束狀態。

### SCM ApiV2：使用 Visual Studio MSBuild

```powershell
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
& $msbuild "C:\91APP\SCMAPIV2\nineyi.scm.apiv2\NineYi.Scm.ApiV2.sln"

# 已在 solution 所在目錄時
& $msbuild .\nineyi.scm.apiv2.sln -p:Configuration=Debug
```

執行前應確認 solution 檔名、MSBuild 路徑、Visual Studio 元件與是否需要先 restore。上面兩個 solution 路徑沿用舊筆記，未驗證是否指向同一檔案。

### WindowsTaskManager：發布到 deploy-ui

```powershell
$project = 'C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager\src\WindowsTaskManager\WindowsTaskManager.csproj'
$output = 'C:\91APP\AI_Devs\taskmanager\deploy-ui'

# publish 預設執行必要的 restore 與 build
dotnet publish $project -c Release -o $output --self-contained false
Get-ChildItem -LiteralPath $output
```

若目標機器沒有安裝相容的 .NET Runtime，改用明確指定平台的獨立部署：

```powershell
dotnet publish $project -c Release -r win-x64 --self-contained true -o $output
Get-ChildItem -LiteralPath $output
```

如果要將 restore 拆開控制網路存取，`--no-restore` 之前必須確認 restore 已取得同一 RID 與獨立部署所需的 runtime 套件。獨立部署的隱含 restore 會帶入 publish 的上下文；單獨執行 `dotnet restore -r win-x64` 不一定等價。若尚未在專案與 SDK 版本上驗證這組條件，請保留 publish 的隱含 restore；CI 若需完全離線，再明確設定並驗證 restore / publish 共用的 RID、自包含屬性及 runtime 版本。

不要在同一個 `$output` 中混放不同 RID 或發布模式的舊產物。原筆記指定 `deploy-ui` 卻檢查 `.\publish`，此處已統一為實際輸出路徑。

## 六、遇到問題時先找失敗層

| 現象 | 優先檢查 |
| --- | --- |
| Restore 失敗 | NuGet 來源、認證、網路、版本及目標框架相容性 |
| 找不到 `project.assets.json` | 是否已還原；build 與 restore 的框架/RID 條件是否一致 |
| 編譯失敗 | 原始碼、專案參考、SDK / MSBuild / targeting pack |
| Test 失敗或找不到測試 | 測試專案、執行器、`--filter` 匹配結果與測試本身 |
| Publish 成功但目標機器無法啟動 | Runtime、RID、組態檔、內容檔、環境變數、原生依賴 |

**速記：restore 準備依賴，build 產生程式，test/run 驗證或啟動，publish 準備交付；專案格式與工具鏈決定使用哪個入口。**

## 參考資料

- [識別專案格式 — Microsoft Learn](https://learn.microsoft.com/en-us/nuget/resources/check-project-format)
- [.NET 專案 SDK 與預設檔案納入規則 — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/project-sdk/overview)
- [.NET 與 .NET Core 名稱 — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/standard/glossary)
- [SDK 預設項目重複錯誤 NETSDK1022 — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/sdk-errors/netsdk1022)
- [SDK 輸出路徑設定 — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/project-sdk/msbuild-props#appendtargetframeworktooutputpath)
- [SDK 格式專案的目標框架 — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/standard/frameworks/)
- [從 .NET Framework 移轉至 .NET — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/porting/framework-overview)
- [dotnet restore — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-restore)
- [dotnet build — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build)
- [MSBuild 如何評估與執行專案 — Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/msbuild/build-process-overview)
- [C# 編譯、IL 與執行時 JIT — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/standard/managed-execution-process)
- [傳統 ASP.NET 網站的 MSB4249 建置錯誤 — Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/msbuild/errors/msb4249)
- [dotnet run — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-run)
- [ASP.NET Core Kestrel Web Server — Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel)
- [IIS Express 概覽 — Microsoft Learn](https://learn.microsoft.com/en-us/iis/extensions/introduction-to-iis-express/iis-express-overview)
- [ASP.NET 應用程式生命週期 — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/aspnet/bb470252%28v%3Dvs.100%29)
- [傳統 ASP.NET Web API 設定 — Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/web-api/overview/advanced/configuring-aspnet-web-api)
- [dotnet test — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test)
- [dotnet publish — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-publish)
- [.NET 發布模式 — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/articles/core/deploying/index)
- [NuGet 套件還原 — Microsoft Learn](https://learn.microsoft.com/en-us/nuget/consume-packages/package-restore)
- [NuGet CLI 還原支援格式 — Microsoft Learn](https://learn.microsoft.com/en-us/nuget/consume-packages/install-use-packages-nuget-cli)
- [NuGet 相依關係解析 — Microsoft Learn](https://learn.microsoft.com/en-us/nuget/concepts/dependency-resolution)
- [dotnet msbuild — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-msbuild)
- [獨立部署的 runtime 修補版本與 no-restore — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/deploying/runtime-patch-selection)
