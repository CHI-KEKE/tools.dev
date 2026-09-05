---
name: doc-diagram-optimizer
description: 將文件、技術文章、Markdown 筆記中的圖解區段升級為精美的視覺圖示。能識別 ASCII 框線表、bash 代碼塊偽裝的流程圖、plain text 表格等低品質圖解，依據內容語意選擇最適合的圖表類型（mermaid flowchart/graph/sequenceDiagram/stateDiagram 等）或 Markdown Table，並套用一致的語意配色系統。當使用者說「優化文件圖表」、「把這段改成精美圖示」、「美化這篇文章」、「把 ASCII 圖轉成 mermaid」、「這段用什麼圖比較好」、「diagram upgrade」、「圖解優化」、「圖示優化」時觸發此 skill。也適用於為新文章從零規劃圖解架構。
---

# Doc Diagram Optimizer

## 概覽

掃描文件中所有「圖解候選區段」，依內容語意選擇最佳圖表類型，並套用語意配色系統，將低品質圖解升級為精美的 mermaid 圖表或 Markdown Table。

## 工作流程

```
Step 1：掃描  → 找出所有升級候選
Step 2：分類  → 判斷每段的資訊本質
Step 3：選型  → 用「選圖決策樹」決定圖表類型
Step 4：實作  → 套用語意配色，寫出 mermaid / Markdown Table
Step 5：驗證  → 確認每張圖「只回答一個問題」
```

---

## Step 1：識別升級候選

以下模式是升級目標，依優先序排列：

| 模式 | 識別方式 | 問題 |
|:---|:---|:---|
| `bash` 代碼塊裡有 `│`, `▼`, `→`, `↓` | 語法高亮告訴瀏覽器「這是程式碼」，但內容是流程 | 語意錯配 |
| Plain text 框線表（`┌┬┐ ├┼┤ └┴┘`） | 沒有代碼塊，用 Unicode 畫線 | 手動對齊、無響應式 |
| `bash` 代碼塊裡純粹是比較/列舉資料 | 不含任何 shell 指令 | 應為 Markdown Table |
| 樹狀縮排結構在 `bash` 裡（`├──`, `└──`） | 表達層次關係但用程式碼語意 | 語意錯配 |

**跳過不動的項目：**
- `yaml` / `json` / `bash`（含真實指令）代碼塊 → 合法用途，不動
- 已經是 `mermaid` 的區段
- 已經是 Markdown Table 的區段

---

## Step 2：判斷資訊本質

每個候選區段問自己：**「這段資訊的形狀是什麼？」**

| 資訊形狀 | 關鍵問題 | 選型方向 |
|:---|:---|:---|
| 有方向、有箭頭、有流動感 | 「請求怎麼走？誰呼叫誰？」 | flowchart 或 sequenceDiagram |
| 多個屬性並列比較 | 「A 和 B 在幾個維度上有何差異？」 | Markdown Table |
| 父子從屬、層次組織 | 「這個東西的結構怎麼拆？」 | graph TD（樹狀） |
| 物件有生命週期 | 「這個東西有哪些狀態？怎麼轉換？」 | stateDiagram-v2 |
| 多個系統跨時間互動 | 「誰先發訊息？誰等待？」 | sequenceDiagram |
| 決策分支 | 「條件成立走哪條路？」 | flowchart（含菱形節點） |
| 並行流程合流 | 「多條線同時跑，最後匯在一起？」 | flowchart（含 PAR subgraph） |

---

## Step 3：選圖決策樹

```
資訊有方向性（流程/呼叫/觸發）？
├─ 是 → 多個系統跨時序互動？
│       ├─ 是 → sequenceDiagram
│       └─ 否 → 有決策分支（是/否）？
│               ├─ 是 → flowchart（含菱形）
│               └─ 否 → flowchart（線性）
│
└─ 否 → 是層次從屬關係？
        ├─ 是 → graph TD（樹狀）
        └─ 否 → 物件有多個狀態與轉換？
                ├─ 是 → stateDiagram-v2
                └─ 否 → 是多欄並列比較？
                        ├─ 是 → Markdown Table
                        └─ 否 → 評估是否需要圖（可能只需條列）
```

**方向選擇（flowchart）：**
- `TD`（Top-Down）：層次、縱深、外到內、上游到下游
- `LR`（Left-Right）：時序觸發、輸入到輸出、時間軸

---

## Step 4：套用語意配色

所有 mermaid 節點依**語意**套色，跨文件保持一致：

| 角色 | 顏色 | Hex | 典型節點 |
|:---:|:---|:---|:---|
| 起點 / 觸發 | 橘 | `#F5A623` | 使用者、請求入口、Push、外部觸發 |
| 中介 / 控制 | 紫 | `#7B68EE` | Nginx、Controller、判斷節點 |
| 設定 / 規則 | 藍 | `#4A90D9` | Ingress、Selector、Config、決策樞紐 |
| 成功 / 目的地 | 綠 | `#5BA85B` | Pod、正常狀態、Endpoints、Promote |
| 失敗 / 危險 | 紅 | `#D9534F` | 重啟、排除、規則不存在、Rollback |
| 底層執行 | 灰 | `#555555` | App 本身、最底層、OS |

套色語法（在 mermaid 節點宣告後加）：
```
style NODE_ID fill:#F5A623,color:#fff
```

---

## Step 5：品質驗證

完成後逐張檢查：

- [ ] **一圖一問題**：這張圖回答的問題能用一句話說清楚嗎？
- [ ] **方向一致性**：flowchart TD 是縱向流程，LR 是時序觸發
- [ ] **顏色有語意**：顏色代表角色，不是隨意裝飾
- [ ] **沒有殘留 ASCII**：原始 bash 偽流程圖已全部移除
- [ ] **節點文字清晰**：用 `\n` 換行讓長文字不溢出節點框

---

## 參考資源

- **完整圖表類型說明** → `references/diagram-catalog.md`（所有圖表的適用情境、特徵與使用決策）
- **mermaid 語法與範例** → `references/mermaid-patterns.md`（各類型的實際寫法、配色範例、常見錯誤）