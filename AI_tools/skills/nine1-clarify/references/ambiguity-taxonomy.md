# Ambiguity Taxonomy — 模糊度分類與掃描規則

需求模糊度掃描使用下列 5 個優先類別，依序評估每個類別的狀態：**Clear / Partial / Missing**。

---

## 類別定義

### Priority 1 — Functional Scope & Behavior（功能範圍與行為）
**Impact Score: 10**

掃描題目：
- 核心使用者目標是否明確定義？
- 成功標準是否有明確描述？
- 範圍外項目（Out-of-scope）是否已聲明？
- 使用者角色/角色分工是否已區分？

### Priority 2 — Domain & Data Model（資料模型）
**Impact Score: 9**

掃描題目：
- 實體（Entity）、屬性、關聯是否清楚？
- 身分識別與唯一性規則是否定義？
- 生命週期/狀態轉移是否有文件記錄？
- 資料量/規模假設是否已說明？

### Priority 3 — Integration & External Dependencies（整合依賴）
**Impact Score: 8**

掃描題目：
- 外部服務/API 是否已識別並包含失敗模式？
- 資料匯入/匯出格式是否已規範？
- 協定/版本假設是否有文件記錄？

### Priority 4 — Edge Cases & Failure Handling（邊界案例）
**Impact Score: 7**

掃描題目：
- 負向情境是否有充分涵蓋？
- 限流/節流需求是否已規範？
- 衝突解決策略是否有定義（例如：併發編輯）？

### Priority 5 — Non-Functional Requirements（非功能需求）
**Impact Score: 8**

掃描題目：
- 效能目標是否已規範（延遲、吞吐量）？
- 安全/隱私需求是否清楚（認證/授權、資料保護）？
- 可觀測性需求是否已定義（日誌、指標）？

---

## 狀態評估標準

| 狀態 | 定義 |
|------|------|
| ✅ Clear | 該類別相關資訊完整，足以做出架構決策 |
| ⚠️ Partial | 部分資訊存在，但有關鍵細節缺失 |
| ❌ Missing | 無任何相關資訊，需要補充 |

---

## 優先序計算

```python
def calculate_priority(category, status):
    impact_scores = {
        "Functional Scope & Behavior": 10,
        "Domain & Data Model": 9,
        "Integration & Dependencies": 8,
        "Non-Functional Requirements": 8,
        "Edge Cases & Failure Handling": 7,
    }
    uncertainty_map = {"Clear": 0, "Partial": 5, "Missing": 10}
    return impact_scores[category] * uncertainty_map[status]
```

分數越高 → 優先生成釐清問題。

---

## 決策點

```python
if all_categories == "Clear":
    # 跳過問題生成，直接進行 Arc42 驗證
    proceed_to_arc42_validation()
else:
    # 依優先序生成問題（參見 question-generation.md）
    proceed_to_question_generation()
```
