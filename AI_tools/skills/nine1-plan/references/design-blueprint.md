# Design Blueprint — 核心設計生成規則

---

## 產出結構

### 3.1 新增檔案清單

以表格列出所有需要新建的類別、介面、模型或服務：

```markdown
| 檔案路徑 | 用途 | 核心職責 |
|---------|------|---------|
| `BusinessLogic/Services/PromotionService.cs` | 促銷邏輯協調 | 驗證規則、套用促銷、管理狀態 |
| `DataAccess/Repositories/IPromotionRepository.cs` | 資料存取合約 | 定義 Promotion 實體的 CRUD 操作 |
```

---

### 3.2 修改檔案清單

列出需要更新的既有檔案：

```markdown
| 檔案路徑 | 需要的變更 | 原因 |
|---------|-----------|------|
| `WebAPI/Controllers/ProductController.cs` | 新增 `ApplyPromotion()` 端點 | 在 API 層啟用促銷功能 |
```

---

### 3.3 完整 File Tree

顯示所有受影響的檔案，標示 [NEW] / [MODIFIED]：

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

File Tree 同時作為 nine1-tasks 任務拆解的參考基準。

---

### 3.4 DB 異動

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

### 3.5 核心程式碼職責

**Service Layer 設計：**
- 列出每個 Service 的主要職責
- 指定 DI 生命週期（Scoped / Transient / Singleton）

**元件互動說明：**
```
API Layer → Service Layer → Repository Layer → Database
```

**複用既有元件：**
- ✅ 可複用的既有 Repository / Helper / Validator
- ❌ 不應新建，應擴充既有元件的情況

**關鍵實作要點：**
列出 1-5 個設計層面（非程式碼）的重要考量。

---

## 設計原則

1. **具體可實作**：每個項目都能直接指派給開發人員執行
2. **複用優先**：先識別可複用元件，避免重複建立
3. **職責明確**：每個類別/服務的邊界清楚
4. **File Tree 完整**：確保任何受影響的檔案都列出，供任務拆解使用
5. **DB 異動完整**：包含 Migration 策略，不遺漏 index 設計
