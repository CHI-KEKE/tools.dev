---
name: common-api-spec-creator
description: >
  將程式碼中的 API 實作轉為可對接、可驗證的規格文件（API Spec）。
  產出內容包含：Request/Response 欄位規格、Data Schema、代表性 JSON 範例。
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

1. 讀取 Controller/Route 定義，確認 Controller 名稱、HTTP Method 與完整 Endpoint 路徑
2. 定位對應 Action Method 與其呼叫的 Service 方法
3. 記錄授權與驗證機制（`[Authorize]`、Model Validation、Middleware）
4. **以 Controller 為單位分組**：同一個 Controller 下的所有 Endpoint 合併在同一份文件

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

1. 產出代表性 Request/Response JSON 範例，確保可直接被整合測試使用

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

### 批次處理

**以 Controller 為單位**，每個 Controller 產出一份獨立文件。同一個 Controller 下的所有 Endpoint 依 HTTP Method 順序（GET → POST → PUT → PATCH → DELETE）排列在同一份文件中。若使用者指定橫跨多個 Controller 的 Endpoint，依所屬 Controller 分別建檔。

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
- [ ] 授權機制已標註（Anonymous / Bearer / 自訂）
- [ ] Request 所有欄位已展開，含層級、型別、必填
- [ ] Response 成功與失敗格式皆已列出
- [ ] Data Schema 欄位均有規則/限制說明
- [ ] JSON 範例可直接用於整合測試
- [ ] 文件末尾有產出時間戳記
- [ ] 文件已儲存至 `/.doc/api-spec-{endpoint-name}.md`

---

## 參考資源

- `assets/api_spec_template.md` — API Spec 輸出模板
- `agents/api_spec_analyst.md` — 詳細分析指引
