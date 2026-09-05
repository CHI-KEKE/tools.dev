## cheetsheet

```csharp
//// new Task<T>(() =>{})
var task = new Task<int>(() => 
{
    int time = new Random().Next(1,5);
    Thread.Sleep(TimeSpan.FromSeconds(time));
    return time;
});

//// START / WAIT / isCompleted
task.Start();
task.IsCompleted
task.Wait();

//// whenall
await Task.WhenAll(BrewCoffeeAsync(),FryEggsAsync(),ToastBreadAsync());

var tasks = urls.Select(async url => await httpClient.GetStringAsync(url)); // 這裡得到 IEnumerable<Task<string>>
var contents = await Task.WhenAll(tasks);  // 正確等待所有請求


//// delay
await Task.Delay(2000); 

//// from result
return Task.FromResult(…)

//// task.run
await Task.Run(() => { throw new InvalidOperationException("無法烤麵包"); });

ThreadPool.GetMinThreads(out minWorker, out minIOC);
ThreadPool.GetMaxThreads(out maxWorker, out maxIOC);
Thread.CurrentThread.ManagedThreadId


Task.Factory.StartNew(() => {
    Console.WriteLine("Time | Threads | Running | Pending ");
    Console.WriteLine("-----+---------+---------+---------");
    while(stop == false)
    {
        Console.WriteLine($"{(DateTime.Now - startDatetime).TotalSeconds,3:n0}s | {ThreadPool.ThreadCount,7} | {running,7} | {ThreadPool.PendingWorkItemCount,7}");
        Thread.Sleep(1000);
    }
});

// 丟任務給 ThreadPool
Enumerable.Range(0, totalTasksCount).ToList().ForEach(i =>
{
    Task.Run(() => {
        Interlocked.Increment(ref running);
        Thread.Sleep(60000);
        Interlocked.Decrement(ref remainingCount);
        Interlocked.Decrement(ref running);
    });
});

var inputTask = Task.Run(() => System.Console.ReadKey()); // 讓他跑, 不 await

var completedTask = await Task.WhenAny(inputTask, deplayTask); // await 取回 真正先完成的那個 Task, 而非裁判自己


var tasks = new List<Task>
{
    Task.Run(() => throw new InvalidOperationException("錯誤 A")),
    Task.Run(() => throw new NotImplementedException("錯誤 B"))
};

await Task.WhenAll(tasks);


var getContentTasks  = new List<Task<byte[]>>();
foreach(var url in urls)
{
    // 呼叫 DownloadFileAsync(url) → ⚠️ 這一步會「建立並啟動」一個非同步任務。
    // 把那個回傳的 Task<byte[]> 加進 getContentTasks List。
    // 所以在這一步已經啟動任務
    // 相當於 var task = DownloadFileAsync(url); // 🚀 下載開始！ getContentTasks.Add(task); // 🧺 放進任務清單
    getContentTasks.Add(DownloadFileAsync(url));
}

var contents = await Task.WhenAll(getContentTasks);

foreach(var content in contents)
{
    $"Sunccessfully donwloaded conetnt, length : {content.Length}".Dump();
    var fileString = System.Text.Encoding.UTF8.GetString(content);
    var preview = fileString.Substring(0, Math.Min(50, fileString.Length));
    $"Preview : {preview}".Dump();
}


var tasks = validators.Select(v => v.IsValidAsync(context)).ToList();
var result = await Task.WhenAll(tasks);



var result = Task.WhenAll(tasks);
foreach(var i in Enumerable.Range(1,3))
{
    $"main thread 繼續作業中 no.{i} ThreadId : {Thread.CurrentThread.ManagedThreadId}".Dump();
    await Task.Delay(500);
}
await result;


var tasks = urls.Select(async url => {
    var response = await client.GetAsync(url);
    var content = await response.Content.ReadAsStringAsync();
    return (Url: url, Content: content);
});

var result = await Task.WhenAll(tasks);
var dicts = result.ToDictionary(x => x.Url, x => x.Content);
```


## 例外

Task.WhenAll() 在「有任一個 Task 出現例外」時的行為 👇

await Task.WhenAll(task1, task2, task3);

如果其中 任何一個 Task 拋出例外（Exception）：

Task.WhenAll 本身會進入 Faulted 狀態。

它不會立刻停止其他 Task。其他 Task 仍會繼續執行，直到完成。

所有 Task 都完成後，Task.WhenAll 才會結束，並聚合所有例外到 AggregateException 裡。



