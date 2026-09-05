---
name: common-b2e-tool-http-file-creator
description: 產生可直接執行的 API 測試內容，支援三種格式：`.http` 檔案（REST Client）、Postman Collection JSON、curl 指令。只要使用者提到「測試 API」、「產生 API 範例」、「建立測試檔案」、「API 呼叫方式」等需求，就應使用此 skill，即使未明確指定格式也應主動詢問並產生。
---

# API 測試產生器

## 輸入

- API 資訊：endpoint、HTTP method、headers、request body（必要）
- 輸出格式偏好：`postman`、`http`、`curl`（若未指定則詢問）
- 環境需求：是否需要多環境切換（選填）

## 輸出

依使用者選擇產生下列其中一種格式：

| 選項 | 格式 | 適用場景 |
|------|------|----------|
| `postman` | Postman Collection v2.1 `.json` | 匯入 Postman 使用 |
| `http` | REST Client `.http` 檔案 | VS Code REST Client / JetBrains HTTP Client |
| `curl` | bash curl 指令 | 終端機直接執行 |

> 若使用者未指定格式，先詢問：
> 「請問希望以哪種格式輸出？1. Postman  2. .http 檔案  3. curl」
> 收到回覆後再產生內容。

所有格式均**不產生**程式碼（禁止：C#、JavaScript、TypeScript、fetch、axios、HttpClient）。

---

## 步驟

### Step 1 — 確認格式

若使用者已指定格式，跳到 Step 2。否則詢問後等待回覆。

### Step 2 — 套用對應格式範本

依格式選擇，參考下方各節範本產生完整可執行內容。

---

## 格式 A：Postman Collection

**檔案命名：** `{FeatureName}.postman_collection.json`

Collection 結構使用 `variable` 管理共用參數，每個 request 放入 `item` 陣列。

```json
{
  "info": {
    "name": "FeatureName",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    { "key": "baseUrl",  "value": "http://localhost:5566" },
    { "key": "shopId",   "value": "123" },
    { "key": "userName", "value": "testuser" }
  ],
  "item": [
    {
      "name": "取得資料",
      "request": {
        "method": "GET",
        "header": [
          { "key": "N1-CC-User-Name", "value": "{{userName}}" },
          { "key": "N1-Shop-Id",      "value": "{{shopId}}" }
        ],
        "url": { "raw": "{{baseUrl}}/api/example/123" }
      }
    },
    {
      "name": "建立資料",
      "request": {
        "method": "POST",
        "header": [
          { "key": "Content-Type",    "value": "application/json" },
          { "key": "N1-CC-User-Name", "value": "{{userName}}" },
          { "key": "N1-Shop-Id",      "value": "{{shopId}}" }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"name\": \"example\"\n}",
          "options": { "raw": { "language": "json" } }
        },
        "url": { "raw": "{{baseUrl}}/api/example" }
      }
    }
  ]
}
```

**多環境：** 在 Postman 建立不同 Environment，以相同 `baseUrl` 變數名稱切換。

| Environment | baseUrl |
|-------------|---------|
| Local | `http://localhost:5566` |
| QA    | `https://api-internal.qa.91dev.tw` |
| PP    | `https://api-internal.pp.91dev.tw` |
| Prod  | `https://api-internal.91app.io` |

---

## 格式 B：.http 檔案

**檔案命名：** `{FeatureName}.http`

在檔案頂部宣告共用變數，每個 request 以 `###` 分隔，確保可在 REST Client 直接執行。

```http
# ========================================
# 環境設定（取消註解以切換）
# ========================================
@baseUrl = http://localhost:5566
# @baseUrl = https://api-internal.qa.91dev.tw   # QA
# @baseUrl = https://api-internal.pp.91dev.tw   # PP
# @baseUrl = https://api-internal.91app.io      # Prod
# @baseUrl = https://api-internal.hk.91app.io   # HK-Prod
# @baseUrl = https://api-internal.my.91app.io   # MY-Prod

# ========================================
# 測試參數
# ========================================
@shopId = 123
@userName = testuser
@resourceId = 123


### 取得資料
GET {{baseUrl}}/api/example/{{resourceId}}
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}


### 建立資料
POST {{baseUrl}}/api/example
Content-Type: application/json
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}

{
    "name": "example"
}


### 更新資料
PUT {{baseUrl}}/api/example/{{resourceId}}
Content-Type: application/json
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}

{
    "name": "updated"
}


### 刪除資料
DELETE {{baseUrl}}/api/example/{{resourceId}}
N1-CC-User-Name: {{userName}}
N1-Shop-Id: {{shopId}}
```

---

## 格式 C：curl 指令

在頂部以 shell 變數集中管理參數，方便切換環境。每個 API 操作加上說明注釋。

```bash
# ========================================
# 環境設定（取消註解以切換）
# ========================================
BASE_URL="http://localhost:5566"
# BASE_URL="https://api-internal.qa.91dev.tw"  # QA
# BASE_URL="https://api-internal.pp.91dev.tw"  # PP
# BASE_URL="https://api-internal.91app.io"     # Prod

SHOP_ID="123"
USER_NAME="testuser"
RESOURCE_ID="123"

# 取得資料
curl -X GET "${BASE_URL}/api/example/${RESOURCE_ID}" \
  -H "N1-CC-User-Name: ${USER_NAME}" \
  -H "N1-Shop-Id: ${SHOP_ID}"

# 建立資料
curl -X POST "${BASE_URL}/api/example" \
  -H "Content-Type: application/json" \
  -H "N1-CC-User-Name: ${USER_NAME}" \
  -H "N1-Shop-Id: ${SHOP_ID}" \
  -d '{"name": "example"}'

# 更新資料
curl -X PUT "${BASE_URL}/api/example/${RESOURCE_ID}" \
  -H "Content-Type: application/json" \
  -H "N1-CC-User-Name: ${USER_NAME}" \
  -H "N1-Shop-Id: ${SHOP_ID}" \
  -d '{"name": "updated"}'

# 刪除資料
curl -X DELETE "${BASE_URL}/api/example/${RESOURCE_ID}" \
  -H "N1-CC-User-Name: ${USER_NAME}" \
  -H "N1-Shop-Id: ${SHOP_ID}"
```

---

## 最佳實務

- 每個 API 視適用性產生 GET / POST / PUT / DELETE
- 變數集中宣告（頂部），避免 hardcode 散落在各 request
- 多環境切換以「取消註解」方式呈現，預設使用 Local
