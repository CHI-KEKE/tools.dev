---
name: common-api-spec-frontend-doc
description: >
  Generate a frontend-consumable API specification document (pure Markdown) directly in the chat
  window — no files saved — from a SINGLE C# controller action method. ALWAYS use this skill
  when the user wants to immediately hand off a spec to a frontend engineer in the current
  conversation: "給前端的規格", "給我規格", "幫我開這支 API 的文件", "前端規格",
  "開規格文件", "貼給前端", "前端怎麼串", "API 說明", or highlights a single method
  name (e.g. #sym:MethodName) and asks for any form of API spec or integration doc.
  Trigger for ONE endpoint at a time; output stays in chat only (never writes files).
  Do NOT trigger for batch / multi-endpoint requests, QA test material generation,
  integration test scaffolding, or any request that explicitly asks to save a file —
  those belong to the common-api-spec-creator skill.
---

# Common API Spec Frontend Doc Skill

---

## Step 1 — Identify the target action

Determine the controller action to document. Priority order:

1. Active editor selection / highlighted symbol in the current file.
2. A method name mentioned explicitly in the user's message.
3. If still ambiguous, ask the user to confirm before proceeding.

---

## Step 2 — Collect all necessary context (read files in parallel)

| File | Purpose |
|---|---|
| Controller file | HTTP verb, route template, authorization attribute (e.g. `[PortalAuthorize]`, `[Authorize]`) and its value, any values read from the auth / session context (e.g. tenant ID, current user) that are injected server-side rather than sent by the client, and which service method is called |
| Service interface (`I*Service.cs`) | Method signature — parameter names and types |
| Service implementation (`*Service.cs`) | Business logic branches, which request fields are actually used, early-exit / guard conditions; trace every `throw` / exception path to find distinct business error conditions (e.g. `DuplicateData`, `NotFound`, `InvalidStatus`) — do NOT go deeper into Repository for this |
| Request entity (`*RequestEntity.cs`) | All fields, their C# types, any `[Required]` / FluentValidation rules |
| Response entity (`*ResponseEntity.cs`, `*Entity.cs`) | All fields returned to the caller |
| Enum files referenced in entities or service | Exact string member names for every relevant enum |
| Repository interface (`I*Repository.cs`) | Filter precedence rules, paired-field constraints |

Use `file_search` or `grep_search` to locate files that cannot be found directly by path.
**Do NOT guess field names, types, or logic — always read the source first.**

---

## Step 3 — Analyse the logic

Reason through each point before writing anything:

- **Route**: class-level `[Route]` prefix + method-level `[Route]` template + HTTP verb.
- **Session-derived values**: Values read from the auth / session context (e.g. tenant ID, current user ID, operator) are injected server-side and **must NOT appear in the request body section** of the document. Identify these by inspecting how the controller populates them — common patterns include a dedicated identity/session service, `HttpContext.User`, or a custom base controller property.
- **Nullable vs required**: Derive from C# type nullability (`?`) and any validator / guard code.
- **Default values**: What does the service or repository use when a nullable field is `null` or an int is `0`?
- **Enum values**: Enumerate every valid string a frontend engineer can send or expect to receive.
- **Error HTTP status codes**: Identify every 4xx/5xx status code the controller or service may return and the exact condition that triggers each one (e.g., validation failure → 400, missing resource → 404, insufficient permission → 403).
- **Pagination defaults**: Note what the service uses for `pageIndex` (default `1`) and `pageSize` (default `100`); document how to compute total pages (`totalCount ÷ pageSize`) in 注意事項.
- **Nullable response fields**: Flag any response field that can return `null` — the frontend needs null-guard handling for these; mark them with `?` in the type column and add a note in 注意事項.
- **Business error enumeration**: From the service implementation, list every distinct `throw` / error path as a separate row in the 錯誤回應 table with its exact trigger condition. Group duplicates by HTTP status, but split distinct business reasons into separate rows (e.g. two different 400 causes = two rows). Stop at the service layer — do not trace into repositories.
- **Field dependency & mutual exclusion**: Identify conditional rules between fields (e.g. "field Y is required when field X contains value Z", "fields A and B are mutually exclusive"). Describe these explicitly in the Request 欄位說明 table's 說明 column AND summarise them as numbered items in 注意事項 so the frontend can implement client-side guard logic.

---

## Step 4 — Choose the document variant

| Variant | Condition |
|---|---|
| **A — Standard** | POST / PUT with a request body, or GET with route params; response is a JSON DTO |
| **B — No-param GET** | GET with absolutely no route params and no body |
| **C — File Download** | Any verb where the return type is `FileStreamResult` or streams a file |

---

## Step 5 — Write the document

> ⚠️ **CRITICAL — NON-NEGOTIABLE OUTPUT RULES:**
> 1. You **MUST** wrap the entire document in a ` ````md ` fenced code block (4 backticks) so the chat UI shows it as raw text, not rendered Markdown. **Never output the document as plain Markdown prose.** Using only 3 backticks will cause inner ` ```json ` blocks to prematurely close the outer fence, breaking the layout.
> 2. You **MUST NOT** embed any Markdown hyperlinks (e.g. `[text](path)`) anywhere inside the document — no file links, no cross-references. Field names in table cells must appear as plain inline code (`` `fieldName` ``) only.
> 3. Do **NOT** output any prose or preamble before the ` ````md ` block. Begin the ` ````md ` fence immediately.

Use the matching variant template below. Output language is **Traditional Chinese** (field names and code values excepted).

> **Variant A — Request section rule**: For POST / PUT, include the full JSON example + field table. For GET with route params only, omit the JSON example and keep only the field table.

---

### Variant A — Standard (POST / PUT / GET with route params)

`````
````md
## API 規格文件：{操作中文名稱} ({ActionMethodName})

### 基本資訊

| 項目 | 說明 |
|---|---|
| **路徑** | `{HTTP_VERB} /api/{Controller}/{Action}{/routeParam}` |
| **權限** | `{授權需求}` |
| **Content-Type** | `application/json` |

---

### Request

```json
{
  "field1": "exampleValue",
  "nullableField": null,
  "pageIndex": 1
}
```

#### Request 欄位說明

Route 參數與 Body 欄位統一列在同一張表；路徑參數在「說明」欄標注「路徑參數」。
前端應永遠帶入所有欄位，非必填欄位以預設值填充，不應省略欄位 key。

| 欄位名稱 | 型別 | 必填 | 預設值 | 說明 |
|---|---|---|---|---|
| `routeParam` | `long` | 是 | — | 路徑參數。{說明} |
| `bodyField` | `string` | 否 | `null` | 說明；Enum 欄位請列舉所有合法值，例：`"Active"` / `"Inactive"` |
| `pageIndex` | `int` | 否 | `1` | 頁碼，從 1 開始 |
| `pageSize` | `int` | 否 | `100` | 每頁筆數 |

---

### Response

```json
{
  "items": [
    {
      "id": 1,
      "name": "範例",
      "nullableField": null
    }
  ],
  "totalCount": 1,
  "pageIndex": 1,
  "pageSize": 100
}
```

#### Response 欄位說明

視結構分「外層」與「items[] 內每筆」子區塊。

**外層**

| 欄位名稱 | 型別 | 說明 |
|---|---|---|
| `items` | `array` | 資料列表 |
| `totalCount` | `int` | 符合條件的總筆數（不分頁） |
| `pageIndex` | `int` | 目前頁碼 |
| `pageSize` | `int` | 每頁筆數 |

**`items[]` 內每筆**

| 欄位名稱 | 型別 | 說明 |
|---|---|---|
| `id` | `long` | 序號 |
| `nullableField` | `string?` | 說明；可為 `null`，前端需做防呆 |

---

### 注意事項與阻擋邏輯

1. **{標題}**：{說明}
2. ...

---

### 錯誤回應

| HTTP 狀態碼 | 觸發條件 |
|---|---|
| `400 Bad Request` | {說明，例：必填欄位未提供、參數格式錯誤} |
| `403 Forbidden` | 權限不足，使用者未具備所需授權 |
| `404 Not Found` | {說明，例：指定資源不存在} |
| `500 Internal Server Error` | 伺服器內部錯誤 |

---

*文件產出時間：{YYYY-MM-DD}*
````
`````

---

### Variant B — No-param GET

`````
````md
## API 規格文件：{操作中文名稱} ({ActionMethodName})

### 基本資訊

| 項目 | 說明 |
|---|---|
| **路徑** | `GET /api/{Controller}/{Action}` |
| **權限** | `{授權需求}` |

---

### Request

無

---

### Response

```json
{
  "items": [
    {
      "value": "example",
      "label": "顯示名稱"
    }
  ]
}
```

#### Response 欄位說明

| 欄位名稱 | 型別 | 說明 |
|---|---|---|
| `items` | `array` | 選項清單 |
| `items[].value` | `string` | 選項值 |
| `items[].label` | `string` | 顯示名稱 |

---

### 注意事項與阻擋邏輯

1. **{標題}**：{說明}

---

### 錯誤回應

| HTTP 狀態碼 | 觸發條件 |
|---|---|
| `400 Bad Request` | {說明} |
| `403 Forbidden` | 權限不足，使用者未具備所需授權 |
| `404 Not Found` | {說明} |
| `500 Internal Server Error` | 伺服器內部錯誤 |

---

*文件產出時間：{YYYY-MM-DD}*
````
`````

---

### Variant C — File Download

`````
````md
## API 規格文件：{操作中文名稱} ({ActionMethodName})

### 基本資訊

| 項目 | 說明 |
|---|---|
| **路徑** | `{HTTP_VERB} /api/{Controller}/{Action}` |
| **權限** | `{授權需求}` |
| **Content-Type** | `application/json` |

---

### Request

```json
{
  "field1": "exampleValue"
}
```

#### Request 欄位說明

| 欄位名稱 | 型別 | 必填 | 預設值 | 說明 |
|---|---|---|---|---|
| `field1` | `string` | 是 | — | 說明 |

---

### Response

回傳 Excel 檔案，`Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`

---

### 注意事項與阻擋邏輯

1. **{標題}**：{說明}

---

### 錯誤回應

| HTTP 狀態碼 | 觸發條件 |
|---|---|
| `400 Bad Request` | {說明} |
| `403 Forbidden` | 權限不足，使用者未具備所需授權 |
| `404 Not Found` | {說明} |
| `500 Internal Server Error` | 伺服器內部錯誤 |

---

*文件產出時間：{YYYY-MM-DD}*
````
`````

---

## Field Writing Rules

| Column | Rule |
|---|---|
| **型別 (Type)** | Use C# type names: `string`, `int`, `long`, `decimal`, `bool`, `short`, `datetime`, `array`. Add `?` for nullable value types (e.g., `long?`). |
| **必填 (Required)** | Mark `是` only when the service / validator will reject a missing / null value. Otherwise `否`. |
| **預設值 (Default)** | The value the service actually uses when the field is absent or null. Use `—` for required fields. Common defaults: `null`, `1` (pageIndex), `100` (pageSize), `""`. |
| **說明 (Description)** | Keep concise. For enum fields, list every valid string literal. For override-priority ID fields, state the override behaviour explicitly. |

---

## Quality Checklist (self-review before output)

- [ ] Document title format: `{中文名稱} ({ActionMethodName})`
- [ ] Route is fully correct: class-level prefix + action template + route params
- [ ] HTTP verb matches the `[Http*]` attribute on the action
- [ ] POST / PUT includes `Content-Type` row; GET **omits** it
- [ ] Correct variant selected (A / B / C) based on the action signature
- [ ] **Variant B**: Request section contains only the single word「無」— no JSON, no table
- [ ] **Variant C**: Response section contains only the single Excel Content-Type sentence — no JSON, no table
- [ ] **Variant A (GET with route params)**: no JSON example in Request; only the field table
- [ ] Route parameters appear in the Request field table and their description says「路徑參數」
- [ ] Every field in the request entity appears in both the JSON example and the field table
- [ ] Every field in the response entity appears in both the JSON example and the field table
- [ ] Enum values use exact string literals (not integers)
- [ ] Session-derived values (tenant ID, current user, operator, etc. — anything read from auth / session context) do NOT appear in the Request field table
- [ ] Nullable fields have `?` in the type column and a note in 注意事項
- [ ] **MUST**: Output is wrapped in a ` ````md ` fenced block (4 backticks) — the fence starts on the very first line, with zero prose before it. Using 3 backticks causes inner ` ```json ` blocks to break the outer fence and render as Markdown
- [ ] **MUST**: No Markdown hyperlinks anywhere inside the document; field names use plain `` `backtick` `` inline code only
- [ ] **MUST**: Output language is Traditional Chinese (field names and code values excepted)
- [ ] 錯誤回應 table lists every possible 4xx/5xx status code with its trigger condition — all derived from code, never guessed; distinct business error reasons each have their own row even if they share the same HTTP status code
- [ ] Conditional field dependencies ("Y required when X = Z", mutual exclusions) are documented in both the Request 欄位說明 table and 注意事項
- [ ] Document ends with a timestamp in `YYYY-MM-DD` format using the current date and time
