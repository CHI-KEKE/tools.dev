---
name: daily-operation-new-ticket
description: 建立 Daily Operation 工作分支與 SQL 檔案骨架。當使用者說「壓資料」、「組語法」、「組SQL」、「產生 SQL」或類似意圖時使用此 skill。
allowed-tools: shell
---

## 目標

針對一張 VSTS 工單，自動完成以下三件事：
1. 建立 Git 分支 `feature/VSTS{TicketNo}_{TicketTitle}`
2. 在 `VSTS\` 目錄下建立對應的工作資料夾
3. 在資料夾內建立一個或多個 SQL 檔案（依工單狀況決定是否帶入語法）

---

## 執行步驟

### Step 0：初始化（靜默執行，不詢問使用者）

執行以下 shell 指令取得目前 Git Repo 的根目錄與使用者 email：

```shell
git rev-parse --show-toplevel
git config user.email
```

- 將根目錄結果存為 `REPO_ROOT`（例：`C:\Repository\operation`）
- 若失敗則使用當前目錄
- 將 email 存為 `CURRENT_USER_EMAIL`；若失敗則使用 `santayang@91app.biz`

---

### Step 1：收集 Ticket 資訊

#### 1-1 詢問 Ticket 號碼

詢問：「請輸入 VSTS Ticket 號碼」

使用者輸入後，透過 Azure DevOps MCP 工具取得工單資訊：

```
get_work_item_basic(id = {TicketNo})
```

- 取得 `title` 欄位作為 `TicketTitle`
- **清理 TicketTitle**：移除 Windows 路徑不合法字元（`\ / : * ? " < > |`），空白與特殊符號一律替換為 `_`，連續底線合併為一個
- 顯示抓到的標題讓使用者確認，例：
  > ✅ 已取得工單 #123456：`更新銷售單狀態`
  > 分支名稱將為：`feature/VSTS123456_更新銷售單狀態`
  > 如需修改標題，請直接回覆新名稱；否則回覆 Enter 繼續

---

### Step 2：詢問是否有參考工單

詢問：「是否有參考工單可作為 SQL 語法範本？（有請輸入工單號碼；沒有請輸入 N）」

- 若使用者輸入 **N 或空白** → `REF_TICKET = null`
- 若使用者輸入工單號碼 → 依以下優先順序尋找 SQL 內容：

#### 2-1 優先：從工作目錄直接複製 SQL 檔案

先檢查參考工單的資料夾是否已存在於工作目錄：
```shell
Get-ChildItem "{REPO_ROOT}\VSTS\*VSTS{RefTicketNo}*\" -Filter "*.sql"
```
- 若找到 → **直接列出檔案清單**，讓使用者選擇，後續直接 `Copy-Item` 複製，**不需讀取 diff**
- 成功取得後顯示：`✅ 已從工作目錄取得 SQL 範本`

#### 2-2 次要：從 Git 歷史找已合併的 PR commit，用 git show 取得完整內容

若工作目錄找不到，改搜尋 git log：
```shell
git log --all --oneline | Select-String "VSTS{RefTicketNo}"
```
- 若找到對應 merge commit，取出來源 commit hash（merge commit 的第二個 parent）
- 列出 `.sql` 檔案清單讓使用者選擇：
  ```shell
  git show {sourceCommitHash} --name-only 2>&1 | Out-String
  ```
