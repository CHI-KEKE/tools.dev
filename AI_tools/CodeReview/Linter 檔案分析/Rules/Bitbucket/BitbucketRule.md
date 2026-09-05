繼承 RuleBase

## PushMessage (字串列表版本)

- 將檢查結果以評論形式推送到 PR
- 若無錯誤訊息，會將 ✔️{規則名稱} 快取起來
- 支援 Bitbucket 和 GitLab 的不同 API 格式



## PushBitbucketMessage

支援三種評論方式

1. 特定行數評論：inline = { to = LineTo, path = Path }
2. 檔案評論：inline = { path = Path }
3. 一般評論：content = { raw = Message }


使用非同步任務並行處理多筆評論
使用 Task.WaitAll() 等待所有評論完成

## PushGitLabMessage

針對特定行數會呼叫 LineCommentAPI
自動加上 🤖 **AI Code Review** 前綴
支援 line_type = "new" 參數


##  GetDiffContent - 取得 Diff 資料


多平台支援

#### Bitbucket

處理 302 重定向
使用 Bearer Token 認證

#### GitLab

從 JSON 回應中提取 changes 欄位
使用 private_token 認證

#### GitHub

使用 token 認證
需要 Accept: application/vnd.github.v3+json 標頭




## GetPlatform

## GetPullRequestTitle




##  GitLab 專屬功能

#### GetGitLabVersions

取得 Merge Request 的版本資訊

#### GetGitLabMergeRequest

取得 MR 詳細資料
快取機制: 5 分鐘有效期
Cache Key: {Platform}MergeRequest:{iid}

#### GetGitLabFiles

使用 LINQ 交集取得符合的檔案
從 source_branch 取得檔案


#### GetGitLabFileContent
URL 編碼檔案路徑
取得原始檔案內容 (/raw 端點)


## Bitbucket 專屬功能

#### GetDiffStatInfo
取得 Diff 統計資訊（新增/刪除行數等）
反序列化為 DiffstatEntity 物件
記錄執行時間到日誌


#### GetCommits
支援分頁查詢（透過 HasNext 和 Next 屬性）
使用 do-while 迴圈取得所有 commits
僅支援 Bitbucket（其他平台拋出 NotImplementedException）
