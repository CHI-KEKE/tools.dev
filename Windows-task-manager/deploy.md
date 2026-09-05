# WindowsTaskManager.Monitor 手動部署為 Windows Service 步驟

## Step 1：Publish 成獨立可執行檔

cd C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager; dotnet publish src\WindowsTaskManager.Monitor\WindowsTaskManager.Monitor.csproj -c Release -r win-x64 --self-contained false -o C:\91APP\AI_Devs\taskmanager\deploy-test

•  -c Release ：正式環境不要用 Debug build
•  -r win-x64 --self-contained false ：產生 Windows 專用、但依賴機器上已安裝的 .NET Runtime（比 self-contained 檔案小很多；若目標機器沒裝 .NET 8 Runtime 才需要改成  --self-contained true ）
•  -o ：輸出到實際要長期運作的資料夾（不要用 bin/Debug 那種暫時路徑，服務要指向這個固定資料夾）


我這裡用 C:\91APP\AI_Devs\taskmanager\deploy-test


## Step 2：確認正式環境設定檔

Publish 完後檢查  C:\Services\WindowsTaskManager.Monitor\appsettings.json ，確認：

•  Logging.LogLevel  建議正式環境用  Information （ appsettings.Development.json  不會被帶到 Release，可以不管）
•  MonitorOptions  各項參數（ IntervalMinutes 、 ToleranceMinutes  等）是否符合正式排程週期需求
•  ExcludedTaskPathPatterns  排除清單是否涵蓋正式機器上的雜訊任務（跟本機測試環境可能不同，建議先手動跑一次 console 模式看有沒有新的雜訊來源）


## Step 3：用 New-Service 註冊為 Windows Service

必須用系統管理員權限開 PowerShell：

New-Service -Name "WindowsTaskManager.Monitor" -BinaryPathName "C:\91APP\AI_Devs\taskmanager\deploy-test\WindowsTaskManager.Monitor.exe" -DisplayName "Windows Task Manager - 排程監控服務" -Description "定期巡檢本機 Windows Task Scheduler，偵測漏排/執行失敗/心跳停止並發送告警" -StartupType Automatic


 #### -Name  

答案：要跟  Program.cs  裡  AddWindowsService  設定的  ServiceName  一致。

Read Program.cs L29:34 (5 lines read)

#### 為什麼要對齊

 AddWindowsService(options => options.ServiceName = "WindowsTaskManager.Monitor")  這行程式碼告訴 .NET Runtime：「當我被 SCM（Service Control Manager）啟動時，我要用這個名稱去跟 SCM 溝通」，具體用在：

1.  ServiceBase.ServiceName ——底層 .NET Worker Service 用這個名稱向 SCM 回報自己的身分、接收 Start/Stop 控制訊號
2. Event Log Source——如果程式寫入 Windows Application Event Log，會用這個名稱當作 Source
3. 服務生命週期溝通——SCM 啟動服務時是透過  -Name  註冊的服務名稱去執行  -BinaryPathName  指定的 exe；exe 啟動後，程式內部用  ServiceName  向 SCM 回報「我是誰、我現在狀態如何」

如果兩者不一致，會發生：SCM 用  -Name  認得這個服務、能啟動 exe 進程，但 exe 內部 Worker Service 用不同的  ServiceName  跟 SCM 溝通生命週期狀態，可能導致：

• 服務顯示狀態卡在「正在啟動」不會變成「執行中」
•  Stop-Service  送出的停止訊號送不到正確的服務實例，造成無法正常停止（要用工作管理員砍 process）

結論

你目前指令裡的  -Name "WindowsTaskManager.Monitor"  已經是對的，跟程式碼裡設定的  ServiceName = "WindowsTaskManager.Monitor"  完全一致，不需要改。這個原則就是： New-Service -Name  必須等於程式碼裡  AddWindowsService  設定的  ServiceName ，兩處要手動保持同步，未來如果改了程式碼裡的名稱，記得  -Name  也要跟著改（且需要先  sc.exe delete  舊服務重新註冊，不能直接改名）。





## Step 4：設定失敗自動重啟（Recovery）

New-Service  沒有內建參數可以設定 Recovery，要用  sc.exe ：

sc.exe failure "WindowsTaskManager.Monitor" reset= 86400 actions= restart/60000/restart/60000/restart/60000

