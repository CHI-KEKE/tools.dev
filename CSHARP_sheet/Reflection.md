```csharp
Type elemType = arr.GetType().GetElementType();
PropertyInfo[] props = elemType.GetProperties();
```