- 使用者選擇後，用 `git show` 取得**完整**檔案內容（⚠️ 勿使用 PR diff，diff 有長度限制容易截斷）：
  ```shell
  # ⚠️ 必須透過 cmd 直接 pipe 到檔案，避免 PowerShell 的編碼轉換導致中文亂碼
  # 先將變數組好，再帶入 cmd 指令
  $sourceCommitHash = "14825e723f"   # merge commit 的第二個 parent hash
  $filePath = "VSTS/VSTS566550_刷A給B/Step01_取貨付款(後付款).sql"   # git 內的相對路徑
  $destPath = "$folder\Step01_取貨付款(後付款).sql"   # 目標檔案完整路徑
  cmd /c "git show `"${sourceCommitHash}:${filePath}`" > `"$destPath`""
  ```
  > ❌ **不可使用** PowerShell 變數中轉（如 `$content = git show ...` 再寫檔），
  > 因為 PowerShell 會對輸出做編碼轉換，導致 SQL 內的中文字變成亂碼。
- 成功取得後顯示：`✅ 已從 git show 取得完整 SQL 範本`

#### 2-3 再次：從工單 PR 連結取得（僅用於確認檔案清單，不讀 diff 內容）

若以上方法找不到檔案清單，透過 Azure DevOps MCP 取得工單詳細資料尋找 PR 連結：
```
get_work_item_details(id = {RefTicketNo})
```
- 在工單的 Related Items / External Links / **Comments** 中尋找 PR 連結（URL 包含 `pull-requests`）
- 若找到 PR 連結，使用 **`bitbucket-pr` skill** 讀取 PR 資訊，**僅用於取得 `.sql` 檔案名稱清單**（不直接用 diff 內容）
- 確認檔案名稱後，改用 2-2 的 `git show` 方式取得完整內容
- ⚠️ **不得直接從 PR diff 擷取 SQL 內容**，diff 有長度上限會造成語法截斷

#### 2-4 最後：從 Azure DevOps 附件找 `.sql` 檔案

若以上方法都找不到：
```
get_work_item_attachments(id = {RefTicketNo})
```
- 從附件中找 `.sql` 檔案，取其內容作為 `REF_SQL`
- 若無 `.sql` 附件，從工單描述中擷取 SQL 程式碼區塊（` ```sql ... ``` `）

#### 2-5 找不到時

- 告知使用者「找不到 SQL 內容，將建立空白檔案」，`REF_SQL = null`

---

### Step 3：收集 SQL 檔案資訊

#### 3-A：有參考 SQL 時（自動模式）

若 Step 2 已成功取得參考 SQL 檔案清單（`REF_SQL` 不為 null），**直接沿用參考工單的檔名與內容，不詢問數量或檔案資訊**，自動產生對應的 SQL 檔案清單：

```
✅ 已從參考工單取得 {N} 個 SQL 檔案，將直接沿用：
  - Step01_取貨付款(後付款).sql  [複製自 VSTS566550]
  - Step02_付款後超取(先付款).sql [複製自 VSTS566550]
直接進入 Step 4 確認。
```

#### 3-B：無參考 SQL 時（手動模式）

若 `REF_SQL = null`，詢問需要建立幾個 SQL 檔案，然後逐一收集每個檔案的資訊。

每個檔案需要：
1. **DBName**：資料庫名稱（例：`ERPDB`、`CRMDB`）
2. **TableName**：資料表名稱（例：`SalesOrderSlave`）；若無特定 Table 可輸入操作描述
3. **StepDesc**：步驟描述（例：`更新銷售單狀態`），中文可用，空白替換為 `_`

最終檔名格式：`Step{N}_{DBName}_{TableName}_{StepDesc}.sql`

**範例互動**：
```
要建立幾個 SQL 檔案？> 2

[檔案 1]
  DBName > ERPDB
  TableName > SalesOrderSlave
  StepDesc > 更新銷售單狀態
  ➜ Step1_ERPDB_SalesOrderSlave_更新銷售單狀態.sql

[檔案 2]
  DBName > CRMDB
  TableName > MemberInfo
  StepDesc > 清洗會員資料
  ➜ Step2_CRMDB_MemberInfo_清洗會員資料.sql