•  reset= 86400 ：失敗計數器 24 小時歸零一次
•  restart/60000 ：失敗後等 60 秒自動重啟，連續三次都設一樣的動作

這正好對應  Program.cs  裡刻意用非 0  Environment.ExitCode = 1  讓例外時被視為「非正常結束」，觸發 SCM 的 Recovery 機制。

## Step 5：設定服務執行帳號的權限

 SchedulerReader  是透過 COM API 讀取 Task Scheduler，執行帳號必須有權限列舉/讀取任務。預設  LocalSystem  通常足夠可以看到本機大多數任務，但如果有些任務是用其他使用者身分建立且設定了較嚴格的存取控制，可能需要調整：

# 若要改用具名帳號執行（非必要，除非有特殊權限需求）
sc.exe config "WindowsTaskManager.Monitor" obj= "DOMAIN\ServiceAccount" password= "xxxxx"

Event Log 讀取（ Microsoft-Windows-TaskScheduler/Operational ）也需要該帳號有讀取權限， LocalSystem  預設沒問題。

Step 6：啟動服務並驗證

Start-Service -Name "WindowsTaskManager.Monitor"
Get-Service -Name "WindowsTaskManager.Monitor"

驗證重點：

1.  Get-Service  顯示  Running 
2. 檢查 log 檔案是否正常輸出： C:\Services\WindowsTaskManager.Monitor\logs\monitor-*.log （對應  Program.cs  裡  AppContext.BaseDirectory\logs  路徑）
3. 用  Get-EventLog -LogName Application -Source "WindowsTaskManager.Monitor"  或直接看 log 檔確認第一輪巡檢有正常跑完，任務數量、排除數量是否合理



## Step 7（可選）：重啟機器驗證開機自動啟動

因為  StartupType Automatic ，建議重開機一次確認服務能自動啟動，不依賴手動  Start-Service 。

────────────────────

卸載/更新時的步驟（供未來參考）

Stop-Service -Name "WindowsTaskManager.Monitor"
sc.exe delete "WindowsTaskManager.Monitor"

更新版本時：先  Stop-Service  → 覆蓋 publish 輸出資料夾 →  Start-Service ，不需要重新註冊服務（ BinaryPathName  沒變的話）。




## 啟動服務


啟動服務

Start-Service -Name "WindowsTaskManager.Monitor"

確認啟動狀態

Get-Service -Name "WindowsTaskManager.Monitor" | Select-Object Name, Status, StartType

預期看到  Status = Running 。

驗證重點

1. 檢查 log 檔案是否正常輸出（對應  Program.cs  裡  AppContext.BaseDirectory\logs  路徑）：

Get-ChildItem "C:\91APP\AI_Devs\taskmanager\deploy-test\logs\"
Get-Content "C:\91APP\AI_Devs\taskmanager\deploy-test\logs\monitor-*.log" -Tail 30

2. 確認第一輪巡檢有跑完，log 內容應該會看到跟你之前 console 模式測試時一樣的訊息（掃描任務數量、排除統計、告警發送等）。
3. 若啟動失敗（ Status  卡在  Stopped  或報錯），可以查 Windows 事件檢視器的 Application log，或執行：

Get-EventLog -LogName Application -Source "WindowsTaskManager.Monitor" -Newest 10

你可以先執行  Start-Service ，跑完後把結果貼給我，我再協助判讀。
這個有UI嗎
有，Windows 內建的「服務」管理工具（Services， services.msc ）就是圖形化介面，不需要打指令也能操作。

開啟方式

• 執行 → 輸入  services.msc  → Enter
• 或開始選單搜尋「服務」（Services）

在裡面能做什麼

1. 找到你的服務：清單依名稱排序，找 WindowsTaskManager.Monitor（會顯示你設定的  DisplayName ：「Windows Task Manager - 排程監控服務」）
2. 左鍵點兩下（或右鍵）該服務，可以看到：
• 一般分頁：啟動類型（對應  -StartupType ）、目前狀態、啟動/停止/暫停/繼續按鈕
• 登入分頁：服務用什麼帳號執行（預設 Local System）
• 復原分頁：對應我們之前用  sc.exe failure  設定的 Recovery（如果你還沒設定，這裡可以直接用 GUI 設定「第一次失敗/第二次失敗/後續失敗」要做什麼動作，例如「重新啟動服務」）
• 相依性分頁：這個服務啟動前需要哪些其他服務先啟動
3. 右鍵選單就有 啟動 / 停止 / 重新啟動 選項，效果等同 PowerShell 的  Start-Service  /  Stop-Service 。



