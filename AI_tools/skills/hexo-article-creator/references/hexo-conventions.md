# Hexo 專案慣例（Allen 的 Hexo blog）

## Frontmatter 格式

```yaml
---
title: 文章標題
date: YYYY-MM-DD HH:mm:ss
categories: 分類（如 Payment）
top_img: 封面圖網址
cover : 封面圖網址（通常與 top_img 相同）
tags:
    - 標籤一
    - 標籤二
toc:
toc_number:
comments :
---
```

## `{% tabs %}` 分頁標籤

文章正文用 tabs 包裝多個段落分頁：

```markdown
{% tabs 文章唯一識別名 %}

<!-- tab 分頁標題一-->
內容...
<!-- endtab -->

<!-- tab 分頁標題二-->
內容...
<!-- endtab -->

{% endtabs %}
```

## 渲染引擎與 HTML 支援

- 實際生效的渲染器是 `hexo-renderer-pandoc`（專案內雖同時裝了 `hexo-renderer-marked`，但 pandoc 優先接管 `.md`）。可從 `hexo generate` 的 log 出現 `[hexo-renderer-pandoc]` 字樣確認。
- **原始 HTML 會被透傳、不會被消毒過濾**，因此可以在 `.md` 檔案內直接寫 `<style>` 區塊與任意 `<div>` 結構，正常渲染——但 pandoc 對「透傳範圍」的判斷比 marked 嚴格且更容易誤觸發（見下方陷阱）。
- `<style>` 建議放在第一個 tab 開頭，一次定義、全文共用（同一頁面全域生效，不需要每個 tab 各自重複）。

## 其他可用的 Hexo tag plugins

