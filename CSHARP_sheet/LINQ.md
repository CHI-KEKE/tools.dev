
## 交集是那些

Intersect：算出「交集是哪些？」（回傳集合）

```csharp
var couponShippingAreas = new HashSet<long> { 1, 2, 3 };
var selectedDeliveryList = new HashSet<long> { 3, 4, 5 };

var intersection = couponShippingAreas.Intersect(selectedDeliveryList);
[3]

bool isValid = couponShippingAreas.Overlaps(selectedDeliveryList);
true
```


## 兩個集合 是否至少有一個共同元素

```csharp
isValidShippingCoupon = couponShippingAreas.Overlaps(selectedDeliveryList);

couponShippingAreas.Any(x => selectedDeliveryList.Contains(x))
```

## 直接排序

```csharp
.Order()
```

## 篩選特定型別

```csharp

var list = new List<object>
{
    "123",
    123,
    "456"
};

var result = list.OfType<int>().ToList();

//// 👉 最後 result 只有：[123]
```

## 篩選掉 null

```csharp
.Where(x => x.HasValue)
.Select(x => x.Value)
```




## 想把 "123" 變成 123

```csharp
var numbers = list
    .OfType<string>()          // 先挑出字串
    .Where(s => int.TryParse(s, out _))
    .Select(int.Parse)
    .ToList();
```
