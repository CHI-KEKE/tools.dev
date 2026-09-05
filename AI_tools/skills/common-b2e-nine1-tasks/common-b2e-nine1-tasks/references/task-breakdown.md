# Task Breakdown — Task Breakdown Principles & Design Document Format

---

## ⛔ Business Rule Inheritance Rule (Mandatory)

If a task's scope involves validation/business rule logic, you **must** filter the rule subset applicable to that task from the parent Work Item's `Custom.ImplementPlan` "業務規則清單" (produced in Step 3), and **paste it in full** into the task design document's "適用業務規則與逐字錯誤訊息" section — **do not write only the rule count or a summary** (e.g. it is forbidden to write only "implement all 19 business rule validations" without listing the actual content).

- Verbatim error messages must exactly match the original text in the ImplementPlan — do not rewrite them
- If a rule spans multiple tasks, each task only needs to list the **subset relevant to its own scope** — there is no need to repeat all 19 rules in every task
- If a rule is marked ⚠️ 待確認 in the ImplementPlan, this marker must be preserved as-is in the task — do not assume a final wording and remove the marker

---

## Cases for Merging into a Single Task

- Entity + Repository interface → `Data Model Layer` (2-4 hours)
- Repository + Service logic → `Business Logic Layer` (depending on complexity)
- API endpoint + Service method → `Feature Implementation`
- CRUD operations in the same domain (completable within 2-4 hours)

---

## Cases for Splitting into Separate Tasks

- Different domains (e.g. Product vs. Promotion)
- Complex flows requiring collaboration between different members
- Non-functional work (performance, security, monitoring)
- Integration/load testing (depends on feature completion)

---

## Task Size Criteria (all must be satisfied)

| Criterion | Target | Too Small | Too Large |
|------|------|------|------|
| Dev time | 2-4 hours | < 30 min → merge | > 8 hours → split |
| File impact | 3-8 files | 1 file → merge | > 10 files → split |
| Functional unit | Testable feature | Code artifact only | Multiple features |
| Autonomy | Single person | — | Requires multi-person collaboration |

---

## Task Design Document Format

Every task must include all of the following sections:

```markdown
### {序號}. {任務標題}

#### 背景與範圍（Context & Scope）
{商業目標與技術背景，1-3 句說明}

#### 目標與非目標（Goals & Non-Goals）
**Goals：**
- {包含項目 1}

**Non-Goals：**
- {明確排除項目 1}

#### 工作說明（Work Description）
{需要實作或修改的內容}

#### 設計考量（Design Considerations）
{涉及的邏輯/元件、取捨、元件互動關係}

#### 替代方案（Alternative Approaches）
{其他可行方法與其優缺點}

#### 橫切關注點（Cross-cutting Concerns）
{安全性、效能、可維護性的相關考量}

#### 關鍵實作重點（Key Implementation Focus）
{設計層面的實作要點，不包含程式碼}

#### 適用業務規則與逐字錯誤訊息（Applicable Business Rules & Verbatim Error Messages）
{僅當本任務範疇涉及驗證/業務規則時包含此段落；若不涉及，整段省略，不留空段落}
{從 ImplementPlan「業務規則清單」中，篩選出**本任務範疇適用**的規則子集，逐條完整貼入（不得只寫數量或摘要）：}

| 判斷條件 | 允許/禁止行為 | 逐字錯誤訊息（來源） |
|---------|--------------|---------------------|
| {條件} | {行為} | 「{逐字訊息}」（來源：Description/AC） |

{若某規則的逐字錯誤訊息在 ImplementPlan 階段已標記 ⚠️ 待確認，此處原樣保留 ⚠️ 標記，不得自行假設最終文案}

#### 單元測試建議（Unit Test Suggestions）
{需要驗證的項目清單}

#### 異動檔案（Files to Modify/Add）
- `{路徑/檔名.cs}` [NEW/MODIFIED] - {說明}

#### 相依關係（Dependencies）
- 待其他任務建立後填入 Task ID（例如：`Task #12456 必須完成後才能開始`）
```

---

## DTO / Entity Field Spec Table (when required)

When a task involves a DTO / Entity / Model, it **must** include a field spec table:

```markdown
| 欄位名稱 | 型別 | 必填 | 說明 | 備註 |
|---------|------|:----:|------|------|
| ProductId | int | ✅ | 商品編號 | PK |
| PromotionName | string | ✅ | 促銷名稱 | Max 100 chars |
| StartDate | DateTime? | ❌ | 開始日期 | Nullable |
```

Applies to:
- New classes
- New properties
- Type changes
- API Request / Response format
- DB Entity mapping

---

## Anti-Pattern Examples

❌ **Over-fragmented (10 tasks):**
Create Entity → create interface → implement Repository → create Service → ...

✅ **Appropriately split (3 tasks):**
- [P] 1. 建立資料模型與持久化層（Entity + Repository + 測試）
- [P] 2. 建立業務邏輯層（Service + 測試）
- 3. 建立查詢 API（Controller + 端點 + 測試）
