# Hexo Pandoc 渲染：`<div>` 內連續 `<span>` 換行寫，會被誤包一層 `<p>`，導致 flex 排版失效

## 問題描述

在自訂 HTML 卡片（例如「糖果分佈圖」「隔板法示意圖」「序列標籤列」）裡，用 `display:flex` 讓一排 `<span>` 橫向排列，結果實際渲染出來卻是**每個 `<span>` 各自佔一行、直向往下疊**，而不是預期的橫向排列。

CSS 本身完全正確（`.candy-row { display:flex; flex-wrap:wrap; ... }`），且同一篇文章裡「開頭標籤與內容寫在同一行」的區塊（例如 `.candy-hero-title`）卻是正常的——問題只發生在特定寫法上，容易被誤以為是瀏覽器快取、部署延遲，或是 CSS 沒生效，但其實三者都不是。

---

## 根本原因

Hexo 這個部落格實際生效的渲染器是 `hexo-renderer-pandoc`，不是常見的 `marked`。pandoc 判斷一段內容要不要當成「原始 HTML 透傳」，依循的是 CommonMark 規格裡的 **HTML block（原始 HTML 區塊）判定規則**，而不是單純「看到 `<div>` 就整段當 HTML」。

CommonMark 對 HTML block 定義了好幾種類型，這裡牽涉到最關鍵的兩種：

- **Type 6**：一行若是以 `<div>`、`<table>`、`<ul>` 等特定「區塊級標籤清單」中的標籤開頭，就會啟動一個 HTML 區塊，之後的每一行都會被當作原始 HTML，直到遇到空行為止。
- **Type 7**：一行如果是「單獨一個完整的標籤」（開始或結束標籤自成一行、前後只有空白），也會啟動 HTML 區塊——但條件比 Type 6 嚴格很多，而且**不能中斷正在進行中的段落（paragraph）**。

關鍵在這裡：`<span>` 不在 Type 6 的區塊級標籤清單中（`span` 是行內元素，不是區塊元素）。所以當一行的內容是「好幾個 `<span>...</span>` 排在一起」，這一行本身**不會被判定成 HTML block 的起始行**。

於是實際發生的事情是：

1. `<div class="candy-row">` 這一行本身，因為 `div` 在清單裡，成功觸發 Type 6 HTML block。
2. 但緊接著換行後的下一行「純粹是一串 `<span>...</span>`」，pandoc 在往下掃描、重新確認每一行內容型態時，判斷這一行不符合任何 HTML block 的啟動條件，於是把它當成**一般 Markdown 段落文字**來處理。
3. Markdown 段落規則會自動把這行文字包進一個 `<p>...</p>` 裡（這是 Markdown 把純文字轉成段落的標準行為，即使文字裡混雜著行內 HTML 標籤也一樣）。
4. 結果就是 `.candy-row` 這個 `flex` 容器底下，實際上只有「一個」子元素：那個被自動生成的 `<p>`。`display:flex` 的橫向排列規則，是作用在**直接子元素**上的，容器裡真正的一堆 `<span>` 全部被關在 `<p>` 裡面、變成 `<p>` 的孫子層級，自然完全不受 flex 規則影響，只能照 `<span>` 自身 CSS（`display:flex` 讓每個 `<span>` 變成 block-level 的小容器）一個個往下疊。

反過來看 `.candy-hero-title` 為什麼沒事：它的寫法是 `<div class="candy-hero-title"><span>...</span>...文字</div>`，**開頭標籤跟所有內容都寫在同一行**。這一行本身仍然是以 `<div` 開頭，符合 Type 6 的啟動條件，所以整行都被當成原始 HTML 透傳，不會被重新判定、也就不會被包 `<p>`。

一句話總結：**pandoc 是「逐行」判斷要不要繼續當作原始 HTML，不是「看到最外層是 div 就整塊都算數」**。只要某一行本身不是以區塊級標籤開頭，就有可能被打回 Markdown 段落處理，即使它的父層是一個貨真價實的 `<div>`。

---

## 錯誤範例

```html
<div class="candy-row">
<span class="candy-piece" style="background:#ffb3c6">🍬</span><span class="candy-piece" style="background:#ffd08a">🍬</span><span class="candy-piece" style="background:#c9b6ef">🍬</span>
</div>
```

