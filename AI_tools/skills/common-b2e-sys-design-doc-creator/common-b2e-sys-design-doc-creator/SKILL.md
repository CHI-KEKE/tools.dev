---
name: common-b2e-sys-design-doc-creator
description: 
  針對指定的程式碼範圍（API、Worker、Controller 等），自動盤點相關程式碼邏輯，並整理出結構化的領域知識文件（Domain Document）。
  文件涵蓋：核心業務價值、程式碼範圍（API Controller / Worker / DB Table）、專有名詞定義、業務規則與限制（強制性規則、狀態轉移）、領域邊界與整合（外部服務相依、事件訂閱與觸發）。
  當使用者說「幫我建立 domain 文件」、「整理這個領域的業務知識」、「這幾隻 API 的 domain 是什麼」、「盤點這個 worker 的業務規則」、「我要了解這個範圍的業務邏輯」，都應優先觸發此 Skill。
  也適合新人 onboarding、業務文件補齊、架構設計前的業務梳理、以及 DDD（Domain-Driven Design）導入前的現況分析。
---

# Domain Creator Skill

協助 RD 針對指定程式碼範圍，產出結構化的**領域知識文件（Domain Document）**。
文件目標是讓任何人（包括非技術背景的 PM/BA）都能理解該程式碼範圍的業務意圖與規則。

## 核心原則

- **業務語言優先**：用業務語言描述，不用技術術語堆砌
- **範圍明確**：每份文件對應一個明確的程式碼範圍
- **規則可驗證**：每條業務規則要能從程式碼中找到對應的實作依據
- **邊界清晰**：明確標示與外部系統的整合點與責任邊界
- **時效標記**：每份報告末尾標註產出時間（`產出時間：YYYY-MM-DD HH:MM`）

---

## 執行流程

### Step 1：確認 Domain 名稱

**⚠️ 必要前置條件**：使用者必須明確說明要建立哪個 Domain 的文件，才能繼續。若使用者沒有指定，**必須先詢問，不可自行假設**。

取得 Domain 名稱後，進入 **Step 1.5**。

---

### Step 1.5：判斷情境（程式碼是否存在）

詢問使用者：

> 「請問這個 Domain 目前是否已經有對應的程式碼（例如 Controller API、Worker 觸發點）？
> - **有**：我將盤點現有程式碼並整理文件
> - **沒有**：我將透過問答引導您完成 Domain 文件」

依使用者回答，選擇執行路徑：

| 使用者回答 | 執行路徑 |
|---|---|
| **有** 對應程式碼 | → 進入 **Step 2A：盤點模式** |
| **沒有** 對應程式碼 | → 進入 **Step 2B：問答引導模式** |

---

### Step 2A：盤點相關程式碼（既有程式碼路徑）

> 適用情境：Domain 已有對應的 Controller / Worker / Service 實作。

先請使用者確認分析範圍：
- 哪幾隻 API endpoint（路由或 Controller 名稱）
- 哪個 Worker
- 哪個 Service 或模組名稱

**確認格式範例：**
> 「請提供程式碼範圍，例如：Controller 名稱、Worker 名稱、API 路由，或功能描述（升等流程、點數兌換）都可以。」

取得範圍後，使用 `common-b2e-tool-code-scanner` Skill 的分析能力，依序執行以下盤點作業：

1. **定位入口點**：找出使用者指定的 Controller / Worker / Service 檔案
2. **追蹤 Service 層**：從 Controller/Worker 找出呼叫的所有 Service 方法
3. **追蹤 Repository 層**：從 Service 找出存取的 Repository 與 DB Table
4. **識別外部整合**：HTTP Client、Redis、MQ（訊息佇列）、外部 API 呼叫
5. **收集事件流**：找出訂閱的事件（Event Subscriber）與觸發的事件（Event Publisher）

