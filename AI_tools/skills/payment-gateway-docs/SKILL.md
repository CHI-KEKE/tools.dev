---
name: payment-gateway-docs
description: Know-how for analyzing and documenting 91APP payment gateway plugins (PaymentMiddleware). Use this when the user asks to analyze a payment plugin, document a new payment flow, organize/split existing payment docs, or maintain the knowledge base under the Paytypes directory.
---

# Skill: Payment Gateway Documentation

**知識庫根目錄：** `C:\Users\Allen Lin\Desktop\joy_2\joy_\Payment\Paytypes`  
**程式碼根目錄：** `C:\91APP\Payment\nineyi.payment.middleware`

---

## 一、整理方法論

### 兩種整理模式

| 模式 | 觸發時機 | 資料來源 | 產出位置 |
|------|----------|----------|----------|
| **A. 從程式碼分析** | 新金流 / 需要程式碼層級說明 | `.cs` 為主，`.md` 輔助 | `paymentmiddleware/` 子資料夾 |
| **B. 既有文件整理** | 既有 `.md` 過長、分類混亂 | 既有 `.md` | 金流根目錄，主題拆分 |

兩種模式可並存，不互斥。

---

### 模式 A：從程式碼分析（標準 SOP）

#### 資料來源優先順序

| 來源 | 優先 | 說明 |
|------|------|------|
| Plugin 程式碼（`.cs`） | ✅ 最優先 | 最精確，包含實際邏輯、dead field、設計意圖 |
| 既有 `.md` 文件 | 輔助 | 業務背景補充，但可能過時或不完整 |

#### 分析流程

```
Step 1：找到 Plugin 進入點
  └→ src/Plugins/NineYi.PaymentMiddleware.Plugins.{PaymentName}/{PaymentName}Plugin.cs

Step 2：依功能逐一讀取
  └→ Pay → QueryPayment → Refund → RefundQuery → Cancel

Step 3：追蹤每個函式的 API 呼叫鏈
  └→ Plugin.cs → HttpClient Interface → HttpClient Implementation
  └→ 找出：API URL、HTTP Method、Request Body 欄位、Response 解析邏輯

Step 4：識別設計特殊點
  └→ 條件分支（if/switch）→ 不同路徑
  └→ Dead field（定義了但從未讀取的欄位）
  └→ 例外處理設計（是否 re-throw、是否 catch 再解析 body）

Step 5：整理並撰寫 markdown
```

---

### 模式 B：既有文件整理（拆分 SOP）

適用情境：既有 `.md` 包含多個主題，篇幅過長、不好維護。

#### 拆分流程

```
Step 1：通讀原始 md，列出所有段落與主題
Step 2：依主題分群（環境設定 / 付款 / 退款 / 錯誤 / 測試 / 異常紀錄）
Step 3：建立各主題 md，內容完整搬移（不刪減）
Step 4：原始 md 改為索引，用表格列出子文件連結
Step 5：異常紀錄獨立拆到 異常紀錄/ 資料夾（一案一 md）
```

#### 主題分群參考

| 主題 | 檔案名稱 |
|------|----------|
| 環境設定、API 端點、後台帳號 | `Environment.md` |
| 測試卡 / 測試帳號 | `TestCards.md` |
| 付款規格、技術架構 | `Payment.md` |
| 付款錯誤情境 | `PaymentErrors.md` |
| 退款規則、狀態對應 | `Refund.md` |
| 退款異常（業務紀錄） | `RefundIssues.md` 或拆入 `異常紀錄/` |

---

## 二、目錄結構規範

### 知識庫目錄結構

```
Paytypes/
├── {金流名稱}/
│   ├── {金流名稱}.md             ← 索引（含說明 + 子文件連結表）
│   ├── Environment.md            ← 環境設定、API 端點、後台帳號
│   ├── TestCards.md              ← 測試卡 / 測試帳號
│   ├── Payment.md                ← 付款規格、技術架構
│   ├── PaymentErrors.md          ← 付款錯誤情境
│   ├── Refund.md                 ← 退款規則、狀態對應
│   ├── paymentmiddleware/        ← 程式碼分析文件（模式 A 產出）
│   │   ├── Pay/
│   │   │   ├── 01-架構總覽.md
│   │   │   ├── 02-付款情境分析.md
│   │   │   └── ...
│   │   ├── Query/
│   │   ├── Refund/
│   │   ├── RefundQuery/（若有實作）
│   │   └── Cancel/
│   └── 異常紀錄/                 ← 一案一 markdown
│       ├── 01-案例名稱.md
│       └── ...
```

