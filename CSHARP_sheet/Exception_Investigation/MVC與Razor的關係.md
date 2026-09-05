# MVC 與 Razor 的關係

## 一句話總結

> **Razor 是 MVC 的「模板引擎」。MVC 負責路由與控制流程，Razor 負責把資料渲染成 HTML。**

---

## 什麼是 MVC（ASP.NET MVC）

MVC 是微軟的 Web 框架，全名 **Model-View-Controller**：

```
HTTP Request
  └─ Controller（控制器）：決定要做什麼
       ├─ Model（模型）：處理資料
       └─ View（視圖）：決定要顯示什麼 ← 這裡用到 Razor
```

Controller 把資料（Model）交給 View，View 負責產生最終的 HTML 回應。

---

## 什麼是 Razor

Razor 是用來撰寫 `.cshtml` 檔案的語法，讓你在 HTML 裡混入 C# 程式碼：

```html
<!-- 這是 Razor 語法的 .cshtml 檔案 -->
<h1>Hello, @Model.UserName!</h1>

@foreach (var item in Model.Items)
{
    <li>@item.Name - @item.Price</li>
}
```

`@` 開頭的部分是 C# 程式碼，其餘是 HTML，Razor 引擎把兩者合併產生最終 HTML。

---

## 版本對應關係

| MVC 版本 | 搭配的 Razor 版本 | 發布年份 |
|---------|-----------------|---------|
| ASP.NET MVC 3 | Razor 1.0 | 2011 |
| ASP.NET MVC 4 | Razor 2.0 | 2012 |
| ASP.NET MVC 5 | Razor 3.0 | 2013 |
| ASP.NET Core MVC | Razor SDK（全新）| 2016+ |

**MVC 4.0 是用 Razor 2.0 編譯的**，它的 class 繼承 Razor 2.0 的 base class。  
如果 runtime 提供的是 Razor 3.0，繼承鏈就斷了。

---

## 這個案例的版本衝突

```
bin 裡：
  System.Web.Mvc.dll     = 4.0（對應 Razor 2.0）
  System.Web.Razor.dll   = 3.0（被 RazorEngine 套件帶進來）

問題：
  MVC 4.0 的 MvcCSharpRazorCodeGenerator
    └─ 繼承 CSharpRazorCodeGenerator（Razor 2.0 的 class）
    └─ 但 runtime 找到的 Razor 是 3.0
    └─ 安全性標記不符 → ReflectionTypeLoadException
```

---

## RazorEngine 套件是什麼？

`RazorEngine`（NuGet 套件）是把 Razor 語法用在**非 Web 場景**的套件，常用來產生 Email HTML 模板：

```csharp
// 用 Razor 語法產生 Email 內容
string template = "Hello @Model.Name, your order @Model.OrderId is confirmed.";
string result = Engine.Razor.RunCompile(template, "key", null, new { Name = "Allen", OrderId = "TS001" });
```

RazorEngine 3.x 依賴 `Microsoft.AspNet.Razor 3.0`，這就是 Razor 3.0 被帶進 scm.nmqv2 的原因。

---

## 為什麼 NMQ 背景服務需要 Razor？

`ERP\Backend\BLV2` 有發送 Email 的功能（例如庫存警告信、活動結束通知），用 RazorEngine 產生動態 HTML 內容。  
這個功能需要 Razor 3.0，但同一個 solution 裡其他 BE/BL 專案依賴 MVC 4.0（Razor 2.0），兩者進同一個 bin 就衝突了。

---

## 重點摘要

- Razor 是 MVC 的 HTML 模板語法引擎，兩者版本強綁定
- MVC 4.0 = Razor 2.0，MVC 5.0 = Razor 3.0
- 同一個 bin 裡 MVC 4.0 + Razor 3.0 組合在 .NET 4.5 下會因繼承安全性規則失敗
- RazorEngine 套件讓 Razor 可以用在 Email 等非 Web 場景，但會帶入 Razor 3.0 相依性
