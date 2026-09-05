# Task Breakdown — 任務拆解原則與設計文件格式

---

## 合併為單一任務的情況

- Entity + Repository 介面 → `資料模型層`（2-4 小時）
- Repository + Service 邏輯 → `業務邏輯層`（視複雜度）
- API 端點 + Service 方法 → `功能實作`
- 同領域的 CRUD 操作（2-4 小時內可完成）

---

## 拆分為獨立任務的情況

- 不同領域（例如 Product vs. Promotion）
- 複雜流程需不同成員協作
- 非功能性工作（效能、安全、監控）
- 整合/負載測試（依賴功能完成）

---

## 任務大小標準（須全部符合）

| 標準 | 目標 | 過小 | 過大 |
|------|------|------|------|
| 開發時間 | 2-4 小時 | < 30 分鐘 → 合併 | > 8 小時 → 拆分 |
| 檔案影響 | 3-8 個 | 1 個 → 合併 | > 10 個 → 拆分 |
| 功能單元 | 可測試功能 | 僅程式碼產出物 | 多個功能 |
| 自主性 | 單人執行 | — | 需多人協作 |

---

## 任務設計文件格式

每個任務必須包含以下所有段落：

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

#### 單元測試建議（Unit Test Suggestions）
{需要驗證的項目清單}

#### 異動檔案（Files to Modify/Add）
- `{路徑/檔名.cs}` [NEW/MODIFIED] - {說明}

#### 相依關係（Dependencies）
- 待其他任務建立後填入 Task ID（例如：`Task #12456 必須完成後才能開始`）
```

---

## DTO / Entity 欄位規格表（必要時）

當任務涉及 DTO / Entity / Model 時，**必須**附上欄位規格表：

```markdown
| 欄位名稱 | 型別 | 必填 | 說明 | 備註 |
|---------|------|:----:|------|------|
| ProductId | int | ✅ | 商品編號 | PK |
| PromotionName | string | ✅ | 促銷名稱 | Max 100 chars |
| StartDate | DateTime? | ❌ | 開始日期 | Nullable |
```

適用範疇：
- 新增類別
- 新增屬性
- API Request / Response 格式
- DB Entity 映射

---

## 反範例說明

❌ **過細拆分（10 個任務）：**
建立 Entity → 建立介面 → 實作 Repository → 建立 Service → ...

✅ **適當拆分（3 個任務）：**
- [P] 1. 建立資料模型與持久化層（Entity + Repository + 測試）
- [P] 2. 建立業務邏輯層（Service + 測試）
- 3. 建立查詢 API（Controller + 端點 + 測試）
