# ASP.NET Core WebAPI Logging 指南

> 適用：91APP N1 WebAPI 專案（.NET 8）
> 案例：AI Code Review API 從 Serilog 改用內建 Logging

---

## 問題起源

部署後 Deployment Log 出現大量 Health Check 噪音，每秒重複印出：

```
[14:03:39 INF] Executing endpoint 'Health checks'
[14:03:39 INF] Executed endpoint 'Health checks'
[14:03:39 INF] HTTP GET /_hc responded 200 in 0.0613 ms
[14:03:39 INF] Request finished HTTP/1.1 GET http://10.50.239.209:5566/_hc - 200 null text/plain
[14:03:40 INF] Request starting HTTP/1.1 GET http://10.50.239.209:5566/_hc - null null
...（無限重複）
```

這些是 K8s Liveness/Readiness Probe 每幾秒打一次 `/_hc` 產生的 log，完全無資訊價值。

---

## 根本原因分析

### 為什麼 LiveBuy 不會印？

LiveBuy 使用 **ASP.NET Core 內建 Logging**：

```json
// LiveBuy appsettings.json
"Logging": {
  "LogLevel": {
    "Default": "Information",
    "Microsoft": "Warning",          // ← 這一行
    "Microsoft.Hosting.Lifetime": "Information"
  }
}
```

`"Microsoft": "Warning"` 這條規則把整個 `Microsoft.*` namespace 的 log 壓到 Warning 以上才顯示，Health Check 相關的：
- `Microsoft.AspNetCore.Routing`（Executing/Executed endpoint）
- `Microsoft.AspNetCore.Diagnostics.HealthChecks`

全部被過濾掉，所以 LiveBuy **從來不會印 health check log**。

---

### 為什麼 AI Code Review 會一直印？

原本的專案使用 **Serilog**，並加了 `UseSerilogRequestLogging()` middleware：

```csharp
// 原本的 Program.cs
builder.Host.UseSerilog();
// ...
app.UseSerilogRequestLogging();  // ← 這個是問題所在
```

`UseSerilogRequestLogging()` 是 Serilog 獨立的 Request Logging middleware，**不受** `Microsoft.*` 的 LogLevel 設定控制。它對**每個 HTTP Request** 都會輸出一行 log，包含：

```
[INF] HTTP GET /_hc responded 200 in 0.06 ms
```

`/_hc` 每秒被打好幾次 → 每秒都印 → 造成 log 噪音。

---

## 解決方案比較

### 方案 A：Serilog 過濾（複雜）

需要兩個地方設定：

```csharp
// Program.cs：過濾 Serilog Request Log
app.UseSerilogRequestLogging(options =>
{
    options.GetLevel = (ctx, _, _) =>
        ctx.Request.Path.StartsWithSegments("/_hc")
            ? Serilog.Events.LogEventLevel.Verbose  // 降級讓它消失
            : Serilog.Events.LogEventLevel.Information;
});
```

```json
// appsettings.json：過濾 Microsoft Routing Log
"Serilog": {
  "MinimumLevel": {
    "Override": {
      "Microsoft.AspNetCore.Routing": "Warning",
      "Microsoft.AspNetCore.Diagnostics.HealthChecks": "Warning"
    }
  }
}
```

→ 需要維護兩套設定，且 Serilog 是額外依賴

---

### 方案 B：改用內建 Logging（推薦）✅

完全移除 Serilog，改用 ASP.NET Core 內建 Logging，與 LiveBuy 等標準 N1 專案一致。

---

## 實作方式（方案 B）

### 1. 移除 Serilog NuGet 套件

```xml
<!-- NineYi.Ai.CodeReview.Api.csproj 移除這三行 -->
<PackageReference Include="Serilog.AspNetCore" Version="8.0.0" />
<PackageReference Include="Serilog.Sinks.Console" Version="5.0.1" />
<PackageReference Include="Serilog.Sinks.File" Version="5.0.0" />
```

