# Hexo Code Block 設定完整解析 — Butterfly v4 vs v5 差異與修正

## 背景

在比對兩個 Hexo 專案的 code block 設定時，發現兩者除了 `_config.yml` 中少了 `exclude_languages` 之外，還有更深層的差異：**Butterfly 主題從 v4 升級到 v5 時，code block 的設定格式發生了破壞性變更（breaking change）**，導致 v4 格式的設定在 v5 主題中被完全忽略。

---

## 環境對比

| 項目 | Hexo（舊） | Hexo-mind（新） |
|------|-----------|----------------|
| Hexo 版本 | 7.2.0 | **8.1.2** |
| Butterfly 版本 | 4.13.0 | **5.5.5-b1** |
| `hexo-renderer-marked` | ^6.0.0 | ^7.0.0 |
| `hexo-filter-mermaid-diagrams` | ✅ 有 | ❌ 無（v5 內建） |
| `markdown-it-attrs` | ✅ 有 | ❌ 無 |

---

## 所有影響 Code Block 呈現的層次

### Layer 1：Hexo 核心（Build 時期）

**`_config.yml`** — 語法高亮引擎設定：

```yml
syntax_highlighter: highlight.js   # 決定用哪個引擎：highlight.js / prismjs

highlight:                          # highlight.js 設定
  line_number: true                 # 顯示行號
  auto_detect: true                 # 自動偵測語言
  tab_replace: ''                   # tab 轉空格數
  wrap: true                        # 是否包 <figure> 元素
  hljs: false                       # 是否套用 hljs CSS class
  exclude_languages: ['mermaid']    # 不套用高亮的語言（mermaid 需排除）

prismjs:                            # prismjs 設定（若不使用可 enable: false）
  enable: false
  preprocess: true
  line_number: true
  tab_replace: ''
  exclude_languages: ['mermaid']
```

**Hexo 核心相關檔案：**

| 檔案 | 作用 |
|------|------|
| `node_modules/hexo/dist/plugins/highlight/index.js` | 註冊 highlight.js / prismjs 兩個 provider |
| `node_modules/hexo/dist/plugins/highlight/highlight.js` | highlight.js 渲染邏輯 |
| `node_modules/hexo/dist/plugins/highlight/prism.js` | prismjs 渲染邏輯 |
| `node_modules/hexo/dist/plugins/filter/before_post_render/backtick_code_block.js` | 將 Markdown ` ``` ` 轉成高亮 HTML（支援 `mark`, `first_line`, `highlight:false`） |
| `node_modules/hexo/dist/plugins/tag/code.js` | `{% codeblock %}` / `{% code %}` tag plugin |

---

### Layer 2：Butterfly 主題設定（`themes/butterfly/_config.yml`）

#### ⚠️ v4 與 v5 格式完全不同（Breaking Change）

**v4 舊格式（Butterfly ≤ 4.x）：**
```yml
highlight_theme: mac       # 視覺主題
highlight_copy: true       # 複製按鈕
highlight_lang: true       # 語言標籤
highlight_shrink: false    # 預設收合
highlight_height_limit: false  # 高度限制（px）
code_word_wrap: false      # 自動換行
```

**v5 新格式（Butterfly 5.x）：**
```yml
code_blocks:
  theme: light             # v5 合法值：darker / pale night / ocean / light / false
                           # ⚠️ v4 的 mac / mac light 已在 v5 移除！
  macStyle: false          # Mac 視窗風格裝飾按鈕（紅黃綠圓點），v5 新增，獨立於 theme
  copy: true               # 複製按鈕
  language: true           # 語言標籤
  shrink: false            # true: 收合 / false: 展開 / none: 展開且隱藏按鈕
  height_limit: false      # 高度限制（px），false = 不限制
  word_wrap: false         # 自動換行（關閉水平 scrollbar）
  fullpage: false          # 全螢幕模式按鈕（v5 新增）