- `{% note info/warning/danger/success %}...{% endnote %}`：內建提示框，適合不需要客製設計的場合。
- `{% btn 'url', label, icon %}`：連結按鈕。
- Mermaid：直接寫 \`\`\`mermaid 區塊即可渲染 flowchart / sequenceDiagram / timeline 等圖表。

## ⚠ Mermaid 常見語法陷阱：避免使用易衝突節點寫法

**症狀**：Mermaid 顯示 `Lexical error on line ...`，常見訊息是指向 API 路徑節點附近，像 `B[/api/carts/create]` 後面連線時報錯，或節點含 `<br/>` 後解析失敗。

**根本原因**：
- `[/.../]` 這種斜線形狀節點語法，遇到本身就含斜線的 API 路徑時，容易與語法邊界衝突。
- 節點內混用 HTML（例如 `<br/>`）在不同 Mermaid 版本與渲染設定下相容性不一致。

**規則（唯一安全做法）**：
- 節點一律優先使用 `id["label"]` 形式，例如 `B["/api/carts/create"]`。
- 節點內不要放 `<br/>`，改用短標題；需要更多資訊時拆成第二張局部圖補充。
- API 路徑、方法名、類別名可放在同一個 quoted label，但字串長度要控制，避免一個節點塞兩行以上長句。

## ⚠ 架構導引圖可讀性規則：不要用超長單鏈取代架構圖

**症狀**：整張圖看起來只是從左到右的長鏈，節點太多時在一般寬度幾乎無法閱讀，也無法表達系統邊界與依賴關係。

**規則（建議預設做法）**：
- 先畫「系統邊界圖」：至少區分外部呼叫端、核心系統、支援依賴（如風控、設定、資料儲存）。
- 再畫「局部放大圖」：只放本篇討論的目標節點與其內部決策流程。
- 單張圖若節點超過 6 個，優先拆圖，不要硬塞成單列長鏈。

## ⚠ 常見排版陷阱：自訂元件的 `table` 選擇器不要用 `width: 100%`（即使沒有外層 wrapper）

**症狀**：內容欄位很窄的表格（例如只有兩三欄、文字很短），即使沒有額外包一層 `xxx-table-wrap` 外框 div，只是自訂元件 `<style>` 裡對 `table` 元素本身寫了 `width:100%`，一樣會撐滿整個文章容器寬度，變成表格左側正常、右側一大片空白的觀感。

**根本原因**：`<table>` 元素預設是 `display:table`，寬度會自動貼合內容（shrink-to-fit）。一旦樣式明確寫 `width:100%`，就會被強制撐到跟父容器（通常是整篇文章寬度）一樣寬，跟表格實際內容需要的寬度無關。

**規則（唯一安全做法）**：自訂元件的 `.xxx table{...}` 規則一律用 `width:auto;max-width:100%;`，不要用 `width:100%`，讓表格寬度貼合實際內容，同時保留 `max-width:100%` 避免內容真的很寬時溢出版面。`assets/components/` 內所有元件（`postgres-elephant-style.html`、`mysql-dolphin-style.html`、`blue-ghost-style.html`、`warm-paper-style.html`、`hacker-matrix-style.html` 等）都已依此規則修正，複製使用時直接沿用即可；若日後新增元件也要套用同樣寫法。

**跟下一則「表格外框 wrapper」陷阱的差異**：這裡是表格本身沒有額外 wrapper div，直接對 `<table>` 元素套用寬度樣式；下一則則是表格外面刻意包一層 `xxx-table-wrap` div 做邊框，兩種情境都要避免 `width:100%`，但修正對象不同（一個改 `table`，一個改 wrapper + `table`）。

## ⚠ 常見排版陷阱：表格外框（table-wrap）不要用 `width: 100%`

**症狀**：內容欄位很窄的表格（例如只有兩欄、文字很短），外層 `xxx-table-wrap` 卻撐滿整個文章寬度，變成右側一大片空白的邊框「大框框」，視覺上非常突兀。

**根本原因**：外層 wrapper 有 `border` 但預設是 block 元素（撐滿容器寬度），內層 `<table>` 又設定 `width: 100%` 跟著撐滿，導致邊框寬度永遠等於文章版面寬度，而不是貼合表格實際內容寬度。

**規則（唯一安全做法）**：
- 外層 wrapper（如 `flow-table-wrap`、`tv-itinerary`）一律加上 `display: inline-block; max-width: 100%;`，讓外框寬度貼合內容。
- 內層 `<table>` 的 `width` 改成 `auto`（不要用 `100%`）。
- `assets/components/flow-banner-note.html` 的 `.flow-table-wrap` 已依此規則修正，複製使用時直接沿用即可；若自訂新的表格外框元件，也要套用同樣寫法。

## ⚠ 常見渲染陷阱：`<div>` 內連續 `<span>` 換行寫，會被 pandoc 誤包一層 `<p>`，讓 `flex` 排版失效

**症狀**：自訂一排用 `display:flex` 橫向排列的 `<span>`（例如一排彩色圓點、糖果圖示、序列標籤），CSS 完全正確，實際渲染出來卻是每個 `<span>` 各自佔一行、直向往下疊，而不是橫向排列。容易誤以為是快取、部署延遲或 CSS 沒生效，但其實都不是——連 `hexo generate` 之後看本機 `public/` 檔案，問題依然存在。

**根本原因**：pandoc 是**逐行**判斷要不要把內容當「原始 HTML 透傳」，依循 CommonMark 的 HTML block 規則，不是「看到最外層是 `<div>` 就整塊都算數」。`<div>` 在 HTML block Type 6 的區塊級標籤清單內，但 `<span>` 不在清單內（`span` 只是行內元素）。所以當 `<div>` 開頭標籤自己一行、緊接著換行後的下一行是「純粹一串 `<span>...</span>`」時：
1. `<div class="xxx">` 這行本身觸發 HTML block，沒問題。
2. 但下一行純 `<span>` 內容，因為不是以區塊級標籤開頭，會被 pandoc 重新判定成**一般 Markdown 段落**，自動包進一層 `<p>`。
3. 結果 `flex` 容器底下多了一層意外的 `<p>` 子元素，`display:flex` 只作用在直接子元素上，裡面真正的 `<span>` 全部變成孫子層級，完全不受 flex 影響，只能各自往下疊。

反過來，如果子層本身也是 `<div>`（例如卡片並排、每個子卡片各自換行寫），完全不會中招——因為 `div` 本身就在區塊級標籤清單內，每一行都能被個別判定為合法的 HTML block 起始行。**這個地雷只發生在「`<div>` 開頭標籤」與「純 `<span>`（或其他非區塊級行內標籤）內容」分行寫的情況。**

**規則（唯一安全做法）**：一排用 `<span>` 構成的橫向排列元件（色點列、糖果／星星圖示列、序列標籤列等），**開頭 `<div>` 標籤跟裡面全部的 `<span>` 一律寫在同一行，不要換行**，即使那一行會變得很長也要保持同行：
```html
<!-- ❌ 錯誤：div 開頭標籤跟 span 內容分行，換行後那一行會被打回段落、自動包 <p> -->
<div class="candy-row">
<span class="candy-piece" style="background:#ffb3c6">🍬</span><span class="candy-piece" style="background:#ffd08a">🍬</span>
</div>
```
```html
<!-- ✅ 正確：開頭標籤與所有 span 內容同一行 -->
<div class="candy-row"><span class="candy-piece" style="background:#ffb3c6">🍬</span><span class="candy-piece" style="background:#ffd08a">🍬</span></div>
```
`assets/components/` 內既有元件若有類似「一排 `<span>`」的結構（例如時間軸的色點、序列標籤），複製使用時也要檢查是否符合這個同行寫法。

**驗證方式**：寫完後除了看 `.md` 原始碼，務必用 Playwright 對該區塊截圖（`element.screenshot()`）或直接檢查 `hexo generate` 產出的 `public/xxx/index.html`，確認該 flex 容器底下沒有被多包一層 `<p>`，肉眼看 `.md` 原始碼無法看出這個問題。

**跟縮排陷阱的差異**：這個陷阱與前面「`<div>` 內縮排達 4 格觸發逐字碼區塊」是兩回事，成因不同（一個是「前導空白是否達到門檻」，一個是「行首標籤是否在 HTML block Type 6 清單內」），排查時不要混淆。

詳細案例分析見 `C:\Users\Allen Lin\Desktop\Tool.dev_ingit\tools.dev\Hexo\div內span換行-pandoc誤包p標籤-flex排版失效bug.md`。

## ⚠ 常見排版陷阱（跟 pandoc 無關，是純 CSS 問題）：`display:flex` 的容器裡不要塞「多個子節點」的混排內容

**症狀一（清單元件）**：清單元件（例如 `hl-checklist`）原本設計是 `<li>{display:flex}` 搭配 `::before` 當勾選圖示，單純文字內容渲染正常。但只要 `<li>` 裡的內容改成「文字＋`<strong>標籤：</strong>`＋`<code>`」這種多個行內元素混排，畫面就會出現詭異的窄欄位逐字換行（例如一段話被拆成好幾個很窄的直排欄位，中文字一個字一行），肉眼很容易看出跑版。

**症狀二（提示框元件）**：提示框元件（例如 `hl-callout`）原本設計是圖示 `<span>` 加上單一段 `<p>` 兩個直接子節點。但只要內文改成「一段 `<p>` 加一個 `<ul class="hl-checklist">` 再加一段 `<p>`」這種多個子節點，畫面就會出現整段內容被拆成好幾欄橫向並排（而不是照順序一行行往下），跟症狀一是同一個成因。

**根本原因**：`display:flex` 只對容器的**直接子節點**生效，並把每一個直接子節點都當成獨立的 flex item 排成一列。容器內如果只有一個文字節點或一個 `<p>`，瀏覽器只會產生一個 flex item，看起來正常；但一旦內容變成多個直接子節點（不論是被行內標籤切開的文字片段，還是多段 `<p>`/`<ul>`），這些節點都會各自變成獨立的 flex item，在沒有設定 `flex-wrap` 時全部擠在同一列裡競爭寬度，畫面上就會出現窄欄位逐字換行或多欄橫向並排的跑版效果。

**規則（唯一安全做法）**：
- 清單元件需要用 `::before` 當作圖示/勾選符號時，`<li>` 本身**不要用 `display:flex`**，改用 `position:relative` 搭配 `padding-left` 留出圖示空間，`::before` 改用 `position:absolute` 定位到左側。這樣 `<li>` 內部維持一般的行內文字排版，`<strong>`、`<code>` 混排也不會被拆成多個欄位。
- 提示框元件如果內文不只一段（例如要加一個清單、或多段文字），一定要把圖示以外的所有內容包進一個 `<div class="hc-body">`，讓 `display:flex` 只看到「圖示 + hc-body」兩個直接子節點，`hc-body` 套用 `flex:1` 占滿剩餘寬度，內部可以自由放多個 `<p>`／`<ul>`，彼此照順序上下堆疊而不會被拆成橫向欄位。

```css
/* ❌ 錯誤：li 用 display:flex，混排 strong/code 會被拆成多個 flex item */
.hl-checklist li{display:flex;gap:12px;align-items:flex-start;}
.hl-checklist li::before{content:"✓";flex:none;width:20px;height:20px;...}
```
```css
/* ✅ 正確：li 用 position:relative + padding-left，::before 用 absolute 定位 */
.hl-checklist li{position:relative;padding:10px 0 10px 32px;}
.hl-checklist li::before{content:"✓";position:absolute;left:0;top:12px;width:20px;height:20px;...}
```

```html
<!-- ❌ 錯誤：hl-callout 內有多個直接子節點（p + ul + p），會被拆成橫向多欄 -->
<div class="hl-callout warn">
<span class="hc-icon">🔍</span>
<p>第一段說明</p>
<ul class="hl-checklist"><li>理由一</li><li>理由二</li></ul>
<p>收尾說明</p>
</div>
```
```html
<!-- ✅ 正確：圖示以外全部包進 hc-body，flex 只看到兩個直接子節點 -->
<div class="hl-callout warn">
<span class="hc-icon">🔍</span>
<div class="hc-body">
<p>第一段說明</p>
<ul class="hl-checklist"><li>理由一</li><li>理由二</li></ul>
<p>收尾說明</p>
</div>
</div>
```

**驗證方式**：清單/提示框類元件如果內文會混排 `<strong>`／`<code>` 等行內標籤，或提示框內文包含多個段落/清單，寫完後務必用 Playwright 截圖或檢視 `hexo generate` 產出的實際頁面（不能只看 `.md` 原始碼判斷），確認同一個 `<li>` 裡的文字是正常一整段換行、同一個 `hl-callout` 裡的內容是上下堆疊，而不是被拆成好幾條窄欄位或橫向並排。

## ⚠ 常見渲染陷阱：`<pre class="...">...</pre>` 程式碼區塊內部不要留空白行

**症狀**：自訂的 `<pre class="xxx-pre">` 深色程式碼區塊，內容用 `<span class="kw">`／`<span class="fn">` 等做語法上色，渲染出來大致正常，但區塊內某個空行之後的內容，直接以逐字 HTML 標籤文字顯示出來（例如畫面上直接冒出 `<span class="kw">if</span> (qty &gt; ...)` 這種字樣），而不是被正確渲染成上色後的程式碼。

**根本原因**：跟本檔另一則「自訂 `<div>` 換行寫 `<span>` 陷阱」同源，都是 pandoc 依 CommonMark 的 HTML block（Type 6）規則逐行判斷「這段還算不算原始 HTML 透傳」。HTML block 一旦遇到**空白行**就會判定為結束，之後的內容改回一般 Markdown 段落解析。程式碼裡常見會在兩個 `if` 判斷之間、或邏輯區塊之間留一行空白讓排版好讀，這行空白就會提前終止 `<pre>` 的透傳範圍，讓後面的 `<span>` 標籤失去透傳資格、被當成純文字逐字印出來。

**規則（唯一安全做法）**：`<pre class="...">...</pre>` 區塊內部**一律不要留空白行**，即使是為了程式碼可讀性想在邏輯區塊之間留空行分隔，也要拿掉，改用註解或直接連續書寫。

```html
<!-- ❌ 錯誤：pre 內部有空白行，空行後的 span 會被當成文字逐字顯示 -->
<pre class="xxx-pre"><span class="kw">if</span> (a == 0)
{
    <span class="kw">return</span> <span class="kw">false</span>;
}

