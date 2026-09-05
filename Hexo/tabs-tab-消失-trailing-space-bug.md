# Hexo Butterfly Tabs：Tab 區塊消失 — 尾部空格 Bug

## 問題描述

在使用 Hexo Butterfly 主題的 `{% tabs %}` 標籤時，某個 tab 在網頁上完全看不到，其他 tab 正常顯示。

---

## 根本原因

Butterfly 主題的 `scripts/tag/tabs.js` 使用以下正則表達式解析 tab：

```javascript
const tabBlock = /<!--\s*tab (.*?)\s*-->\n([\w\W\s\S]*?)<!--\s*endtab\s*-->/g
```

**關鍵：`-->\n`**，正則要求 `-->` 後面**緊接換行符**，中間不能有任何字元（包含空格）。

---

## 錯誤範例

```markdown
<!-- tab WAF 動作模式 count block--> 
```

`-->` 後面藏了一個**肉眼不易察覺的尾部空格（trailing space）**，導致：

- regex 無法匹配這個 tab
- 整個 tab 區塊（標籤 + 內容）被靜默跳過
- 網頁上該 tab 完全消失，不報錯

---

## 正確寫法

```markdown
<!-- tab WAF 動作模式 count block-->
```

`-->` 後面**直接換行**，無任何多餘字元。

---

## 比對

| 狀況 | 原始內容 | 結果 |
|------|---------|------|
| ❌ Bug | `block--> ` + 換行 | regex 不匹配 → tab 消失 |
| ✅ 正常 | `block-->` + 換行 | regex 正常匹配 → tab 顯示 |

---

## 排查方式

1. 用編輯器開啟 `.md` 檔案，開啟「顯示不可見字元」功能
2. 檢查所有 `<!-- tab ... -->` 結尾是否有多餘空格
3. 或用以下指令掃描：

```bash
# 找出有 trailing space 在 --> 前後的 tab 行
grep -n "tab .*--> $" your-post.md
```

---

## 常見發生情境

- 複製貼上 tab 語法時，不小心帶入尾部空格
- 編輯器自動補空格（某些 IDE 有此行為）
- 從其他地方貼上內容後格式調整殘留

---

## 相關檔案

- Bug 修復位置：`Hexo/source/_posts/DeepType/Cyber/WAF.md` 第 16 行
- Tabs 解析邏輯：`themes/butterfly/scripts/tag/tabs.js` 第 10 行
