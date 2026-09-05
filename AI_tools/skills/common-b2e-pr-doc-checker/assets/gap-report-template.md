# PR 文件對齊報告

> **Skill**：common-b2e-pr-doc-checker  
> **Repo**：{repo-name}  
> **Branch**：{feature-branch} → {base-branch}  
> **平台**：{Bitbucket / GitLab / Unknown}

---

## 整體評級

<!-- 填入：✅ Aligned / ⚠️ Partial / ❌ Gap Detected / ℹ️ Low Risk -->
**{評級}**

---

## 環境資訊

| 項目 | 值 |
|------|---|
| Base Branch | {base-branch} |
| PR Branch | {feature-branch} |
| 平台 | {platform} |
| 程式碼異動檔案數 | {count} |
| `/.doc/` 已異動檔案數 | {doc-count}（PR 中已包含的文件更新）|
| 分析來源 | {Code diff [, Commit] [, User Story WI#{id}] [, Task WI#{id}]} |

---

## 異動信號摘要

| 信號類型 | 觸發等級 | 代表性異動檔案 | 覆蓋狀態 |
|---------|---------|--------------|---------|
| {API_ENDPOINT} | 🔴 必須更新 | {OrderController.cs} | {✅ / ⚠️ / ❌} |
| {DB_SCHEMA} | 🔴 必須更新 | {20240301_AddColumn.cs} | {✅ / ⚠️ / ❌} |
| {BUSINESS_LOGIC} | 🟡 建議更新 | {OrderService.cs} | {✅ / ⚠️ / ❌} |

---

## 落差明細

<!-- 若無落差，本節替換為「✅ 所有異動信號皆已覆蓋，文件對齊。」 -->

### 落差 1：{簡短標題}

- **信號類型**：{API_ENDPOINT / DB_SCHEMA / BUSINESS_LOGIC / ...}
- **觸發等級**：{🔴 必須更新 / 🟡 建議更新}
- **觸發依據**：`{檔案路徑#行號}` 或 commit `{hash}`
- **意圖來源**：{Code diff / Commit `feat: xxx` / User Story WI#{id} / Task WI#{id}}
- **覆蓋狀態**：{❌ 未覆蓋 / ⚠️ 部分覆蓋}
- **應更新文件**：`/.doc/{路徑/檔名.md}`（若不存在：`需新建`）
- **遺漏內容摘要**：
  - {例：新 endpoint `POST /api/orders/refund` 未出現在 api_spec}
  - {例：`RefundReason` 欄位定義未補入 db_schema}
- **補件建議**：使用 `{common-api-spec-creator / common-b2e-doc-system-design-creator}` 補齊

---

### 落差 2：{簡短標題}

<!-- 重複上方區塊格式 -->

---

## `/.doc/` 已覆蓋項目

<!-- 若 Stage 2 有找到已覆蓋的信號，在此列出，給使用者正向回饋 -->

| 信號類型 | 對應文件 | 狀態 |
|---------|---------|------|
| {API_ENDPOINT} | `/.doc/api_spec/spec.md` | ✅ 已覆蓋 |

---

## 補件 Handoff 建議

<!-- 依落差類型填入，若無落差則省略本節 -->

| 落差類型 | 建議 Skill | 操作提示 |
|---------|-----------|---------|
| API endpoint 遺漏 | `common-api-spec-creator` | 針對 `{controller/endpoint}` 呼叫 |
| 業務規則 / 領域知識遺漏 | `common-b2e-doc-system-design-creator` | 指定 Domain 為 `{domain-name}` |
| DB Schema 遺漏 | `common-b2e-doc-system-design-creator` | 指定 Migration `{migration-name}` |

---

> 產出時間：{YYYY-MM-DD HH:MM}  
> 分析來源：{Code diff [, Commit] [, User Story WI#{id}] [, Task WI#{id}]}
