# 操作紀錄：將 AI Code Review 專案文件發布為 GitLab Pages

- **日期**：2026-08-17
- **專案**：`g11n/nineyi.ai.code.review.v2`（GitLab: `https://gitlab.91app.com`）
- **目標**：讓 `docs/nineyi-ai-code-review-v2-overview.html` 可以透過網址直接瀏覽，不用下載檔案打開。
- **分支**：`master`

---

## 一、背景與目標

專案內已有一份手寫的技術文件 `docs/nineyi-ai-code-review-v2-overview.html`，原本只能下載後在本機開啟。希望透過 **GitLab Pages** 功能，讓這份 HTML 文件自動部署成一個可直接訪問的網頁，方便團隊隨時查閱、分享連結。

---

## 二、操作步驟

### Step 1：確認前置條件

- 確認公司自架 GitLab（`gitlab.91app.com`）有開放 **Pages** 功能（專案左側選單可見 **Deploy → Pages**）。
- 確認要使用的分支：**`master`**（非 `main`），因為這個專案的實際開發分支是 `master`。
- 確認目標檔案存在：`docs/nineyi-ai-code-review-v2-overview.html`。

### Step 2：修改 `.gitlab-ci.yml`，新增 `pages` job

在既有的 `.gitlab-ci.yml`（原本已 include 公司共用 CI/CD pipeline 範本）中，額外新增一個名為 `pages` 的 job：

```yaml
# 將 docs/nineyi-ai-code-review-v2-overview.html 部署為 GitLab Pages 靜態網頁。
# GitLab 規定 job 名稱必須是 "pages"，且產物須放在 "public" 目錄下才會被識別。
pages:
  stage: .pre
  tags:
    - production
  script:
    - mkdir -p public
    - cp docs/nineyi-ai-code-review-v2-overview.html public/index.html
  artifacts:
    paths:
      - public
  rules:
    # 僅在 master 分支推送時才部署，避免每個 feature branch 都覆蓋正式頁面。
    - if: '$CI_COMMIT_BRANCH == "master"'
```

**關鍵設計說明**：

| 設定 | 說明 |
|---|---|
| `job 名稱固定為 pages` | GitLab 硬性規定，只有名稱叫 `pages` 的 job 才會被辨識為 Pages 部署工作 |
| `artifacts.paths: public` | GitLab 規定產物必須放在 `public/` 目錄下 |
| `cp ... public/index.html` | 把既有 HTML 複製並改名為 `index.html`，作為網站首頁（若不改名，訪問網站根目錄會找不到頁面） |
| `stage: .pre` | 使用 GitLab 保留的內建階段 `.pre`，不會與共用 CI 範本中既有 stage 名稱衝突，最先執行、風險最低 |
| `tags: [production]` | 沿用專案既有 `rel:build` job 使用的 Runner tag，確保有 Runner 可以領取執行；此 tag 僅代表「哪台 Runner 執行」，與正式環境部署無關 |
| `rules: if CI_COMMIT_BRANCH == "master"` | 限制只有推送到 `master` 分支才觸發部署，避免 feature branch 的測試內容洗掉正式頁面 |

### Step 3：Commit & Push

```powershell
cd "C:\91APP\AI_Devs\codereview\gitlab-codereview\nineyi.ai.code.review.v2"
git add .gitlab-ci.yml
git commit -m "pages"
git push upstream master
```

推送後 GitLab 自動觸發 Pipeline #484654。

### Step 4：確認 Pipeline 執行結果

前往 GitLab 專案 → **CI/CD → Pipelines**，可見：

- Pipeline 名稱：`pages`
- 觸發分支：`master`
- `pages` job（位於 `.pre` stage）狀態為 **Passed**

`pages` job 的執行 log 重點：

```
$ mkdir -p public
$ cp docs/nineyi-ai-code-review-v2-overview.html public/index.html
Uploading artifacts for successful job
Uploading artifacts...
public: found 2 matching artifact files and directories
Uploading artifacts as "archive" to coordinator... 201 Created
Job succeeded
```

> 補充：同一條 pipeline 中還有其他 job（如 `qa:config:build`、`dev:trigger-deploy` 等）持續執行中，這些屬於專案既有共用 CI 範本的正常流程，與本次 Pages 部署無關，**不需要等它們跑完**，`pages` job 成功後 GitLab 就會在背景處理網頁部署。

### Step 5：取得 Pages 網址並驗證

1. 前往 GitLab 專案左側選單 **Deploy → Pages**。
2. 頁面顯示 Pages 已部署成功，並提供可訪問網址。
3. 開啟該網址，確認能直接看到 `nineyi-ai-code-review-v2-overview.html` 的完整內容 ✅ **驗證成功**。

---

## 三、結果

- ✅ `docs/nineyi-ai-code-review-v2-overview.html` 已成功透過 GitLab Pages 發布。
- ✅ 團隊成員之後只需要分享一組網址，即可直接在瀏覽器查看該技術文件，不需再下載 HTML 檔案。
- ✅ 部署機制已固定綁定 `master` 分支，之後只要更新 `docs/nineyi-ai-code-review-v2-overview.html` 內容並 push 到 `master`，Pages 網頁會自動同步更新。

---

## 四、後續注意事項

1. **存取權限**：企業自架 GitLab 的 Pages 預設通常需登入公司 GitLab 帳號才能瀏覽（視 instance 設定而定）。若需要開放給沒有 GitLab 帳號的人瀏覽，需另外請管理員調整 Pages 存取層級，並評估文件內容是否適合對外公開。
2. **更新文件流程**：日後若要更新網頁內容，只需修改/覆蓋 `docs/nineyi-ai-code-review-v2-overview.html` 並 push 到 `master`，`pages` job 會自動重新執行並更新網頁內容，不需要再次修改 `.gitlab-ci.yml`。
3. **若之後想改放多份文件**：可將 `public/` 目錄下放置多個 HTML 檔案（例如 `public/webhook-readme.html`），並在 `public/index.html` 中加上超連結索引，即可用同一個 Pages 網站承載多份文件。
