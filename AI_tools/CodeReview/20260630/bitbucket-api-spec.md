# Bitbucket Proxy API Specification

> 透過 AI Code Review V2 站台代理呼叫 Bitbucket API。所有呼叫皆由伺服器端自動附帶 Bitbucket Access Token，前端無須自行處理驗證。

## API 基本資訊

- **Base URL**: `https://{host}/api/bitbucket`
- **Content-Type**: `application/json`（所有 request / response）
- **用途**: 透過 AI Code Review V2 站台代理呼叫 Bitbucket API，並由 server 端統一處理 Bitbucket Access Token

## 目錄

1. [共通 Response 規則](#共通-response-規則)
2. [POST /api/bitbucket/diff — Get PR Diff](#1-post-apibitbucketdiff--get-pr-diff)
3. [POST /api/bitbucket/comment — Post PR Comment](#2-post-apibitbucketcomment--post-pr-comment)
4. [POST /api/bitbucket/diffstat — Get DiffStat](#3-post-apibitbucketdiffstat--get-diffstat)
5. [POST /api/bitbucket/file-content — Get File Raw Content](#4-post-apibitbucketfile-content--get-file-raw-content)
6. [POST /api/bitbucket/commits — Get Commits](#5-post-apibitbucketcommits--get-commits)
7. [POST /api/bitbucket/src-tree — Get Repository Source Tree](#6-post-apibitbucketsrc-tree--get-repository-source-tree)
8. [注意事項](#注意事項)

---

## 共通 Response 規則

### 成功（200）

- 所有 response 都會帶 `traceId`
- 格式：`bb-{action}-{6碼亂數}`
- 範例：`bb-diff-a1b2c3`
- 可使用 `traceId` 於 server log 查詢完整請求鏈路

### 失敗（500）

```json
{
  "traceId": "bb-diff-a1b2c3",
  "error": "錯誤訊息"
}
```

| 欄位 | 型別 | 必有 | 說明 |
| --- | --- | --- | --- |
| `traceId` | string | 是 | 後端產生的請求追蹤 ID |
| `error` | string | 是 | 失敗原因或錯誤訊息 |

---

## 1. POST /api/bitbucket/diff — Get PR Diff

**說明**: 取得 PR 所有異動檔案的 unified diff，且已套用排除清單（例如 migration、auto-generated 檔案不會包含在結果內）。

### Request Body

```json
{
  "diffUrl": "https://api.bitbucket.org/2.0/repositories/workspace/repo/diff/...",
  "repoFullName": "workspace/repo-slug",
  "prNumber": 1234
}
```

### Request 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `diffUrl` | string | 是 | Bitbucket webhook payload `pullrequest.links.diff.href` 的值 |
| `repoFullName` | string | 是 | Repository 完整名稱，格式必須為 `workspace/repo-slug` |
| `prNumber` | int | 是 | Pull Request 編號 |

### Response 200

```json
{
  "traceId": "bb-diff-a1b2c3",
  "fileCount": 2,
  "files": [
    {
      "filePath": "WebStore/Backend/Services/FooService.cs",
      "fileExtension": ".cs",
      "diff": "diff --git a/...\n@@ -10,5 +12,8 @@\n+新增的程式碼...",
      "changedLineRanges": [
        { "start": 12, "end": 19 }
      ]
    }
  ]
}
```

### Response 欄位說明

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `traceId` | string | 請求追蹤 ID |
| `fileCount` | int | 異動檔案數量（已過濾） |
| `files` | array | 檔案 diff 結果清單 |
| `files[].filePath` | string | 檔案完整路徑 |
| `files[].fileExtension` | string | 檔案副檔名（含 `.`，例如 `.cs`） |
| `files[].diff` | string | 該檔案 raw unified diff 文字，可直接送給 Dify AI |
| `files[].changedLineRanges` | array | 新增行號範圍陣列，元素格式為 `{ start, end }`，採 1-based |
| `files[].changedLineRanges[].start` | int | 變更區段起始行 |
| `files[].changedLineRanges[].end` | int | 變更區段結束行 |

---

## 2. POST /api/bitbucket/comment — Post PR Comment

**說明**: 在指定 PR 貼上一則 PR-level comment（非 inline comment）。

### Request Body

```json
{
  "repoFullName": "workspace/repo-slug",
  "prNumber": 1234,
  "body": "留言內容，支援 Markdown"
}
```

### Request 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `repoFullName` | string | 是 | Repository 完整名稱，格式必須為 `workspace/repo-slug` |
| `prNumber` | int | 是 | Pull Request 編號 |
| `body` | string | 是 | 留言內容，支援 Bitbucket Markdown 格式 |

### Response 200

```json
{
  "traceId": "bb-comment-a1b2c3",
  "message": "Comment posted successfully"
}
```

### Response 欄位說明

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `traceId` | string | 請求追蹤 ID |
| `message` | string | 成功訊息 |

---

## 3. POST /api/bitbucket/diffstat — Get DiffStat

**說明**: 取得 PR 各檔案的變更統計（新增/刪除行數）以及每個檔案對應的 self link。

### Request Body

```json
{
  "repoFullName": "workspace/repo-slug",
  "prNumber": 1234
}
```

### Request 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `repoFullName` | string | 是 | Repository 完整名稱，格式必須為 `workspace/repo-slug` |
| `prNumber` | int | 是 | Pull Request 編號 |

### Response 200

```json
{
  "traceId": "bb-diffstat-a1b2c3",
  "data": {
    "pagelen": 500,
    "values": [
      {
        "status": "modified",
        "lines_removed": 2,
        "lines_added": 5,
        "old": { "path": "src/Services/FooService.cs" },
        "new": {
          "path": "src/Services/FooService.cs",
          "links": {
            "self": { "href": "https://api.bitbucket.org/2.0/repositories/.../src/.../..." }
          }
        }
      }
    ]
  }
}
```

### Response 欄位說明

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `traceId` | string | 請求追蹤 ID |
| `data` | object | Bitbucket 原始 JSON 透傳內容 |
| `data.pagelen` | int | 單頁筆數 |
| `data.values` | array | 各檔案 diff 統計結果 |
| `data.values[].status` | string | 檔案變更狀態，例如 `modified`、`added`、`removed` |
| `data.values[].lines_removed` | int | 刪除行數 |
| `data.values[].lines_added` | int | 新增行數 |
| `data.values[].old.path` | string | 舊檔案路徑 |
| `data.values[].new.path` | string | 新檔案路徑 |
| `data.values[].new.links.self.href` | string | 檔案 self link，可用於後續取得原始檔案內容 |

> `data` 為 Bitbucket 原始 JSON 透傳；其中 `new.links.self.href` 可搭配 `/api/bitbucket/file-content` 取得完整檔案內容。

---

## 4. POST /api/bitbucket/file-content — Get File Raw Content

**說明**: 取得指定 commit 下某個檔案的完整原始內容。此端點回傳的是完整程式碼內容，而非 diff。

### Request Body

```json
{
  "repoFullName": "workspace/repo-slug",
  "prNumber": 1234,
  "headCommitSha": "aae240de1992abc123",
  "filePath": "WebStore/Backend/Services/FooService.cs"
}
```

### Request 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `repoFullName` | string | 是 | Repository 完整名稱，格式必須為 `workspace/repo-slug` |
| `prNumber` | int | 是 | Pull Request 編號，僅用於 log tracing |
| `headCommitSha` | string | 是 | PR HEAD commit SHA，可由 webhook payload `pullrequest.source.commit.hash` 取得 |
| `filePath` | string | 是 | 檔案完整路徑（相對於 repo 根目錄） |

### Response 200

```json
{
  "traceId": "bb-file-a1b2c3",
  "filePath": "WebStore/Backend/Services/FooService.cs",
  "content": "using System;\n\nnamespace ...\n{\n    // 完整原始程式碼\n}"
}
```

### Response 欄位說明

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `traceId` | string | 請求追蹤 ID |
| `filePath` | string | 實際取得內容的檔案路徑 |
| `content` | string | 完整原始檔案內容 |

---

## 5. POST /api/bitbucket/commits — Get Commits

**說明**: 取得 PR 的 commit 列表。

### Request Body

```json
{
  "repoFullName": "workspace/repo-slug",
  "prNumber": 1234
}
```

### Request 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `repoFullName` | string | 是 | Repository 完整名稱，格式必須為 `workspace/repo-slug` |
| `prNumber` | int | 是 | Pull Request 編號 |

### Response 200

```json
{
  "traceId": "bb-commits-a1b2c3",
  "data": {
    "pagelen": 30,
    "values": [
      {
        "hash": "aae240de1992",
        "message": "fix: stripe payment channel",
        "date": "2026-07-01T02:30:00+00:00",
        "author": { "raw": "Allen Lin <allen@example.com>" }
      }
    ]
  }
}
```

### Response 欄位說明

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `traceId` | string | 請求追蹤 ID |
| `data` | object | Bitbucket 原始 JSON 透傳內容 |
| `data.pagelen` | int | 單頁筆數 |
| `data.values` | array | Commit 列表 |
| `data.values[].hash` | string | Commit SHA |
| `data.values[].message` | string | Commit 訊息 |
| `data.values[].date` | string | Commit 時間（ISO 8601） |
| `data.values[].author.raw` | string | 作者原始顯示字串 |

> `data` 為 Bitbucket 原始 JSON 透傳；通常 `values[0].hash` 即為最新 commit SHA。

---

## 6. POST /api/bitbucket/src-tree — Get Repository Source Tree

**說明**: 取得 Repository 在指定 commit 下的目錄樹（目錄列表）。注意 `path` 必須是目錄路徑；若傳入檔案路徑，`data` 會變成該檔案的純文字內容，而不是 JSON 結構。

### Request Body

```json
{
  "repoFullName": "workspace/repo-slug",
  "commitHash": "aae240de1992abc123",
  "path": "WebStore/Backend/Services"
}
```

### Request 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
| --- | --- | --- | --- |
| `repoFullName` | string | 是 | Repository 完整名稱，格式必須為 `workspace/repo-slug` |
| `commitHash` | string | 是 | Commit SHA |
| `path` | string | 是 | **目錄路徑**；填入空字串 `""` 代表 repo 根目錄 |

### Response 200（傳入目錄路徑時）

```json
{
  "traceId": "bb-srctree-a1b2c3",
  "data": {
    "pagelen": 100,
    "values": [
      { "type": "commit_file", "path": "WebStore/Backend/Services/FooService.cs" },
      { "type": "commit_directory", "path": "WebStore/Backend/Services/Stripe" }
    ]
  }
}
```

### Response 欄位說明

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `traceId` | string | 請求追蹤 ID |
| `data` | object \| string | 正常傳目錄時為 Bitbucket 原始 JSON；若錯傳檔案路徑，可能變成純文字檔案內容 |
| `data.pagelen` | int | 單頁筆數 |
| `data.values` | array | 目錄下的檔案與子目錄清單 |
| `data.values[].type` | string | 類型，例如 `commit_file` 或 `commit_directory` |
| `data.values[].path` | string | 項目的完整路徑 |

---

## 注意事項

1. **traceId**: 每次請求都會產生唯一 ID；若發生問題，請提供 `traceId` 給後端查 log。
2. **repoFullName 格式**: 必須為 `workspace/repo-slug`，例如 `nineyi/nineyi.webstore.mobilewebmall`。
3. **headCommitSha 來源**: 可從 Bitbucket webhook payload `pullrequest.source.commit.hash` 取得，或從 `/api/bitbucket/commits` 的 `values[0].hash` 取得。
4. **diffUrl 來源**: 可從 Bitbucket webhook payload `pullrequest.links.diff.href` 取得。
5. **src-tree path 限制**: `/api/bitbucket/src-tree` 只接受目錄路徑；若要取得單一檔案完整內容，請改用 `/api/bitbucket/file-content`。
