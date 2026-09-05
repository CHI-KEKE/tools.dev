---
name: f2e-static-layouting
description: |
  根據 Figma 設計稿執行靜態切版的 Agent Skill。輸入 Figma URL，透過 Figma MCP 抓取設計資料，
  依序分析 Design Token、UI 元件庫、Codebase 共用元件，制定切版策略，準備 Mock 資料，最後產出靜態頁面。

  **觸發條件**：使用者提供 Figma URL 並要求切版、UI 實作、「依照設計稿」時啟動。
  不限頁面類型（列表、表單、詳情、Dashboard、空白頁…）；不限技術棧或 UI Library。

compatibility:
  required_mcps:
    - figma (get_metadata / get_design_context)
  recommended_tools:
    - bash (codebase 探索)
    - file 讀寫工具
    - browser / playwright (切版驗證)
---

# Figma 靜態切版 Skill

## ⛔ 全域禁止事項

在開始任何步驟前，請先確認以下禁止事項：

1. **禁止載入其他 Skill**（尤其是 `frontend-design`）。輸出格式由 Codebase 技術棧決定，不是 HTML。
2. **禁止在 Phase 0 確認前呼叫 `get_design_context`**。
3. **禁止在 Phase 2 完成前進入 Phase 3**。沒有讀 Codebase 就不能制定策略。
4. **禁止在 Phase 3 使用者確認前開始切版**。

---

## 執行流程

```
[Figma URL]
    ↓
Phase 0: 清查 UI 清單
         ── HARD STOP：輸出清單，等待使用者確認後才繼續 ──
    ↓
Phase 1: 讀 Figma（逐一讀每個確認的 UI）
    ↓
Phase 2: 讀 Codebase
         ── 此 Phase 不可跳過，未完成不得進入 Phase 3 ──
    ↓
Phase 3: 制定切版策略
         ── HARD STOP：輸出策略，等待使用者確認後才繼續 ──
    ↓
Phase 4: 準備 Mock 資料
    ↓
Phase 5: 執行切版
```

---

## 前置：解析 Figma URL

從 URL 萃取兩個參數：

- **fileKey**：`/design/` 或 `/file/` 後的字串
- **nodeId**：`node-id=` 的值（`73-665` 與 `73:665` 都可接受）

---

## Phase 0 — 清查 UI 清單

> Figma URL 可能指向一個 section 或畫布區域，內含多個頁面、Modal、State 變體。**必須先盤點，不能假設只有一個 UI。**

### 0-1. 用 get_metadata 掃描結構

```
get_metadata({ fileKey, nodeId })
```

`get_metadata` 只回傳輕量 XML 骨架，**不佔 context**，專門用於此步驟。
此時**禁止呼叫 `get_design_context`**。

### 0-2. 分類每個子節點

依以下規則識別，詳細判斷邏輯見 `references/ui-enumeration.md`：

| 節點特徵 | 類型 | 切版策略 |
|---|---|---|
| `frame`，寬度 ~1440px | **頁面** | 列入清單 |
| `frame`，寬度 400–800px | **Modal / Dialog** | 列入清單 |
| `instance`，同名多個 | **UI 互動狀態** | 代表需要 state 切換，列入清單並標記需確認觸發條件 |
| 子節點含 `hidden=true` | **State 變體內容** | 歸入對應 instance 的 state 流程 |
| `vector` | 流程連接箭頭 | 忽略 |
| `section` 含規格文字 | 設計師標注區 | 忽略 |
| section 名稱（如「多店」）| 畫布分區標籤 | **不是功能名稱**，忽略，以子節點為準 |

### 0-3. ── HARD STOP ──

整理所有節點後，**必須輸出以下格式的清單，然後停止等待使用者回覆。在收到明確確認之前，不得呼叫 `get_design_context` 或進行任何後續步驟。**

