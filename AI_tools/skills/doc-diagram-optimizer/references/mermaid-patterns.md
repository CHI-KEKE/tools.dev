# Mermaid 語法模式與配色範例

## 目錄

1. [flowchart TD — 縱向流程](#flowchart-td--縱向流程)
2. [flowchart LR — 時序觸發](#flowchart-lr--時序觸發)
3. [flowchart 含決策分支](#flowchart-含決策分支)
4. [flowchart 含 subgraph（平行流程）](#flowchart-含-subgraph平行流程)
5. [graph TD — 樹狀從屬](#graph-td--樹狀從屬)
6. [sequenceDiagram — 時序圖](#sequencediagram--時序圖)
7. [stateDiagram-v2 — 狀態機](#statediagram-v2--狀態機)
8. [語意配色快速參照](#語意配色快速參照)
9. [常見錯誤與修正](#常見錯誤與修正)

---

## flowchart TD — 縱向流程

**使用時機：** 層次結構、外到內、上游到下游、請求進入系統的路徑

```mermaid
flowchart TD
    U["👤 外部使用者"]
    ALB["☁️ AWS ALB（公用）\nLayer 5：最外層"]
    NGINX["🔀 Nginx Ingress Controller\nLayer 4"]
    SVC["🔌 K8s Service\nLayer 2"]
    POD["📦 Pod（App 程式）\nLayer 1：最內層"]

    U --> ALB --> NGINX --> SVC --> POD

    style ALB fill:#F5A623,color:#fff
    style NGINX fill:#7B68EE,color:#fff
    style SVC fill:#5BA85B,color:#fff
    style POD fill:#555,color:#fff
```

**重點語法：**
- 節點：`ID["顯示文字"]`
- 多行文字：`ID["第一行\n第二行"]`
- 箭頭鏈：`A --> B --> C`
- 帶標籤箭頭：`A -->|"標籤"| B`

---

## flowchart LR — 時序觸發

**使用時機：** 觸發→判斷→結果的時序，Probe 流程，輸入到輸出

```mermaid
flowchart LR
    K["⚙️ kubelet\n每 N 秒"]
    K -->|"HTTP GET /_hc"| HC{回應？}
    HC -->|"✅ 200 OK"| OK["🟢 正常運行"]
    HC -->|"❌ 失敗"| RESTART["🔄 重啟 Pod"]

    style K fill:#5BA85B,color:#fff
    style OK fill:#5BA85B,color:#fff
    style RESTART fill:#D9534F,color:#fff
```

**重點語法：**
- 菱形節點（判斷）：`ID{問題？}`
- 條件分支：`HC -->|"✅ 成功"| OK`

---

## flowchart 含決策分支

**使用時機：** 多條件路徑、if-else 邏輯、排查樹

```mermaid
flowchart TD
    START["📨 請求進入 ALB"]
    CHK["🔍 比對 Listener Rules"]
    R1["✅ 規則存在 → Nginx TG"]
    R2["❌ 規則不存在"]
    DEF["🚫 DEFAULT → 403"]

    START --> CHK
    CHK --> R1
    CHK --> R2
    CHK --> DEF

    style START fill:#F5A623,color:#fff
    style CHK fill:#4A90D9,color:#fff
    style R1 fill:#5BA85B,color:#fff
    style R2 fill:#D9534F,color:#fff
    style DEF fill:#D9534F,color:#fff
```

---

## flowchart 含 subgraph（平行流程）

**使用時機：** CI/CD 的 A 線/B 線、Blue-Green 部署、並行任務

```mermaid
flowchart TD
    START[開始] --> PAR{平行執行}

    PAR --> A1
    PAR --> B1

    subgraph A["🔴 A 線"]
        A1[任務 A1] --> A2[任務 A2] --> A3[✅ A 完成]
    end

    subgraph B["🟢 B 線"]
        B1[任務 B1] --> B2[任務 B2] --> B3[✅ B 完成]
    end

    A3 --> JOIN[兩線匯合]
    B3 --> JOIN
    JOIN --> END[結束]

    style START fill:#F5A623,color:#fff
    style JOIN fill:#4A90D9,color:#fff
```

**重點語法：**
```
subgraph 名稱["顯示標題"]
    direction TB
    節點...
end
```

---

## graph TD — 樹狀從屬

**使用時機：** 組織結構、系統組件從屬、K8s 架構層次

> 用 `graph` 而非 `flowchart`：`graph` 強調從屬關係，`flowchart` 強調流程

```mermaid
graph TD
    CLUSTER["🏗️ K8s Cluster"]
    MASTER["🎛️ Master Node（Control Plane）\nAPI Server、Scheduler"]
    WORKER["🖥️ Worker Node ×N"]
    KL["⚙️ kubelet"]
    PODS["📦 管理所有 Pod"]

    CLUSTER --> MASTER
    CLUSTER --> WORKER
    WORKER --> KL
    KL --> PODS

    style CLUSTER fill:#4A90D9,color:#fff
    style MASTER fill:#7B68EE,color:#fff
    style WORKER fill:#F5A623,color:#fff
    style KL fill:#5BA85B,color:#fff
    style PODS fill:#555,color:#fff
```

---

## sequenceDiagram — 時序圖

**使用時機：** API 鏈路、跨服務呼叫、非同步流程

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant FE as Frontend
    participant API as .NET API
    participant DB as PostgreSQL

    U->>FE: 送出訂單
    FE->>API: POST /orders
    API->>DB: INSERT order
    DB-->>API: OK
    API->>API: 觸發付款流程
    API-->>FE: 201 Created
    FE-->>U: 顯示成功頁面
```

**重點語法：**
- 宣告參與者：`participant ID as 顯示名稱`
- 實線呼叫：`A->>B: 訊息`
- 虛線回應：`A-->>B: 訊息`
- 自呼叫：`A->>A: 內部處理`

---

## stateDiagram-v2 — 狀態機

**使用時機：** 訂單生命週期、部署狀態、連線狀態

```mermaid
stateDiagram-v2
    [*] --> 待付款
    待付款 --> 已付款 : 付款成功
    待付款 --> 已取消 : 逾時 / 取消
    已付款 --> 出貨中 : 倉庫出貨
    出貨中 --> 已完成 : 確認收貨
    已完成 --> 退款中 : 申請退款
    退款中 --> 已退款 : 退款核准
    已取消 --> [*]
    已退款 --> [*]
    已完成 --> [*]
```

**重點語法：**
- 初始狀態：`[*] --> 狀態名`
- 轉換：`狀態A --> 狀態B : 事件/條件`
- 終止：`狀態 --> [*]`

---

## 語意配色快速參照

```
起點 / 觸發 / 外部輸入    → fill:#F5A623,color:#fff  (橘)
中介 / 控制 / 管理層      → fill:#7B68EE,color:#fff  (紫)
設定 / 規則 / 決策樞紐    → fill:#4A90D9,color:#fff  (藍)
成功 / 目的地 / 正常狀態  → fill:#5BA85B,color:#fff  (綠)
失敗 / 危險 / 異常        → fill:#D9534F,color:#fff  (紅)
底層執行 / 最終層         → fill:#555555,color:#fff  (灰)
```

**套色方式（在 mermaid 區塊末尾統一加）：**
```
style 節點ID fill:#F5A623,color:#fff
```

---

## 常見錯誤與修正

| 錯誤 | 症狀 | 修正方式 |
|:---|:---|:---|
| 流程圖放進 `bash` 代碼塊 | 顯示等寬字、深色背景，無法渲染 | 改用 ` ```mermaid ` |
| 節點 ID 含空格或特殊字元 | 渲染失敗 | 改用英文 ID，顯示文字放 `["..."]` |
| 節點文字太長不換行 | 節點框過寬，圖形變形 | 用 `\n` 在節點文字中換行 |
| 過多節點在同一張圖 | 圖形雜亂、線條交叉 | 拆成多張圖，每張只回答一個問題 |
| `flowchart` 用來畫從屬關係 | 語意不清（graph 才是從屬） | 改用 `graph TD` |
| 所有節點同一顏色 | 顏色沒有傳遞語意 | 依角色套用語意配色系統 |
