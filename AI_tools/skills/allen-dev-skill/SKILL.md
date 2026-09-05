---
name: allen-dev-skill
description: 通用功能開發全流程 Skill，適用於任何專案的需求分析、現況探索、規劃、實作、測試到文件撰寫。當 Allen 提到「開始做一個需求」、「分析一張 story」、「我有一個需求」、「幫我規劃實作」、「從 story 開始」、「開發流程」或任何需要從需求理解→程式碼分析→實作→測試→文件的完整開發作業時，使用此 skill。支援從 Azure DevOps User Story 或直述需求兩種觸發方式。
---

# Allen Dev Skill

通用功能開發全流程 Skill。依序引導 16 個步驟，從需求解析到文件交付，確保每個環節都有明確的人機確認點。

## 完整流程概覽

```
Step 1  → 解析需求 / Story
Step 2  → 詢問牽涉的專案清單
Step 3  → 詢問各專案的 branch → checkout + pull
Step 4  → 深度分析各專案現況
Step 5  → 結合需求說明現況 → 詢問是否開始規劃
Step 6  → 輸出完整實作規劃 → 等待使用者確認（絕不提前實作）
Step 7  → 詢問是否可以實作
Step 8  → 執行實作
Step 9  → 確認防護完整性（NRE、邊界值等）
Step 10 → 補足 try/catch（必要時詢問）
Step 11 → 補足完整 log
Step 12 → 補足完整程式碼註解
Step 13 → 補足單元測試
Step 14 → 執行 Build 確認無錯誤
Step 15 → 執行單元測試確認全部通過
Step 16 → 完成確認 → 詢問是否撰寫文件
```

---

## Step 1｜解析需求

**觸發方式一：Azure DevOps User Story**
- 使用 `azure-devops-assistant-get_work_item_details` 拉取 Story
- 若 Story 含圖片，補用 `azure-devops-assistant-get_work_item_attachments`
- 解析 Story 的 Description、Acceptance Criteria、子項目

**觸發方式二：使用者直述需求**
- 直接從對話中取得需求內容

**輸出格式：**

```
## 我對這個需求的理解

### 目標
[一句話說明]

### 功能範圍
- [功能點 1]
- [功能點 2]

### 驗收條件
- [條件 1]

### 問題與疑問
- [若有不清楚的地方列出來]
```

解析完畢後，確認理解是否正確，等待使用者回應後再進行 Step 2。

---

## Step 2｜詢問牽涉的專案

詢問：「這個需求會牽涉到哪些專案？（可以是複數）」

等待使用者明確列出所有專案名稱與路徑後，進行 Step 3。

---

## Step 3｜詢問 Branch 並同步最新程式碼

詢問：「請告訴我每個專案要使用哪一支 branch？」

格式範例：
```
專案 A → feature/xxx
專案 B → develop
```

取得資訊後，對每個專案依序執行：
```powershell
cd <專案路徑>
git checkout <branch>
git pull
```

- 若 checkout/pull 失敗，立即回報錯誤，不繼續往下。
- 全部成功後告知使用者，進行 Step 4。

---

## Step 4｜深度分析各專案現況

針對需求相關的程式碼區域進行完整分析，包含：
- 找到相關的 Service / Repository / Controller / Entity
- 理解現有的資料流程與呼叫鏈
- 找出需要修改或新增的位置
- 識別潛在的影響範圍（相依模組）

分析工具優先順序：`grep` > `glob` > `view`，大量平行搜尋以節省時間。若有多個專案，各自獨立分析。

---

## Step 5｜說明現狀 + 詢問是否開始規劃

**輸出格式：**

```
## 現況分析摘要

### 相關程式碼位置
| 檔案 | 方法/類別 | 說明 |

### 現有流程
[描述現有資料流]

### 缺少的部分（對應需求）
- [缺少 1]
```

詢問：「以上是我對現況的理解，是否符合你的預期？確認後我可以開始規劃。」

若使用者有異議，充分討論直到共識達成，再進行 Step 6。

---

## Step 6｜輸出完整實作規劃

**⚠️ 此步驟絕對不實作任何程式碼，也不執行 commit。**

**輸出格式：**

```
## 實作規劃

### 異動清單
| 檔案 | 類型（新增/修改） | 異動說明 |

### 詳細說明

#### 1. [異動項目]
- 位置：[檔案路徑 + 方法名]
- 做法：[具體說明]
- 注意事項：[防護、邊界等]

### 不實作的項目（及理由）
```

