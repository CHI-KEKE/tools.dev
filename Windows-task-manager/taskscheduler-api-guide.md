# Windows Task Scheduler API 說明文件

> 分析日期：2026-05-19
> 適用專案：`nine1.tools.windows-task-manager`
> NuGet 套件：`TaskScheduler` v2.12.2（by David Hall / dahall）

---

## 一、API 是什麼？

本專案並非呼叫 HTTP REST API，而是透過 **NuGet 套件 `TaskScheduler`（v2.12.2）** 操作 Windows 作業系統的排程服務。

### 底層架構圖

```
C# 程式碼（TaskSchedulerService.cs）
        │
        ▼
  NuGet Package: TaskScheduler v2.12.2
  (by David Hall / GitHub: dahall/TaskScheduler)
  命名空間：Microsoft.Win32.TaskScheduler
        │
        ▼
  Windows Task Scheduler COM API
  (Task Scheduler 2.0, Vista+)
        │
        ├─ 本機 → svchost.exe → Task Scheduler 服務（Schedule.dll）
        └─ 遠端 → RPC over TCP Port 135 → 遠端 Windows Server
```

### 套件資訊

| 項目 | 內容 |
|------|------|
| NuGet 套件名稱 | `TaskScheduler` |
| 版本 | `2.12.2` |
| 作者 | David Hall（dahall） |
| GitHub | https://github.com/dahall/TaskScheduler |
| API 文件 | https://dahall.github.io/TaskScheduler |
| 說明 | Windows Task Scheduler COM API 的 .NET 封裝，支援本機與遠端操作 |
| 作業系統需求 | **Windows 專屬**（Linux/macOS 不支援，呼叫會拋出例外） |

---

## 二、核心類別一覽

| 類別 | 命名空間 | 說明 |
|------|---------|------|
| `TaskService` | `Microsoft.Win32.TaskScheduler` | 連接到 Task Scheduler 的入口，相當於「連線物件」 |
| `TaskFolder` | `Microsoft.Win32.TaskScheduler` | 代表 Task Scheduler 的資料夾節點（`\` 根目錄、`\MyFolder\` 等） |
| `Task` | `Microsoft.Win32.TaskScheduler` | 代表單一排程任務，包含狀態、啟用/停用、執行時間等 |
| `TaskDefinition` | `Microsoft.Win32.TaskScheduler` | 任務的定義結構，包含 Actions、Triggers、Settings、RegistrationInfo |
| `ExecAction` | `Microsoft.Win32.TaskScheduler` | 執行程式的動作（Action），指定程式路徑與參數 |
| `DailyTrigger` | `Microsoft.Win32.TaskScheduler` | 每日觸發的排程規則 |
| `TaskState` | `Microsoft.Win32.TaskScheduler` | 列舉：`Unknown / Disabled / Queued / Ready / Running` |

---

## 三、本專案實際使用的 API 完整清單

### 3-1 建立連線（TaskService）

#### 本機連線
```csharp
// 連接到本機 Task Scheduler 服務
using var ts = new TaskService();
```
- 連接本機的 Windows Task Scheduler 服務
- 不需要帳號密碼

#### 遠端連線
```csharp
// 連接到遠端 Windows Server 的 Task Scheduler
var ts = new TaskService(
    targetServer: "192.168.1.100",  // 遠端 IP
    userName: "administrator",       // Windows 帳號
    accountDomain: null,             // 網域（可選）
    password: "password"             // 密碼
);
```
- 透過 **RPC over TCP Port 135** 連接遠端 Windows Server
- 遠端 Server 須開啟 Task Scheduler 服務及防火牆例外
- 若連線失敗（無權限、網路不通、逾時），會拋出對應例外

#### 僅傳 IP（CurrentUser / ServiceAccount 模式）
```csharp
var ts = new TaskService(targetServer: "192.168.1.100");
// 使用目前執行身份（IIS Application Pool 帳號）的憑證
```

---

### 3-2 讀取任務（Read）

#### 取得所有任務（排除 \Microsoft\ 系統任務）
```csharp
// ts.RootFolder.AllTasks 會遞迴取得所有子資料夾的任務
foreach (var task in ts.RootFolder.AllTasks)
{
    // 排除 Windows 系統內建任務
    if (task.Path.StartsWith("\\Microsoft\\", StringComparison.OrdinalIgnoreCase))
        continue;

    // 讀取任務基本資訊
    string name        = task.Name;         // 任務名稱
    string path        = task.Path;         // 完整路徑（如 \MyFolder\MyTask）
    bool   isEnabled   = task.Enabled;      // 是否啟用
    string status      = task.State.ToString(); // Unknown/Ready/Running/Disabled/Queued
    
    // 執行時間（DateTime.MinValue 表示從未執行/無排程）
    DateTime? lastRun  = task.LastRunTime == DateTime.MinValue ? null : task.LastRunTime;
    DateTime? nextRun  = task.NextRunTime == DateTime.MinValue ? null : task.NextRunTime;
    
    // 任務描述資訊
    string description = task.Definition.RegistrationInfo.Description;
    string author      = task.Definition.RegistrationInfo.Author;
}
```

#### 取得單一任務
```csharp
// 以任務名稱取得，找不到回傳 null
Task? task = ts.GetTask("MyTaskName");