<span class="kw">if</span> (b &gt; a)
{
    <span class="kw">return</span> <span class="kw">true</span>;
}</pre>
```
```html
<!-- ✅ 正確：pre 內部連續書寫，不留空白行 -->
<pre class="xxx-pre"><span class="kw">if</span> (a == 0)
{
    <span class="kw">return</span> <span class="kw">false</span>;
}
<span class="kw">if</span> (b &gt; a)
{
    <span class="kw">return</span> <span class="kw">true</span>;
}</pre>
```

**驗證方式**：寫完後可用簡單腳本掃描 `.md` 檔案，逐行檢查是否處於某個 `<pre class="...">` 到對應 `</pre>` 之間、且該行去除空白後為空字串，若有就要修掉；也可以直接跑 `hexo generate` 後檢查 `public/` 輸出有沒有殘留逐字的 `&lt;span` 字樣。

## 何時用內建 tag plugin，何時用自訂 HTML/CSS

- 若使用者沒有特別視覺需求 → 優先用 `{% note %}` 等內建 tag，維護成本低。
- 若使用者想要客製化風格（例如病歷表、時間軸卡片）→ 用自訂 HTML/CSS，見 `assets/components/` 內的範例元件。

## ⚠ 常見渲染陷阱：自訂 `<div>` 內部一律不要縮排，全部頂格寫

**根本原因**：pandoc 把「一行的前導空白總數（從行首算起的絕對欄位，不是相對父層的縮排量）達到 4 格」視為觸發縮排程式碼區塊的條件。這件事不只在「空行之後」才生效，也**跟巢狀層級無關**——即使每層只縮排 2 格，只要巢狀到第 2 層（2+2=4 格），一樣會觸發；不需要空行、不需要巢狀 `<div>` 自己另起一行，任何情況只要那一行前導空白 ≥ 4 格就會被吃進 `<pre><code>`，並連帶把後面縮排一致的兄弟行（`<ul><li>`、下一個 `<div>`、`<span>` 等）一起吞掉。

**症狀**：畫面上直接出現逐字的 `<div class="...">`、`<table>`、`<span>` 等原始標籤文字（而不是被渲染成真正的區塊/表格/欄位），且外觀通常帶有等寬字型＋一個可橫向捲動的灰底框（因為被當成 `<pre><code>`）。

**已知會誤觸發的情境**（實測驗證過，涵蓋本 skill 所有元件模板曾經踩過的雷）：

1. 容器 `<div>` 直接縮排放巢狀 `<div>`/`<table>`（即使中間沒有空行）。
2. 兩層巢狀各自「看起來合理」的 2 格縮排，疊加後仍達 4 格（例如 `stage-card > stage-head > span`，或 `medchart > medchart-field > div.k`）。
3. 單行內容且標籤有完整開合（如 `<div class="tl-head"><span>...</span></div>`），只要那一行本身縮排達 4 格，一樣會中招。
4. `<div>` 內含空行前後夾雜 `$$...$$` 數學公式，空行後的段落若帶 4 格以上縮排。

**規則（唯一安全做法）**：
- **自訂 `<div>` 區塊內部，所有內容行一律頂格書寫（縮排 0 格），不管巢狀幾層。** 不要用「每層縮排 2 格」的排版習慣，因為疊加兩層就會超過門檻。`assets/components/` 內所有模板都已改成這個寫法，複製時直接照抄縮排即可。
- 唯一例外：`<div>` 開頭標籤與緊接在下一行、且兩者之間完全沒有空行的**第一行**內容，維持 2 格縮排是安全的（因為此時仍屬於 pandoc 對開頭標籤的原始 HTML 透傳範圍）；但只要那一行本身還有更深一層巢狀標籤，仍要頂格，不要疊加縮排。
- 巢狀 `<div>` 若本身是需要獨立成塊的元素（如 `fact-table-wrap`、`table`），建議在其前後各留一個空行，並整體頂格寫。
- 寫完後可用 `hexo generate` 實際產生 `public/` 檔案，搜尋輸出 HTML 有沒有殘留 `&lt;div` / `&lt;table` / `&lt;span` / `<pre><code>` 字樣，作為最終驗證（比肉眼看 `.md` 原始碼更可靠）。

**範例對照**：
```markdown
<!-- ❌ 錯誤：每層縮排 2 格，兩層疊加變 4 格觸發雷 -->
<div class="stage-card">
  <div class="stage-head">
    <span class="stage-name">標題</span>
  </div>