async Task Demo()
{
    var t1 = Task.Run(() => throw new InvalidOperationException("A 錯誤"));
    var t2 = Task.Run(() => throw new ArgumentException("B 錯誤"));
    var t3 = Task.Run(() => "OK");

    try
    {
        await Task.WhenAll(t1, t2, t3);
    }
    catch (Exception ex)
    {
        Console.WriteLine(ex.GetType().Name); // => AggregateException
        Console.WriteLine(ex.Message);        // => One or more errors occurred.
        
        // 如果要看細節：
        if (ex is AggregateException agg)
        {
            foreach (var inner in agg.InnerExceptions)
            {
                Console.WriteLine($"Inner: {inner.GetType().Name} - {inner.Message}");
            }
        }
    }
}


AggregateException
One or more errors occurred.
Inner: InvalidOperationException - A 錯誤
Inner: ArgumentException - B 錯誤


| 行為                                                               | 說明                                                        |
| ---------------------------------------------------------------- | --------------------------------------------------------- |
| ✅ 所有 Task 都會執行完                                                  | 不會因為一個錯誤就提前中斷。                                            |
| ⚠️ `await` 會丟出 AggregateException                                | 要用 `catch (Exception)` 或 `catch (AggregateException)` 接住。 |
| ✅ 可透過 `Task.WhenAll(...).ContinueWith()` 處理例外                    | 若不想用 try/catch，也可在 ContinueWith 內觀察 `.Exception`。         |
| 🧩 可用 `Task.WhenAll().ConfigureAwait(false)` 在非 UI 環境避免 deadlock | 特別是在 ASP.NET 或 console app 裡。                             |


👉 即使其中一個 Task 發生 Exception，其他尚未出錯或尚未完成的 Task 仍然會繼續執行到結束。



## best practice

💡 Guideline 1：Avoid async void

（盡量不要使用 async void）


🌱 白話解釋

在 C# 裡，async 方法通常有三種回傳型別：

Task

Task<T>

void

前兩種（Task 與 Task<T>）才是自然的非同步回傳型別，因為它們會回傳一個「代表這個動作」的 Task 物件。

而 async void 是個特例，主要是為了讓 事件處理器（Event Handler） 能夠是非同步的，例如：



private async void button1_Click(object sender, EventArgs e)
{
    await Task.Delay(1000);
}


⚠️ 為什麼其他情況要避免？

例外處理（Exception Handling）會出問題

async Task 的例外會被包在 Task 裡面 → 呼叫者可以 await 或用 try/catch 接住。

async void 的例外會直接丟到 SynchronizationContext，導致你在 try/catch 裡面也接不到錯。


private async void ThrowExceptionAsync()
{
    throw new InvalidOperationException();
}

public void Test()
{
    try
    {
        ThrowExceptionAsync();
    }
    catch
    {
        // 永遠不會進來！
    }
}



無法組合（Composability）

Task 可以被 await、Task.WhenAll、Task.WhenAny 等操作組合。

void 沒有 Task 可供追蹤，無法知道它什麼時候結束。

難以測試（Unit Test）
單元測試框架（例如 MSTest、xUnit）只能等待 Task 型別，不能測 async void。



✅ 實務建議

除了事件處理器（event handler）外，請一律用 async Task 或 async Task<T>。

若事件處理器中有邏輯，可分拆成可測試的 async Task 方法：

private async void button1_Click(object sender, EventArgs e)
{
    await DoSomethingAsync();
}

public async Task DoSomethingAsync()
{
    await Task.Delay(1000);
}




💡 Guideline 2：Async all the way

（非同步要一路到底，不要一半同步一半非同步）

🌱 白話解釋

非同步就像「傳染病」或「烏龜層層疊」（作者原文比喻）。
你一旦讓某個方法變成 async，它呼叫的上層也要變成 async，一路傳到最外層。

⚠️ 為什麼不能混著用？

因為如果你用同步的方式去「等非同步結果」，例如：


var task = DelayAsync();
task.Wait(); // 或 task.Result



在 GUI 或 ASP.NET 環境下會造成 死結（Deadlock）。

💥 死結的原因

await 會捕捉目前的 SynchronizationContext（GUI 或 ASP.NET 環境只允許一個動作同時執行）。

當你呼叫 Task.Wait() 時，主執行緒在等結果；
而 await 又要回到主執行緒繼續執行 → 雙方互等 → 卡死。

✅ 解法

讓 async 由內往外傳到底。
例如讓 controller、event handler、service 都改成 async。

如果是 Console App，Main 不能是 async，所以這裡是唯一可例外：


static void Main() => MainAsync().Wait();
static async Task MainAsync() => await Task.Delay(1000);


永遠用 await 取代 .Result 或 .Wait()。



💡 Guideline 3：Configure Context（使用 ConfigureAwait(false)）
🌱 白話解釋

await 會自動「記住目前的執行環境（context）」，完成後再回去。
這在 GUI 程式裡很方便，因為可以回 UI 執行續更新畫面。

但在非 GUI 或大量 await 的情況下，這會拖慢效能。
所以你可以在 await 後加 .ConfigureAwait(false)，告訴程式：