實際被 pandoc 轉出來的結果（簡化示意）：

```html
<div class="candy-row">
<p><span class="candy-piece" ...>🍬</span><span class="candy-piece" ...>🍬</span><span class="candy-piece" ...>🍬</span></p>
</div>
```

`.candy-row` 底下多了一層意外的 `<p>`，`flex` 排列因此失效。

---

## 正確寫法

**規則：`<div>` 開頭標籤跟它底下所有的 `<span>` 內容，一律寫在同一行，不要換行。**

```html
<div class="candy-row"><span class="candy-piece" style="background:#ffb3c6">🍬</span><span class="candy-piece" style="background:#ffd08a">🍬</span><span class="candy-piece" style="background:#c9b6ef">🍬</span></div>
```

這樣整行都是以 `<div` 開頭，pandoc 會把它判定為 Type 6 HTML block 的起始行，之後不會再重新逐行判斷型態，整段都當原始 HTML 透傳，`flex` 排列正常生效。

> 補充：如果子元素本身是 `<div>`（例如 `.candy-split` 裡面包好幾個 `.candy-kid`），即使每個子 `<div>` 各自換行寫，也不會有這個問題——因為 `div` 本身就在 Type 6 的區塊級標籤清單裡，每一行仍然會被個別判定為合法的 HTML block 起始行。**這個地雷只發生在子層是 `<span>`（或其他非區塊級的行內標籤）、而且該行沒有夾雜任何區塊級標籤時。**

---

## 比對

| 寫法 | 該行是否以區塊級標籤開頭 | pandoc 判定 | flex 排列結果 |
|---|---|---|---|
| `<div class="candy-row">` + 換行 + 純 `<span>` 一整行 | 否（span 行內元素不在清單內） | 被打回 Markdown 段落，自動包 `<p>` | ❌ 失效，直向堆疊 |
| `<div class="candy-row">` + 全部 `<span>` 同一行 | 是（整行以 `<div` 開頭） | 判定為 HTML block，原始透傳 | ✅ 正常橫向排列 |
| `<div class="candy-split">` + 換行 + 多個子 `<div class="candy-kid">` 各自一行 | 是（每行都以 `<div` 開頭） | 每行都判定為 HTML block | ✅ 正常 |

---

## 排查方式

1. 打開 `hexo generate` 後的 `public/xxx/index.html`，搜尋預期是 flex 容器的 class（例如 `candy-row`），檢查底下是否多了一層不該存在的 `<p>`。
2. 若發現多了 `<p>`，回頭看 `.md` 原始碼裡，該容器 `<div>` 開頭標籤後面**緊接的下一行內容第一個字元是不是 `<span>`（或其他非區塊級標籤）**——這就是觸發點。
3. 修法統一：把該區塊「開頭 `<div>` 標籤＋全部行內內容」合併成同一行書寫，不要跨行。
4. 用 Playwright 對該區塊截圖（`element.screenshot()`），肉眼確認排列方向是否符合預期，比單看 `.md` 原始碼或只看 CSS 更可靠。

---

## 常見發生情境

- 為了讓 `.md` 原始碼好讀，把一長串 `<span>` 標籤刻意換行、分組（例如按顏色分組換行），結果每組換行後的內容都各自被打回段落處理。
- 序列標籤列（如 `候選結果 → A`、`第 2 筆 → B` 這類一排小標籤）為了排版方便逐行寫一個 `<span>`，同樣會中招。
- 這個地雷跟另一個已知的「`<div>` 內縮排達 4 格觸發逐字碼區塊」陷阱容易混淆，但成因完全不同：縮排陷阱是「前導空白達到門檻」，這個陷阱是「行首標籤是否在 Type 6 清單內」，兩者要分開排查。

---

## 相關檔案

- 案例位置：`Hexo-mind/source/_posts/重複組合.md`（`.candy-row`、`.candy-bars-demo`、`.candy-seq` 三處皆曾中招）
- 渲染引擎：`hexo-renderer-pandoc`（可從 `hexo generate` log 出現 `[hexo-renderer-pandoc]` 字樣確認目前生效的渲染器）
- 參考規格：[CommonMark Spec – HTML blocks](https://spec.commonmark.org/0.31.2/#html-blocks)（Type 6、Type 7 判定條件）