</div>
```
```markdown
<!-- ✅ 正確：全部頂格，不管巢狀幾層 -->
<div class="stage-card">
<div class="stage-head">
<span class="stage-name">標題</span>
</div>
</div>
```

## ⚠ 常見渲染陷阱（更嚴重）：自訂 `<div>` 內不要放 Markdown 表格語法，一律改用原始 `<table>` HTML

**症狀**：跟上一個陷阱不同，這個會直接讓 `hexo generate` / `hexo deploy` **整個 FATAL 崩潰**，而不只是畫面顯示跑版：

```
FATAL Error: Can't find handler for document
    at HandlerList.handlesDocument (...\mathjax-full\js\core\HandlerList.js:60:15)
```

**根本原因**：把 Markdown 的 `| 欄 | 欄 |` 表格語法直接寫在自訂 `<div class="...">` 包裝內、且表格上下有空行時，pandoc 的表格解析器跟「這段在原始 HTML 透傳範圍內」的判斷會衝突，產生破損、標籤沒有正確 open/close 的 HTML。這段破損 HTML 不會讓 `hexo generate` 當下報錯，而是留到後面的 `hexo-filter-mathjax`（`mathjax-full` 的文件解析器）去解析全頁 HTML 時，因為文件結構不合法而直接拋出 `Can't find handler for document`，導致整個網站的 `generate`/`deploy` 都失敗（不只該篇文章）。