```
發現以下 UI，請確認切版範圍：

頁面（x N）
  P1. [名稱] — [node-id] — [說明]

Modal / Dialog（x N）
  M1. [名稱] — [node-id] — [步驟數 / 說明]

互動狀態（需 state 切換）
  S1. [名稱] × N 個 instance — 推測觸發條件：___

以上全部切版，還是只切部分？
請確認後我再讀取每個 UI 的設計細節。
```

收到使用者確認後，才針對每個確認的 UI 進入 Phase 1。

---

## Phase 1 — 讀 Figma

針對 Phase 0 **使用者確認的每個 UI**，逐一呼叫：

```
get_design_context({ fileKey, nodeId, clientLanguages, clientFrameworks })
```

> ✅ 截圖已內含在回傳結果中，不需另外呼叫 `get_screenshot`。
> 若需節省 context，可傳 `excludeScreenshot: true`。

**節點過大時**：當 MCP 回傳稀疏 XML metadata 並出現提示：
> *"The design was too large to fit into context... you MUST call get_design_context on the IDs of the sublayers"*

此時需對每個子節點 ID **個別呼叫** `get_design_context`，分批取得完整資料。

### 1-2. 理解 MCP 回傳格式

`get_design_context` 回傳的是 **React + Tailwind 的參考程式碼**，不是原始設計資料。
這份程式碼是「起點」，**必須依照目標 Codebase 的技術棧轉換**，不能直接複製貼上。

回傳內容包含四個部分：

| 部分 | 說明 |
|---|---|
| **import 宣告** | 含 CodeConnect 連結的元件 import（路徑可能是 URL） |
| **圖片資產常數** | `const imgXxx = "https://www.figma.com/api/mcp/asset/..."` |
| **React + Tailwind 程式碼** | 帶有 `data-node-id` 屬性的完整結構 |
| **Design Token 清單** | 附在程式碼結尾，含語意名稱與對應值 |

### 1-3. 萃取 Design Token

MCP 在程式碼末尾附上 Token 清單：

```
Light/700 ( text-Secondary ): #374151
Light/600 ( text-Tertiary ): #667079
Light/800 ( text-Primary ): #111827
14-M = sm: Font(family: "Noto Sans TC", style: Medium, size: 14, weight: 500, lineHeight: 1.8)
```

這些是語意名稱，**在 Phase 2 讀既有頁面時對應到專案實際 Token**。

### 1-4. 處理 CodeConnectSnippet

```tsx
<CodeConnectSnippet data-name="Button" data-snippet-language="React">
  <Button text="儲存" variant="solid" size="lg" color="blue" />
</CodeConnectSnippet>
```

處理規則：
1. 移除 `<CodeConnectSnippet>` wrapper，只保留內部元件
2. import 路徑若是 URL，在 Codebase 中搜尋對應元件並改用本地路徑
3. Codebase 找不到才考慮 UI Library 或自行實作

### 1-5. 資產識別：區分 Icon 與圖片

- **Icon**（`data-name` 含 Icon／Chevron／Arrow 等，尺寸 16–32px 正方形）→ Phase 2-4 查找 Codebase icon，不用 placeholder
- **圖片**（Banner、Avatar 等）→ 依尺寸換成 `https://placehold.co/{w}x{h}`

詳細規則見 `references/assets-handling.md`。

### 1-6. 分析視覺結構

閱讀程式碼與截圖，記錄：

```
頁面類型：___
主要區塊（section）：___
互動元素清單：___
資料來源推測：___
特殊需求：___（分頁、篩選、Modal…）
CodeConnectSnippet 元件清單：___
Icon 清單：___
```

---

## Phase 2 — 讀 Codebase

> ⛔ **此 Phase 不可跳過。** 未完成 Phase 2 不得進入 Phase 3。
> 輸出格式由 Codebase 技術棧決定，**不得擅自輸出 HTML 或使用其他 Skill 的輸出規範**。

### 2-1. 了解技術棧

