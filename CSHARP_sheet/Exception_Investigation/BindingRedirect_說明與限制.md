# Binding Redirect 是什麼？

## 定義

Binding Redirect 是在 `app.config` / `web.config` 裡的一段設定，告訴 .NET Runtime：

> 「當程式要求載入 X.dll 的 **舊版本**，請改給它 **新版本**。」

---

## 為什麼需要它？

當你的專案依賴多個套件，這些套件各自依賴不同版本的同一個 dll，就會發生「版本衝突」。

**範例情境：**

```
你的專案
  ├─ 套件 A → 依賴 Newtonsoft.Json 9.0
  └─ 套件 B → 依賴 Newtonsoft.Json 12.0

bin 裡只能放一個 Newtonsoft.Json.dll，放哪個？
```

---

## Binding Redirect 的格式

```xml
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity
          name="Newtonsoft.Json"
          publicKeyToken="30ad4fe6b2a6aeed"
          culture="neutral" />
        <bindingRedirect
          oldVersion="0.0.0.0-11.0.0.0"   <!-- 這些舊版本... -->
          newVersion="12.0.0.0" />          <!-- 統一給這個版本 -->
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
```

**語意**：任何要求 0.0.0.0 到 11.0.0.0 的地方，都載入 12.0.0.0。

---

## NuGet 自動產生 Binding Redirect

當你用 NuGet 安裝套件，VS 通常會自動在 app.config / web.config 加入 binding redirect，避免版本衝突。

---

## 這個案例嘗試的 Redirect

```xml
<!-- 嘗試：把所有 Razor 2.0 請求導向 3.0 -->
<dependentAssembly>
  <assemblyIdentity name="System.Web.Razor" publicKeyToken="31bf3856ad364e35" />
  <bindingRedirect oldVersion="0.0.0.0-2.0.0.0" newVersion="3.0.0.0" />
</dependentAssembly>
```

**為什麼這個解法失敗：**

Binding Redirect 只能解決「找不到版本」的問題，無法解決「繼承安全性標記不符」的問題。

```
MVC 4.0 的 MvcCSharpRazorCodeGenerator 是用 Razor 2.0 的 API 編譯的
  ↓
Redirect 把 Razor 2.0 的請求導到 3.0
  ↓
繼承的 base class 是 Razor 3.0 的版本
  ↓
但 MVC dll 裡的安全性 attribute 還是照著 Razor 2.0 時期的設定
  ↓
.NET 4.5 驗證：安全性標記還是不符 → 還是爆
```

---

## Binding Redirect 能解決的問題 vs 不能解決的問題

| 情況 | 能解決嗎 |
|------|---------|
| 套件 A 要 Json 9.0，套件 B 要 Json 12.0，兩個 API 相容 | ✅ 可以 |
| 找不到指定版本的 dll | ✅ 可以 |
| 繼承安全性標記版本不符（本案例） | ❌ 不行 |
| 兩個版本 API 不相容（method signature 改了） | ❌ 不行，會 MissingMethodException |

---

## 重點摘要

- Binding Redirect 是版本統一工具，讓 runtime 在找 dll 時有「備用版本」
- NuGet 通常自動處理，不需要手動寫
- 它只能解決「版本不對應」問題，無法修正「安全性繼承規則」問題
- 使用時要確認兩個版本的 API 相容，否則會在 runtime 發生 MissingMethodException
