沒掛 也沒 yaml


```csharp
/// <summary>
/// dify API key.
/// </summary>
protected override string DifyApiKey { get; } = "app-gqEaDhs6lVrHJFM1HI0GSPnu";

/// <summary>
/// AllowFileExtensions
/// </summary>
protected override List<string> AllowFileExtensions { get; } = new List<string>() { ".cs" };

/// <summary>
/// 檔案排除黑名單
/// </summary>
protected List<string> ExcludedFileTypes { get; } = new List<string>() { ".typegen.ts" };

```