# Stage 3：意圖補充（Commit → User Story → Task）

**目標**：當 Stage 2 的 diff 分析無法明確判斷落差原因時，依優先順序從 Commit → User Story → Task 補充開發意圖，協助精準判斷哪些文件該補。

> ⚠️ 此 Stage 為條件觸發。若 Stage 2 已能明確判斷所有落差，跳過本 Stage 直接進 Stage 4。

---

## 分析來源優先順序

```
Priority 1: Commit message
Priority 2: User Story (Azure DevOps Work Item)
Priority 3: Task (Azure DevOps Work Item 子項目)
```

**使用原則**：
- 從優先度 1 開始，若已能補充足夠意圖，不繼續讀取更低優先度的來源。
- 多個來源的資訊以 **Code diff 為最高優先**；意圖來源只是輔助，不可覆蓋 diff 的實際程式碼異動事實。

---

## Priority 1：Commit Message 分析

```powershell
git log origin/{baseBranch}..HEAD --format="%H %s %b" --no-merges
```

### 解讀規則

| Commit 類型前綴 | 文件觸發提示 |
|----------------|------------|
| `feat:` / `feature:` | 新功能 → 幾乎必定需要更新文件 |
| `fix:` / `bugfix:` | 修好 bug → 若修改涉及業務規則則需更新，否則通常不需要 |
| `refactor:` | 重構 → 若 API/業務行為不變則不需要，但若欄位改名則需更新 |
| `chore:` / `docs:` / `ci:` | 通常不需更新業務知識文件 |
| `BREAKING CHANGE:` | 重大變更 → 必定需要更新 |

若 commit message 包含 Ticket 編號（如 `VSTS-1234`、`#1234`），記錄備用於 Priority 2。

---

## Priority 2：User Story 讀取（Azure DevOps）

透過 `tf-work-item-context` Skill 取得 User Story 的 Description 與 Acceptance Criteria：

> 若 `tf-work-item-context` 無法取得，標記 `[BLOCKED: AzDO 連線失敗]`，跳至 Priority 3。

### 解讀重點

從 User Story Description 與 AC 中提取：

1. **功能範圍描述**：「新增 XXX 功能」→ 對應到哪個 Domain
2. **業務規則**：AC 中的驗收條件 → 對應 `basic_knowledge` 或 `business_flow` 文件
3. **API 合約**：若 AC 提到「前端可以呼叫 API 取得 XXX」→ 對應 `api_spec` 文件
4. **欄位定義**：若 AC 提到新欄位 → 對應 `db_schema` 或 DTO 相關文件

---

## Priority 3：Task 讀取（Azure DevOps 子項目）

若 User Story 不夠具體，進一步讀取其下的 Task Description：

> 透過 `tf-work-item-context` Skill 取得 Task，尋找技術設計描述與 ImplementPlan。

### 解讀重點

1. **ImplementPlan 中的 File Tree**：對照實際 diff，確認哪些部分被實作
2. **DB 異動描述**：是否有新 Table / 欄位 → 對應 `db_schema`
3. **API 設計描述**：Request/Response 格式 → 對應 `api_spec`

---

## Stage 3 輸出

補充完意圖後，整合進 Stage 2 的覆蓋狀態，為每個 ⚠️/❌ 的信號補上「意圖說明」：

```
信號：BUSINESS_LOGIC（OrderService.cs）
意圖來源：Commit - "feat: 新增訂單退款業務規則限制"
補充判斷：✅ 確認需要更新 /.doc/basic_knowledge/ 中的業務規則文件
```

整合後進入 Stage 4。
