# 資產處理指南：Icon 與圖片

## 如何判斷是 Icon 還是圖片

從 MCP 回傳的程式碼中，透過以下特徵判斷：

| 特徵 | Icon | 圖片 |
|---|---|---|
| `data-name` | 含 `Icon`、`Arrow`、`Chevron`、`Close`、`Search`、`Check` 等語意詞 | Banner、Thumbnail、Avatar、Photo、Image 等 |
| 尺寸 | 通常為正方形，16 / 20 / 24 / 32px | 非正方形，或明顯較大（>48px） |
| 常數名稱 | `imgCommonChevronUp`、`imgIconSearch` | `imgBanner`、`imgProductThumb` |
| 用途語境 | 按鈕內、標題旁、狀態指示 | 內容區塊、卡片封面 |

---

## Icon 處理

### Step 1 — 找出專案 icon 實作模式

```bash
# 看既有頁面如何引用 icon
grep -rn "Icon" <ClientApp>/src/Page --include="*.tsx" | grep "import" | head -20

# 看 UI Library 有沒有 icon export
grep -rn "Icon" <ClientApp>/src/Component --include="*.tsx" | grep "import" | head -10
```

### Step 2 — 識別實作模式

| 模式 | 範例 import | 範例使用 |
|---|---|---|
| **具名 Icon 元件**（最常見） | `import { ChevronUpIcon } from '@91app/atmos-ui'` | `<ChevronUpIcon className="w-6 h-6" />` |
| **通用元件 + name prop** | `import Icon from '@Component/Icon'` | `<Icon name="chevron-up" size={24} />` |
| **SVG sprite** | `import { ReactComponent as ChevronUp } from '@/icons/chevron-up.svg'` | `<ChevronUp />` |
| **Icon font** | — | `<i className="icon-chevron-up" />` |
| **直接 import SVG** | `import ChevronUpSvg from './chevron-up.svg'` | `<img src={ChevronUpSvg} />` |

### Step 3 — 建立 MCP → Codebase 對應表

從 Phase 1 整理的 icon 清單，逐一搜尋對應名稱：

```bash
grep -rn "ChevronUp\|chevron-up\|chevronUp" <ClientApp>/src --include="*.tsx" | grep "import" | head -5
```

| MCP data-name / 常數名 | Codebase Icon 名稱 | 用法 |
|---|---|---|
| `CommonChevronUp` | `CommonChevronUpIcon` | `<CommonChevronUpIcon />` |
| `CommonClose` | `CommonCloseIcon` | `<CommonCloseIcon />` |
| （依設計稿補充） | （依搜尋結果補充） | — |

### Step 4 — 找不到時的 fallback

1. UI Library 有同名或近似名稱 → 用 UI Library
2. Codebase 有對應 SVG 檔 → import SVG
3. 都沒有 → 用 inline `<svg>`，或標記 `{/* TODO: icon - <name> */}`

---

## 圖片處理

MCP 回傳的圖片 URL 7 天後過期，**一律替換為 placeholder**。

### 尺寸讀取優先順序

1. Tailwind class 的明確數字：`w-[400px] h-[200px]` → 400×200
2. 正方形 class：`size-[48px]` → 48×48
3. Figma 節點的 `width` / `height` 屬性
4. 無法判斷 → 預設 `100x100`

### 替換方式

```tsx
// MCP 原始（不用）
const imgBanner = "https://www.figma.com/api/mcp/asset/...";
<img className="w-[400px] h-[200px]" src={imgBanner} alt="" />

// ✅ 替換為 placeholder
<img src="https://placehold.co/400x200" width={400} height={200} alt="" />
```

**Placeholder 格式**：`https://placehold.co/{width}x{height}`

支援加上背景色與文字：
- `https://placehold.co/400x200/e5e7eb/667079` （背景色/文字色，十六進位不含 #）
- `https://placehold.co/400x200?text=Banner`

### Avatar / 人像的特殊處理

正方形且尺寸 32–64px、`data-name` 含 `Avatar`、`User`、`Profile` → 用圓形 placeholder：

```tsx
<img
  src="https://placehold.co/40x40"
  width={40}
  height={40}
  className="rounded-full"
  alt=""
/>
```