// 取得執行程式路徑與參數
var execAction = task.Definition.Actions.OfType<ExecAction>().FirstOrDefault();
string program   = execAction?.Path ?? "";       // 程式路徑（如 C:\app\run.exe）
string arguments = execAction?.Arguments ?? "";   // 執行參數（如 --mode=prod）
```

---

### 3-3 新增任務（Create）

```csharp
// Step 1: 建立新的任務定義
var td = ts.NewTask();

// Step 2: 設定基本資訊
td.RegistrationInfo.Description = "Task created by Windows Task Manager Web Interface";
td.RegistrationInfo.Author = Environment.UserName;

// Step 3: 加入執行動作（ExecAction）
td.Actions.Add(new ExecAction(
    path: "C:\\app\\myprogram.exe",   // 程式絕對路徑
    arguments: "--env=prod"            // 執行參數（可選）
));

// Step 4: 加入觸發器（Trigger）
// 目前專案只實作 DailyTrigger，每日執行一次
td.Triggers.Add(new DailyTrigger { DaysInterval = 1 });

// Step 5: 向 Task Scheduler 根目錄註冊此任務
ts.RootFolder.RegisterTaskDefinition(
    path: "MyTaskName",    // 任務名稱（在根目錄下）
    definition: td
);
```

**注意**：目前 Create 功能的 Trigger 固定為每日執行，時間點由系統預設，未暴露給使用者設定。

---

### 3-4 更新任務（Update）

```csharp
// Step 1: 取得現有任務
var task = ts.GetTask("MyTaskName");

// Step 2: 取得任務定義（可修改）
var td = task.Definition;

// Step 3: 更新描述
td.RegistrationInfo.Description = "新的說明文字";

// Step 4: 更新執行動作（清空後重新加入）
td.Actions.Clear();
td.Actions.Add(new ExecAction("C:\\new\\path.exe", "--new-args"));

// Step 5: 保留原有設定的情況下重新註冊
// 保留：觸發器（Triggers）、Principal（執行身份）、LogonType
string currentUser = task.Definition.Principal.UserId;
TaskLogonType logonType = task.Definition.Principal.LogonType;

ts.RootFolder.RegisterTaskDefinition(
    path: "MyTaskName",
    definition: td,
    createType: TaskCreation.CreateOrUpdate,   // 不存在建立、存在則更新
    userId: currentUser,
    password: null,                            // 保留原密碼
    logonType: logonType,
    sddl: null
);

// Step 6: 更新啟用狀態（需重新取得任務物件才能設定）
var updatedTask = ts.GetTask("MyTaskName");
updatedTask.Enabled = true; // 或 false
```

**重要行為**：UpdateTask 設計上保留原有的 Triggers、Principal、LogonType，僅更新 Program / Arguments / Description / Enabled。

---

### 3-5 刪除任務（Delete）

```csharp
// 直接從根目錄刪除，不可恢復（硬刪除）
ts.RootFolder.DeleteTask("MyTaskName");

