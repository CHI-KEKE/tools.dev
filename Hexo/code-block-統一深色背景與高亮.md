# Hexo Code Block 統一深色背景與語法高亮修正

## 修正日期

2026-09-14

## 問題

`C:\Dev\Hexo-mind\source\_posts\Docker\包 .NET 給 PO 使用.md` 的部分 code block 顯示為淺色背景，且不同文章的 code block 顏色不一致。

## 原因

1. Butterfly 主題設定 `themes/butterfly/_config.yml` 的 `code_blocks.theme` 原本是 `light`。
2. 部分文章在 Markdown 內嵌 `.highlight` 或 `pre` 樣式，會覆蓋主題預設的 code block 顏色。

Hexo 的 Markdown code fence 會先由 highlight.js 產生 HTML，再由 Butterfly 主題 CSS 控制最終外觀；因此主題設定與文章內嵌 CSS 都可能影響呈現結果。

## 修正內容

### 1. 切換 Butterfly 語法高亮主題

檔案：`C:\Dev\Hexo-mind\themes\butterfly\_config.yml`

```yml
code_blocks:
  theme: darker
```

### 2. 新增全站 code block 覆蓋樣式

檔案：`C:\Dev\Hexo-mind\themes\butterfly\source\css\_custom\code-block.styl`

統一設定：

- code block 背景：`#0d1117`
- 行號欄與工具列背景：`#161b22`
- 程式碼文字：`#f0f6fc`
- 以 `!important` 確保文章內嵌樣式無法覆蓋深色背景
- 保留 highlight.js 的語法 token 顏色

### 3. 載入自訂樣式

檔案：`C:\Dev\Hexo-mind\themes\butterfly\source\css\index.styl`

新增：

```stylus
@import '_custom/code-block'
```

## 驗證

執行：

```powershell
npm run build
```

結果：成功產生 44 個頁面；Docker 文章成功產生 13 個 code block，產出的 CSS 已包含深色背景與文字高亮規則。

## 後續調整位置

| 需求 | 修改位置 |
|------|----------|
| 切換整體語法高亮配色 | `themes/butterfly/_config.yml` → `code_blocks.theme` |
| 調整全站 code block 背景與文字 | `themes/butterfly/source/css/_custom/code-block.styl` |
| 調整 highlight.js 引擎設定 | `_config.yml` → `syntax_highlighter` / `highlight` |
