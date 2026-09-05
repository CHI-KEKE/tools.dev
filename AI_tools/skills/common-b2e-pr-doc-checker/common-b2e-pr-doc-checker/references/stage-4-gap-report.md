# Stage 4：文件落差報告

**目標**：整合 Stage 1–3 的結果，產出結構化的「文件對齊報告」，告訴開發者哪些文件需要補件，以及建議補件的方式。

---

## 報告格式

使用 `assets/gap-report-template.md` 的範本輸出，內容依以下規則填寫。

---

## 整體評級規則

| 評級 | 條件 |
|------|------|
| ✅ **Aligned** | 所有 🔴 信號皆已覆蓋，且無任何 ❌ 落差 |
| ⚠️ **Partial** | 存在 ⚠️ 部分覆蓋，但所有 🔴 信號皆有對應文件（只是內容不完整）|
| ❌ **Gap Detected** | 存在任何 ❌ 未覆蓋的 🔴 信號 |
| ℹ️ **Low Risk** | 所有異動皆為 🟢 分類（Config / Test only）|

---

## 落差項目格式

每個落差項目必須包含：

```markdown
### [落差項目標題]

- **信號類型**：{API_ENDPOINT / DB_SCHEMA / ...}
- **觸發等級**：{🔴 必須更新 / 🟡 建議更新}
- **觸發依據**：{檔案路徑#行號 或 commit hash}
- **意圖來源**：{Code diff / Commit / User Story / Task}（優先度最高的有效來源）
- **覆蓋狀態**：{❌ 未覆蓋 / ⚠️ 部分覆蓋}
- **應更新文件**：{`/.doc/` 相對路徑，若文件不存在則標注「需新建」}
- **補件建議**：
  - 建議使用 `{common-b2e-api-spec-creator / common-b2e-doc-system-design-creator}` 補齊
  - 需補充的具體內容：{欄位名稱 / endpoint 路由 / 業務規則描述}
```

---

## 補件 Handoff 建議

在報告末尾，依落差的類型給出 handoff 建議：

| 落差類型 | 建議使用的 Skill |
|---------|----------------|
| API endpoint 或 Request/Response 遺漏 | `common-api-spec-creator` |
| 業務規則 / 領域知識遺漏 | `common-b2e-doc-system-design-creator` |
| DB Schema 遺漏 | `common-b2e-doc-system-design-creator` |
| 全面補件（大型 PR） | 先 `common-b2e-tool-code-scanner`（Level 2 或 Level 3），再補 domain 文件 |

> **不執行補件**：本 Skill 只回報落差，不自動觸發補件。使用者確認後，可自行呼叫對應 Skill。

---

## 產出時間標記

報告末尾必須加上：

```
產出時間：YYYY-MM-DD HH:MM
分析來源：Code diff{, Commit}{, User Story WI#{id}}{, Task WI#{id}}
````

若 Stage 3 有使用 Azure DevOps Work Item，附上對應的 WI ID。