**已知會觸發的情境**：
```markdown
<!-- ❌ 錯誤：div 包裝內用 Markdown 表格語法 -->
<div class="flow-table-wrap">

| 欄位 | 說明 |
|:---|:---|
| 內容 | 說明 |

</div>
```

**規則（唯一安全做法）**：
- 自訂 `<div>` 包裝內若要放表格，**一律用原始 HTML `<table><tr><th>/<td></table>` 標籤手寫**，不要用 Markdown 的 `|---|---|` 語法，即使看起來語法本身沒問題。
- `assets/components/flow-banner-note.html` 的 `.flow-table-wrap` 範例目前也是用 Markdown 表格語法示範，複製使用時請自行替換成 `<table>` HTML 寫法（未來會統一修正範例檔）。
- 純 Markdown 表格（沒有包在自訂 `<div>` 裡、前後也不是自訂容器）不受此陷阱影響，可以正常使用。
- 這個陷阱與上一個「縮排陷阱」是兩回事：縮排陷阱只影響單一區塊視覺跑版，這個表格陷阱會讓整個網站建置失敗，優先度更高、務必檢查。
- 寫完後跑一次 `hexo generate`（或 `hexo deploy` 前的 clean+generate），確認沒有出現 `FATAL Error: Can't find handler for document`，作為此陷阱的最終驗證。

