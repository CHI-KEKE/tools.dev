---
name: common-api-spec-creator
description: >
  將程式碼中的 API 實作轉為可對接、可驗證的規格文件（API Spec）。
  產出內容包含：Request/Response 欄位規格、Data Schema、每支 API 各自的 Request/Response JSON 範例。
  當使用者說「幫我整理 API 規格」、「這支 API 的 Request/Response 是什麼」、「產 API 文件」、「把這支 API 文件化」、「給我可對接的 API Spec」、「前後端要對接規格」、「盤點 API」、「這支 API 的完整規格」，應優先觸發此 Skill。
  也適合前後端對接前的規格確認、整合測試素材準備、與 QA 確認 API contract。
---

# API Spec 文件化 Skill

從現有程式碼中萃取 API 對外契約，輸出可直接用於前後端對接、整合測試與 QA 確認的規格文件。

## 核心原則

- **契約優先**：API 文件描述的是對外介面契約，不是內部實作流程
- **數據來源可驗證**：所有欄位、型別、限制，必須來自程式碼或既有規格，不可臆測
- **未知明示**：若找不到對應欄位或設定，明確標註「待確認」，不可省略
- **固定落地**：所有產出文件寫入 `/.doc/api-spec-{scope}.md`，不只在對話中回覆

---

## 觸發情境

| 使用者說的是… | 觸發行為 |
|---|---|
| 幫我整理 `POST /v1/orders` 的規格 | 針對特定 Endpoint 產文件 |
| 這支 API 的 Request/Response 是什麼 | 解析並輸出完整規格 |
| 把這幾支 API 都文件化 | 批次對多個 Endpoint 產文件 |
| 前後端要對接，幫我整理規格 | 產出可對接版格式 |
| 給我可直接用的 API Spec | 輸出含範例的完整文件 |

判斷後直接執行，不需要再詢問確認。若 Endpoint 不明確，請使用者指定。

---

## 分析步驟

### Step 1：定位 API 入口

1. 讀取 Controller/Route 定義，先列出該 Controller 下**所有**具備 HTTP 屬性（`[HttpGet]`/`[HttpPost]`/`[HttpPut]`/`[HttpDelete]`/`[HttpPatch]` 或路由屬性）的 Action Method，並記錄總數 **N**——這是本次文件必須涵蓋的基準數量，任何一支都不可事後遺漏
2. 確認每支 Endpoint 的 HTTP Method 與完整路徑
3. 定位對應 Action Method 與其呼叫的 Service 方法
4. 記錄授權與驗證機制（`[Authorize]`、Model Validation、Middleware）
5. **以 Controller 為單位分組**：同一個 Controller 下的所有 Endpoint 合併在同一份文件
6. **產出前自我核對**：文件內列出的 API 數量是否等於 N，若少於 N，回頭找出缺漏的 Endpoint 補齊，不可在數量不符的情況下視為完成

### Step 2：解析請求契約

1. 抽取 Header 需求（Content-Type、Authorization、自訂 Header）
2. 抽取 Path、Query、Body 參數
3. 以表格標註每個欄位的型別、是否必填、格式限制與驗證規則
4. 若為多階層 JSON，展開為欄位路徑（`parent.child`、`items[].field`）並標示層級

### Step 3：解析回應契約

1. 抽取成功回應格式（2xx）
2. 抽取錯誤回應格式（4xx/5xx）
3. 以表格列出狀態碼與對應觸發條件
4. 若回應為多階層 JSON，展開至葉節點並標示型別

### Step 4：產生範例

1. **每一支 API 都必須各自產出 Request 與 Response JSON 範例，不可只列 Data Schema、省略範例，也不可用「同上」帶過**——即使多支 API 欄位相似，也要各自寫出完整範例
2. 範例須確保可直接被整合測試使用

---

## 輸出模板

使用 `assets/api_spec_template.md` 的格式輸出。若需深入步驟，讀取 `agents/api_spec_analyst.md`。

### 輸出要求

- 文件標題格式：
  - 頂層：`# {ControllerName} API Spec`
  - 每支 API：`## [API Name] - [HTTP Method] /path`
- 必須包含：
  - Request/Response 規格
  - Data Schema
  - JSON Example
- Request/Response/Data Schema 皆須以表格呈現，欄位至少包含「型別」
- JSON 若有多階層，必須展開顯示完整欄位路徑（如 `parent.child`、`items[].field`）與層級
- 欄位命名與型別必須來自程式碼或現有規格，不可憑空推測
- **JSON Example 為每支 API 的必填項目**，Request 與 Response 範例缺一不可；批次產出多支 API 時仍須逐支確認 Example 存在，不可因數量多而省略

### 批次處理

**以 Controller 為單位**，每個 Controller 產出一份獨立文件。同一個 Controller 下的所有 Endpoint 依 HTTP Method 順序（GET → POST → PUT → PATCH → DELETE）排列在同一份文件中。若使用者指定橫跨多個 Controller 的 Endpoint，依所屬 Controller 分別建檔。

若單一 Controller 底下 Endpoint 數量較多（例如 8 支以上），建議：
1. 先列出所有 API 的標題骨架（`## [API Name] - [HTTP Method] /path`），確認數量與 Step 1 記錄的 N 一致
2. 再逐支填入完整內容（Request/Response 規格、Data Schema、Example）

避免一次性產出時，因輸出過長而在後段 API 省略範例或整支遺漏。

---

## 輸出文件位置

完成後將結果儲存至 **`/.doc`** 目錄：

- **一個 Controller 一個檔案**：`/.doc/api-spec-{controller-name}.md`
  - `{controller-name}`：以 Controller 類別名稱命名（英文小寫 + 連字號，去掉 `Controller` 後綴），例如：
    - `OrderController` → `/.doc/api-spec-order.md`
    - `MemberLoginController` → `/.doc/api-spec-member-login.md`
- 若 `/.doc` 目錄不存在，先建立目錄再寫入
- 寫入完成後，回覆使用者每個檔案的儲存路徑

---

## 輸出品質檢核清單

每份輸出在產出前自我確認：

- [ ] Endpoint 路徑與 HTTP Method 已確認（來自程式碼）
- [ ] **文件內 API 數量 = Step 1 記錄的基準數量 N，無任何 Endpoint 遺漏**
- [ ] 授權機制已標註（Anonymous / Bearer / 自訂）
- [ ] Request 所有欄位已展開，含層級、型別、必填
- [ ] Response 成功與失敗格式皆已列出
- [ ] Data Schema 欄位均有規則/限制說明
- [ ] **每支 API 皆同時有 Request Example 與 Response Example，無一支只有 Schema 沒有範例**
- [ ] JSON 範例可直接用於整合測試
- [ ] 文件末尾有產出時間戳記
- [ ] 文件已儲存至 `/.doc/api-spec-{endpoint-name}.md`

---

## 參考資源

- `assets/api_spec_template.md` — API Spec 輸出模板
- `agents/api_spec_analyst.md` — 詳細分析指引
