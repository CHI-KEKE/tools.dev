---
name: api-test
description: 此 Skill 用於確保當 AI 需要測試 API 時，必須使用 REST Client，格式，並產生 `.http` 檔案，而不是使用 curl、Postman 或程式碼。
---

# API 測試 Skill
此格式適用於：

-   VS Code REST Client Extension
-   JetBrains HTTP Client

------------------------------------------------------------------------

## 使用時機

當使用者有以下需求時，必須使用此 Skill：

-   測試 API
-   提供 API 範例
-   驗證 API 功能
-   建立 API 測試檔案
-   示範 API 呼叫方式

------------------------------------------------------------------------

## 事前確認清單（產生 .http 前必問）

在產生任何 `.http` 檔案之前，AI **必須先確認**以下項目。若使用者已在對話中提供，則直接套用，不需重複詢問。

### 0. 自動偵測 API Domain（優先執行）

在產生 `.http` 檔案前，**必須先掃描**專案中的 `charts/*/values-*.yaml` 檔案，從 `api.ingress.hosts[*].host` 欄位提取各環境的 domain。

**掃描規則：**

1. 搜尋路徑：`charts/**/*.yaml`（含子目錄下所有 values YAML）
2. 讀取每個 YAML 中的 `api.ingress.hosts` 陣列，取第一個 `host` 值作為該環境的 domain
3. 依檔名關鍵字對應環境（優先用 `env` 欄位，其次用 `market` 欄位輔助判斷）：

| 檔名關鍵字 | `market` | `env` | 對應環境標籤 |
|-----------|----------|-------|------------|
| `values-tw-qa.yaml` | TW | QA | TW-QA |
| `values-tw-pp.yaml` | TW | PP | TW-PP |
| `values-tw-prod.yaml` | TW | Prod | TW-Prod |
| `values-hk-qa*.yaml` | HK | QA | HK-QA |
| `values-hk-prod.yaml` | HK | Prod | HK-Prod |
| `values-my-qa*.yaml` | MY | QA | MY-QA |
| `values-my-prod.yaml` | MY | Prod | MY-Prod |

4. 若 YAML 內有 `api.servicePort`，本地環境使用該 port（預設 5566）

**偵測結果套用至多環境範本：**

將偵測到的 host 加上 `https://` scheme，填入多環境範本的對應註解行，格式如下：

```http
# @baseUrl = https://<host>      # <環境標籤>
```

**若找不到任何 values YAML 或 host 欄位，則回退至預設多環境範本（手動填入）。**

---

### 1. 驗證方式（Authentication）

**依據目前所在專案自動套用對應的驗證範本，不需詢問使用者**：

#### 專案驗證對照表

| 專案 pattern | 驗證方式 | 必要變數 | Header 範本 |
|-------------|----------|---------|-------------|
| `nineyi.webstore.mobilewebmall` | Cookie（雙 token） | `@auth`、`@uauth` | `Cookie: auth={{auth}}; auth_samesite={{auth}}; uauth={{uauth}}; uauth_samesite={{uauth}}` |
| `nineyi.sms` | Cookie（單 token） | `@sid` | `Cookie: sid={{sid}}` |
| `nine1.*`（如 nine1.coupon、nine1.member…） | 自訂 Header | `@shopId`、`@userName` | `N1-ShopId-Id: {{shopId}}`<br>`N1-CC-User-Name: {{userName}}` |
| 其他專案 | 未知，**必須詢問使用者** | — | 請使用者提供驗證方式與 Header 格式 |

> **偵測方式**：掃描工作區根目錄名稱或 `.sln` / `.csproj` 檔名，比對上表 pattern。  
> 若無法確認，則視為「其他專案」並詢問使用者。

---

#### nineyi.webstore.mobilewebmall 變數範本

```http
# ========================================
# 驗證設定（nineyi.webstore.mobilewebmall）
# ========================================
@auth  = REPLACE_WITH_AUTH_COOKIE_VALUE
@uauth = REPLACE_WITH_UAUTH_COOKIE_VALUE
```

每個 Request：

```http
Cookie: auth={{auth}}; auth_samesite={{auth}}; uauth={{uauth}}; uauth_samesite={{uauth}}
```

> **注意**：`@auth` / `@uauth` 定義時**不可加外層引號**，否則 Cookie header 會展開成雙重引號導致驗證失敗。

---

#### nineyi.sms 變數範本

```http
# ========================================
# 驗證設定（nineyi.sms）
# ========================================
@sid = REPLACE_WITH_SESSION_ID
```