### 命名規則

| 層級 | 規則 | 原則 |
|------|------|------|
| 金流根目錄文件 | 英文主題名（無前綴、無編號） | 已在金流子資料夾內，不需重複前綴 |
| 索引文件 | `{金流名稱}.md` | 與資料夾同名 |
| paymentmiddleware 子資料夾 | 功能名稱（PascalCase） | `Pay/`、`Refund/` |
| paymentmiddleware 文件 | `NN-描述.md`（兩位數編號） | `01-概覽與API序列.md` |
| 異常紀錄 | `NN-案例摘要.md`（兩位數編號） | `03-付款查詢401權限異常.md` |

---

## 三、各功能文件撰寫要點

### Pay 文件必包含
- 完整 API 呼叫序列（帶 HTTP Method + URL）
- 付款路徑的條件分支（如不同 PaymentFlow）
- Request ExtendInfo 欄位說明（欄位名稱、來源、用途）
- Response ReturnCode 對照表
- 特殊設計說明（如：為何不直接呼叫 API、表單導向設計等）

### Query 文件必包含
- 查詢路徑數量（單路徑 or 多路徑判斷條件）
- 狀態判斷邏輯（if/switch 完整對應）
- WaitingToPay 的設計意圖（查詢失敗 ≠ 付款失敗）
- Dead field 標示
- 至少 3 個具體情境

### Refund 文件必包含
- 是否需要多個 API 呼叫（依 PaymentFlow 列出）
- 條件執行步驟（如 ApplicationFee、Transfer Reversal）
- HTTP 錯誤處理方式（是否吞例外）
- ReturnCode 對照

### RefundQuery 文件（若實作）
- 狀態對應表（PENDING / 最終成功狀態）
- 輪詢機制說明

---

## 四、各金流已完成的文件

### QFPay
**路徑：** `Paytypes/QFPay/`
**整理模式：** B（既有文件整理）

| 文件 | 內容 |
|------|------|
| `QFPay.md` | 索引，含說明與子文件連結 |
| `Environment.md` | 參考連結、商戶後台、API 環境網址 |
| `TestCards.md` | 測試卡列表、特殊行為說明 |
| `Payment.md` | 技術架構、平台整合規格、UI 行為、金額限制、Pay Page URL 範例 |
| `PaymentErrors.md` | 常見付款異常、WeChat Pay 問題、QFSign_Error、並行交易處理 |
| `Refund.md` | 退款規則、Refund Mapping、RefundQuery Mapping、關帳期限 |
| `RefundIssues.md` | 3 個退款異常事件紀錄 |

**QFPay 特殊知識：**
- 使用 Hosted Payment Pages，需自行組裝跳轉 URL 並以 API Key 做 SHA256 簽名
- QA 測試環境分兩套：信用卡用 Sandbox、第三方支付用 Live Testing Environment
- `syssn` 對應 TransactionId
- Visa/Mastercard 當日退款須全額；隔日才可部分退款
- FPS 關帳期限只有 29 天（其餘多為 365 天）
- 尚未進行程式碼層級分析（`paymentmiddleware/` 尚未建立）

---

### Razer
**路徑：** `Paytypes/Razer/`
**整理模式：** B（既有文件整理）

| 文件 | 內容 |
|------|------|
| `Razer.md` | 索引，含支援付款方式總表 |
| `Environment.md` | 商戶帳號（vinoair / elemis01）、PMW API 端點 |
| `Payment.md` | 前台串接路徑、txn_channel 對應、API Response 範例、支援卡別 |
| `PaymentErrors.md` | 失敗文案（CreditCardOnce_Razer）、最低金額問題 |
| `Refund.md` | 退款狀態、ErrorCode Retry 機制、支援付款方式範圍 |
| `PayNow.md` | PayNow QR Code 說明、查詢 SQL、QueryPayment API + Response |
| `Fiuu.md` | Fiuu 新品牌、Sandbox/Prod 端點差異、IsFiuuEnable Feature Toggle SQL |
| `Installment/` | 分期付款系統設計（DB schema、購物車流程、每期金額計算） |
| `異常紀錄/01-後台自動退款.md` | Razer 後台付款後約一小時自動退款，影響取消/退貨/門市逾期未取退款流程 |

