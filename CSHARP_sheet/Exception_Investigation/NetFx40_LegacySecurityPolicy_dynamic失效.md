# NetFx40_LegacySecurityPolicy — 導致 dynamic 失效

## 🚨 錯誤訊息

```
System.InvalidOperationException: 動態作業只能在同質性 AppDomain 中執行。
  於 System.Runtime.CompilerServices.CallSiteBinder.BindCore[T](CallSite`1 site, Object[] args)
  於 System.Dynamic.UpdateDelegates.UpdateAndExecute1[T0,TRet](CallSite site, T0 arg0)
```

## 📍 發生背景

為了解決 `ReflectionTypeLoadException`（MVC/Razor 版本衝突），嘗試在 `App.config` 加入：

```xml
<runtime>
  <NetFx40_LegacySecurityPolicy enabled="true"/>
</runtime>
```

問題二的錯誤消失了，但隨即出現新錯誤，發生在任何使用 `dynamic` 關鍵字的程式碼。

## 🔍 根本原因

### `NetFx40_LegacySecurityPolicy` 是什麼

這個設定讓 .NET 4.5+ 的 Runtime 退回 .NET 4.0 的舊安全性模型（**CAS, Code Access Security**）。

| 設定 | 安全模型 | 繼承安全性規則 |
|------|---------|--------------|
| 未設定（預設） | .NET 4.5 新模型 | 嚴格，觸發 ReflectionTypeLoadException |
| `enabled="true"` | .NET 4.0 舊模型（CAS） | 寬鬆，ReflectionTypeLoadException 消失 |

### 副作用：AppDomain 變成「非同質性」

啟用 CAS 舊模型後，AppDomain 的「同質性（homogeneous）」狀態被破壞。

```
NetFx40_LegacySecurityPolicy enabled="true"
  └─ AppDomain 進入「非同質性（heterogeneous）」模式
       └─ .NET DLR（Dynamic Language Runtime）規定：
          dynamic 關鍵字只能在同質性 AppDomain 中運作
```

### 為什麼 `dynamic` 需要同質性 AppDomain

`dynamic` 關鍵字在 C# 底層依賴 DLR（Dynamic Language Runtime）。執行時 DLR 需要：

1. **動態生成委派（delegate）**：根據實際型別在 runtime 建立呼叫方式
2. **在 AppDomain 內即時編譯**：透過 `CallSite<T>` 快取呼叫點

這些操作需要在「同質性 AppDomain」中執行，因為非同質性 AppDomain 的安全性邊界不允許動態型別解析跨越安全性區域。

## 💥 兩個約束無法共存

| 問題 | 需要的條件 |
|------|-----------|
| 問題二（ReflectionTypeLoadException） | 需要寬鬆的繼承安全性 → 啟用 LegacySecurityPolicy |
| 問題三（dynamic 失效） | 需要同質性 AppDomain → 不能啟用 LegacySecurityPolicy |

**這兩個條件在同一個 AppDomain 裡無法同時成立**，走 config 調整這條路是死路。

## ✅ 解決方案

移除 `NetFx40_LegacySecurityPolicy` 設定，改從問題二的根本原因下手：

**不讓程式碼呼叫 `ObjectContext.CreateQuery`**，就不會觸發 EF 全 Assembly 掃描，兩個問題自然都不存在。

```xml
<!-- ❌ 移除這段 -->
<runtime>
  <NetFx40_LegacySecurityPolicy enabled="true"/>
</runtime>
```

詳見：[ReflectionTypeLoadException_MVC_Razor版本衝突.md](./ReflectionTypeLoadException_MVC_Razor版本衝突.md)

## 📝 重點摘要

- `NetFx40_LegacySecurityPolicy` 是「讓 .NET 4.5 退回 4.0 安全模型」的設定
- 它確實能解決繼承安全性問題，但代價是讓 `dynamic` 關鍵字失效
- 這是 .NET 框架設計上的互斥約束，不是 bug，也沒有辦法同時解決兩個問題
- 正確做法是讓程式碼不進入「需要 LegacySecurityPolicy」的處境