讀取以下類型的檔案並分析其邏輯：
- `*Controller.cs` — API 入口，抽取 endpoint 路由與商業意圖
- `*Worker.cs` — 背景工作，抽取觸發條件與工作內容
- `*Service.cs` — 商業邏輯，抽取業務規則與條件判斷
- `*Repository.cs` — 資料存取，抽取使用的 DB Table 與 SQL 邏輯
- `*Entity.cs` / `*Model.cs` — 資料模型，抽取欄位與狀態定義

詳細分析指引請讀取 `agents/scope_analyst.md`。

完成盤點後，進入 **Step 3**。

---

### Step 2B：引導問答模式（全新 Domain 路徑）

> 適用情境：Domain 尚無對應程式碼，透過問答收集業務知識。

依照 `agents/domain_interviewer.md` 的引導流程，分三輪與使用者進行問答：

**第一輪：業務核心（必問）**
- 這個 Domain 要解決什麼業務問題？服務對象是誰？
- 核心的業務「名詞」有哪些？（例如：會員等級、升等門檻）
- 這些名詞之間的關係是什麼？

**第二輪：業務規則（按需展開）**
- 有哪些「不能做」或「必須滿足」的限制條件？
- 這個 Domain 的資料有「狀態」的概念嗎？狀態怎麼流轉？
- 什麼事件或動作會觸發狀態的變化？

**第三輪：邊界整合（按需展開）**
- 這個 Domain 需要與哪些外部系統互動？
- 預計需要儲存哪些資料？有哪些主要的資料表？

每輪問答結束後，**給出摘要讓使用者確認**，確認後再進行下一輪。
全部問答完成後，進入 **Step 3（草稿模式）**。

---

### Step 3：整理領域知識並輸出 8 個文件

依照 `assets/domain_document_template.md` 的格式，**分別產出以下 8 個獨立 md 檔案**。

> **資料來源說明**：
> - 來自 **Step 2A（盤點模式）**：所有內容須有程式碼依據（類別 + 方法名稱）
> - 來自 **Step 2B（問答模式）**：每份文件開頭加上草稿標記，程式碼範圍標示 🔲 待實作，業務規則依據標示「來自訪談」，schema 欄位標示 📝 待 RD 補充

#### 各檔案內容對應

| 檔案 | 內容 | 資料來源 |
|---|---|---|
| `00-overview.md` | 核心業務價值、程式碼範圍（Controller/Worker/DB Table 清單）、專有名詞 / 關鍵字 Mapping（合併表，中文名 / 英文關鍵字 / 業務說明） | Q1~Q3、Q11~Q12 / code 掃描 |
| `01-c4-l1-system-context.md` | C4 L1 System Context：此 Domain 在整體系統中的位置，外部使用者與系統 | Q7（2B）/ code 掃描（2A） |
| `02-c4-l2-container.md` | C4 L2 Container：涉及哪些 Application、彼此串接方式（Mermaid graph） | Q8（2B）/ code 掃描（2A） |
| `03-db-schema.md` | DB Table 清單 + table name；schema 欄位由 RD 補充 | Q11~Q12（2B）/ Repository 分析（2A） |
| `04-sequence-diagram.md` | Sequence Diagram；**必須標明重要邏輯（判斷分支、狀態變更、規則套用點）；若有對外打的 API，需標明完整 API 路徑（method + endpoint）** | Q6~Q10 推導 + 重要邏輯標註（2B）/ code 掃描 + Controller/HttpClient 路徑抽取（2A） |
| `05-api-list.md` | API endpoint 清單（Controller / route / HTTP method / 說明） | 2B：規劃清單（🔲 待實作）；2A：從 Controller 掃出 |
| `06-event-queue.md` | 訂閱事件、觸發事件、MQ topic 清單 | Q13~Q14（2B）/ NMQ 分析（2A） |
| `07-cross-app-relationship.md` | 跨 Application 關係：呼叫方向、整合方式、邊界定義 | Q9~Q10（2B）/ HTTP Client 分析（2A） |
| `08-business-flow.md` | 核心業務流程 Mermaid flowchart | Q6（2B）/ Service 邏輯分析（2A） |