詢問：「以上是完整的實作規劃，是否同意？或有需要調整的地方？」

---

## Step 7｜詢問是否可以實作

使用者確認規劃後，明確詢問：「規劃已確認，是否可以開始實作？」

等待使用者明確同意後才進行 Step 8。

---

## Step 8｜執行實作

依照 Step 6 確認的規劃逐一實作：
- 不主動 commit，除非使用者明確要求
- 修改範圍嚴格限制在規劃內
- 每個異動項目完成後在對話中標注

Step 8 完成後，連續執行 Step 9–13（無需每步詢問確認）。

---

## Step 9｜確認防護完整性

自我審查：
- [ ] 物件取值前有 null 防護
- [ ] 集合操作前有 `.Any()` 或 count 防護
- [ ] 外部資料（DB / API）回傳值的 null 處理
- [ ] guard clause 取代巢狀 if

---

## Step 10｜try/catch 防護

評估原則：
- **需要**：呼叫外部服務、DB 查詢、非關鍵輔助功能（失敗不應中斷主流程）
- **不需要**：純計算邏輯、驗證邏輯

若不確定，詢問使用者：「[方法名] 失敗時是否應該中斷主流程？」

---

## Step 11｜補足完整 Log

格式建議：`[MethodName][功能標籤] 說明, 關鍵參數: {value}`

必須涵蓋：
- 方法入口（含關鍵參數）
- 查詢結果（筆數或空結果）
- guard clause 觸發點
- catch 區塊的 Error log（含完整 Exception 訊息）

---

## Step 12｜補足完整程式碼註解

- `/// <summary>` XML doc 加在所有 public / private 方法
- 非顯而易見的邏輯加上行內 `////` 說明
- 說明「為什麼」而非「做什麼」

---

## Step 13｜補足單元測試

測試框架依專案現有配置（xUnit / NUnit / MSTest + NSubstitute / Moq）。

命名規範：`Method_When條件_Should結果`

必要情境：
1. 正常路徑：Service 回傳正確資料 → 欄位正確填入
2. 空資料路徑：無相關資料 → 不呼叫 Service
3. Service 回傳 null → 不拋例外，欄位保持預設
4. Service 拋出例外 → 不傳播，主流程正常完成

新增測試檔案後，確認是否需要更新 `.csproj` 的 `<Compile Include>`（舊版 .NET Framework 專案需要）。

---

## Step 14｜執行 Build

先確認框架：

**.NET Framework（.csproj 有 ToolsVersion）**：
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" "<solution>.sln" /t:Build /p:Configuration=Debug /nologo /verbosity:minimal 2>&1 | Select-Object -Last 10
```

**.NET 5/6/7/8+**：
```powershell
dotnet build "<solution>.sln" --configuration Debug 2>&1 | Select-Object -Last 10
```

若有 `error CS` 錯誤，修正後重新 Build，直到通過。

---

## Step 15｜執行單元測試

**dotnet test** 或 VSTest 視專案配置而定。確認所有測試通過後告知結果。

---

## Step 16｜完成確認與文件詢問

輸出完成摘要：

```
## 實作完成摘要

### 異動檔案清單
| 檔案 | 異動類型 | 說明 |

### 新增測試
| 測試類別 | 測試方法數 |

### Build & Test
- Build：✅ 通過
- 單元測試：✅ X 項全過
```

詢問：「實作已完成，是否需要撰寫本次的技術文件？」

若使用者同意：
1. 詢問：「文件要放在哪個路徑？」
2. 詢問：「文件需要包含哪些項目？我建議以下目錄，請確認或調整：」

提供建議目錄：

```
1. 背景與目標
2. 需求摘要（含 Story 連結）
3. 現況分析
4. 技術實作說明
   4.1 異動清單
   4.2 資料流程（若適用）
   4.3 關鍵邏輯說明
5. API Spec（若有新增/修改 API）
   - Endpoint
   - Request / Response Schema
   - 錯誤碼定義
6. 單元測試說明
7. 技術 Takeaway（必要）
   - 重要設計決策
   - 注意事項 / 已知限制
   - 後續建議
```

確認目錄後再撰寫文件。

---

## 重要守則

- 每個步驟完成後等使用者確認才進行下一步（Step 8–13 為連續實作可例外）
- Step 6 之前絕對不寫任何程式碼
- 任何時候都不主動 commit
- 使用者在任一步驟反映理解有誤，回到適當步驟重新確認
- 多個專案時，Step 4 各自分析，Step 6 說明跨專案異動順序