**Razer 特殊知識：**
- Razer 新品牌為 **Fiuu**，API Domain 已改為 `api.fiuu.com` / `sandbox-api.fiuu.com`
- `txn_channel` 由程式碼 hardcode（`CREDIT` / `CREDITBA` / `GRABPAY` 等），非動態帶入
- Razer **不走匯款**，採連路退（原路退回）
- 退款 ErrorCode：`PR015`、`PR020` 自動 Retry；其餘跳 Slack 通知 RD 介入
- 信用卡一次付清支援 Visa / MasterCard，**不支援 JCB / AMEX**
- 最低金額與支援卡別目前為 hardcode，版本更新需注意
- 尚未進行程式碼層級分析（`paymentmiddleware/` 尚未建立）

---

### Stripe
**路徑：** `Paytypes/stripe/`

| 資料夾/文件 | 內容 |
|------------|------|
| `paymentmiddleware/Pay/` | 架構總覽、付款情境（三路徑）、3D 驗證觸發條件、ReturnCode 對照、QueryPayment 分析 |
| `paymentmiddleware/Query/` | 雙模式 QueryPayment 概覽 + 8 個情境 |
| `paymentmiddleware/Refund/` | 概覽與 API 序列、DirectCharge 退款、DestinationCharge 退款、ApplicationFee 退款 |
| `paymentmiddleware/Cancel/` | Cancel 流程 |
| `06-帳戶類型與金鑰管理.md` | DirectCharge / DestinationCharge 差異 |
| `07-退款與ApplicationFee機制.md` | 退款業務規則 |
| `08-系統使用費與金流手續費.md` | 費用結構 |
| `09-信用卡付款與記住信用卡.md` | 信用卡付款、舊卡復用 |
| `10-3D驗證失敗處理.md` | 3D 失敗情境處理 |
| `11-Stripe後台操作.md` | 後台操作說明 |
| `12-OAuth整合.md` | OAuth 流程 |
| `異常紀錄/` | 4 個異常案例（各自獨立 markdown） |

**Stripe 特殊知識：**
- Pay 三路徑：單純 Pay / 記住信用卡（RememberPaymentMethodProcess）/ 舊卡復用（ReusePaymentMethodPaymentIntentProcess）
- 兩種 PaymentFlow：DirectCharge（子帳號）/ DestinationCharge（主帳號 + Transfer）
- Stripe **無 RefundQuery**（退款呼叫後直接得到最終結果）
- Dead fields：`three_d_secure_status_def`（Pay）、`query_string`（Query）
- 金額單位：原始金額 × 100（最小貨幣單位）

---

### Cybersource
**路徑：** `Paytypes/Cybersource/`

| 資料夾/文件 | 內容 |
|------------|------|
| `paymentmiddleware/Pay.md` | Secure Acceptance 表單流程、HMAC-SHA256 簽名 |
| `paymentmiddleware/Query.md` | 雙路徑（Form-Data / Create Search API）、ics_bill 判斷邏輯 |
| `paymentmiddleware/Refund.md` | REST API 退款、HTTP 錯誤不拋例外設計 |
| `paymentmiddleware/RefundQuery.md` | TRANSMITTED 才算成功、輪詢循環說明 |
| `01-概覽與整合架構.md` | 整合架構、文件聯絡資訊 |
| `02-環境配置.md` | API 端點設定 |
| `03-付款結果判斷.md` | 狀態邏輯 + 完整 JSON 範例 |
| `04-退款與查詢狀態判斷.md` | 退款 / 退款查詢狀態對應 |
| `異常紀錄/` | 6 個異常案例 |

