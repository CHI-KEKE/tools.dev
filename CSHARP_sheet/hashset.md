
## 直接從 List 做成 hashset

```csharp
var moduleSet = new HashSet<string>(sortedModules, StringComparer.OrdinalIgnoreCase);
```

