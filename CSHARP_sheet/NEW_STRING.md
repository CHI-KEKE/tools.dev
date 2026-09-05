

## new string


string 不是集合型別，不能用 {} 這樣初始化


```csharp
var template = "感謝您於{{LIVE_NAME}}活動購物!{{PRODUCT_INFO}}商品加入購物車連結";


var template = new string[]
{
    "感謝您於{{LIVE_NAME}}活動購物!{{PRODUCT_INFO}}商品加入購物車連結"
};


var template = new string('A', 5); // AAAAA
```




## String Builder

```csharp
JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true});

StringBuilder sb = new StringBuilder();
string.Join("\t",props.Select(p => p.Name)
```


## 拆字串 => 陣列 => 特殊處理

```csharp
var moduleList = modules
    .Split(',', StringSplitOptions.RemoveEmptyEntries)
    .Select(m => m.Trim())
    .Where(m => string.IsNullOrWhiteSpace(m) == false)
    .Distinct()
    .ToList();
```