```

---

### Step 4：摘要確認

顯示完整執行計畫，詢問是否確認：

```
📋 執行計畫確認
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Git 分支：feature/VSTS{TicketNo}_{TicketTitle}
📁 資料夾：VSTS\VSTS{TicketNo}_{TicketTitle}\
📄 SQL 檔案：
  - Step1_ERPDB_SalesOrderSlave_更新銷售單狀態.sql  [參考工單 #xxxxx]
  - Step2_CRMDB_MemberInfo_清洗會員資料.sql          [空白]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
確認執行？(Y/N)
```

---

### Step 5：執行

確認後依序執行：

#### 5-1 建立 Git 分支

```shell
cd {REPO_ROOT}
git checkout master
git pull
git checkout -b feature/VSTS{TicketNo}_{TicketTitle}
```

- 先切換到 `master` 並 `pull` 最新程式碼，確保分支從最新版本建立
- 若 `git checkout master` 失敗（例如本地有未提交變更），顯示錯誤並停止，提示使用者先處理工作區異動
- 若分支已存在（`already exists`），詢問使用者是否切換到既有分支（`git checkout`）或重新命名後再建立
- 成功後顯示：`✅ 分支已建立：feature/VSTS{TicketNo}_{TicketTitle}`

#### 5-2 建立資料夾

```shell
mkdir "{REPO_ROOT}\VSTS\VSTS{TicketNo}_{TicketTitle}"
```

- 若資料夾已存在，顯示警告但繼續執行
- 成功後顯示：`✅ 資料夾已建立：VSTS\VSTS{TicketNo}_{TicketTitle}\`

#### 5-3 建立 SQL 檔案

對每個 SQL 檔案：

```shell
# 若有 REF_SQL 內容則寫入，否則建立空白檔
echo. > "{REPO_ROOT}\VSTS\VSTS{TicketNo}_{TicketTitle}\Step{N}_{DBName}_{TableName}_{StepDesc}.sql"
```

- 若有 `REF_SQL`，將其寫入對應檔案
- 若無，建立空白（0 byte）的 `.sql` 檔案
- 每個檔案建立後顯示：`✅ Step{N}_{DBName}_{TableName}_{StepDesc}.sql`

#### 5-4 使用者要求 commit 時

當使用者要求 commit，**只能 stage 本次工單的 SQL 資料夾**，嚴禁使用 `git add -A` 或 `git add .`：

```shell
# ✅ 正確：只 add 本次工單資料夾
git add "VSTS/VSTS{TicketNo}_{TicketTitle}/"

# ❌ 錯誤：會把所有未追蹤檔案（如 .gitignore）一起 commit
git add -A
git add .
```

- commit 前執行 `git status` 確認 staged 範圍，確保只包含本次工單的 SQL 檔案
- 若發現有其他無關檔案被 staged，先 `git restore --staged <file>` 移除後再 commit

---

### Step 6：回傳結果

```
🎉 完成！

🌿 目前分支：feature/VSTS{TicketNo}_{TicketTitle}
📁 工作資料夾：VSTS\VSTS{TicketNo}_{TicketTitle}\
📄 已建立 SQL 檔案：
  ✅ Step1_ERPDB_SalesOrderSlave_更新銷售單狀態.sql
  ✅ Step2_CRMDB_MemberInfo_清洗會員資料.sql

💡 提示：SQL 檔案已開啟，請填入對應的操作語法。
```

---

## 注意事項

- **TicketTitle 清理規則**：移除 `\ / : * ? " < > |`，空白與特殊符號替換為 `_`，連續 `_` 合併為一個，前後 `_` 去除
- **Git 分支名稱**不允許空白或特殊字元，清理規則同上
- **SQL 檔案命名**：StepDesc 中的空白替換為 `_`
- 建立 SQL 檔案時**不自動加入任何 SQL 範本語法**，除非有參考工單提供內容
- **參考工單尋找 SQL 的優先順序**：① 工單 PR 連結（用 `bitbucket-pr` skill 讀取）→ ② git log 找合併 PR commit → ③ Azure DevOps 附件 → ④ 工單描述 SQL 區塊
- 若 git commit 含有多個 `.sql` 檔案，列出清單讓使用者選擇（可多選或全選）
- 若參考工單的 Azure DevOps 附件含有多個 `.sql` 檔，請列出清單讓使用者選擇
- 若使用者在 Step 3 輸入 `0` 個 SQL 檔案，跳過 Step 3 直接進入 Step 4，並在計畫中標示「無 SQL 檔案」
- **有參考 SQL 時（Step 3-A）**：直接沿用參考工單的檔名與內容，不詢問數量或檔案資訊，自動進入 Step 4
- **取得 SQL 內容一律用 `git show` 或直接 `Copy-Item`**，⚠️ 嚴禁從 PR diff 擷取 SQL 內容（diff 有長度上限，會造成語法截斷）
- **`git show` 寫檔必須透過 `cmd` pipe**，⚠️ 嚴禁用 PowerShell 變數中轉（`$content = git show ...`），否則 PowerShell 的編碼轉換會導致 SQL 中的中文字變成亂碼
- **commit 只能包含本次工單的 SQL 資料夾**，⚠️ 嚴禁用 `git add -A` 或 `git add .`，必須明確指定 `git add "VSTS/VSTS{TicketNo}_{TicketTitle}/"`，避免將 `.gitignore` 等無關檔案一併 commit