**Cybersource 特殊知識：**
- Pay **完全不呼叫 API**，純表單導向（Secure Acceptance）
- QueryPayment 雙路徑：Form-Data 驗簽（無延遲）/ Create Search API（有同步延遲）
- Search API 成功判定：必須找到 `ics_bill` application 且 `reasonCode=100`
- Search API 失敗判定：只認 `rFlag=ESYSTEM`，其他失敗一律 WaitingToPay（允許 Cybersource 頁面重試）
- Refund 的 HTTP 錯誤不拋例外（`FlurlHttpException` catch 後解析 body）
- RefundQuery 的 `TRANSMITTED` 才算成功（`PENDING` 只是受理）
- 認證方式兩種：Secure Acceptance（HMAC-SHA256）/ REST API（HTTP Signature）

---

## 五、程式碼位置速查

### Plugin 目錄結構

```
src/Plugins/NineYi.PaymentMiddleware.Plugins.{Name}/
├── {Name}Plugin.cs           ← 核心邏輯（Pay/Query/Refund/Cancel）
├── {Name}Module.cs           ← DI 註冊
├── HttpClients/
│   ├── I{Name}HttpClient.cs  ← API 端點定義
│   └── {Name}HttpClient.cs   ← API 實作
├── Entities/                 ← API Request/Response model
├── ExtentionInfo/            ← PMW Request/Response ExtendInfo
├── Helpers/                  ← 工具類別（簽名、轉換）
├── Services/                 ← 複雜流程拆出的 Service（如 Stripe 的 Strategy）
└── Constants/
```

### 各金流 Plugin 路徑

| 金流 | Plugin 路徑 |
|------|------------|
| Stripe | `src/Plugins/NineYi.PaymentMiddleware.Plugins.Stripe/` |
| Cybersource | `src/Plugins/NineYi.PaymentMiddleware.Plugins.Cybersource/` |

---

## 六、文件撰寫格式規範

### markdown 必要元素

1. **H1 標題**：`# {金流名稱} — {主題}`
2. **概覽段落 or 流程圖**：用 ASCII 示意圖描述資料流
3. **條件分支**：用表格或 code block 呈現 if/switch 邏輯
4. **ReturnCode 對照表**：所有回傳碼一覽
5. **情境分析**：至少 3 個具體情境，每個有 request 假設 → 執行步驟 → 結果

### API 呼叫格式

````
```
HTTP_METHOD /path/to/endpoint
Header: value

{
  "field": "value"
}
```
````

### 情境格式

```
### 情境 N：標題
前提條件（request 欄位設定）
→ 執行步驟 1
→ 執行步驟 2
→ ReturnCode：XXX（說明）
```

---

## 七、新金流分析 SOP（模式 A）

1. **列出所有 `.cs` 檔案**
   ```
   glob: src/Plugins/NineYi.PaymentMiddleware.Plugins.{Name}/**/*.cs
   ```

2. **優先讀取**（依序）
   - `{Name}Plugin.cs` — 全部方法
   - `I{Name}HttpClient.cs` — 所有 API 端點定義
   - `{Name}HttpClient.cs` — API 實作邏輯
   - `ExtentionInfo/*.cs` — 所有 ExtendInfo 欄位
   - `Entities/*.cs` — Response 解析與 ReturnCode 映射

3. **建立資料夾**
   ```
   Paytypes/{GatewayName}/paymentmiddleware/{Pay,Query,Refund,...}/
   ```

4. **依資訊量決定是否拆文件**
   - 有多個條件路徑（如不同 PaymentFlow）→ 各一個 md
   - 有多個 API 呼叫步驟 → 各一個 md
   - 單純流程 → 單一 md

5. **標記 Dead Field**
   - 定義在 ExtendInfo 但從未被讀取的欄位
   - 在文件中明確標示 `⚠️ Dead field`

---

## 八、既有文件整理 SOP（模式 B）

1. **通讀原始 md**，列出所有段落標題與主題

2. **依主題分群**，對照分群參考表（見一、模式 B）

3. **建立子文件**，將內容完整搬移（不刪減、不改寫）

4. **將原始 md 改為索引**
   - H1 保留金流名稱與一行說明
   - 加入索引表，格式：
     ```markdown
     | 主題 | 檔案 |
     |------|------|
     | 環境設定 | [Environment.md](./Environment.md) |
     ```

5. **判斷異常紀錄是否獨立**
   - 3 個案例以下：可留在 `RefundIssues.md` 或 `PaymentErrors.md`
   - 3 個案例以上：建立 `異常紀錄/` 資料夾，一案一 md（`NN-案例摘要.md`）
