# 圖表類型完整目錄

## 目錄

1. [C4 Model 系列](#c4-model-系列)
   - Context Diagram（系統環境圖）
   - Container Diagram（容器架構圖）
   - Component Diagram（組件架構圖）
2. [行為圖：描述「系統怎麼動」](#行為圖描述系統怎麼動)
   - Sequence Diagram（時序圖）
   - Flowchart（流程圖）
   - State Machine Diagram（狀態機圖）
   - Activity Diagram（活動圖）
3. [結構圖：描述「層次與組織」](#結構圖描述層次與組織)
   - Tree Diagram（樹狀圖）
   - Layer Diagram（層次架構圖）
   - Network Topology（網路拓撲圖）
4. [資料圖：描述「資料長什麼樣」](#資料圖描述資料長什麼樣)
   - ER Diagram
   - Data Flow Diagram (DFD)
5. [時間軸圖](#時間軸圖)
   - Deployment Diagram（部署架構圖）
   - Gantt / Timeline
6. [決策與分析圖](#決策與分析圖)
   - Decision Tree
   - Mind Map
7. [表格 vs 圖的邊界](#表格-vs-圖的邊界)

---

## C4 Model 系列

C4 用四個縮放層次描述系統，核心原則是「用不同解析度回答不同對象的問題」。

### Context Diagram（C4 Level 1）— 系統環境圖

**回答的問題：** 這個系統存在於什麼世界裡？和哪些人、哪些外部系統互動？

**適合情境：**
- 向非技術人員（PM、老闆、客戶）介紹系統
- 釐清「邊界在哪」
- 評估新需求會影響哪些外部關係

**圖的特徵：**
- 中間是你的系統（一個大方塊）
- 外面是使用者（人像）和外部系統（方塊）
- 只有箭頭，沒有任何內部細節

**不適合：** 說明技術細節、服務之間的 API 呼叫

---

### Container Diagram（C4 Level 2）— 容器架構圖

> 「Container」不是 Docker，而是「可獨立部署的執行單元」（Web App、API、DB、MQ 等）

**回答的問題：** 這個系統由哪些大塊組成？它們如何通訊？

**適合情境：**
- 跟開發團隊說明技術選型（語言、資料庫）
- 說明服務之間如何通訊（REST / gRPC / MQ）
- 新人 Onboarding，建立整體認知

**圖的特徵：**
- 多個方塊（Web、API、DB、Cache）
- 每個方塊標示技術（Node.js、PostgreSQL、Redis）
- 箭頭上標示通訊協定

**不適合：** 說明一個 API 內部怎麼運作、程式碼結構

---

### Component Diagram（C4 Level 3）— 組件架構圖

**回答的問題：** 某個容器內部由哪些組件構成？

**適合情境：**
- 說明單一服務的內部架構
- 討論 Clean Architecture / DDD 的分層
- Code Review 前讓 reviewer 先有全局概念
- 設計新功能時規劃模組邊界

**不適合：** 向非技術人員解釋、說明系統之間的整合

---

## 行為圖：描述「系統怎麼動」

### Sequence Diagram（時序圖）

**回答的問題：** A 呼叫 B 再呼叫 C，整個請求的時間順序是什麼？

**適合情境：**
- 說明一個 API 請求的完整鏈路
- Debug 複雜的跨服務呼叫
- 說明非同步流程（誰先發、誰等待）
- 設計新功能時確認每個系統該做什麼

**圖的特徵：**
- 橫軸是參與者（系統/服務/角色）
- 縱軸是時間（由上往下）
- 實線是呼叫，虛線是回應

**不適合：** 說明靜態架構、超過 6-7 個參與者

**mermaid 類型：** `sequenceDiagram`

---

### Flowchart（流程圖）

**回答的問題：** 這個邏輯有哪些判斷分支？

**適合情境：**
- 說明業務流程（退款流程、審核流程）
- 說明演算法邏輯
- 說明錯誤處理路徑
- 跟 PM 討論邊界情況（edge case）

**與 Sequence Diagram 的差異：**
- Flowchart：焦點在「邏輯分支」，單一流程，問「會不會走這條路？」
- Sequence：焦點在「時間順序與參與者」，多系統互動，問「誰先誰後？」

**mermaid 類型：** `flowchart TD` 或 `flowchart LR`

---

### State Machine Diagram（狀態機圖）

**回答的問題：** 這個物件有哪些狀態？什麼事件觸發狀態轉換？

**適合情境：**
- 訂單狀態（待付款 → 已付款 → 出貨中 → 已完成 → 已退款）
- 流程審核（草稿 → 審核中 → 通過 / 退回）
- 連線狀態（connecting → connected → disconnected）
- 任何有「生命週期」的物件

**獨特價值：** 強迫列出所有合法轉換路徑，設計階段就能發現「這個狀態能不能回頭？」等遺漏的業務規則

**mermaid 類型：** `stateDiagram-v2`

---

### Activity Diagram（活動圖）

**回答的問題：** 並行的多條流程怎麼協調？

**適合情境：**
- CI/CD 的 A 線 / B 線平行執行
- 說明 Fork（分叉）和 Join（匯合）的流程
- BPMN 業務流程建模

**與 Flowchart 的差異：** Flowchart 是單線，Activity Diagram 支援多條平行流程的分叉與合流

**mermaid 實作：** `flowchart TD` 搭配 `subgraph` + parallel 結構

---

## 結構圖：描述「層次與組織」

### Tree Diagram（樹狀圖）

**回答的問題：** 這個東西的層次結構是什麼？

**適合情境：**
- 組織架構
- 檔案系統結構
- 功能模組的從屬關係
- DNS / K8s 的組件從屬（kubelet → Pod）

**不適合：** 有多個父節點的關係（那要用 Graph）、有方向性的流程

**mermaid 類型：** `graph TD`（不用 `flowchart`，因為這是從屬關係而非流程）

---

### Layer Diagram（層次架構圖）

**回答的問題：** 這個系統的分層是什麼？依賴方向是什麼？

**適合情境：**
- Clean Architecture（Domain / Application / Infrastructure）
- 說明依賴規則（只能上層依賴下層，不能反向）
- MVC / MVP / MVVM 架構說明

---

### Network Topology Diagram（網路拓撲圖）

**回答的問題：** 機器、網路設備、子網路怎麼連接？

**適合情境：**
- VPC 子網路設計（Public / Private Subnet）
- 防火牆規則說明
- Load Balancer 到 EC2 的實體連線
- 給維運團隊看的部署細節

---

## 資料圖：描述「資料長什麼樣」

### ER Diagram（實體關係圖）

**回答的問題：** 資料庫的表格之間怎麼關聯？

**適合情境：**
- 資料庫 Schema 設計
- 說明一對多 / 多對多關係
- 新人理解資料模型

**mermaid 類型：** `erDiagram`

---

### Data Flow Diagram（資料流圖 DFD）

**回答的問題：** 資料從哪裡來、流向哪裡、在哪裡被處理？

**適合情境：**
- 說明資料治理（GDPR 合規需要知道個資流向）
- 設計 ETL / 資料管線
- 說明 Event-Driven 架構的訊息流

**與 Sequence Diagram 的差異：**
- DFD：關注資料本身（這個資料怎麼被轉換）
- Sequence：關注呼叫順序（誰呼叫誰）

---

## 時間軸圖

### Deployment Diagram（部署架構圖）

**回答的問題：** 系統的每個部分跑在哪台機器 / 哪個環境？

**適合情境：**
- 說明 Dev / Staging / Prod 環境差異
- K8s 的 Pod 跑在哪個 Node
- 多機房 / 多區域架構
- 說明給 DevOps / SRE 看的執行環境

**與 Container Diagram 的差異：**
- Container Diagram：邏輯架構，問「有哪些服務？」，對象是開發人員
- Deployment Diagram：實體環境，問「服務跑在哪裡？」，對象是 DevOps / 維運

---

### Gantt / Timeline Diagram

**適合情境：**
- 專案排程、Sprint 規劃可視化
- 事故後報告（Incident Post-mortem）的事件還原
- 部署過程的時間記錄

**mermaid 類型：** `gantt`

---

## 決策與分析圖

### Decision Tree（決策樹）

**回答的問題：** 根據不同條件，最終決定是什麼？

**適合情境：**
- 價格計算邏輯（折扣條件）
- 路由規則（哪個請求走哪條路徑）
- 排查流程（先檢查什麼、再檢查什麼）

---

### Mind Map（心智圖）

**回答的問題：** 這個主題有哪些相關的面向？

**適合情境：**
- 需求分析的初始發散
- 技術選型的考量面向
- 系統功能的全貌盤點

**不適合：** 有明確順序或依賴的內容

**mermaid 類型：** `mindmap`

---

## 表格 vs 圖的邊界

| 用表格 | 用圖 |
|:---|:---|
| 資料是靜態比較（A vs B 在多個屬性上） | 資料有方向性、流動感、因果關係 |
| 主要是查詢、參考用 | 主要是理解流程、結構、狀態 |
| 欄位少於 5 個 | 節點關係複雜、有分支或循環 |
| 沒有「流」的概念 | 有時間軸或順序 |

> **核心原則：一張圖只回答一個問題。** 當一張圖試圖同時說明「架構」又說明「流程」時，兩件事都說不清楚。