「這段 await 完成後，不需要回原本的 context，用 thread pool 執行就好。」



await Task.Delay(1000).ConfigureAwait(false);
⚙️ 效能與死結的關聯
避免頻繁回 UI thread，能提升效能。

若使用 .ConfigureAwait(false)，有時還能避免死結（因為不綁定 context）。

🚫 什麼情況不能用？
當你 await 之後需要「回 UI 控制項」或「使用 HttpContext」時，不能用 ConfigureAwait(false)。

csharp
Copy code
private async void button_Click(object sender, EventArgs e)
{
    button.Enabled = false;
    await Task.Delay(1000); // 不要加 ConfigureAwait(false)
    button.Enabled = true;  // 需要回 UI
}
但若邏輯可以拆開，像這樣就能在子方法使用：

csharp
Copy code
private async Task DoWorkAsync()
{
    await Task.Delay(1000).ConfigureAwait(false);
}


💡 Guideline 4：Know Your Tools（熟悉常用非同步工具）

| 需求            | 工具                                              |
| ------------- | ----------------------------------------------- |
| 執行背景工作        | `Task.Run()`                                    |
| 包裝舊式 async 模型 | `TaskCompletionSource<T>`                       |
| 支援取消          | `CancellationTokenSource` / `CancellationToken` |
| 回報進度          | `IProgress<T>` / `Progress<T>`                  |
| 處理資料流         | `TPL Dataflow` / `Reactive Extensions (Rx)`     |
| 鎖定共享資源        | `SemaphoreSlim.WaitAsync()`                     |
| 非同步初始化        | `AsyncLazy<T>`                                  |
| 非同步佇列         | `BufferBlock<T>` / `AsyncCollection<T>`         |


🔒 非同步鎖的例子

SemaphoreSlim mutex = new SemaphoreSlim(1);
int value;

async Task UpdateValueAsync()
{
    await mutex.WaitAsync();
    try
    {
        value = await GetNextValueAsync(value);
    }
    finally
    {
        mutex.Release();
    }
}

這樣可以避免兩個同時執行的 async 方法修改同一個資源。


| Guideline             | 重點                                                                   | 例外                      |
| --------------------- | -------------------------------------------------------------------- | ----------------------- |
| **Avoid async void**  | 用 `async Task` 取代 `async void`                                       | 事件處理器                   |
| **Async all the way** | 不要混用同步/非同步                                                           | Console Main            |
| **Configure context** | 用 `ConfigureAwait(false)` 提升效能與防止死結                                  | 需要 UI 或 HttpContext 的地方 |
| **Know your tools**   | 熟悉 `Task.Run`, `SemaphoreSlim`, `CancellationToken`, `Progress<T>` 等 | —                       |

## whenall


Validators

```csharp
var tasks = this._validators.Select(async validator =>
{
    string errorMessage = string.Empty;
    string exceptionMessage = string.Empty;
    bool isValid = false;

    try
    {
        var result = await validator.IsValidAsync(context);
        isValid = result.isValid;
        errorMessage = result.errorMessage;
    }
    catch (Exception ex)
    {
        var serviceName = validator.GetType().Name;
        exceptionMessages.Enqueue($"{serviceName} 發生exception!");
        this._logger.LogError(ex, "Service name: {serviceName}, PayProcessContext:{@context}.An exception occure.", serviceName, context);
    }

    //// 如果發生exception，isValid會是false但錯誤訊息是空的，所以要判斷有錯誤訊息再印出
    if (isValid == false && string.IsNullOrEmpty(errorMessage) == false)
    {
        invalidResult.Enqueue(errorMessage);
    }

}).ToList();

Task.WhenAll(tasks).GetAwaiter().GetResult();
```

CreateTaskByShop
```csharp
        List<Task> taskList = new List<Task>();
        foreach (var shopPromotion in shopPromotionList)
        {
            taskList.Add(CreateTaskByShopAsync(shopPromotion, dateEnd));
        }
        Task.WhenAll(taskList).ConfigureAwait(false).GetAwaiter().GetResult();
    }

    /// <summary>
    /// 建立NMQ Task
    /// </summary>
    /// <param name="shopPromotion">商店及活動清單</param>
    /// <param name="dateEnd">執行日期(截止日)</param>
    /// <returns></returns>
    private async Task CreateTaskByShopAsync(KeyValuePair<long, List<long>> shopPromotion, DateTime dateEnd)
    {
        var taskData = new PromotionRewardPointSkuAddEntity
        {
            ShopId = shopPromotion.Key,
            PromotionEngineIds = shopPromotion.Value,
            ExecuteDateTime = dateEnd
        };

        var taskDataString = JsonSerializer.Serialize(taskData);

        await this._nmqV3TaskService.CreateTaskAsync(nameof(PromotionRewardPointSkuAddJob), taskDataString);
    }
```

