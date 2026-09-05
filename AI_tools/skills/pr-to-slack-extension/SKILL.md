---
name: pr-to-slack-extension
description: Know-how for building and modifying the PR to Slack Chrome Extension. Use this when the user asks to adjust, debug, or extend the pr-to-slack Google Chrome extension located at tools.dev/google-extension/pr-to-slack/.
---

# Skill: PR to Slack Chrome Extension

## 專案概述

一個 Chrome Extension（Manifest V3），讓使用者在 GitHub / GitLab / Bitbucket PR 頁面一鍵組裝訊息並發送到 Slack。

**位置：** `tools.dev/google-extension/pr-to-slack/`

---

## 檔案結構

```
pr-to-slack/
├── manifest.json    # Extension 設定、權限宣告
├── background.js    # Service Worker，負責實際 fetch API
├── popup.html       # Extension 彈出視窗 UI
├── popup.js         # UI 邏輯、訊息組裝、狀態管理
└── icons/           # icon16.png / icon48.png / icon128.png
```

---

## 核心架構

### Manifest V3 重點

```json
{
  "manifest_version": 3,
  "permissions": ["activeTab", "scripting", "storage"],
  "host_permissions": ["https://api.infra.91app.io/*"],
  "background": { "service_worker": "background.js" }
}
```

- `activeTab` + `scripting`：允許 `executeScript` 注入腳本讀取當前頁面 DOM
- `storage`：儲存使用者設定（channel、checkbox 狀態）
- `host_permissions`：**必須**包含 fetch 目標 domain，否則 service worker 發出的 fetch 會被 Chrome 擋掉，回傳 `TypeError: Failed to fetch`

> ⚠️ **修改 manifest.json 後必須到 `chrome://extensions` 重新載入 extension**，否則新權限不會生效。

### 訊息流程

```
popup.js (UI)
  → chrome.runtime.sendMessage({ action:'sendSlack', text, slackChannel })
  → background.js (Service Worker)
  → fetch(API_URL, { headers, body })
  → sendResponse({ success, error })
  → popup.js 顯示結果
```

background.js 需 `return true` 在 `onMessage` listener 中，讓 `sendResponse` 保持非同步可用。

---

## API 規格

**Endpoint：** `POST https://api.infra.91app.io/v1/Ops/SlackSimple`

**Headers：**
```
Content-Type: application/json
x-api-key: <key>
```

**Body：**
```json
{
  "slack_channel": "rd-sg-slacktest",
  "message": "<!here> from @allenlin\n\n*PR Title*\n`head` => `base`\nhttps://...",
  "broadcast": true,
  "username": "PR",
  "icon": ":atom_symbol:",
  "level": "Info"
}
```

> `message` 欄位直接傳 JS 字串（含 `\n` 換行），`JSON.stringify` 會自動處理跳脫，不需手動替換。

---

## 跨平台 PR 資訊擷取（`extractPRInfo`）

此函式透過 `chrome.scripting.executeScript` 注入到頁面執行，**不可直接引用 popup.js 的變數**。

| 平台 | URL 判斷 | Title selector | Branch selectors |
|------|----------|----------------|-----------------|
| GitHub | `/pull/\d+` | `h1 .js-issue-title` / `h1 bdi` / `[data-testid="issue-title"]` | `a.prc-BranchName-BranchName-CMTaU`（新版）/ `.base-ref` `.head-ref`（舊版） |
| GitLab | `/-/merge_requests/\d+` | `h1[data-testid="title-content"]` | `a.ref-container`（用 `title` 屬性取完整名稱） |
| Bitbucket | `/pull-requests/\d+` | `h1[tabindex="-1"]` | `[data-qa="pr-branches-and-state-styles"] div[role="button"]`，去掉 `"Branch: "` 和 `"repo:"` 前綴 |

---

## 訊息模板系統

```javascript
const TEMPLATES = {
  review: (title, url, headBranch, baseBranch) => {
    const branchLine = headBranch && baseBranch ? `\`${headBranch}\` => \`${baseBranch}\`\n` : '';
    return `<!here> from @allenlin\n*${title}*\n${branchLine}${url}\n`;
  },
  merged: (title, url) => `✅ *PR 已 Merge*\n*${title}*\n${url}`,
  simple: (title, url) => `*${title}*\n${url}`
};
```

所有模板輸出都會再經過 `applyOptions(text)` 處理 checkbox 狀態。

---

## Checkbox 選項與 `applyOptions`

```javascript
function applyOptions(text) {
  // autoSend OFF：把 <!here> from @allenlin 換成 @here
  let result = autoSendEl.checked
    ? text
    : text.replace('<!here> from @allenlin', '@here');

  // aiReview：附加或移除最後一行
  result = result.replace(AI_REVIEW_LINE, '');
  if (aiReviewEl.checked) result += AI_REVIEW_LINE;
  return result;
}
```

| Checkbox | ID | 預設 | 效果 |
|---|---|---|---|
| Auto Send Mode | `autoSend` | ✅ checked | `<!here> from @allenlin` / 取消勾選改為 `@here` |
| 顯示 Branch Name | `showBranch` | ✅ checked | 訊息包含 head → base branch 資訊 |
| AI Code Review | `aiReview` | ⬜ unchecked | 附加 `\n✅已確認 ai code review 結果` 到訊息末尾 |

所有 checkbox 狀態透過 `chrome.storage.local` 持久化。

---

## 錯誤處理

background.js 回傳詳細錯誤：
- **網路錯誤**（fetch 失敗）：`${err.name}: ${err.message}`，例如 `TypeError: Failed to fetch`
- **HTTP 錯誤**：`HTTP ${status} ${statusText} — ${responseBody}`

popup.html 的 `#status` 設定 `white-space: pre-wrap; word-break: break-all` 讓長錯誤訊息可以換行顯示。

---

## `chrome.storage.local` 儲存的 key

| Key | Type | 說明 |
|---|---|---|
| `slackChannel` | string | 目標 Slack channel 名稱 |
| `showBranch` | boolean | 是否顯示 branch name |
| `aiReview` | boolean | 是否附加 AI review 確認文字 |
| `autoSend` | boolean | Auto Send Mode（預設 true） |

---

## 常見問題

### `Failed to fetch` / `TypeError: Failed to fetch`

1. **`manifest.json` 的 `host_permissions` 未包含目標 API domain** → 修改後務必在 `chrome://extensions` reload extension
2. **網路不通** → 用 PowerShell `Invoke-RestMethod` 直接測試 API

### `chrome.runtime.sendMessage` 沒有回應

- background service worker 可能已休眠，確保 `onMessage` listener 有 `return true`

### Branch 名稱抓不到

- GitHub 新版 UI 的 class 名稱可能隨版本改變（`prc-BranchName-BranchName-CMTaU`），需定期檢查 DOM selector

---

## 後續擴充建議

- 支援多個 Slack channel 快速切換（下拉選單）
- 支援自訂 username / icon per channel
- 支援 `<@userID>` 格式的真實 Slack mention（需查詢 Slack User ID）
