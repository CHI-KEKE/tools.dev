
## 時間長度

```csharp
Thread.Sleep(TimeSpan.FromSeconds(time));

$"{(DateTime.Now - startDatetime).TotalSeconds,3:n0}s"

TimeSpan.FromSeconds(5)

(DateTime.Now - startDatetime).TotalSeconds
```

## new 一個時間

```csharp
new DateTime(1994,10,14);
```

## 時間區間

```csharp
Thread.Sleep(TimeSpan.FromSeconds(time));
$"{(DateTime.Now - startDatetime).TotalSeconds,3:n0}s"
TimeSpan.FromSeconds(5)
```

## 取得特定時間

```csharp
DateTime.Today
```

## 時區問題

```csharp
his.BookingTimeUTC?.ToLocalTime();
```

## 特定格式

```csharp

var startTime = DateTime.Now.ToString("HH:mm:ss");
var birDate = birthdate.Date;
var today = DateTime.Today.Date;
DateTime.Now:HH:mm:ss
```


## StopWatch

```csharp
public static long MeasureTime(Action action)
{
    var stopWatch = new Stopwatch();
    stopWatch.Start();
    action();
    stopWatch.Stop();
    return stopWatch.ElapsedMilliseconds;
}

public static async Task<long> MeasureTimeAsync(Func<Task> action)
{
	Stopwatch stopwatch = new Stopwatch();
	stopwatch.Start();

	await action();

	stopwatch.Stop();
	return stopwatch.ElapsedMilliseconds;
}
```



## Unix Timestamp

```csharp
///現在時間轉 Unix timestamp
long unixTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
Console.WriteLine(unixTimestamp);

// 指定時間轉 Unix timestamp
DateTimeOffset dateTime = new DateTimeOffset(
    2026, 5, 4, 12, 0, 0, TimeSpan.Zero
);

long unixTimestamp = dateTime.ToUnixTimeSeconds();

Console.WriteLine(unixTimestamp); // 2026-05-04 12:00:00 UTC


//如果有 UTC 字串
string utcString = "2026-05-04T12:00:00Z";

DateTimeOffset dateTime = DateTimeOffset.Parse(utcString);

long unixTimestamp = dateTime.ToUnixTimeSeconds();

Console.WriteLine(unixTimestamp);
```