---
name: member-tier-redo
description: 建立會員等級重新計算 (Redo) 的 SQL 腳本資料夾與兩個步驟 SQL 檔案，並 commit 後發出 PR。當使用者提到「等級計算 redo」、「重新計算等級」、「塞 Pool」、「DailyVerify 重算」、「member tier redo」等關鍵字時，請主動使用此 Skill。
---

# Member Tier Redo Skill

此 Skill 用於快速建立會員等級重新計算 (Redo) 所需的 SQL 腳本並發 PR。

## 流程概覽

1. 收集必要參數
2. 建立資料夾與兩個 SQL 檔案
3. Git commit 並發 PR，附上 PR 連結

---

## Step 1: 收集參數

若對話中尚未提供以下資訊，一次詢問所有項目：

```
請提供以下資訊：
1. 工單號 (VSTS ID)：例如 592040
2. 商店序號 (ShopId)：例如 40187
3. 等級計算開始日（StartDate）：預設為 currentDate - 1，格式 YYYY/MM/DD
4. 等級計算結束日（EndDate）：預設為 currentDate，格式 YYYY/MM/DD
```

**預設值規則：**
- StartDate 預設 = currentDate - 1（執行當下日期減一天）
- EndDate / CalculateDate 預設 = currentDate（執行當下日期）

---

## Step 2: 建立資料夾與 SQL 檔案

收集完參數後，執行以下步驟：

### 2-1 建立資料夾

在 workspace 的 `VSTS/` 目錄下建立：

```
VSTS/VSTS{工單號}-{商店序號}Redo/
```

例如：`VSTS/VSTS592040-40187Redo/`

### 2-2 建立 step01_UpdateDailyVerify.sql

讀取 `.github/skills/member-tier-redo/assets/step01_DailyVerify_template.sql`，替換以下佔位符後，建立 `step01_UpdateDailyVerify.sql`：

| 佔位符 | 替換為 |
|--------|--------|
| `{{VSTS_ID}}` | `VSTS{工單號}` 例如 `VSTS592040` |
| `{{SHOP_ID}}` | 商店序號數字，例如 `40187` |
| `{{CALCULATE_DATE}}` | 若 EndDate 為今天，使用 `CAST(GETDATE() AS DATE)`；否則使用 `'YYYY/MM/DD'` 格式的字串 |

**注意：** 若 EndDate 為今天，`@CalculateDate` 行應為：
```sql
@CalculateDate      DATE        = CAST(GETDATE() AS DATE),
```
若為指定日期（例如 2026/03/24），應為：
```sql
@CalculateDate      DATE        = '2026/03/24',
```

### 2-3 建立 step02_InsertPool.sql

讀取 `.github/skills/member-tier-redo/assets/step02_InsertPool_template.sql`，替換以下佔位符後，建立 `step02_InsertPool.sql`：

| 佔位符 | 替換為 |
|--------|--------|
| `{{VSTS_ID}}` | `VSTS{工單號}` 例如 `VSTS592040` |
| `{{SHOP_ID}}` | 商店序號數字，例如 `40187` |
| `{{START_DATE}}` | StartDate，格式 `YYYY/MM/DD` 例如 `2026/03/24` |
| `{{END_DATE}}` | 若 EndDate 為今天，使用 `CAST(GETDATE() AS DATE)`；否則使用 `'YYYY/MM/DD'` |
| `{{CALCULATE_DATE}}` | 同 EndDate 的替換規則 |

**範例（EndDate 為今天）：**
```sql
@EndDate            DATETIME    = CAST(GETDATE() AS DATE),
@CalculateDate      DATE        = CAST(GETDATE() AS DATE),
```

**範例（EndDate 為指定日期）：**
```sql
@EndDate            DATETIME    = '2026/03/24',
@CalculateDate      DATE        = '2026/03/24',
```

---

## Step 3: Git Commit 並發 PR

### 3-1 確認工作目錄

workspace 根目錄為 `c:\91APP\nineyi.database.operation`

### 3-2 Branch 命名

```
VSTS{工單號}-{商店序號}Redo
```
例如：`VSTS592040-40187Redo`

### 3-3 執行 Git 指令

在終端機執行以下指令（注意：Windows 使用 PowerShell）：

```powershell
cd c:\91APP\nineyi.database.operation
git checkout -b VSTS{工單號}-{商店序號}Redo
git add "VSTS/VSTS{工單號}-{商店序號}Redo/"
git commit -m "VSTS{工單號} Redo 等級計算 - ShopId {商店序號}"
git push origin VSTS{工單號}-{商店序號}Redo
```

若 branch 已存在，改用：
```powershell
git checkout VSTS{工單號}-{商店序號}Redo
git push origin VSTS{工單號}-{商店序號}Redo
```

### 3-4 建立 PR

使用 GitHub 工具（mcp_github 或等效工具）建立 PR：
- **Title**: `VSTS{工單號} Redo 等級計算 - ShopId {商店序號}`
- **Base branch**: `main`（若不存在則用 `master`）
- **Head branch**: `VSTS{工單號}-{商店序號}Redo`
- **Body**: 簡要說明 redo 的目的與日期範圍

若 GitHub 工具不可用，提示使用者手動在 GitHub 建立 PR，並提供 branch 名稱。

### 3-5 回傳 PR 連結

完成後，輸出 PR 連結給使用者。

---

## 輸出確認

完成後向使用者確認：
1. 已建立資料夾：`VSTS/VSTS{工單號}-{商店序號}Redo/`
2. 已建立 `step01_UpdateDailyVerify.sql`（參數：ShopId={商店序號}, CalculateDate={日期}）
3. 已建立 `step02_InsertPool.sql`（參數：ShopId={商店序號}, StartDate={開始日}, EndDate={結束日}）
4. PR 連結：{PR URL}
