# 問題：command 'markdown.extension.onBackspaceKey' not found

## 問題描述

在 VS Code 編輯 `.md` 檔案時，按下 `Backspace` 鍵卻跳出以下錯誤：

```
command 'markdown.extension.onBackspaceKey' not found
```

## 根本原因

`markdown.extension.onBackspaceKey` 是 **Markdown All in One** 擴充套件所註冊的指令。

當該擴充套件：
- 未安裝
- 已停用
- 版本不相容

但 VS Code 的 `keybindings.json` 中仍存有對應的快捷鍵綁定，就會在按下 `Backspace` 時觸發此錯誤。

最常見的情境：**曾安裝 Markdown All in One 後又移除，但快捷鍵綁定未一併清除。**

---

## 解決方式

### 方案一（推薦）：重新安裝 Markdown All in One

1. 按 `Ctrl+Shift+X` 開啟擴充套件面板
2. 搜尋 `Markdown All in One`
3. 若已安裝 → 先解除安裝，再重新安裝
4. 若未安裝 → 直接安裝（作者：Yu Zhang）
5. 重新載入 VS Code

### 方案二：移除殘留的快捷鍵綁定

1. 按 `Ctrl+Shift+P`，搜尋並開啟 `Open Keyboard Shortcuts (JSON)`
2. 找到含有 `markdown.extension.onBackspaceKey` 的項目，例如：

```json
{
  "key": "backspace",
  "command": "markdown.extension.onBackspaceKey",
  "when": "editorTextFocus && !editorReadonly && editorLangId == markdown"
}
```

3. 刪除該項目後存檔

### 方案三（臨時）：繞過問題直接編輯

用終端機或其他編輯器（如記事本、Notepad++）開啟 `.md` 檔案進行編輯，不受 VS Code 快捷鍵影響。

---

## 相關資訊

| 項目 | 內容 |
|------|------|
| 錯誤指令 | `markdown.extension.onBackspaceKey` |
| 相關擴充套件 | Markdown All in One（作者：Yu Zhang） |
| 觸發按鍵 | `Backspace` |
| 影響範圍 | 編輯 `.md` 檔案時 |