每個 Request：

```http
Cookie: sid={{sid}}
```

---

#### nine1.* 變數範本

```http
# ========================================
# 驗證設定（nine1.*）
# ========================================
@shopId   = 12842
@userName = REPLACE_WITH_USERNAME
```

每個 Request：

```http
N1-ShopId-Id: {{shopId}}
N1-CC-User-Name: {{userName}}
```

---

#### 通用驗證備選（其他專案或明確指定時）

| 驗證類型 | 對應 Header / 範本 |
|----------|-------------------|
| Bearer Token | `Authorization: Bearer {{token}}` → 使用 `@token = xxx` 變數 |
| API Key | `X-Api-Key: {{apiKey}}` → 使用 `@apiKey = xxx` 變數 |
| 無驗證 | 不加任何 Header |

**若使用者提供 Token**，必須：
1. 在變數區塊宣告 `@token = xxx`
2. 每個 Request 加上 `Authorization: Bearer {{token}}`

### 2. 自訂 Headers

詢問是否有需要額外帶入的自訂 Header，例如：

- `X-Request-Id`
- 其他業務專用 Header

所有自訂 Header 值均須提取為頂端變數，不可寫死在每個 Request 內。

### 3. 確認範本

依偵測到的專案類型套用上方對應變數範本；若為其他專案，詢問使用者後再補充。

------------------------------------------------------------------------

## 輸出規則

AI 必須遵守：

1.  必須產生 `.http` 格式
2.  使用 REST Client 語法
3.  使用變數（包含驗證 Header 值）
4.  每個 Request 使用 `###` 分隔
5.  必須可直接在 REST Client 執行
6.  所有 Header 值（驗證、Shop-Id、User-Name 等）必須提取為頂端變數

------------------------------------------------------------------------

## 檔案命名規則

使用：

FeatureName.http

範例：

Coupon.http

User.http

Order.http

------------------------------------------------------------------------

## 標準範本

### 基本範本

``` http
@baseUrl = https://localhost:5566
@shopId = 123
@userName = testuser


### 取得資料
GET {{baseUrl}}/api/example
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}


###

### 建立資料
POST {{baseUrl}}/api/example
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}

{
    "name": "example"
}
```

### 多環境支援範本

當需要支援多環境測試時，**優先使用從 `charts/*/values-*.yaml` 自動偵測的 host**，產生以下格式：

``` http
# ========================================
# 環境設定
# ========================================
# 本地開發環境（預設）
@baseUrl = http://localhost:5566

# 切換至其他環境（取消註解以使用）：
# 以下 domain 從 charts/*/values-*.yaml 的 api.ingress.hosts[*].host 自動偵測
# @baseUrl = https://coupon-api-backend-internal.qa.91dev.tw      # TW-QA
# @baseUrl = https://coupon-api-backend-internal.pp.91dev.tw      # TW-PP
# @baseUrl = https://coupon-api-backend-internal.91app.io         # TW-Prod
# @baseUrl = https://coupon-api-backend-internal.qa1.hk.91dev.tw  # HK-QA
# @baseUrl = https://coupon-api-backend-internal.hk.91app.io      # HK-Prod
# @baseUrl = https://coupon-api-backend-internal.qa1.my.91dev.tw  # MY-QA
# @baseUrl = https://coupon-api-backend-internal.my.91app.io      # MY-Prod

# ========================================
# 測試參數
# ========================================
@shopId = 12842
@userName = testuser
@resourceId = 123


### 取得資料
GET {{baseUrl}}/api/example/{{resourceId}}
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}
```

**多環境支援要點：**
- 預設使用本地開發環境
- **domain 優先從 `charts/*/values-*.yaml` → `api.ingress.hosts[*].host` 自動偵測**，不可憑空猜測
- 偵測後加上 `https://` scheme 組成完整 `@baseUrl`
- 使用完整 URL 而非變數引用
- 在註解中標註環境名稱（TW-QA / HK-Prod 等）
- 提供清晰的分隔線和區塊說明
- 測試參數獨立區塊設定

------------------------------------------------------------------------

## 強制規定

允許輸出：

-   .http

禁止輸出：

-   curl
-   Postman
-   C#
-   JavaScript
-   fetch
-   axios

------------------------------------------------------------------------

## 最佳實務

每個 API 至少包含：

-   GET
-   POST
-   PUT（如適用）
-   DELETE（如適用）

------------------------------------------------------------------------

## 總結

當使用者要求測試 API：

AI 必須產生 REST Client `.http` 檔案。
