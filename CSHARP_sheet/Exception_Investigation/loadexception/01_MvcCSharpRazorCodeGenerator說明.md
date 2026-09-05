# MvcCSharpRazorCodeGenerator 說明

## 它是什麼

`MvcCSharpRazorCodeGenerator` 是一個 **class（類別）**，不是套件。  
它住在 MVC 官方 dll 裡，用來把 `.cshtml` 編譯成 C# 程式碼。

```
NuGet 套件：  Microsoft.AspNet.Mvc 4.0.x
  └─ 安裝後產生：System.Web.Mvc.dll
       └─ namespace：System.Web.Mvc.Razor
            └─ class：MvcCSharpRazorCodeGenerator  ← 這個
```

## 繼承鏈

```
MvcCSharpRazorCodeGenerator
  └─ MvcRazorCodeGenerator        ← MVC 層定義
       └─ CSharpRazorCodeGenerator ← Razor 層定義
            └─ RazorCodeGenerator  ← Razor 基底
```

## 開發者如何「引入」它

開發者**沒有主動引入**，它是被動跟進來的：

```
開發者做的事：
  NuGet 安裝 Microsoft.AspNet.Mvc

NuGet 自動下載：
  System.Web.Mvc.dll          ← MvcCSharpRazorCodeGenerator 住在這裡
  System.Web.Razor.dll 2.0    ← MVC 4.0 依賴的 Razor 版本
  System.Web.WebPages.dll
```

開發者完全不需要知道 `MvcCSharpRazorCodeGenerator` 的存在。  
它只會在 `ReflectionTypeLoadException` 的 `LoaderExceptions` 裡出現，  
表示 CLR 在嘗試載入這個 class 時失敗了。

## 它為什麼會出現在 LoaderExceptions

EF 的 `ObjectContext.CreateQuery<T>` 會掃描所有 Assembly。  
掃描過程中 CLR 嘗試載入每個 class，包含 `MvcCSharpRazorCodeGenerator`。  
此時會驗證繼承鏈的版本是否一致：

```
MVC 4.0 dll 說：「我的父類別是 Razor 2.0 的 CSharpRazorCodeGenerator」
bin 裡的 Razor dll：「我是 Razor 3.0」
CLR：「版本不符，載入失敗」→ TypeLoadException
```

## 類比

| 概念 | 比喻 |
|------|------|
| NuGet 套件 | 箱子 |
| dll | 箱子裡的書 |
| namespace | 書裡的章節 |
| class | 章節裡的某一頁 |

`MvcCSharpRazorCodeGenerator` 是那一頁，跟著 MVC 套件一起來，平常不需要直接使用。
