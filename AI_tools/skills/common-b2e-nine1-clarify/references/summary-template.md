# Summary Template — Phase 1 完成摘要輸出格式

---

```markdown
# Phase 1 完成摘要 — #{workItemId} {title}

---

### 🔒 技術相容性閘門
<!-- 若 Step 2 跳過，顯示「無技術相容性掃描（WI 不符合觸發條件）」 -->

| 技術點 | 狀態 | 官方依據 | 備註 |
|--------|------|---------|------|
| {技術點} | {狀態} | {連結或說明} | {備註} |

**閘門結論：** {✅ 通過 / ⚠️ 通過（含風險）/ ❌ 阻擋（不應出現在此，流程已終止）}

---

### 📊 模糊度改善總覽

| 類別 | 初始狀態 | 釐清後 |
|------|---------|--------|
| Functional Scope & Behavior（功能範圍與行為） | {狀態} | {狀態} |
| Domain & Data Model（資料模型） | {狀態} | {狀態} |
| Integration & External Dependencies（整合依賴） | {狀態} | {狀態} |
| Edge Cases & Failure Handling（邊界案例） | {狀態} | {狀態} |
| Non-Functional Requirements（非功能需求） | {狀態} | {狀態} |

---

### 💬 釐清 Q&A

#### Round 1
**Q1 [{類別}]：** {問題}
**A：** {使用者答案實質內容}

...

---

### 🗂️ Arc42 架構就緒度

| 段落 | 必要性 | 狀態 | 備註 |
|------|--------|------|------|
| Solution Strategy (作法概述) | ✅ 必要 | {狀態} | {說明} |
| Container Diagram (容器圖) | 建議 | {狀態} | {說明} |
| Component Diagram (元件圖) | 建議 | {狀態} | {說明} |
| Database Schema (資料庫結構) | {必要性} | {狀態} | {說明} |
| API Specification (API 規格) | {必要性} | {狀態} | {說明} |
| Runtime View (執行時期視圖) | 建議 | {狀態} | {說明} |
| Non Functional Requirements (非功能需求) | ✅ 必要 | {狀態} | {說明} |

**整體就緒度：** {✅ Ready / ⚠️ Proceed with Caution / ❌ Needs More Input}

---

### 📋 建議行動

- **相容性（若有風險項）**：{具體建議}
- **{Arc42 section}（{狀態}）**：{具體建議}

---

**✅ Phase 1 完成，可執行 `common-b2e-nine1-plan` 進行架構規劃。**
```