taskschd.msc

在「執行」（ Win + R ）視窗輸入這行按 Enter，就會開啟工作排程器 GUI。


## 個別的 fail

 1  這個參數（shopEtlFlowId）的使用流程

當你執行  NineYi.OsmPlus.Batch.RunFlowById.exe 1 ...  時， args[0] = "1"  會被解析成  shopEtlFlowId = 1 ，接著：

1.  Program.ExecuteFlowId(1, ...) 
• 呼叫  EtlFlowControlService.CreateFlowTask(1, Running) 
2.  EtlFlowTaskRepository.CreateFlowTask 
var param = new { shopEtlFlowId = 1, flowTaskStatus = "Running" };
ExecuteStoredProcedure<EtlFlowTaskEntity>("csp_BatchCreateEtlFlowTaskByShopEtlFlowId", param);
``` 實際上是呼叫 **DB Stored Procedure `csp_BatchCreateEtlFlowTaskByShopEtlFlowId`**，以 `shopEtlFlowId = 1` 去 `ShopEtlFlow` 資料表撈出對應的流程定義（`ShopEtlFlow_Id = 1` 這筆），並在 `EtlFlowTask` / `EtlFlowTaskSlave` 建立一筆狀態為 `Running` 的執行紀錄，回傳一個 `EtlFlowTaskEntity`（含 `Id`、`ShopId`、`EtlCategoryName`、`ShopEtlFlowDescription` 等）。
3. 若成功建立  etlTask （不為 null），才會進入  while(true)  迴圈，抓 Slack Hook 設定，接著呼叫：
flowControlService.DoProcess(etlTask, userName, isDebugMode, ref isExecuteFlow, isEmergency);
``` `DoProcess` 內部會依 `ShopEtlFlow_Id=1` 底下設定的 `ShopEtlFlowStep`（多個步驟），透過 Reflection 動態建立對應的 `xxxFlowService`（例如你之前遇到錯誤的 `ProductFeedFlowService`）逐一執行。

簡單說： 1  不是流程種類代碼、也不是站台代碼，而是資料庫  ShopEtlFlow  表中某一筆流程定義的 PK（ ShopEtlFlow_Id ）。程式會依這個 Id 去 DB 撈出「這是哪個商店、哪個流程分類、包含哪些步驟」，然後照順序執行。 若 DB 裡沒有  ShopEtlFlow_Id = 1  這筆資料， CreateFlowTask  會回傳  null ，直接印出「該流程狀態為已完成，不執行結束」並跳出，不會報錯。








2. 檢查 Operational Log 容量設定與目前使用量

$log = Get-WinEvent -ListLog "Microsoft-Windows-TaskScheduler/Operational"
$log | Format-List LogName, IsEnabled, MaximumSizeInBytes, FileSize, RecordCount, LogMode

重點看：

•  MaximumSizeInBytes  vs  FileSize ：如果 FileSize 接近上限，且  LogMode  是  Circular （預設），代表舊紀錄持續被覆蓋滾動掉，早期執行紀錄就會消失
•  RecordCount ：目前存了多少筆事件，配合你機器上有多少心跳型任務（每 30 分鐘一次的量很大）評估多久會輪替一次

3. 直接用任務 GUID 查詢，繞過 GUI 篩選

$task = Get-ScheduledTask -TaskPath "\Member\" -TaskName "OMO_Member_ETL_LoyaltyPointMigration_StoreImport_Routine"
$taskId = $task.TaskPath + $task.TaskName
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -MaxEvents 2000 |
    Where-Object { $_.Message -like "*$($task.TaskName)*" } |
    Select-Object -First 20 TimeCreated, Id, Message

這樣可以確認 Event Log 裡到底有沒有殘留任何跟這個任務名稱相關的事件——如果完全查無，代表不是「GUI篩選失效」而是 log 裡真的沒有這筆資料（要嘛被覆蓋掉了，要嘛任務被重建過導致內部識別碼變了）。