# Windows Task Manager — 系統架構與核心流程分析

> 分析日期：2026-05-19
> 涉及專案：`nine1.tools.windows-task-manager`（單一專案）
> 路徑：`C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager`

---

## 一、在整個流程中的位置（Big Picture）

```bash
公司內部人員（Browser）
        │
        │ HTTP Request
        ▼
[Windows Task Manager Web]  ← 本文件分析範疇
    ASP.NET Core 8.0 / Razor Pages / IIS
        │
        ├─── 認證層（Google OAuth 2.0 / Demo）
        │        └─ user-roles.json（角色設定）
        │
        └─── 排程操作層（Microsoft.Win32.TaskScheduler）
                 │
                 ├─ localhost / 127.0.0.1 → 本機 Windows Task Scheduler
                 └─ 遠端 IP → 遠端 Windows Server Task Scheduler
                              （RPC Port 135，支援帳密/網域/ServiceAccount）
```

**系統定位**：提供一個 Web UI，讓公司人員不需遠端桌面登入 Windows Server，透過瀏覽器即可對 Windows Task Scheduler 執行 CRUD 與啟停管理。

---

## 二、觸發條件

| 情境 | 觸發方式 |
|------|---------|
| 查看任務列表 | 使用者登入後進入 `/Tasks/Index` |
| 新增任務 | 使用者點選「新增任務」→ `/Tasks/Create` |
| 編輯任務 | 使用者點選「編輯」→ `/Tasks/Edit?taskName=xxx` |
| 刪除任務 | 使用者點選「刪除」→ POST `/Tasks/Delete` |
| 啟用/停用 | 使用者點選開關→ POST `/Tasks/Toggle` |
| 查看執行歷史 | 使用者點選「歷史」→ `/Tasks/History` |
| 登入 | 使用者點擊「Google 登入」→ `/Login` → Google OAuth → `/LoginCallback` |

**前置條件**：
1. 使用者必須已登入（`[Authorize]`）
2. 必須在 Session 中已選擇 Server（`Session["SelectedServer"]`）
3. 對應角色必須符合操作權限（`Policy`）

---

## 三、認證流程（Google OAuth）

```bash
使用者點選「Google 登入」
        │
        ▼
/Login  → 導向 Google OAuth 2.0 授權頁
        │
        ▼
Google 授權完成
        │
        ▼
/LoginCallback  OnGetAsync()
        │
        ├─ AuthenticateAsync() 失敗 → Redirect /Login
        │
        ├─ 取得 Email
        │     └─ Email 為空 → LogWarning + Redirect /Login
        │
        ├─ UserRoleService.GetUserRole(email)
        │     └─ 查 user-roles.json，找不到 → 預設 ReadOnly
        │
        ├─ 建立含 Role Claim 的 ClaimsPrincipal
        │
        ├─ SignInAsync( Cookie Scheme )
        │
        └─ Redirect /Index
```

### Development 模式（Demo 認證）

```bash
任何 HTTP Request
        │
        ▼
DemoAuthenticationHandler.HandleAuthenticateAsync()
        │
        └─ 直接回傳固定 Claims：
              Name: "Demo Admin"
              Email: "admin@demo.local"
              Role: "Admin"   ← 無需 user-roles.json
```

---

## 四、核心流程 — Task 管理 CRUD

### 4-1 任務列表（Index）

```bash
GET /Tasks/Index
        │
        ├─ 讀取 Session["SelectedServer"]
        │     └─ 為空 → Redirect /Index（首頁選 Server）
        │
        ├─ ServerService.GetServerInfo(serverName)
        │     └─ Cache Miss → RefreshServerInfo() → 再取
        │           └─ 仍找不到 → Redirect /Index
        │
        ├─ ViewMode == "tree"（預設）
        │     └─ TaskSchedulerService.GetTaskFolderTree(serverName)
        │           └─ 依 Task Path 建立樹狀結構（TaskFolderNode）
        │                 └─ 有 SearchQuery/StatusFilter → FilterFolderTree()
        │
        └─ ViewMode == "list"
              └─ TaskSchedulerService.GetAllTasks(serverName)
                    └─ 依 SearchQuery / StatusFilter 過濾後回傳
```

