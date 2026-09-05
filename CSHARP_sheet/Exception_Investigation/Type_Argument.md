

```bash
CS0411 The type arguments for method 'Enumerable.Select<TSource, TResult>(IEnumerable<TSource>, Func<TSource, int, TResult>)' cannot be inferred from the usage. Try specifying the type arguments explicitly.
```

## 為什麼錯誤訊息會指到 Select<TSource, TResult>(..., Func<TSource, int, TResult>)？

Select 在 LINQ 有兩個 overload

```csharp
Select<TSource, TResult>(IEnumerable<TSource>, Func<TSource, TResult>)

Select<TSource, TResult>(IEnumerable<TSource>, Func<TSource, int, TResult>)（多給你 index）
```

當你的 lambda 回傳型別推不出來時，編譯器會嘗試在 overload 間推導、匹配，最後兩個都推不出 TResult，就會吐出這種看起來「好像在講另一個 overload」的錯誤訊息。

重點不是 index 那個參數，而是：TResult 你寫的 lambda 讓編譯器推不出來。


## 錯誤程式案例

```csharp
void Main()
{
	var numberStrings = "7,8,9,10,11";
	var sortedList = numberStrings.Split(",")
								  .Select(num => int.TryParse(num, out int n) ? n : null)
								  .Where(n => n.HasValue).Select(n => n.Value)
								  .Order()
								  .Dump();
}
```

#### TryParse 成功時回傳 n，它的型別是什麼？

n 是 int。

#### 失敗時回傳 null，型別是什麼？

null 不是 int，null 只能指派給：參考型別（class）Nullable value type（例如 int?）或一些特殊情境（例如 var x = (string)null;）

#### 三元運算子 ?: 的規則

condition ? expr1 : expr2 這兩個 expr 必須能被推成同一個結果型別（或有明確的共同型別轉換）。但現在是

expr1 = int
expr2 = null

編譯器沒有辦法「自動知道」你想要的是 int?，因為 n 本身是 int，它不會自動升級成 int?（除非你明確讓它升級）。


## 修改

```csharp
void Main()
{
	var numberStrings = "7,8,9,10,11";
	var sortedList = numberStrings.Split(",")
								  .Select(num => int.TryParse(num, out int n) ? (int?)n : null)
								  .OfType<int>()
								  .Order()
								  .Dump();
}
```