```bash
cat <project-root>/package.json | grep -E '"react|"vue|"angular|"tailwind|"sass|"styled|"mui|"antd|"shadcn|"chakra|"react-hook-form|"formik|"zod'
```

關鍵資訊：前端框架、UI Library、表單方案、CSS 方案。

### 2-2. 了解目錄結構

```bash
ls <ClientApp>/src/
```

找到：頁面目錄、共用元件目錄、路由設定、Layout、Hooks。

### 2-3. 盤點共用元件與建立 Token 對應表

```bash
ls <ClientApp>/src/Component/
grep -n "className" <similar-page>/index.tsx | head -30
```

建立 **MCP Token → 專案 Token** 對應表：

| MCP Token 名稱 | hex 值 | 專案使用方式 |
|---|---|---|
| Light/800 (text-Primary) | #111827 | （依專案填入） |
| Light/700 (text-Secondary) | #374151 | （依專案填入） |
| 14-M | size 14 weight 500 | （依專案填入） |

### 2-4. 分析 Icon 實作方式

Icon 是 Design System 的一環，**必須用 Codebase 的 icon 機制**。

步驟：找出 icon 實作模式 → 對照 icon 清單搜尋對應名稱 → 找不到依 fallback 處理。

詳細操作見 `references/assets-handling.md`。

### 2-5. 找最相近的既有頁面

```bash
head -30 <similar-page>/index.tsx
grep -n "className" <similar-page>/index.tsx | head -20
```

學習：UI Library import 路徑、包裝元件 API、CSS Token 命名慣例。

### 2-6. 確認路由格式

```bash
head -30 <routeConfig>
```

---

## Phase 3 — 制定切版策略

### 3-0. 確認工作類型

**這是新頁面，還是現有頁面的擴充？**

| 工作類型 | 判斷方式 | 對應做法 |
|---|---|---|
| **新增頁面** | Codebase 中沒有對應 Page 目錄 | 建立全新目錄與檔案，新增 Route |
| **迭代既有頁面** | 已有對應 Page 目錄 | 只修改差異部分，不重寫整頁 |

若未說明，主動詢問：

```
這個設計稿是新頁面，還是現有頁面的修改？
如果是修改，請告訴我對應路徑或 Route。
```

**迭代模式**額外步驟：讀取現有程式碼，整理差異清單（新增／修改／移除／型別變更）。

### 3-0b. 確認 State 流程（有 instance 群組時必做）

針對每個 instance 群組確認：

```
1. 每個 instance 代表什麼狀態？（預設是哪個？）
2. 各狀態的觸發條件？（點什麼 / 操作什麼）
3. hidden=true 的子節點屬於哪個狀態？
4. 涉及 Modal 時：
   - 哪個按鈕開啟？
   - 有幾個步驟？各步驟觸發條件？
   - Modal 確認後，頁面哪個 state 改變？
```

整理成 State 流程圖：

```
[初始狀態] ─→ 操作 ─→ [狀態 B] ─→ 操作 ─→ [狀態 C]
```

### 3-1. 檔案結構規劃

**新增模式**：

```
# 簡單頁面
Page/<featureName>/
├── index.tsx
├── type.ts
└── mock.ts

# 中型（3+ sections）
Page/<featureName>/
├── index.tsx
├── <SectionA>.tsx
├── <SectionB>.tsx
├── type.ts
├── mock.ts
└── constants.ts

# 複雜（有 Modal、子流程）
Page/<featureName>/
├── index.tsx
├── <SectionA>.tsx
├── <Modal>.tsx
├── hooks/
├── type.ts
├── mock.ts
└── constants.ts
```

**迭代模式**：只列需要異動的檔案與改動說明。

### 3-2. 元件選用策略

**決策原則**（依序）：
1. Codebase 已有包裝元件 → 直接用
2. CodeConnectSnippet 有元件 → Codebase 搜尋後使用
3. UI Library 有對應元件 → 用 UI Library
4. 都沒有 → 自行實作

### 3-3. Mock 資料策略