### 4-2 新增任務（Create）

```bash
GET /Tasks/Create  → 空表單（需 ReadWriteOrAdmin）

POST /Tasks/Create
        │
        ├─ 驗證：TaskName、Program 不可空
        │     └─ 失敗 → 停留表單 + TempData["Error"]
        │
        └─ TaskSchedulerService.CreateTask(taskName, program, arguments)
              │
              ├─ 成功 → TempData["Message"] + Redirect /Tasks/Index
              └─ 例外 → TempData["Error"] + 停留表單
```

**CreateTask 底層行為**：
1. `ts.NewTask()` 建立新 TaskDefinition
2. 設定 Description、Author（`Environment.UserName`）
3. 加入 `ExecAction(program, arguments)`
4. 若有 schedule → 加入 `DailyTrigger`（目前固定每日）
5. `ts.RootFolder.RegisterTaskDefinition(taskName, td)`

### 4-3 編輯任務（Edit）

```bash
GET /Tasks/Edit?taskName=xxx  （需 ReadWriteOrAdmin）
        │
        ├─ TaskName 為空 → TempData["Error"] + Redirect /Tasks/Index
        ├─ GetTask(TaskName) == null → TempData["Error"] + Redirect
        └─ 填入表單（Program, Arguments, Description, IsEnabled）

POST /Tasks/Edit
        │
        ├─ 驗證：TaskName、Program 不可空
        │
        └─ UpdateTask(TaskName, Program, Arguments, Description, IsEnabled)
              │
              ├─ GetTask() → 取得現有 TaskDefinition
              ├─ 更新 Description
              ├─ 清空 Actions → 重新加入 ExecAction
              ├─ 保留原有 Triggers / Principal / LogonType
              ├─ RegisterTaskDefinition(CreateOrUpdate) 重新註冊
              ├─ 再取更新後任務 → 設定 Enabled 狀態
              │
              ├─ 成功 → TempData["Message"] + Redirect /Tasks/Index
              └─ 例外 → TempData["Error"] + 停留表單
```

### 4-4 刪除任務（Delete）

```bash
POST /Tasks/Delete  （需 AdminOnly）
        │
        ├─ name 為空 → TempData["Error"] + Redirect /Tasks/Index
        │
        ├─ Session["SelectedServer"] 有值 → DeleteTask(name, serverName)
        ├─ Session["SelectedServer"] 無值 → DeleteTask(name)（本機）
        │
        ├─ 成功 → TempData["Message"] + Redirect /Tasks/Index
        └─ 例外 → TempData["Error"] + Redirect /Tasks/Index
```

**DeleteTask 底層**：`ts.RootFolder.DeleteTask(taskName)`（硬刪除，無軟刪除）

### 4-5 啟用/停用（Toggle）

```bash
POST /Tasks/Toggle?name=xxx&action=enable|disable  （需 ReadWriteOrAdmin）
        │
        ├─ name 或 action 為空 → 400 BadRequest
        ├─ Session["SelectedServer"] 無值 → Redirect /Index
        │
        ├─ action == "enable"  → EnableTask(name, serverName)
        │                            task.Enabled = true
        ├─ action == "disable" → DisableTask(name, serverName)
        │                            task.Enabled = false
        │
        ├─ 成功 → TempData["Message"] + Redirect /Tasks/Index
        └─ 例外 → TempData["Error"] + Redirect /Tasks/Index
```

### 4-6 執行歷史（History）

```bash
GET /Tasks/History?taskName=xxx  （需 Authorize）
        │
        ├─ taskName 有值 → GetTaskHistory(taskName)
        │     └─ task.GetRunTimes(now-30天, now)
        │           ⚠️ 注意：Result 固定為 "Completed"，無真實執行結果
        │
        └─ taskName 無值 → 取前 5 個任務的歷史合併，依 StartTime 降序
```

---

## 五、分支決策表

### 5-1 權限 Policy 對照

| 操作 | Policy | 允許角色 |
|------|--------|---------|
| 查看列表 / 執行歷史 | `[Authorize]` | ReadOnly、ReadWrite、Admin |
| 新增 / 編輯 / 啟停 | `ReadWriteOrAdmin` | ReadWrite、Admin |
| 刪除 | `AdminOnly` | Admin 只 |