## 一般資料表的欄寬與右側空白

**症狀**：一般資料表的外框已經延伸到內容區全寬，但欄位只依內容自然寬度集中在左側，右側留下大片空白，或不同欄位的寬度比例不符合閱讀重點。

**原因**：主題或瀏覽器的自動表格佈局會依儲存格內容計算欄寬。當表格外框設定滿版、欄位沒有明確分配時，短內容欄位可能只佔一小段，剩餘空間不會依預期平均分配。

**規則**：

- 先依表格實際用途設定欄寬比例，不要把所有表格套用同一組比例。
- 需要填滿容器時，對該表格設定 `table-layout: fixed`，並用專屬 class 限定欄寬，例如 `.library-table` 的三欄比例可設定為 `12% / 43% / 45%`。
- 不要把三欄比例套到兩欄或其他結構的表格，避免製造新的空白欄位或壓縮內容。
- 長識別字、方法名與錯誤訊息使用 `overflow-wrap: anywhere` 或等效換行規則，避免欄位被撐寬。
- 若表格只是簡短內容比較，也可以保留 `width:auto`，不要為了視覺滿版而強制拉寬。

**驗證方式**：至少檢查桌面與約 390px 手機寬度的實際 Hexo 頁面，確認欄位填滿比例、長文字換行與水平溢出。不要只看 Markdown 原始碼或只確認 `hexo generate` 成功。

## ⚠ 常見渲染陷阱：自訂「終端機 / 深色 code 區塊」不要用 `<pre><code>`，改用純 `<pre>`

**症狀**：想做深色終端機風格的 ASCII 流程圖（深色背景＋亮色文字），自訂 CSS 也寫了顏色，但實際渲染出來的文字幾乎看不見——背景是深色、文字也是深色，對比度極低，肉眼幾乎讀不到內容。

**根本原因**：Butterfly 主題對 `#article-container pre code` 有自己的一套顏色規則（`color: var(--hl-color)` 等），選擇器是 `#article-container`（ID）疊加兩層元素，優先度很高。就算自訂 class（如 `.pf-term code`）也寫了 `color`，仍可能在某些情境被主題規則覆蓋或疊加出低對比效果；就算加了 `!important` 想蓋掉，也容易因為巢狀在 `<pre><code>` 結構裡而被其他 code 相關規則（字重、text-shadow、background）互相干擾，導致顏色跟預期不符。

