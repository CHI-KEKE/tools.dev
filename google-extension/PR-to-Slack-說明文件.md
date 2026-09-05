# PR to Slack — Chrome Extension 說明文件

> 一鍵將 GitHub Pull Request 的標題、Branch 資訊與網址組裝成訊息，發送到指定 Slack 頻道。

---

## 目錄

- [專案結構](#專案結構)
- [安裝步驟](#安裝步驟)
- [設定 Slack Webhook](#設定-slack-webhook)
- [使用方式](#使用方式)
- [訊息模板](#訊息模板)
- [快捷鍵](#快捷鍵)
- [技術說明](#技術說明)
- [注意事項與已知問題](#注意事項與已知問題)
- [未來可擴充項目](#未來可擴充項目)

---

## 專案結構

```
google-extension/
└── pr-to-slack/
    ├── manifest.json     # Extension 設定（Manifest V3）
    ├── background.js     # Service Worker，負責呼叫 Slack Webhook API
    ├── popup.html        # 彈出視窗 UI
    ├── popup.js          # UI 邏輯、頁面資料擷取、訊息組裝
    ├── README.md         # 本說明文件的簡要版
    └── icons/
        ├── icon16.png
        ├── icon48.png
        └── icon128.png
```

---

## 安裝步驟

1. 開啟 Chrome，網址列輸入：
   ```
   chrome://extensions/
   ```
2. 右上角開啟「**開發者模式**」
3. 點擊「**載入未封裝項目**」
4. 選擇 `pr-to-slack/` 資料夾
5. Extension 安裝完成，工具列出現 **PR to Slack** 圖示

> ⚠️ 每次修改程式碼後，需回到 `chrome://extensions/` 點擊該 Extension 的 **↺ 重新整理** 才會生效。

---

## 設定 Slack Webhook

1. 前往 [https://api.slack.com/apps](https://api.slack.com/apps)
2. 點擊「**Create New App**」→ 選「From scratch」
3. 左側選單選「**Incoming Webhooks**」→ 開啟開關
4. 點擊「**Add New Webhook to Workspace**」→ 選擇要發送的 Channel
5. 複製產生的 Webhook URL，格式如下：
   ```
   ```
6. 將此 URL 貼入 Extension Popup 的「Slack Webhook URL」欄位
7. 點擊欄位外部，URL 會自動儲存（下次開啟不需重填）

---

## 使用方式

1. 前往 GitHub 的任一 PR 頁面，例如：
   ```
   https://github.com/org/repo/pull/123
   ```
2. 點擊瀏覽器右上角的 **PR to Slack** 圖示，或按快捷鍵（見下方）
3. Popup 自動擷取：
   - PR 標題
   - Branch 資訊（`head` => `base`）
   - PR 網址
4. 選擇訊息模板，或直接編輯文字區塊
5. 確認 Slack Webhook URL 已填入
6. 點擊「**發送到 Slack ▶**」

---

## 訊息模板

### 🔍 請求 Review（預設）

```
<!here>

*PR 標題*

`feature/my-branch` => `main`

https://github.com/org/repo/pull/123
```

### ✅ 已 Merge

```
✅ *PR 已 Merge*
*PR 標題*
https://github.com/org/repo/pull/123
```

### 📎 純連結

```
*PR 標題*
https://github.com/org/repo/pull/123
```

> 所有模板內容均可在 Popup 的文字框內手動修改後再發送。  
> 點擊「重置」可還原為目前選擇的模板預設內容。

---

## 快捷鍵

| 平台 | 快捷鍵 |
|------|--------|
| Windows / Linux | `Alt + Shift + P` |
| macOS | `Alt + Shift + P` |

> 如需更改快捷鍵，前往 `chrome://extensions/shortcuts`，找到「PR to Slack」修改。

---

## 技術說明

### Manifest V3

本 Extension 採用 Chrome Manifest V3 規範：

- **`background.js`**：以 Service Worker 形式執行，負責透過 `fetch` 呼叫 Slack Webhook
- **`chrome.scripting.executeScript`**：將 `extractPRInfo()` 注入當前頁面執行，擷取 PR 資訊
- **`chrome.storage.local`**：儲存 Webhook URL，避免每次重填

### GitHub PR 頁面資料擷取

| 資料 | 主要 Selector | Fallback |
|------|--------------|---------|
| PR 標題 | `h1 .js-issue-title` / `h1 bdi` / `[data-testid="issue-title"]` | `document.title`（去除 ` by ...` 後綴） |
| Base Branch | `a.prc-BranchName-BranchName-CMTaU`（第 1 個） | `.base-ref` |
| Head Branch | `a.prc-BranchName-BranchName-CMTaU`（第 2 個） | `.head-ref` |

### Slack `@here` 語法

Slack Incoming Webhook 中，`@here` 必須使用特殊格式才能真正 tag：

| 想要的效果 | 正確語法 |
|-----------|---------|
| @here | `<!here>` |
| @channel | `<!channel>` |
| @everyone | `<!everyone>` |

---

## 注意事項與已知問題

### ⚠️ GitHub UI 更新導致 Selector 失效

GitHub 前端為 React + CSS Module，class 名稱（如 `prc-BranchName-BranchName-CMTaU`）**可能隨版本更新而變動**。

若未來 Branch 資訊無法顯示，請：
1. 開啟 GitHub PR 頁面
2. 按 F12 開啟 DevTools
3. 找到 Branch 顯示區塊，複製新的 class 名稱
4. 更新 `popup.js` 中 `extractPRInfo()` 的 selector

### ⚠️ Extension 修改後必須手動重新整理

程式碼變更後不會自動生效，需至 `chrome://extensions/` 點擊 **↺ 重新整理**。

### ⚠️ 非 PR 頁面無法使用

偵測規則為 URL 符合 `github.com/*/pull/*`，在其他頁面開啟 Popup 時發送按鈕會被停用。

### ⚠️ Webhook URL 明文儲存

Webhook URL 儲存於 `chrome.storage.local`，屬於本機瀏覽器儲存，**不會上傳**，但請勿將 Webhook URL commit 進任何版本控制。

### ⚠️ Slack Webhook 無法撤回訊息

訊息一旦發送即無法從 Extension 撤回，請在發送前確認訊息內容。

---

## 未來可擴充項目

| 功能 | 說明 |
|------|------|
| 多 Webhook / Channel 切換 | Popup 加入下拉選單，對應不同專案的 Slack Channel |
| 自訂訊息模板 | 讓使用者在設定頁自定義模板格式 |
| 支援 GitLab / Jira | 判斷 URL domain，切換不同的 selector 與格式 |
| 發送歷史紀錄 | 記錄最近發送的訊息，方便重送 |
| Slack Block Kit 格式 | 改用結構化 Block 訊息，顯示更豐富的卡片樣式 |
