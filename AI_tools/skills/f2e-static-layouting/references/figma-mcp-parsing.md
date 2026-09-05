# Figma MCP 輸出解析指南

> 本文件基於對 `get_design_context` 的實際呼叫觀察，描述真實回傳格式。

---

## get_design_context 回傳結構

回傳的是 **React + Tailwind 參考程式碼**，不是原始設計資料結構。
共四個部分，依序出現：

---

### 部分 1 — Import 宣告

```tsx
import SubAtomHeader from "https://gitlab.xxx.com/.../Table/header.tsx"
import Button from "./index"
```

- 若路徑是完整 URL → **Code Connect** 連結，需在 Codebase 中搜尋對應元件
- 若路徑是相對路徑（`./index`）→ 同樣需確認 Codebase 中的實際位置

---

### 部分 2 — 圖片／Icon 資產常數

```tsx
const imgVector128Stroke = "https://www.figma.com/api/mcp/asset/895578fa-...";
const imgBanner = "https://www.figma.com/api/mcp/asset/2f411c99-...";
```

- 所有 `imgXxx` 都是 Figma 遠端資產，**7 天後過期**，不直接使用
- 常數命名通常對應 Figma layer name（`Vector128Stroke`、`Union`、`Exclude`…）
- 判斷是 icon 還是圖片，見 SKILL.md Phase 1-5

---

### 部分 3 — React + Tailwind 程式碼本體

完整結構範例：

```tsx
export default function Component() {
  return (
    <div
      className="bg-white border border-[#e5e7eb] border-solid flex flex-col p-[20px] rounded-[10px]"
      data-node-id="10003:52709"
      data-name="成效標頭"
    >
      {/* CodeConnectSnippet 包裝的元件 */}
      <CodeConnectSnippet data-node-id="..." data-name="Button" data-snippet-language="React">
        <Button text="進入直播間" variant="outline" size="sm" color="blue" />
      </CodeConnectSnippet>

      {/* 普通 div 結構 */}
      <div className="flex flex-col font-['Noto_Sans_TC:Medium',sans-serif] font-medium text-[#374151] text-[14px] tracking-[1.2px]">
        <p className="leading-[1.8]">直播名稱</p>
      </div>

      {/* 圖片資產引用 */}
      <img className="size-[24px]" src={imgVector128Stroke} alt="" />
    </div>
  );
}
```

**注意事項**：

| 項目 | 說明 |
|---|---|
| `data-node-id` | 開發輔助屬性，切版時全部移除 |
| `data-name` | 對應 Figma layer name，icon 判斷的依據之一 |
| Tailwind class | 色彩使用原始 hex（`text-[#374151]`），需轉換為專案 Token |
| `CodeConnectSnippet` | wrapper 本身不輸出，只保留內部元件 |
| `font-['Noto_Sans_TC:Medium',sans-serif]` | 字型 class，轉換為專案字型設定或直接移除 |

---

### 部分 4 — Design Token 清單（程式碼結尾附加）

真實格式範例：

```
Light/700 ( text-Secondary ): #374151
Light/600 ( text-Tertiary ): #667079
Light/800 ( text-Primary ): #111827
Light/500 ( text-Placeholder ): #A0A6B0
Light/400: #E5E7EB
Light/100: #FFFFFF
Light/Backgroud: #F8F9FC
Light/blue ( text-system ): #3B82F6
Light/green: #1B9A00
14-M = sm: Font(family: "Noto Sans TC", style: Medium, size: 14, weight: 500, lineHeight: 1.8, letterSpacing: 1.2)
14-R = sm: Font(family: "Noto Sans TC", style: Regular, size: 14, weight: 400, lineHeight: 1.8, letterSpacing: 1.2)
12-R = xs: Font(family: "Noto Sans TC", style: Regular, size: 12, weight: 400, lineHeight: 1.5, letterSpacing: 0.4)
```

這份清單是**語意命名系統**，需在 Phase 2 對應到專案的 Token / class：

| MCP 語意名稱 | hex / 規格 | 對應方式（依專案填入） |
|---|---|---|
| Light/800 (text-Primary) | #111827 | ___ |
| Light/700 (text-Secondary) | #374151 | ___ |
| Light/600 (text-Tertiary) | #667079 | ___ |
| Light/500 (text-Placeholder) | #A0A6B0 | ___ |
| Light/400 | #E5E7EB | ___ |
| Light/100 | #FFFFFF | ___ |
| Light/Background | #F8F9FC | ___ |
| Light/blue | #3B82F6 | ___ |
| Light/green | #1B9A00 | ___ |
| 14-M | size 14 / weight 500 / lh 1.8 | ___ |
| 14-R | size 14 / weight 400 / lh 1.8 | ___ |
| 12-R | size 12 / weight 400 / lh 1.5 | ___ |

---

## CodeConnectSnippet 格式

MCP 目前回傳兩種格式：

**格式 A — 單一元件**
```tsx
<CodeConnectSnippet data-node-id="..." data-name="Button" data-snippet-language="React">
  <Button text="查看所有留言" variant="outline" size="sm" color="blue" />
</CodeConnectSnippet>
```

**格式 B — 多選項（選最合適的一個）**
```tsx
<CodeConnectSnippet
  data-snippet-language="React"
  options={[<Button variant="primary" />, <Button variant="secondary" />]}
/>
```

**處理規則**：
1. 移除 `<CodeConnectSnippet>` wrapper
2. 從頂部 import 宣告取得元件來源路徑
3. 在 Codebase 搜尋對應元件，改用本地 import
4. 找不到時 fallback 到 UI Library

---

## 節點過大的處理

當節點超出 context 限制，MCP 回傳稀疏 metadata（XML 格式）並出現提示：

```
IMPORTANT: The design was too large to fit into context with get_design_context.
Instead you have received a sparse metadata response, you MUST call get_design_context
on the IDs of the sublayers to get the full code.
```

處理步驟：
1. 從 metadata 讀取子節點 ID 清單
2. **逐一**對每個子節點呼叫 `get_design_context`
3. 分批呼叫，避免單次 context 再次超限（先呼叫較小的葉節點）