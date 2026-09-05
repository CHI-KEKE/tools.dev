# 本機 GAC 安裝說明

## 為什麼本機需要安裝 GAC

| 環境 | GAC 狀態 | 結果 |
|------|---------|------|
| Production | ✅ 有 Razor 2.0（伺服器安裝 ASP.NET MVC Runtime） | 正常 |
| CI 伺服器 | ❌ 沒有 | ReflectionTypeLoadException（ELMAH 證明） |
| 本機（開發）| ❌ 沒有 | 本機測試爆炸 |

CLR 載入 dll 的優先順序：
```
1. GAC（最優先）
2. bin 目錄（其次）
```

本機/CI 的 GAC 沒有 Razor 2.0，CLR 改用 bin 裡的 Razor 3.0，與 MVC 4.0 繼承鏈衝突 → 爆炸。

---

## 確認本機 GAC 現況

```powershell
$gacutil = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\gacutil.exe"
& $gacutil /l System.Web.Razor   # 查詢，不會影響機器
& $gacutil /l System.Web.Mvc     # 查詢，不會影響機器
```

`/l` = list（唯讀查詢），完全安全，不寫入任何東西。

---

## 手動注冊 Razor 2.0 進 GAC

專案的 packages 資料夾裡就有 Razor 2.0 dll，**不需要額外下載**：

```
C:\91APP\NMQ\nineyi.scm.nmqv2\packages\Microsoft.AspNet.Razor.2.0.20710.0\lib\net40\System.Web.Razor.dll
```

**步驟：**

1. 用**系統管理員**身分開 PowerShell
2. 執行：

```powershell
$gacutil = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\gacutil.exe"
$razor2  = "C:\91APP\NMQ\nineyi.scm.nmqv2\packages\Microsoft.AspNet.Razor.2.0.20710.0\lib\net40\System.Web.Razor.dll"
& $gacutil /i $razor2
```

3. 確認成功：

```powershell
& $gacutil /l System.Web.Razor
# 看到 Version=2.0.0.0 → 成功
```

---

## 注意事項

- **不需要**安裝 VS 2010 的 AspNetMVC4Setup.exe（那是給舊版 VS 的）
- VS 2019/2022 上直接用 gacutil 手動注冊即可
- 安裝 GAC 只影響本機開發環境，與 Production/CI 無關
- CI 的保護靠 `GetOrderCustomInfosByContains`（不觸發 EF 掃描）

---

## gacutil 指令速查

| 指令 | 說明 | 會改變機器嗎 |
|------|------|------------|
| `/l <name>` | 列出 GAC 中符合名稱的 dll | ❌ 不會 |
| `/i <path>` | 把 dll 注冊進 GAC | ✅ 會 |
| `/u <name>` | 從 GAC 移除 dll | ✅ 會 |