// 若任務在子資料夾中，需傳入完整路徑
ts.RootFolder.DeleteTask("\\MyFolder\\MyTaskName");
```

---

### 3-6 啟用 / 停用任務（Enable / Disable）

```csharp
var task = ts.GetTask("MyTaskName");

// 啟用
task.Enabled = true;

// 停用
task.Enabled = false;
```

**注意**：設定 `task.Enabled` 後立即生效，Task Scheduler 服務即時更新狀態。

---

### 3-7 查詢執行歷史（History）

```csharp
var task = ts.GetTask("MyTaskName");

// 取得過去 30 天的執行時間點清單
// GetRunTimes() 回傳的是「預計執行時間」，非真實執行記錄
// 真實執行記錄需讀取 Windows 事件檢視器（Event Log）
var runTimes = task.GetRunTimes(
    start: DateTime.Now.AddDays(-30),
    end: DateTime.Now
);
```

⚠️ **限制說明**：
- `GetRunTimes()` 實際上是計算 Trigger 在時間範圍內的觸發點，**並非真實執行日誌**
- 本專案未使用 Windows Event Log 查詢真實執行結果，因此所有歷史記錄的 `Result` 固定為 `"Completed"`
- 要取得真實執行結果，需查詢 Windows Event Log（Channel: `Microsoft-Windows-TaskScheduler/Operational`）

---

### 3-8 判斷任務是否執行中

```csharp
var task = ts.GetTask("MyTaskName");
bool isRunning = task?.State == TaskState.Running;
```

---

### 3-9 取得 Server 任務統計（ServerService 使用）

```csharp
using var ts = new TaskService();

// 排除 Microsoft 系統任務
var tasks = ts.RootFolder.AllTasks
    .Where(t => !t.Path.StartsWith("\\Microsoft\\", StringComparison.OrdinalIgnoreCase))
    .ToList();

