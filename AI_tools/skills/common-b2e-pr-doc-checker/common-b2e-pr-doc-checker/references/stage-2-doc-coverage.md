# Stage 2：`.doc/` 文件覆蓋核查

**目標**：依 Stage 1 的異動信號清單，找出 `/.doc/` 中對應的知識文件，比對覆蓋是否完整，產出每個信號的覆蓋狀態。

---

## Step 2.1：掃描 `/.doc/` 目錄結構

```powershell
Get-ChildItem -Path ".doc" -Recurse -Filter "*.md" | Select-Object -ExpandProperty FullName
```

列出所有 `/.doc/*.md` 檔案，建立文件索引。  
若目錄為空，繼續但於最終報告標記「⚠️ 文件庫為空」。

---

## Step 2.2：信號對文件的對應規則

依 Stage 1 的每個異動信號，套用以下對應邏輯找出「應核查的文件」：

### 對應表

| 異動信號 | 應存在於 `/.doc/` 的文件類型 | 判斷關鍵字（文件檔名或路徑） |
|---------|---------------------------|--------------------------|
| `API_ENDPOINT` | API Spec 或 Business Flow 文件 | `api_spec`、`spec.md`、`business_flow`、`api.md` |
| `REQUEST_RESPONSE` | API Spec（Request/Response schema） | `api_spec`、`spec.md`、`data_schema` |
| `BUSINESS_LOGIC` | 領域業務知識文件 | `basic_knowledge`、`domain`、`business_flow` |
| `DB_SCHEMA` | DB Schema 文件 | `db_schema`、`entity`、`schema.md` |
| `DOMAIN_EVENT` | 業務流程或領域文件 | `business_flow`、`event`、`domain` |
| `EXTERNAL_INTEGRATION` | 領域文件或外部整合說明 | `domain`、`integration`、`repo_refs` |
| `WORKER` | 業務流程文件 | `business_flow`、`worker`、`domain` |

> 比對方式：檔案路徑包含上方關鍵字（case-insensitive），即視為「候選文件」。  
> 若同一信號找到多個候選文件，全部納入核查範圍。

---

## Step 2.3：文件內容比對

對每個「候選文件」執行語意層面的比對：

### 比對重點

| 信號類型 | 比對項目 |
|---------|---------|
| `API_ENDPOINT` | 文件中是否包含本次 PR 新增/修改的 endpoint 路由 |
| `REQUEST_RESPONSE` | 文件中是否包含對應的 DTO/Request/Response 欄位 |
| `BUSINESS_LOGIC` | 文件中是否反映本次新增的業務規則、狀態轉移、條件判斷 |
| `DB_SCHEMA` | 文件中是否包含本次 Migration 新增/修改的欄位定義 |
| `DOMAIN_EVENT` | 文件中是否記載本次新增的事件類型與觸發條件 |
| `EXTERNAL_INTEGRATION` | 文件中是否包含本次新增的外部服務名稱/endpoint 設定 |
| `WORKER` | 文件中是否描述本次修改的背景作業觸發條件與流程 |

---

## Step 2.4：覆蓋狀態判定

對每個 Stage 1 異動信號，判定：

| 狀態 | 判定條件 |
|------|---------|
| ✅ **已覆蓋** | 找到對應文件，且語意層面的比對項目均已包含 |
| ⚠️ **部分覆蓋** | 找到對應文件，但比對項目中有遺漏（如：新欄位未更新到文件）|
| ❌ **未覆蓋** | 完全找不到對應文件，或文件存在但與本次異動完全無交集 |
| 🟢 **低風險** | 信號觸發等級為 🟢（`CONFIG_ONLY` / `TEST_ONLY`），不計入落差 |

---

## Step 2.5：判斷是否需要進入 Stage 3

| 條件 | 動作 |
|------|------|
| 所有 🔴 信號皆為 ✅ 已覆蓋 | → 直接進 Stage 4，輸出「文件對齊」報告 |
| 存在任何 ⚠️ 或 ❌ 狀態，且落差原因不明確 | → 進 Stage 3 補充意圖 |
| 存在任何 ⚠️ 或 ❌ 狀態，且已從 diff 中明確判斷落差原因 | → 直接進 Stage 4，不需 Stage 3 |

> **判斷原則**：若 diff 本身已足夠判斷「什麼功能改了、對應文件應該更新哪裡」，就直接進 Stage 4。只有在 diff 無法判斷開發意圖（如：重構或大量重寫）時，才進 Stage 3 補充 commit / user story 脈絡。