### 5-2 StatusFilter 過濾對照

| StatusFilter 值 | 篩選條件 |
|----------------|---------|
| `enabled` | `t.IsEnabled == true` |
| `disabled` | `t.IsEnabled == false` |
| `running` | `t.Status == "Running"` |
| `all` / 空 / 其他 | 不篩選，顯示全部 |

### 5-3 Server 連線方式對照

| 條件 | 連線行為 |
|------|---------|
| serverName 為空 | `new TaskService()` 本機 |
| IPAddress == localhost / 127.0.0.1 | `new TaskService()` 本機 |
| AuthMethod == "CurrentUser" / "ServiceAccount" | `new TaskService(ipAddress)` 只傳 IP |
| AuthMethod == 其他（預設帳密） | `new TaskService(ip, username, domain, password)` |

### 5-4 遠端連線例外處理

| 例外類型 | 行為 |
|---------|------|
| `UnauthorizedAccessException` | IsConnected=false，GenerateDemoData() |
| `PingException` | IsConnected=false，GenerateDemoData() |
| `TimeoutException` | IsConnected=false，GenerateDemoData() |
| `Exception`（其他） | IsConnected=false，GenerateDemoData() |

---

## 六、狀態流轉圖

### 任務 Enabled 狀態

```bash
[任務建立（預設 Enabled）]
        │
        ├─ Toggle disable → [Disabled]
        │       └─ Toggle enable → [Enabled]
        │
        ├─ Edit + IsEnabled=false → [Disabled]
        │       └─ Edit + IsEnabled=true → [Enabled]
        │
        └─ Delete（Admin） → [已刪除，不可恢復]
```

### 使用者角色狀態

```bash
[新使用者首次 Google 登入]
        │
        └─ user-roles.json 無記錄 → [ReadOnly]（預設）
                │
                └─ Admin 在管理頁面設定 → [ReadOnly / ReadWrite / Admin]
```

---

## 七、例外處理一覽

| 發生位置 | 例外情況 | 處理方式 | 用戶端結果 |
|---------|---------|---------|-----------|
| `LoginCallback` | Google 認證失敗 | Redirect /Login | 回到登入頁 |
| `LoginCallback` | Email 為空 | LogWarning + Redirect /Login | 回到登入頁 |
| `TaskSchedulerService.GetAllTasks` | 非 Windows / 無權限 | catch → 回傳 Demo 資料 | 看到示範任務 |
| `TaskSchedulerService.GetTask` | 任務不存在 | return null | 上層 Page 處理 |
| `TaskSchedulerService.CreateTask` | 失敗 | throw InvalidOperationException | TempData["Error"] |
| `TaskSchedulerService.UpdateTask` | 任務不存在 | throw InvalidOperationException | TempData["Error"] |
| `TaskSchedulerService.UpdateTask` | 其他失敗 | Console.WriteLine + throw | TempData["Error"] |
| `TaskSchedulerService.DeleteTask` | 失敗 | throw InvalidOperationException | TempData["Error"] |
| `TaskSchedulerService.EnableTask` | 失敗 | throw InvalidOperationException | TempData["Error"] |
| `TaskSchedulerService.GetTaskHistory` | 任何錯誤 | 吞掉例外，回傳空清單 | 顯示無歷史 |
| `ServerService.GetServerInfoFromConfig` | 遠端連線失敗 | IsConnected=false + DemoData | 顯示模擬數字 |
| 全域 | 未捕獲例外 | `Log.Fatal` → 應用程式結束 | IIS 500 |

---

## 八、關鍵資料說明

### Session["SelectedServer"]
- **產生**：首頁（`/Index`）使用者選擇 Server 後寫入 Session
- **傳遞**：所有 Task 相關 Page（Index / Delete / Toggle）從 Session 讀取
- **消費**：決定 `TaskSchedulerService` 連接哪台 Windows Server
- **過期**：Session IdleTimeout = 30 分鐘

### user-roles.json
- **格式**：`{ "email@domain.com": "Admin" | "ReadWrite" | "ReadOnly" }`
- **讀取時機**：`UserRoleService` 建構時一次性載入到記憶體 Dictionary
- **寫入時機**：Admin 在管理頁面修改角色時即時寫入檔案
- **未找到 email**：預設回傳 `UserRole.ReadOnly`

