# Arc42 Readiness — 架構就緒度評估

---

## 評估目標

審視 Work Item 內容（Description、Comments、Clarifications），檢查各 Arc42 section 是否具備足夠資訊供 Phase 2（nine1-plan）生成完整架構文件。

---

## 各 Section 評估標準

### 1. Solution Strategy（作法概述）— 必要
- ✅ Ready：已描述實作方式（架構模式、技術棧、模組劃分）
- ⚠️ Needs Input：僅概略提及方向，缺少具體決策
- ❌ Missing：完全未描述

### 2. Container Diagram — 建議（多服務架構時必要）
- ✅ Ready：已提及系統容器（Web App、API、DB）
- ⚠️ Needs Input：提及部分容器但有缺漏（例如未說明 DB 類型）
- ❌ Missing：未提及系統邊界

### 3. Component Diagram — 建議（複雜內部結構時必要）
- ✅ Ready：已提及內部元件（Controllers、Services、Repositories）
- ⚠️ Needs Input：分層概念存在但不完整
- ❌ Missing：未提及內部結構

### 4. Database Schema — 若有 DB 異動則必要
- ✅ Ready：已提及資料表、欄位、關聯
- ⚠️ Needs Input：提及需要 DB 異動但無結構說明
- ❌ Missing：未提及任何 DB 資訊

### 5. API Specification — 若有 API 異動則必要
- ✅ Ready：已列出端點、Request/Response 格式
- ⚠️ Needs Input：提及需要 API 但無格式說明
- ❌ Missing：未提及 API 設計

### 6. Runtime View — 建議（複雜流程時必要）
- ✅ Ready：已描述資料流或時序
- ⚠️ Needs Input：有流程描述但缺少錯誤處理
- ❌ Missing：未描述執行時期行為

### 7. Non-Functional Requirements — 必要
- ✅ Ready：已提及效能目標、安全性、可擴展性
- ⚠️ Needs Input：部分非功能需求已定義但不完整
- ❌ Missing：完全未提及

---

## 整體就緒度計算

```python
required_sections = [
    "Solution Strategy",
    "Non-Functional Requirements",
    # 條件性必要（若有異動）
    "Database Schema",    # 若 WI 提及 DB 異動
    "API Specification",  # 若 WI 提及 API 異動
]

def calculate_readiness(arc42_status):
    required_statuses = [arc42_status[s] for s in required_sections]
    
    if "Missing" in required_statuses:
        return "❌ Needs More Input"
    elif "Needs Input" in required_statuses:
        return "⚠️ Proceed with Caution"
    else:
        return "✅ Ready for Planning"
```

---

## 輸出格式（整合於最終摘要）

```markdown
### 🗂️ Arc42 架構就緒度

| 段落 | 必要性 | 狀態 | 備註 |
|-----|--------|------|------|
| Solution Strategy (作法概述) | ✅ 必要 | ✅ Ready | {說明} |
| Container Diagram (容器圖) | 建議 | ⚠️ Needs Input | {說明} |
| Component Diagram (元件圖) | 建議 | ✅ Ready | {說明} |
| Database Schema (資料庫結構) | ✅ 必要 | ❌ Missing | {說明} |
| API Specification (API 規格) | ✅ 必要 | ✅ Ready | {說明} |
| Runtime View (執行時期視圖) | 建議 | ⚠️ Needs Input | {說明} |
| Non Functional Requirements (非功能需求) | ✅ 必要 | ✅ Ready | {說明} |

**整體就緒度：** {✅ Ready / ⚠️ Proceed with Caution / ❌ Needs More Input}

**建議行動：**
- **{section}（{狀態}）**：{具體建議}
```

---

## 評估原則

- **✅ Ready**：Phase 2 可直接生成完整 section，無需 `[TBD]` 標記
- **⚠️ Needs Input**：可生成 section 但會有 `[TBD]`，需要使用者在 Phase 2 補充
- **❌ Missing**：無法生成 section，Phase 2 需先補充或標記 `[需補充]`

此評估**不暫停等待使用者確認**，結果直接整合至最終摘要輸出。
