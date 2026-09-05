# Design Blueprint — Core Design Generation Rules

---

## Output Structure

### 3.1 New File List

List, in a table, all classes, interfaces, models, or services that need to be newly created:

```markdown
| 檔案路徑 | 用途 | 核心職責 |
|---------|------|---------|
| `BusinessLogic/Services/PromotionService.cs` | 促銷邏輯協調 | 驗證規則、套用促銷、管理狀態 |
| `DataAccess/Repositories/IPromotionRepository.cs` | 資料存取合約 | 定義 Promotion 實體的 CRUD 操作 |
```

---

### 3.2 Modified File List

List existing files that need to be updated:

```markdown
| 檔案路徑 | 需要的變更 | 原因 |
|---------|-----------|------|
| `WebAPI/Controllers/ProductController.cs` | 新增 `ApplyPromotion()` 端點 | 在 API 層啟用促銷功能 |
```

---

### 3.3 Complete File Tree

Show every affected file, marked [NEW] / [MODIFIED]:

```
ProjectRoot/
├── BusinessLogic/
│   ├── Services/
│   │   ├── PromotionService.cs [NEW]
│   │   └── ProductService.cs [MODIFIED]
...

📊 Summary:
- 影響檔案總數: N
- 新增: M 個
- 修改: K 個
```

The File Tree also serves as the reference baseline for `common-b2e-nine1-tasks`'s task breakdown.

---

### 3.4 DB Changes

```markdown
**新增資料表：**
- `TableName`（欄位定義、PK/FK 說明）

**修改資料表：**
- `ExistingTable`：新增 `ColumnName`（型別、說明）

**索引：**
- `IX_TableName_ColumnName`（用途說明）

**Migration 策略：**
- 現有資料的預設值處理
- CHECK constraint 說明
```

---

### 3.5 Core Code Responsibilities

**Service Layer design:**
- List the main responsibility of each Service
- Specify the DI lifetime (Scoped / Transient / Singleton)
- **Validation method spec (if it includes validation-type methods such as ValidateXxx / CheckXxx):**
  **Directly reuse the business rule list already produced by Step 3 in the "判斷條件 → 允許/禁止行為 → 逐字錯誤訊息（來源）" format** — do not re-scan Description/AC or redefine the rule format. Simply map that list onto the corresponding Service/method, and add an "Error Handling" column (exception type / HTTP status code):

  | 判斷條件 | 允許/禁止行為 | 錯誤處理方式 | 逐字錯誤訊息（來源） |
  |---------|--------------|-------------|---------------------|
  | 活動狀態 = 進行中 且 欄位 ∈ 凍結清單 | 禁止修改該欄位 | 拋出 BusinessException | 「活動進行中，該欄位不可編輯」（來源：AC） |

  - If a rule in Step 3's list is missing a verbatim error message (source not specified), do not fabricate one here — mark it ⚠️ 待確認 only.
  - If a validation rule not present in Step 3 is discovered during design, it must be backfilled into Step 3's list — do not add it only here, to avoid the two lists going out of sync.
  - **If Step 3's business rule list is empty** (this feature has no explicit business rules or error-handling scenarios), omit the validation method spec table here and instead state "本功能無需額外驗證規則說明" — do not generate an empty table or placeholder row.
  This rule list also serves as the enumeration basis for Unit Test cases; the verbatim-preserved error messages also serve as the basis for Unit Test assertion content.

**Component interaction description:**
```
API Layer → Service Layer → Repository Layer → Database
```

**Reuse of existing components:**
- ✅ Existing Repository / Helper / Validator that can be reused
- ❌ Cases where new creation should be avoided in favor of extending an existing component
- 🆕 **New dependency selection: if Step 3.5's Internal SDK Discovery produced Internal SDK Candidates, prefer the internal SDK
  before considering an external NuGet package** (⚡ SDK-first principle). If there are no Candidates or this design involves no new dependency, skip this item.

**Key implementation points:**
List 1-5 important design-level (non-code) considerations.

---

## Design Principles

1. **Concretely implementable**: every item can be directly assigned to a developer to execute
2. **Reuse first**: identify reusable components first, avoid duplicate creation
3. **Clear responsibilities**: the boundary of each class/service is clear
4. **Complete File Tree**: ensure every affected file is listed, for use in task breakdown
5. **Complete DB changes**: include the migration strategy, do not omit index design