### TaskFolderNode（樹狀結構）
- 由 `GetTaskFolderTree()` 依照任務 Path 動態建立
- 每次請求都重新建構（無快取）
- `TotalTasks / EnabledTasks / DisabledTasks` 為遞迴計算的計算屬性

---

## 九、特殊案例 / 備註

| 項目 | 說明 |
|------|------|
| **非 Windows 環境** | `TaskSchedulerService` 全部操作均 try-catch，失敗時回傳 Demo 資料，不拋出例外到 UI |
| **歷史記錄限制** | `GetTaskHistory` 使用 `GetRunTimes`（預計執行時間），非真實執行結果，Result 固定為 `"Completed"` |
| **無限制任務過濾** | `GetAllTasks` 排除 `\Microsoft\` 路徑下的系統任務 |
| **UpdateTask 保留設定** | 更新時保留原 Triggers、Principal、LogonType，只修改 Actions 和 Description |
| **Google OAuth 機敏資訊** | ClientId/ClientSecret 不放 appsettings，透過環境變數或 web.config 注入 |
| **HTTP 環境支援** | `CookieSecurePolicy.None` + `UseHttps = false`，允許內部 HTTP 測試環境部署 |
| **DemoAuth 開發模式** | 只在 `Development` 環境啟用，Production/QA 強制使用 Google OAuth |
| **軟刪除** | 目前無軟刪除機制，Delete 為直接呼叫 `RootFolder.DeleteTask`，不可恢復 |
| **History 只取前 5 筆** | 無 taskName 時只取前 5 個任務的歷史，效能考量的硬限制 |

---

## 十、關鍵檔案索引

| 角色 | 路徑 |
|------|------|
| 應用程式進入點 / DI 設定 | `src/WindowsTaskManager/Program.cs` |
| Demo 認證處理器 | `src/WindowsTaskManager/DemoAuthenticationHandler.cs` |
| Google OAuth Callback | `src/WindowsTaskManager/Pages/LoginCallback.cshtml.cs` |
| 任務列表 Page | `src/WindowsTaskManager/Pages/Tasks/Index.cshtml.cs` |
| 新增任務 Page | `src/WindowsTaskManager/Pages/Tasks/Create.cshtml.cs` |
| 編輯任務 Page | `src/WindowsTaskManager/Pages/Tasks/Edit.cshtml.cs` |
| 刪除任務 Page | `src/WindowsTaskManager/Pages/Tasks/Delete.cshtml.cs` |
| 啟停任務 Page | `src/WindowsTaskManager/Pages/Tasks/Toggle.cshtml.cs` |
| 執行歷史 Page | `src/WindowsTaskManager/Pages/Tasks/History.cshtml.cs` |
| **核心服務：Task Scheduler** | `src/WindowsTaskManager/Services/TaskSchedulerService.cs` |
| **核心服務：使用者角色** | `src/WindowsTaskManager/Services/UserRoleService.cs` |
| **核心服務：Server 管理** | `src/WindowsTaskManager/Services/ServerService.cs` |
| Task 資料模型 | `src/WindowsTaskManager/Models/TaskInfo.cs` |
| 使用者角色列舉 | `src/WindowsTaskManager/Models/UserRole.cs` |
| Server 設定模型 | `src/WindowsTaskManager/Models/ServerInfo.cs` |
| 使用者角色設定 | `src/WindowsTaskManager/user-roles.json` |
| 環境設定（含 ServersConfig） | `src/WindowsTaskManager/appsettings.json` |

---

## 文件缺少元素說明

| 元素 | 狀態 | 原因 |
|------|------|------|
| Request/Response 格式 | ⏭️ 略過 | 本專案為 Razor Pages（非 REST API），無 JSON 合約 |
| Admin 頁面流程 | ⚠️ 未分析 | `Pages/Admin/` 目錄未納入本次範疇 |
| `appsettings.json` ServersConfig 結構 | ⚠️ 未列出 | 可補充多台 Server 設定方式 |
| wwwroot / 前端 JS 行為 | ⚠️ 未分析 | 搜尋/過濾的前端互動未追蹤 |