**規則（唯一安全做法）**：
- 深色终端机／log 风格的自訂區塊，**不要用 `<pre><code>...</code></pre>`，只用單一 `<pre class="your-class">...</pre>`**（不包 `<code>` 子元素）。少了 `<code>` 這一層，就完全脫離主題 `pre code` 選擇器的管轄範圍，改由你自己的 class 全權控制樣式。
- 區塊內要做局部變色（如標示 `[Step #19]`、DB 來源、成功訊息）時，直接在 `<pre>` 內文字包 `<span class="your-tag">...</span>`，並在 CSS 對每個 tag class 都加 `color: ... !important`，確保不被任何殘留規則覆蓋。
- 背景、字體、行高、`white-space: pre` 等也都直接寫在 `pre.your-class` 這個選擇器上並加 `!important`，不要依賴 `<code>` 層。
- 範例（本 skill 在 Stripe-fee.md 文章中修好的寫法）：
```html
<div class="pf-term">
<div class="pf-term-bar"><span class="pf-term-dot r"></span><span class="pf-term-dot y"></span><span class="pf-term-dot g"></span><span class="pf-term-title">標題</span></div>
<pre class="pf-term-pre"><span class="tstep">[Step #19]</span> 這一行是一般文字
    這一行也是一般文字</pre>
</div>
```
```css
.pf-term { background: #221f36; border-radius: 12px; padding: 18px 22px 22px; }
.pf-term pre.pf-term-pre { margin: 0 !important; background: transparent !important; padding: 0 !important; border: none !important; box-shadow: none !important; font-family: Consolas, monospace !important; white-space: pre !important; color: #f3f1ff !important; text-shadow: none !important; }
.pf-term .tstep { color: #c7b8ff !important; font-weight: 700; }
```
- 寫完後最好用 Playwright 或瀏覽器實際截圖驗證文字是否清晰可讀（肉眼看 `.md` 原始碼沒辦法看出主題 CSS 疊加後的實際對比度），不要只憑 CSS 寫得「看起來應該對」就結案。

## 程式碼區塊：外框與內容底色必須一致

案例：2026-09-09，compression.md 套用 Cozy Meadow 後，RAR 分卷範例的文字區是奶白底，右側卻出現大片米黃色（截圖 aaa_57_0.png）。

**原因**：Butterfly 的程式碼區使用外層 `.highlight` 與內層 `table / .gutter / .code / pre`。內部表格使用 `width:auto` 時，短內容只占左側；外框與內容區底色不同，會使右側留白露出另一塊顏色。

**強制規則**：

- 修改程式碼區外觀時，必須一起檢查外框、內部表格、內容欄、行號欄、工具列與 pre 的背景及文字顏色。
- 程式碼外框與內容區使用同一個語意色彩變數，讓短內容右側的留白保持一致；工具列與行號欄可以有明確、刻意的區隔色。
- 一般資料表的樣式不可未經檢查就套到程式碼內部表格；特別留意 width、背景、斑馬紋、hover、border 與 padding。
- 不要為了遮掉色差，把所有資料表改成滿版寬度。優先統一程式碼外框與內容背景，維持一般表格既有寬度規則。
- 淺色與深色模式都必須使用對應色彩變數，不能只修正淺色模式的固定色碼。

本次已驗證的修正方式（限定在文章樣式範圍）：

```css
#article-container .highlight,
#article-container .highlight .code {
  background: var(--cozy-surface);
}
#article-container .highlight table,
#article-container .highlight pre {
  background: transparent;
}
#article-container .highlight .gutter {
  background: var(--cozy-paper);
}
```

**驗收要求**：

1. 檢查文章中所有程式碼區塊，尤其是只有一至三行、檔名清單等短內容，以及需要橫向捲動的長程式碼。
2. 在桌面、約 390px 手機及深色模式，實際查看包含完整外框、右側留白、工具列與行號欄的截圖。
3. 不得只因建置成功、沒有 console error、圖表正常或沒有水平溢出，就宣告整體視覺正確。
4. 可用 computed styles 輔助比對外框與內容區的實際背景；若涉及透明或繼承背景，需檢查最終視覺結果，不能只比較 CSS 字串。
5. 已部署的工作，須在正式網址重查受影響的所有程式碼區塊；只有本機截圖不算完成線上驗證。