### 2. 修改 Program.cs

```csharp
// ❌ 移除
using Serilog;

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("logs/codereview-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// ❌ 移除
app.UseSerilogRequestLogging();

// ❌ 移除
try {
    Log.Information("Starting...");
    await app.RunAsync();
} finally {
    Log.CloseAndFlush();
}
```

```csharp
// ✅ 改用
try {
    app.Logger.LogInformation("Starting NineYi AI Code Review API");
    await app.RunAsync();
}
catch (Exception ex) {
    app.Logger.LogCritical(ex, "Application terminated unexpectedly");
}
```

### 3. 修改 appsettings.json

```json
// ❌ 移除 Serilog 區塊
"Serilog": {
  "MinimumLevel": { ... }
}

// ✅ 改用（與 LiveBuy 一致）
"Logging": {
  "LogLevel": {
    "Default": "Information",
    "Microsoft": "Warning",
    "Microsoft.Hosting.Lifetime": "Information"
  }
}
```

---

## 內建 Logging 設定說明

### LogLevel 數值對照

| Level | 數值 | 用途 |
|---|---|---|
| `Trace` | 0 | 最詳細，通常不開 |
| `Debug` | 1 | 開發偵錯用 |
| `Information` | 2 | 正常流程記錄 |
| `Warning` | 3 | 非預期但不影響運行 |
| `Error` | 4 | 錯誤，需要關注 |
| `Critical` | 5 | 嚴重錯誤，服務可能中斷 |
| `None` | 6 | 完全不記錄 |

### Override 規則（重要）

設定越具體的 namespace，優先度越高：

```json
"Logging": {
  "LogLevel": {
    "Default": "Information",               // 最低優先
    "Microsoft": "Warning",                 // 覆蓋所有 Microsoft.*
    "Microsoft.Hosting.Lifetime": "Information"  // 最高優先，覆蓋上面那條
  }
}
```

結果：
- `Microsoft.AspNetCore.Routing` → Warning（被 `Microsoft: Warning` 過濾）✅
- `Microsoft.Hosting.Lifetime` → Information（被具體規則覆蓋）✅ 可以看到 "Now listening on"
- 自己寫的 `NineYi.*` → Information（走 Default）✅

---

## Serilog vs 內建 Logging 比較

| 特性 | Serilog | 內建 Logging |
|---|---|---|
| 安裝 | 需要額外 NuGet 套件 | 內建，零套件 |
| 設定複雜度 | 較高（兩套設定） | 低（一個 `Logging` 區塊） |
| Request Logging | `UseSerilogRequestLogging()` middleware | 無獨立 middleware（由框架處理） |
| Health Check 噪音 | 需額外過濾 | `Microsoft: Warning` 自動過濾 |
| Structured Log | ✅ 支援 | ✅ 支援（JSON 輸出） |
| 與 N1 標準一致 | ❌ | ✅ |

---

## 實際效果

移除 Serilog 後，Log 只會看到有意義的資訊：

```
[INF] Starting NineYi AI Code Review API
[INF] Now listening on: http://[::]:5566
[INF] Application started. Press Ctrl+C to shut down.
[INF] Received Bitbucket webhook for PR #42
[INF] Code review completed for repo: nineyi.webstore.mobilewebmall
```

K8s 每秒打的 `/_hc` → 完全靜默，不再干擾。

---

## 快速 Checklist

新建 N1 WebAPI 專案時的 Logging 設定：

- [ ] 不安裝 Serilog（除非有特殊需求如寫檔案、遠端 Sink）
- [ ] `appsettings.json` 使用標準 `Logging.LogLevel` 設定
- [ ] `"Microsoft": "Warning"` 過濾框架噪音
- [ ] `"Microsoft.Hosting.Lifetime": "Information"` 保留啟動訊息
- [ ] **不要** 加 `UseSerilogRequestLogging()`
- [ ] 自己的程式碼注入 `ILogger<T>` 使用