```

**如果用 v4 格式設定 v5 主題，設定會被完全忽略，fallback 到 `default_config.js` 的預設值（theme: 'light'）。**

---

### Layer 3：主題 JavaScript（執行時期）

**`themes/butterfly/layout/includes/head/config.pug`** — 把主題設定注入頁面 JS：

- v4 讀取 `theme.highlight_copy`, `theme.highlight_lang` ...
- v5 讀取 `theme.code_blocks.copy`, `theme.code_blocks.language` ...（結構不同）

**`themes/butterfly/source/js/main.js`** → `addHighlightTool()`：
- 讀取 `window.GLOBAL_CONFIG.highlight`
- 根據 highlight.js vs prismjs 決定 DOM 包裝方式
- 加入工具列（複製按鈕、語言標籤）
- 實作 shrink / expand、height_limit 展開、fullpage 全螢幕

---

### Layer 4：CSS 樣式

| 檔案 | 影響 |
|------|------|
| `source/css/_highlight/highlight.styl` | 核心樣式：工具列、複製通知、展開按鈕、fullpage、macOS 風格 |
| `source/css/_highlight/highlight/index.styl` | highlight.js 專用：行號、diff、table/code 結構 |
| `source/css/_highlight/prismjs/index.styl` | prismjs 專用：token 顏色方案切換 |
| `source/css/_highlight/prismjs/line-number.styl` | prismjs 行號樣式（受 word_wrap 影響） |
| `source/css/_highlight/prismjs/diff.styl` | prismjs caption / scrollbar 微調 |

---

## 設定生效的完整流程

```
_config.yml（syntax_highlighter / highlight / prismjs）
    ↓ Build 時期：Hexo 核心將 markdown code fence 轉成高亮 HTML
themes/butterfly/_config.yml（code_blocks.*）
    ↓ via config.pug 注入 window.GLOBAL_CONFIG.highlight
main.js addHighlightTool()
    ↓ 執行時期：建構 DOM 工具列與互動行為
_highlight/*.styl
    ↓ 最終視覺呈現
```

---

## 發現的所有差異

### 差異一：`_config.yml` 缺少 `exclude_languages`

Hexo-mind 原本缺少，**已補上**：

```yml
highlight:
  ...
  exclude_languages: ['mermaid']   # ← 補上，避免 highlight.js 干擾 mermaid 渲染

prismjs:
  ...
  exclude_languages: ['mermaid']   # ← 補上
```

### 差異二：Butterfly 主題 code block 設定格式錯誤（最關鍵）

Hexo-mind 使用 Butterfly v5，但 `_config.yml` 還在用 v4 舊格式，**已修正**：

```yml
# 修正前（v4 格式，在 v5 中被完全忽略）
highlight_theme: mac
highlight_copy: true
highlight_lang: true
highlight_shrink: false
highlight_height_limit: false
code_word_wrap: false

# 修正後（v5 正確格式）
code_blocks:
  theme: mac
  macStyle: false
  copy: true
  language: true
  shrink: false
  height_limit: false
  word_wrap: false
  fullpage: false
```

---

## 調整設定時應改哪裡

| 目標 | 改哪裡 |
|------|--------|
| 換語法高亮引擎（highlight.js / prismjs） | `_config.yml` → `syntax_highlighter` |
| 加/移除行號 | `_config.yml` → `highlight.line_number` |
| 讓某語言不被高亮（如 mermaid） | `_config.yml` → `highlight.exclude_languages` |
| 換配色主題 | `themes/butterfly/_config.yml` → `code_blocks.theme`（v5）/ `highlight_theme`（v4） |
| 複製按鈕 | `themes/butterfly/_config.yml` → `code_blocks.copy` |
| 控制自動換行 | `themes/butterfly/_config.yml` → `code_blocks.word_wrap` |
| 收合 code block | `themes/butterfly/_config.yml` → `code_blocks.shrink` |
| 自訂樣式 | `themes/butterfly/source/css/_highlight/*.styl` |
| 單篇文章覆蓋收合行為 | 文章 front matter → `highlight_shrink: true/false` |
