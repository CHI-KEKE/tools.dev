# common-dotnet-framework-build

使用 MSBuild 建置 .NET Framework 專案與方案（Solution）。

## 用途

當需要建置、編譯或重建 .NET Framework 專案（`.csproj`、`.vbproj`）或方案（`.sln`）時使用。  
自動定位 MSBuild.exe、選擇組態（Configuration）、偵測地區設定（Region），並清楚呈現建置結果。

## 觸發情境

| 使用者說 | 觸發 |
|---|---|
| 「build 我的專案」、「幫我編譯」、「跑 msbuild」 | ✅ |
| 「為什麼 build 失敗？」、「compile this」、「rebuild」 | ✅ |
| 提供 `.sln` / `.csproj` 路徑並要求建置 | ✅ |

## 功能特色

- **自動定位 MSBuild**：優先使用 `vswhere.exe`（VS 2017+），並提供各版本 VS 的 fallback 路徑
- **支援多組態**：Debug / Release 及自訂組態名稱（未指定時預設 Debug）
- **地區設定偵測**：自動偵測 `<BaseName>.<Config>.<Region>.config` 格式的地區設定檔（HK / MY / TW / SG / PX…），並提示使用者選擇
- **結果判斷以 Exit Code 為準**：不依賴輸出文字，避免因地區化 Visual Studio（中文、日文等）輸出不同摘要而誤判
- **分類錯誤訊息**：依專案分組顯示錯誤，並提供常見錯誤碼的修正建議

## 建置流程

```
Step 1：定位 MSBuild.exe（vswhere → fallback 路徑）
Step 2：確認建置目標（.sln / .csproj）
Step 3：選擇組態（使用者未指定時預設 Debug）
Step 3b：偵測地區設定（僅在使用者明確指定組態時執行）
Step 4：執行 MSBuild
Step 5：報告建置結果
```

### MSBuild 定位順序

| 方法 | 說明 |
|---|---|
| `vswhere.exe`（優先） | 適用 VS 2017+，自動找到最新版本 |
| VS 2022 fallback | `C:\Program Files\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe` |
| VS 2019 fallback | `C:\Program Files (x86)\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe` |
| VS 2017 fallback | `C:\Program Files (x86)\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe` |

### 地區設定偵測（Step 3b）

僅在使用者明確指定組態時執行。偵測檔名格式：

```
<BaseName>.<Configuration>.<Region>.config
```

例如：`AppSettings.Debug.HK.config`、`ConnectionStrings.PP.MY.config`

偵測到地區設定檔後，會詢問使用者要套用哪個地區（HK / MY / TW / SG / PX…），並以 `/p:Region=HK` 傳遞給 MSBuild。

## 適用專案類型

此 Skill 針對傳統 .NET Framework 的 `classic .csproj`（`packages.config` 風格）設計。  
SDK-style 專案（含 `<Project Sdk="Microsoft.NET.Sdk">`）請改用 `dotnet build`。

## 常見錯誤對照

| 錯誤碼 | 原因 | 解決方式 |
|---|---|---|
| `MSB3644` | 未安裝對應 .NET Framework 目標套件 | 安裝對應版本的 Targeting Pack |
| `MSB3821` | 檔案被鎖定或路徑過長 | 確認沒有開啟的檔案 handle，或啟用長路徑 |
| `CS0246` / `BC30002` | 缺少型別（NuGet 未還原） | 執行 `nuget restore` 或加 `/restore` 旗標 |
| `MSB4019` | 缺少 SDK 或 import target | 重新安裝 Visual Studio 工作負載 |
| `The system cannot find the path` | 專案路徑不正確 | 確認傳入的路徑 |

## 檔案

- [`SKILL.md`](./SKILL.md) — Skill 主要內容，供 AI Agent 讀取執行

## 維護說明

更新時機：
- Visual Studio 新版本發佈，需更新 MSBuild fallback 路徑清單
- 新增支援的地區代碼（Region）
- 建置參數或 MSBuild 旗標有異動
