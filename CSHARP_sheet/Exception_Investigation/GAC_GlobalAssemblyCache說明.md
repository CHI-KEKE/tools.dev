# GAC（Global Assembly Cache）是什麼？

## 定義

GAC 是 Windows 系統上 .NET Framework 的**全域組件快取**，位置在：

```
C:\Windows\Microsoft.NET\assembly\
```

它是一個特殊的資料夾，用來存放**可被多個應用程式共用的 .NET dll**。

---

## GAC vs 應用程式 bin 資料夾

| 項目 | GAC | 應用程式 bin |
|------|-----|------------|
| 位置 | `C:\Windows\Microsoft.NET\assembly\` | 應用程式自己的目錄 |
| 共用範圍 | 整台機器所有應用程式 | 只有這個應用程式 |
| 安裝方式 | 需要強式名稱（Strong Name）簽署 | 直接複製 dll |
| 優先順序 | 低於 bin（bin 優先） | 高於 GAC |
| 版本管理 | 可同時存放多個版本 | 同名 dll 會互蓋 |

---

## .NET 載入 dll 的優先順序

```
1. 應用程式 bin 資料夾（最優先）
2. GAC（全域快取）
3. 其他 probing 路徑
```

所以 bin 裡的 dll 會**蓋過** GAC 裡的版本。

---

## 這個案例與 GAC 的關係

生產伺服器安裝了 .NET Framework 的累計更新（Cumulative Update）或安全性修補（Security Patch）。這些 patch 會把修正後的 dll 更新到 GAC，包含 `System.Web.Mvc.dll` 和 `System.Web.Razor.dll` 的修正版本。

```
生產伺服器 GAC：
  System.Web.Mvc.dll    → patch 過的版本，安全性標記已修正
  System.Web.Razor.dll  → patch 過的版本

本機 / CI 機座：
  GAC 沒有這些 patch
  只有 bin 裡的原始版本 → 版本衝突存在 → 爆炸
```

這就是為什麼「線上沒問題，本機/CI 爆炸」——不是程式碼問題，是環境的 patch 版本不同。

---

## 實際查詢 GAC 內容

```powershell
# 查詢 GAC 裡的特定 dll
Get-ChildItem "C:\Windows\Microsoft.NET\assembly" -Recurse -Filter "System.Web.Mvc.dll" |
    Select-Object FullName, LastWriteTime

# 用 gacutil 工具查詢（需安裝 Windows SDK）
gacutil /l System.Web.Mvc
```

---

## 重點摘要

- GAC 讓多個應用程式共用同一份 dll，不用各自複製
- 生產伺服器的 GAC 通常有較新的 patch，解決了版本安全性問題
- 開發機 / CI 機的 GAC 往往沒有這些 patch，所以容易踩到環境差異 bug
- **「線上可以，本機不行」** 很多時候就是 GAC patch 版本差異造成的
