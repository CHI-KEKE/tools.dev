# 事件識別模式（Event Patterns）

本文件說明如何在 C# 專案中識別事件的發布（Publisher）與訂閱（Subscriber）。

---

## 識別 Publisher（事件發布者）

### 模式 1：直接呼叫 Publish 方法

```csharp
// MassTransit
await _bus.Publish(new OrderCreatedEvent { ... });

// RabbitMQ / Custom MQ
await _messagePublisher.PublishAsync("order.created", payload);

// Azure Service Bus
await _serviceBusSender.SendMessageAsync(new ServiceBusMessage(...));
```

**識別方式**：
- 搜尋 `Publish`、`PublishAsync`、`SendMessage`、`SendMessageAsync`
- 搜尋 `IPublishEndpoint`、`IBus`、`IMessagePublisher`、`ServiceBusSender`

### 模式 2：Domain Event（領域事件）

```csharp
// 將事件加入 Domain Entity 的待發布清單
entity.AddDomainEvent(new MemberUpgradedEvent(...));

// 在 UoW 提交後統一發布
foreach (var domainEvent in entity.DomainEvents)
    await _mediator.Publish(domainEvent);
```

**識別方式**：
- 搜尋 `AddDomainEvent`、`IDomainEvent`、`DomainEvents`
- 搜尋 `IMediator.Publish`、`INotification`

---

## 識別 Subscriber（事件訂閱者）

### 模式 1：MassTransit Consumer

```csharp
public class OrderCreatedConsumer : IConsumer<OrderCreatedEvent>
{
    public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
    {
        // 處理邏輯
    }
}
```

**識別方式**：
- 搜尋實作 `IConsumer<T>` 的類別
- 搜尋 `ConsumeContext<T>`

### 模式 2：MediatR Notification Handler

```csharp
public class MemberUpgradedHandler : INotificationHandler<MemberUpgradedEvent>
{
    public async Task Handle(MemberUpgradedEvent notification, CancellationToken ct)
    {
        // 處理邏輯
    }
}
```

**識別方式**：
- 搜尋實作 `INotificationHandler<T>` 的類別

### 模式 3：Worker 消費 MQ

```csharp
public class MessageWorker : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        await _consumer.SubscribeAsync<OrderCreatedEvent>(async msg => {
            // 處理邏輯
        });
    }
}
```

**識別方式**：
- 搜尋 Worker 的 `ExecuteAsync` 方法中的訂閱呼叫
- 搜尋 `Subscribe`、`SubscribeAsync`、`StartConsuming`

---

## 事件命名慣例

常見的事件命名模式（幫助識別事件類別）：

| 後綴模式 | 意義 |
|---|---|
| `*Event` | 通用事件 |
| `*Created` / `*Updated` / `*Deleted` | CRUD 事件 |
| `*Upgraded` / `*Downgraded` | 狀態變更事件 |
| `*Message` | 訊息型事件 |
| `*Command` | 命令型（通常 1:1） |
| `*Notification` | 通知型 |

---

## 注意事項

- 有些專案用自訂的 Event Bus 介面，搜尋時要看注入的介面名稱
- Worker 消費 MQ 時，訂閱的 Topic / Queue 名稱通常在 `appsettings.json` 中配置
- 如果找不到明確的事件，記錄「未識別到明確的事件機制」
