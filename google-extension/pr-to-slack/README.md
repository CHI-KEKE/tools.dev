# PR to Slack — Chrome Extension

一鍵將 GitHub Pull Request 的標題與網址組裝成訊息，發送到 Slack。

## 檔案結構

```
pr-to-slack/
├── manifest.json   # Extension 設定
├── popup.html      # 彈出視窗 UI
├── popup.js        # UI 邏輯、抓取 PR 資訊
├── background.js   # 呼叫 Slack Webhook API
└── icons/          # Extension 圖示
```

## 安裝步驟

1. 開啟 Chrome，前往 `chrome://extensions/`
2. 右上角開啟「**開發者模式**」
3. 點擊「**載入未封裝項目**」
4. 選擇本資料夾 `pr-to-slack/`

## 使用方式

1. 前往任一 GitHub PR 頁面（例如 `github.com/xxx/yyy/pull/123`）
2. 點擊瀏覽器右上角的 **PR to Slack** 圖示
3. 視窗會自動抓取 PR 標題與網址
4. 選擇訊息模板（🔍 請求 Review / ✅ 已 Merge / 📎 純連結）或自行編輯
5. 填入 Slack Webhook URL（只需填一次，之後會自動儲存）
6. 點擊「**發送到 Slack ▶**」

## 取得 Slack Webhook URL

1. 前往 https://api.slack.com/apps
2. 建立新 App → 選「From scratch」
3. 左側選單選「**Incoming Webhooks**」→ 開啟
4. 點「Add New Webhook to Workspace」→ 選擇 Channel
5. 複製產生的 Webhook URL（格式：`https://hooks.slack.com/services/...`）

## 訊息模板

| 模板 | 格式 |
|------|------|
| 🔍 請求 Review | `👀 *PR Review 請求* + 標題 + 網址` |
| ✅ 已 Merge | `✅ *PR 已 Merge* + 標題 + 網址` |
| 📎 純連結 | `標題 + 網址` |
