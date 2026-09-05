# C# 專案結構識別模式

本文件提供識別 .NET/C# 專案各種結構特徵的參考資料，供盤點分析時使用。

---

## 專案類型識別

### 從 .csproj 判斷

```xml
<!-- Web API -->
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <!-- OutputType 通常不寫，預設就是 Exe -->
  </PropertyGroup>
</Project>

<!-- Console App / Worker Service -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
  </PropertyGroup>
  <!-- Worker 特徵：Microsoft.Extensions.Hosting -->
</Project>

<!-- Class Library -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Library</OutputType>
    <!-- 或不寫 OutputType -->
  </PropertyGroup>
</Project>
```

### 從 NuGet 套件判斷

| 套件 | 代表的類型 |
|---|---|
| `Microsoft.AspNetCore.*` | Web API |
| `Microsoft.Extensions.Hosting.Abstractions` | Worker Service |
| `Microsoft.EntityFrameworkCore.*` | 有資料庫存取 |
| `StackExchange.Redis` | 有 Redis 操作 |
| `RabbitMQ.Client` | 有 RabbitMQ 操作 |
| `MassTransit.*` | 訊息佇列抽象層（可能用 RabbitMQ 或 ASB）|
| `xunit` / `NSubstitute` / `FluentAssertions` | 測試專案 |
| `Swashbuckle.AspNetCore` | Web API（有 Swagger）|

---

## 常見目錄結構模式

### 標準分層架構

```
ProjectName/
├── Controllers/          → HTTP 端點（Web API 專用）
├── Services/             → 業務邏輯層
│   ├── Interfaces/       → Service 介面定義
│   └── Implementations/  → Service 實作
├── Repositories/         → 資料存取層
│   ├── Interfaces/
│   └── Implementations/
├── Models/               → 資料模型
│   ├── Requests/         → API 請求 DTO
│   ├── Responses/        → API 回應 DTO
│   └── Entities/         → DB Entity
├── Mappers/              → DTO ↔ Entity 轉換
├── Validators/           → 輸入驗證
├── Helpers/              → 工具方法
├── Extensions/           → 擴充方法
├── Configurations/       → 設定類別（對應 appsettings section）
├── Middlewares/          → ASP.NET Core 中介層
├── Filters/              → Action Filter
└── Exceptions/           → 自定義例外
```

### Worker Service 結構

```
WorkerName/
├── Workers/              → IHostedService 實作
├── Handlers/             → 訊息處理器
├── Consumers/            → 訊息佇列消費者
├── Services/             → 業務邏輯
└── Configurations/       → 設定
```

---

## 進入點識別

### Web API 進入點
```csharp
// Program.cs 特徵
builder.Services.AddControllers();
app.MapControllers();

// Controller 特徵
[ApiController]
[Route("api/[controller]")]
public class OrderController : ControllerBase
```

### Worker Service 進入點
```csharp
// Program.cs 特徵
builder.Services.AddHostedService<MyWorker>();

// Worker 特徵
public class MyWorker : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken) { }
}
```

### 訊息消費者進入點
```csharp
// MassTransit 特徵
public class OrderCreatedConsumer : IConsumer<OrderCreated>
{
    public async Task Consume(ConsumeContext<OrderCreated> context) { }
}

// 原生 RabbitMQ 特徵
_channel.BasicConsume(queue: "order.queue", autoAck: false, consumer: consumer);
```

---

## 相依關係掃描模式

### 建構子注入（最常見）
```csharp
public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IMemberService _memberService;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        IOrderRepository repository,
        IMemberService memberService,
        ILogger<OrderService> logger)
    {
        _repository = repository;
        _memberService = memberService;
        _logger = logger;
    }
}
```
掃描 `private readonly` 欄位 + 建構子參數，可以識別所有注入的依賴。

### 外部 HTTP 呼叫模式
```csharp
// HttpClient 模式
private readonly HttpClient _httpClient;
await _httpClient.GetAsync("https://...");
await _httpClient.PostAsJsonAsync("/api/...", request);

// IHttpClientFactory 模式
var client = _httpClientFactory.CreateClient("MemberService");
```

### Redis 存取模式
```csharp
// IDistributedCache
await _cache.GetStringAsync(key);
await _cache.SetStringAsync(key, value, options);

// StackExchange.Redis
var db = _redis.GetDatabase();
await db.StringGetAsync(key);
await db.StringSetAsync(key, value, expiry);
```

### EF Core 資料庫存取模式
```csharp
// DbContext
public class OrderDbContext : DbContext
{
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
}

// 查詢
await _context.Orders
    .Where(o => o.MemberId == memberId)
    .ToListAsync();

// 寫入
_context.Orders.Add(order);
await _context.SaveChangesAsync();
```

### 訊息發佈模式
```csharp
// MassTransit
await _publishEndpoint.Publish(new OrderCreated { ... });
await _sendEndpoint.Send(new ProcessOrder { ... });

// 原生 RabbitMQ
_channel.BasicPublish(exchange: "order.exchange", routingKey: "order.created", ...);

// Azure Service Bus
await _sender.SendMessageAsync(new ServiceBusMessage(...));
```

---

## 技術債掃描模式

### TODO / FIXME 掃描
```
// TODO: 這裡需要加入驗證
// FIXME: 效能問題，需要優化
// HACK: 暫時解決方案
// XXX: 這裡有已知問題
```

### Magic Number 識別
```csharp
// ⚠️ Magic Number
if (memberPoints > 1000)  // 1000 是什麼？
var expiry = TimeSpan.FromSeconds(86400);  // 86400 = 一天？

// ✅ 良好做法
private const int GoldTierThreshold = 1000;
private static readonly TimeSpan DefaultExpiry = TimeSpan.FromDays(1);
```

### 方法過長識別
行數 > 100 行的方法通常包含：
- 多個業務邏輯分支（多個 if/switch）
- 重複性程式碼（應抽出為 private method）
- 在同一個方法中混合了驗證、處理、回應組裝

---

## 命名慣例識別

### 層次識別（從命名推斷職責）

| 類別名稱尾碼 | 層次 | 職責 |
|---|---|---|
| `Controller` | 表現層 | HTTP 端點 |
| `Service` | 業務層 | 業務邏輯 |
| `Repository` | 資料層 | DB CRUD |
| `Handler` | 應用層 | 命令/查詢處理 |
| `Validator` | 業務層 | 輸入驗證 |
| `Mapper` / `Profile` | 跨層 | 物件映射 |
| `Factory` | 跨層 | 物件建立 |
| `Extension` | 工具 | 擴充方法 |
| `Helper` / `Util` | 工具 | 輔助方法 |
| `Entity` / `Model` | 資料 | 資料結構 |
| `Request` / `Response` | 表現層 | API DTO |
| `Config` / `Options` | 設定 | 設定值對應 |
| `Background` / `Worker` | 背景 | 背景作業 |
| `Consumer` | 訊息 | 訊息消費 |

### C# 命名風格

```csharp
// ✅ 屬性命名：PascalCase
public string OrderId { get; set; }
public bool IsActive { get; set; }

// ✅ 私有欄位：_camelCase
private readonly IOrderService _orderService;

// ✅ 方法：PascalCase
public async Task<Order> GetOrderAsync(int orderId)

// ✅ 常數：PascalCase 或 ALL_CAPS（舊式）
private const int MaxRetryCount = 3;
```
