# {ControllerName} API Spec

> Controller 路徑：`{Controller 檔案路徑或 Route Prefix}`
> 包含 Endpoint 數量：{N} 支

---

## [API Name] - [HTTP Method]

> 簡述此 API 的功能與目的。

---

### 1. 請求與回應 (Request & Response)

**Endpoint:** `{HTTP_METHOD /path}`

#### 2.1 請求資訊

| 區塊 | 名稱 | 型別 | 必填 | 說明 |
|---|---|---|---|---|
| Header | `Content-Type` | String | Yes | `application/json` |
| Header | `Authorization` | String | No | `Bearer <token>` |
| Path | `{id}` | String/Integer | No | 路徑參數 |
| Query | `page` | Integer | No | 分頁頁碼 |

#### 2.2 Request Body 欄位

| 欄位路徑 | 層級 | 型別 | 必填 | 說明 |
|---|---:|---|---|---|
| `memberId` | 1 | String | Yes | 會員識別碼 |
| `items` | 1 | Array\<Object\> | Yes | 訂單商品清單 |
| `items[].sku` | 2 | String | Yes | 商品 SKU |
| `items[].qty` | 2 | Integer | Yes | 購買數量 |
| `shipping.address.city` | 3 | String | No | 配送城市 |

#### 2.3 Response 欄位（Success）

| 狀態碼 | 欄位路徑 | 層級 | 型別 | 必定出現 | 說明 |
|---|---|---:|---|---|---|
| `200` | `statusCode` | 1 | Integer | Yes | 狀態碼 |
| `200` | `message` | 1 | String | Yes | 回傳訊息 |
| `200` | `data` | 1 | Object | Yes | 回傳主體 |
| `200` | `data.orderId` | 2 | String | Yes | 訂單編號 |
| `200` | `data.items` | 2 | Array\<Object\> | No | 商品結果清單 |

#### 2.4 Response 欄位（Error）

| 狀態碼 | 欄位路徑 | 層級 | 型別 | 必定出現 | 說明 |
|---|---|---:|---|---|---|
| `400/401/403/404/500` | `statusCode` | 1 | Integer | Yes | 錯誤狀態碼 |
| `400/401/403/404/500` | `errorCode` | 1 | String | Yes | 系統錯誤代碼 |
| `400/401/403/404/500` | `message` | 1 | String | Yes | 錯誤描述 |
| `400` | `errors[].field` | 2 | String | No | 驗證失敗欄位 |
| `400` | `errors[].reason` | 2 | String | No | 驗證失敗原因 |

---

### 3. 資料格式 (Data Schema)

| 欄位路徑 | 層級 | 型別 | 必填 | 規則/限制 | 說明 |
|---|---:|---|---|---|---|
| `{field}` | `{N}` | `{Type}` | Yes/No | `{長度/枚舉/格式}` | `{欄位說明}` |
| `{parent.child}` | `{N}` | `{Type}` | Yes/No | `{限制}` | `{巢狀欄位說明}` |
| `{items[].field}` | `{N}` | `{Type}` | Yes/No | `{限制}` | `{陣列元素欄位說明}` |

> 規則：JSON 若有多階層，必須完整展開到葉節點，使用 `parent.child` 與 `items[].field` 表示。

---

### 4. 使用範例 (Example)

```json
// Request Example
{
  "{field}": "{value}"
}
```

```json
// Response Example
{
  "statusCode": 200,
  "message": "success",
  "data": {
    "{field}": "{value}"
  }
}
```

---
*產出時間：{YYYY-MM-DD HH:MM} ｜ Controller：{ControllerName}*