#### 3.6 輸出文件

完成內容整理後，在 **`.docs/B2E/domain-{Domain名稱}/`** 目錄下建立 8 個 md 檔案：

```
.docs/B2E/domain-{Domain名稱}/
├── 00-overview.md
├── 01-c4-l1-system-context.md
├── 02-c4-l2-container.md
├── 03-db-schema.md
├── 04-sequence-diagram.md
├── 05-api-list.md
├── 06-event-queue.md
├── 07-cross-app-relationship.md
└── 08-business-flow.md
```

- Domain 名稱使用使用者指定的名稱，例如：
  - `.docs/B2E/domain-MemberTier/`
  - `.docs/B2E/domain-PointRedemption/`
- 若目錄不存在，**先建立目錄再依序寫入 8 個檔案**
- 全部寫入後，列出所有檔案路徑告知使用者

---

## 輸出品質檢核清單

每份文件產出前自我確認：

**通用（兩條路徑皆適用）**
- [ ] 已取得使用者明確的 Domain 名稱
- [ ] 已詢問使用者選擇盤點模式或問答模式
- [ ] `00-overview.md`：核心業務價值用非技術語言，PM 看得懂
- [ ] `00-overview.md`：包含「專有名詞 / 關鍵字 Mapping」整合表格（中文名 / 英文關鍵字 / 業務說明），且至少列出一組
- [ ] `00-overview.md`：表格的業務說明使用業務語言，非技術定義
- [ ] `01-c4-l1-system-context.md`：列出所有外部使用者與系統
- [ ] `02-c4-l2-container.md`：Mermaid graph 呈現 Application 串接關係
- [ ] `03-db-schema.md`：包含 table name，schema 欄位有標示待補充方式
- [ ] `04-sequence-diagram.md`：列出參與者，並**標明重要邏輯**（關鍵判斷分支、狀態變更、業務規則套用點）
- [ ] `04-sequence-diagram.md`：若有**對外呼叫的 API**，訊息標籤含完整 **HTTP method + endpoint**（例：`POST /api/members/{id}/upgrade`），並於「對外 API 清單」表列出
- [ ] `05-api-list.md`：列出 endpoint 或規劃清單
- [ ] `06-event-queue.md`：訂閱與觸發事件分開列出
- [ ] `07-cross-app-relationship.md`：整合方式與邊界定義完整
- [ ] `08-business-flow.md`：Mermaid flowchart 有判斷分支
- [ ] **8 個檔案皆已儲存至 `.docs/B2E/domain-{名稱}/`**

**Step 2A 盤點模式專屬**
- [ ] 每條業務規則有程式碼依據（類別 + 方法名稱）
- [ ] DB Table 從 Repository 分析取得，欄位盡量完整

**Step 2B 問答模式專屬**
- [ ] 每份文件開頭有草稿標記（⚠️ 草稿文件）
- [ ] 程式碼範圍、API 清單標示 🔲 待實作
- [ ] 四輪問答皆完成且使用者已確認摘要
- [ ] 業務規則依據欄位標示「來自訪談」
- [ ] DB Schema 欄位標示 📝 待 RD 補充

---

## 參考資源

- `agents/scope_analyst.md` — Step 2A 程式碼範圍分析的詳細指引
- `agents/domain_interviewer.md` — Step 2B 引導問答流程的詳細指引
- `assets/domain_document_template.md` — 領域知識文件完整模板
- `assets/domain-catalog-template.md` — Domain Catalog 索引檔模板（由 `common-b2e-domain-initialize` Agent Step 4 使用）
- `references/event_patterns.md` — 事件識別模式（如何找 MQ Publisher / Subscriber）
- `references/boundary_patterns.md` — 邊界識別模式（如何定義與外部系統的邊界）
