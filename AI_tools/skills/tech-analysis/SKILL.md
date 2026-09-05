---
name: tech-analysis
description: >
  專為 Allen 的技術鏈路分析與文件整理工作設計的 Skill。
  當 Allen 說「分析 XXX 的鏈路」、「解析 XXX 的流程」、「幫我盤點 XXX 的脈絡」、「分析 XXX API 的呼叫關係」、
  「整理成文件」、「建立分析文件」，或任何涉及程式碼流程/商業邏輯/API 鏈路分析並輸出 Markdown 文件的任務，
  都應呼叫此 Skill。適用場景包括：Controller 鏈路、Service 流程、Processor Pipeline、
  API 呼叫關係、資料流向、狀態機分析、跨專案串接分析。
---

# Tech Analysis Skill

## 核心工作流程

觸發此 Skill 後，依序執行以下階段：

### Phase 1 — 釐清範疇（Clarify Scope）

在開始搜尋程式碼前，先向 Allen 確認以下資訊（可一次詢問）：

1. **分析對象**：「你要分析的是哪個 API/功能/流程？」（若已明確則跳過）
2. **涉及專案**：「這個分析涉及哪些專案？還是只看單一專案？」
3. **分析深度**：
   - 快速概覽（鏈路圖 + 關鍵步驟）
   - 完整分析（含分支邏輯、例外處理、狀態機）
4. **輸出目錄**：「要儲存到哪個目錄？」（若未指定，預設問一次）

> 若 Allen 的問題已包含足夠資訊，直接進入 Phase 2，不必重複詢問。

---

### Phase 2 — 程式碼探索（Code Exploration）

依據分析對象，使用 grep/glob/view 工具進行探索。

**探索順序建議：**
1. 先找 **Route / Controller / Action** 作為入口
2. 往下追 **Service / Helper** 的核心邏輯
3. 找 **Processor Pipeline 定義**（ProcessorDefinitionCenter / Module）
4. 往上追**呼叫方**（誰觸發這個 API）
5. 往下追**下游呼叫**（這個 API 又呼叫誰）

**工具使用優先順序：**
`grep` (精確搜尋) > `glob` (找檔案) > `view` (讀內容)

並行呼叫多個搜尋，不要逐一等待。

---

### Phase 3 — 文件撰寫（Documentation）

依據 `references/doc-structure.md` 中定義的標準結構撰寫文件。

**必要元素（所有分析都要有）：**
- 定位宣告（在整個流程中的位置）
- 全貌鏈路圖（ASCII/Mermaid）
- 觸發條件
- 逐步流程

**選用元素（依分析深度加入）：**
- 分支決策表 / ReturnCode 對照
- 狀態流轉圖
- 例外處理一覽
- 關鍵資料說明（如 k 值）
- Request / Response 格式
- 關鍵檔案索引

詳細結構模板見：`references/doc-structure.md`

---

### Phase 4 — 輸出確認（Output）

文件撰寫完成後：
1. 將 Markdown 存入指定目錄
2. 回報文件路徑
3. 列出「本次文件缺少的元素」，詢問 Allen 是否需要補充

---

## 互動原則

- **不要自行猜測不確定的商業邏輯**，先搜尋程式碼確認
- **看到複雜的 if/else 或 switch**，一律用表格整理，不要用文字描述
- **每個狀態流轉都要畫出來**，不允許用文字描述取代
- **探索完成後先整理結構，再動筆寫文件**，避免寫到一半才發現鏈路不完整
- 若分析途中發現範疇比預期大，先回報給 Allen，確認是否繼續深入

---

## 參考資源

- **文件結構模板**：`references/doc-structure.md` — 標準文件結構與各元素的撰寫指引