| 情境 | Mock 策略 |
|---|---|
| 新增列表頁 | 至少 5 筆，涵蓋不同狀態值 |
| 新增表單頁（新增模式） | 空的 `defaultValues` |
| 新增表單頁（編輯模式） | 預填資料的 mock object |
| 新增詳情頁 | 一筆完整的 mock object |
| 新增 Dashboard | 各指標數值 + 圖表假資料 |
| 迭代既有頁面 | 在現有 mock 補充新欄位，不替換整份資料 |

### 3-4. ── HARD STOP ──

**必須輸出以下確認清單，然後停止等待使用者回覆。在收到明確確認之前，不得建立任何檔案或開始切版。**

```
工作類型：新增頁面 / 迭代既有頁面（路徑：___）
差異範圍：___（迭代模式）
檔案異動清單：___
主要元件：___（含 CodeConnectSnippet 對應結果）
State 流程：___
Mock 策略：___
Route path：___（新增模式）

確認後開始執行？
```

---

## Phase 4 — 準備 Mock 資料

先建立型別與 mock，再寫元件。

```typescript
// type.ts
export interface IXxxItem { ... }
export interface IXxxFormValues { ... }
export type TXxxStatus = 'active' | 'inactive' | ...
```

```typescript
// mock.ts — 語意化假資料，不要 lorem ipsum
export const MOCK_LIST: IXxxItem[] = [ /* 3–5 筆 */ ]
export const MOCK_DETAIL: IXxxItem = { ... }
export const MOCK_FORM_DEFAULT: IXxxFormValues = { ... }
```

---

## Phase 5 — 執行切版

按以下順序建立檔案：

**`type.ts` → `mock.ts` → `constants.ts` → 子元件 → `index.tsx` → route**

### MCP 程式碼轉換步驟

1. **移除 `data-node-id` 屬性**
2. **替換 CodeConnectSnippet**：移除 wrapper，改為 Codebase 本地路徑
3. **轉換 Tailwind class**：依 Phase 2 對應表，`text-[#374151]` → 專案 Token
4. **轉換框架語法**：依 Codebase 技術棧調整

### 執行原則

- **不寫 API 邏輯**，所有資料來自 mock
- **不寫業務邏輯**，互動只做 UI 層（state 切換、onChange）
- **對齊既有頁面 pattern**，包含 className 命名、元件 API 用法
- 遇到不確定，**先讀既有頁面原始碼**，不要猜測

### TODO / FIXME 標記規範

**每一處跳過的實作都必須留下標記。**

| 標記 | 使用時機 |
|---|---|
| `// TODO:` | 功能暫時跳過（API、驗證、i18n、權限、邏輯） |
| `// FIXME:` | 暫時用替代方案（icon 找不到、Token 不確定、元件缺失） |

詳細格式與範例見 `references/todo-conventions.md`。

**切版完成時，在 `index.tsx` 頂部加上整頁 TODO 總表：**

```tsx
/**
 * TODO List（靜態切版 → 正式實作）
 *
 * [ ] API    - GET  /api/xxx/list
 * [ ] API    - POST /api/xxx
 * [ ] Valid  - 補上表單驗證 schema
 * [ ] Auth   - 依權限控制按鈕 disabled
 * [ ] i18n   - 中文字串替換為 t('key')
 * [ ] FIXME  - XxxIcon 找不到（共 N 處）
 */
```

### 驗證

- [ ] 頁面正常 render，無 console error
- [ ] 視覺與 Figma 截圖大致吻合
- [ ] 互動元素可操作
- [ ] Route 可正常導覽

---

## 附錄

- `references/figma-mcp-parsing.md` — MCP 輸出格式解析
- `references/ui-enumeration.md` — 節點分類規則與清查流程
- `references/assets-handling.md` — Icon／圖片處理
- `references/component-decision.md` — 元件選用決策
- `references/todo-conventions.md` — TODO/FIXME 標記規範