int total   = tasks.Count;
int enabled = tasks.Count(t => t.Enabled);
int disabled = tasks.Count(t => !t.Enabled);
```

---

## 四、TaskState 列舉對照

| 值 | 說明 | 觸發情境 |
|----|------|---------|
| `Unknown` | 未知狀態 | 無法讀取任務狀態時 |
| `Disabled` | 已停用 | task.Enabled = false |
| `Queued` | 排隊等待中 | 已到觸發時間，等待資源 |
| `Ready` | 就緒（待執行） | 正常待機狀態 |
| `Running` | 執行中 | 任務正在執行 |

---

## 五、TaskCreation 列舉（UpdateTask 使用）

| 值 | 說明 |
|----|------|
| `Create` | 只建立新任務，已存在則失敗 |
| `Update` | 只更新已存在的任務，不存在則失敗 |
| `CreateOrUpdate` | 不存在則建立，已存在則更新（本專案使用） |
| `Disable` | 停用任務 |
| `DontAddPrincipal` | 不變更 Principal 設定 |
| `ValidateOnly` | 只驗證，不實際建立/更新 |

---

## 六、連線限制與例外對照

| 例外類型 | 原因 | 本專案處理方式 |
|---------|------|--------------|
| `UnauthorizedAccessException` | 帳號無 Task Scheduler 管理權限 | IsConnected=false + Demo 資料 |
| `PingException` | 網路不通，無法連到遠端 IP | IsConnected=false + Demo 資料 |
| `TimeoutException` | RPC 連線逾時（預設 30 秒） | IsConnected=false + Demo 資料 |
| `Exception`（其他） | COM 錯誤、服務未啟動等 | IsConnected=false + Demo 資料 |
| 非 Windows 環境 | 整個 TaskService 初始化失敗 | 回傳 Demo 任務資料（GetAllTasks） |

---

## 七、RPC 遠端連線的系統需求

要讓遠端 Windows Server 可被連線管理，需確認：

| 項目 | 設定方式 |
|------|---------|
| Task Scheduler 服務已啟動 | `services.msc` → Task Scheduler → 啟動 |
| Windows 防火牆開放 RPC | 開放 TCP Port **135** 及動態 RPC Port（49152-65535） |
| Remote Registry 服務 | 部分操作需要（建議啟動） |
| WMI 服務 | `winmgmt` 服務需啟動 |
| 執行帳號權限 | 連線帳號需有目標機器的本機管理員或 Task Scheduler 管理權限 |
| 網路可達性 | 應用程式伺服器需能透過 TCP 連達目標 Server |

---

## 八、本專案使用 API 的關係圖

```
TaskSchedulerService.cs
        │
        ├── GetAllTasks()
        │       └── TaskService.RootFolder.AllTasks（遍歷）
        │               └── Task.Name / Path / Enabled / State
        │                   LastRunTime / NextRunTime
        │                   RegistrationInfo.Description / Author
        │
        ├── GetTask()
        │       └── TaskService.GetTask(name)
        │               └── Task.Definition.Actions.OfType<ExecAction>()
        │                       └── ExecAction.Path / Arguments
        │
        ├── CreateTask()
        │       └── TaskService.NewTask()
        │               └── TaskDefinition.RegistrationInfo.Description / Author
        │               └── TaskDefinition.Actions.Add( ExecAction )
        │               └── TaskDefinition.Triggers.Add( DailyTrigger )
        │       └── TaskService.RootFolder.RegisterTaskDefinition(name, td)
        │
        ├── UpdateTask()
        │       └── TaskService.GetTask(name)
        │               └── td.RegistrationInfo.Description（更新）
        │               └── td.Actions.Clear() + Add(ExecAction)（更新）
        │               └── task.Definition.Principal.UserId / LogonType（保留）
        │       └── TaskService.RootFolder.RegisterTaskDefinition(CreateOrUpdate)
        │       └── updatedTask.Enabled = bool（更新啟用狀態）
        │
        ├── DeleteTask()
        │       └── TaskService.RootFolder.DeleteTask(name)
        │
        ├── EnableTask() / DisableTask()
        │       └── TaskService.GetTask(name)
        │               └── task.Enabled = true / false
        │
        ├── GetTaskHistory()
        │       └── TaskService.GetTask(name)
        │               └── task.GetRunTimes(start, end)
        │                   ⚠️ 回傳預計觸發時間，非真實執行日誌
        │
        ├── IsTaskRunning()
        │       └── TaskService.GetTask(name)
        │               └── task.State == TaskState.Running
        │
        └── GetTaskFolderTree()
                └── GetAllTasks() 後依 Path 解析組成 TaskFolderNode 樹狀結構
```

---

## 九、未使用但值得知道的 API（擴充參考）

| API | 說明 | 適用情境 |
|-----|------|---------|
| `task.Run()` | 手動立即執行任務 | 新增「立即執行」按鈕 |
| `task.Stop()` | 停止執行中的任務 | 新增「強制停止」功能 |
| `ts.RootFolder.GetFolders()` | 列出子資料夾 | 改用原生資料夾 API 取代路徑解析 |
| `ts.RootFolder.CreateFolder()` | 建立資料夾 | 支援在特定資料夾新增任務 |
| `task.GetInstances()` | 取得所有執行中的 Task Instance | 精確判斷是否有多個 instance 同時執行 |
| `WeeklyTrigger / MonthlyTrigger` | 每週/每月觸發器 | 擴充 Create/Edit 的排程設定選項 |
| `TimeTrigger` | 指定時間觸發（一次性） | 建立一次性任務 |
| `EventTrigger` | Windows 事件觸發 | 事件驅動的任務排程 |
| Event Log 查詢 | 真實執行歷史需從 Event Log 讀取 | 改善 History 功能的準確性 |

---

## 十、關鍵檔案索引

| 角色 | 路徑 |
|------|------|
| API 封裝服務 | `src/WindowsTaskManager/Services/TaskSchedulerService.cs` |
| 服務介面定義 | `src/WindowsTaskManager/Services/ITaskSchedulerService.cs` |
| 資料模型 | `src/WindowsTaskManager/Models/TaskInfo.cs` |
| NuGet 設定 | `src/WindowsTaskManager/WindowsTaskManager.csproj`（`TaskScheduler v2.12.2`） |
| 套件官網 | https://github.com/dahall/TaskScheduler |
| 套件 API 文件 | https://dahall.github.io/TaskScheduler |
