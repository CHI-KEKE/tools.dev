# UI 清查指南

## 為什麼需要 Phase 0

Figma URL 可能指向：
- 單一頁面 frame → 直接進 Phase 1
- 一個 section / 畫布區域 → 內含多個 frame、Modal、state variants，必須先清查

跳過這個步驟，很容易漏切 Modal、或把設計師的「狀態展示」誤當成多個獨立頁面。

---

## 節點分類規則

### 要切的節點

**頁面（frame，寬度 ~1440px）**
- 代表一個完整頁面
- 通常包含 header、sidemenu、breadcrumbs、content area
- 策略：個別呼叫 `get_design_context`

**Modal / Dialog（frame，寬度 400–800px）**
- 通常有 shadow、rounded corner
- 可能含多個步驟（step 1 / step 2）
- 策略：個別呼叫 `get_design_context`，多步驟用 step state 控制

**instance 群組（同名多個 instance）**
- 代表同一個 UI 在不同互動狀態下的呈現
- **需要實作 state 切換 + 條件渲染**
- 每個 instance = 一個 state，需確認觸發條件
- 策略：與使用者確認 state 流程後，統一在同一元件中處理
- 範例：`點數折抵設定 × 3`（Switch 關閉 / Switch 開啟空表 / Switch 開啟有資料）

**hidden=true 的子節點**
- 設計師用 hidden 標記「這個狀態下不顯示」的內容
- 通常對應某個 state 的條件渲染
- 策略：確認觸發條件，納入對應 instance 的 state 流程

---

### 不切的節點（過濾掉）

| 節點類型 | 說明 |
|---|---|
| `vector` | 設計師畫的流程連接箭頭 |
| `section`（含規格文字、圖片） | 設計師的標注說明區，如「規格需求」 |
| section 名稱本身 | 畫布分區標籤（如「多店」「單店」），**不是功能名稱** |
| 純 symbol / 輔助線 frame | 設計師的對齊輔助工具 |
| `rounded-rectangle` 密集排列 | grid 輔助線（見 `hidden=true` 的輔助線 frame） |

---

## instance 群組判斷流程

```
發現同名 instance × N 個
    ↓
比對各 instance 的截圖差異
    ↓
差異是 UI 狀態（Switch on/off、有無資料、步驟不同）？
    ↓ YES
    這是互動狀態群組，需確認 state 流程：
    1. 每個 instance 代表什麼狀態？
    2. 觸發條件是什麼操作？
    3. 有沒有 Modal 介入？
    4. hidden=true 的子節點屬於哪個 state？
    ↓
    統一在一個 React 元件中，用 state + 條件渲染實作
```

---

## 常見 Figma 畫布結構模式

### 模式 A：單一頁面 URL
```
URL node-id → 直接是一個 1440px frame
→ 跳過 Phase 0，直接 get_design_context
```

### 模式 B：功能流程展示區
```
Section「功能名稱」
  ├── frame「頁面-狀態A」（1440px）← 頁面
  ├── frame「頁面-狀態B」（1440px）← 同頁面的另一個 state
  ├── instance「Modal-步驟1」（672px）← Modal
  ├── instance「Modal-步驟2」（672px）← Modal 的下一步
  └── vector（連接箭頭）← 忽略
```

### 模式 C：設計師說明區 + 流程圖
```
Section「規格需求」
  ├── rounded-rectangle（截圖區塊）← 忽略
  └── text（說明文字）← 忽略
```

---

## 與使用者確認的清單範本

```
發現以下 UI，請確認切版範圍：

頁面（x 1）
  P1. 點數設定 — node-id: 2297:12741 — 主頁面

互動狀態（需 state 切換）
  S1. 點數折抵設定區塊 × 2 個 instance
      - 狀態 A（Switch 關閉）：僅顯示 Switch
      - 狀態 B（Switch 開啟）：Switch + Table
      - Table 內含 2 個子狀態：空狀態 / 有資料列
      推測觸發：Switch 切換

Modal（x 1）
  M1. 折抵設定 — node-id: 2297:12327 — 2 步驟
      Step 1：選擇門市（Checkbox 樹狀清單）
      Step 2：設定折抵比例（4 個 input）
      推測觸發：點「新增設定」按鈕

以上全部切版，還是只切部分？
各 instance state 的觸發條件確認後才開始實作。
```