
## 快捷鍵

- alt + ctrl + 下  -> `可以一次性游標延伸`
- shift + alt + -> `直接反白一個 block`
- 左邊點擊某個檔案 & shift + alt + R  -> `Reveal File Explorer`
- 新增檔案 ctrl + alt + n
- 新增資料夾 Ctrl + shhift + alt + n
- 找快捷鍵 ctrl +K + S



## 自定義 wrapper

Ctrl + shift + p
Configure Snippets



C:\Users\Allen Lin\AppData\Roaming\Code\User\snippets

新增檔案

markdown.sql.code-snippets

CODE-SNIPPETS File (.code-snippets)

```json
{
  "wrap-sql-codeblock": {
    "prefix": "sqlwrap",
    "body": [
      "```sql",
      "$TM_SELECTED_TEXT",
      "```"
    ],
    "description": "Wrap selected text in ```sql code block"
  }
}
```


## 快捷鍵 vs code 開資料夾

code .
code ////



## 開新視窗就自動載入某資料夾 (尚未搞清楚)


1. Ctrl + Shift + P（macOS：Cmd + Shift + P）
2. Preferences: Open Keyboard Shortcuts (JSON)


```json
{
  "key": "ctrl+shift+n",
  "command": "vscode.openFolder",
  "args": {
    "uri": "file:///D:/Projects/backend"
  }
}
```



## 定義新的 shorcut


Ctrl + Shift + P

輸入 Preferences: Open Keyboard Shortcuts (JSON)


```json
{
  "key": "ctrl+alt+n",
  "command": "explorer.newFile",
  "when": "explorerViewletVisible && filesExplorerFocus"
}
```



## User setup versus system setup

https://code.visualstudio.com/docs/setup/windows



## 上一頁

在 VS Code 裡，「回到上一頁 / 上一個游標位置」通常是：

Windows / Linux

Alt + Left