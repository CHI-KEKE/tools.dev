# 圖表範例

以下全部是為說明選圖與語法而設計的假設案例，不是 91APP 的實際系統。使用時先按 [選圖規範](diagram-selection.md) 核對來源、名稱與分支，再放入文章既有 tabs。範例不限定配色，沿用文章已定調的風格。

## 系統情境：誰使用系統？

核心系統不展開內部類別，箭頭說明互動目的。

```mermaid
flowchart LR
    Customer["顧客"] -->|提交訂單| Ordering["訂單系統"]
    Ordering -->|請求付款| Payment["外部付款系統"]
```

## Container 視圖：系統由哪些應用與儲存組成？

假設前端、API、Worker 與資料庫是已確認的應用程式／資料儲存。這是以 flowchart 表達的 Container 視圖，並非 Docker 拓撲。

```mermaid
flowchart TB
    User["顧客"] -->|操作| Web
    subgraph System["訂單系統"]
        Web["Web App：訂單操作介面"] -->|HTTPS 訂單請求| Api["Order API：接單"]
        Api -->|寫入待處理訂單| Db[("Order DB")]
        Worker["Worker：處理訂單"] -->|讀寫訂單狀態| Db
    end
```

## Component 視圖：放大單一應用程式

只展示 Order API 內部元件，不將 Controller 說成獨立部署單位。

```mermaid
flowchart TB
    Client["呼叫端"] -->|HTTP request| Controller
    subgraph Api["Order API 內部"]
        Controller["Controller：接收請求"] -->|建立訂單| Service["Order Service：協調"]
        Service -->|保存訂單| Repo["Repository：資料存取"]
    end
    Repo -->|SQL| Db[("Order DB")]
```

## Sequence：同步請求與互斥結果

此假設 API 的規格已明確定義兩種回傳。`alt` 兩邊擇一，activation 在分支結束後統一關閉。

```mermaid
sequenceDiagram
    autonumber
    participant Client as 呼叫端
    participant Api as API
    participant Store as Repository
    Client->>Api: 取得訂單
    activate Api
    Api->>Store: 依識別值查詢
    Store-->>Api: 查詢結果
    alt 找到訂單
        Api-->>Client: 訂單資料
    else 查無訂單
        Api-->>Client: 查無資料結果
    end
    deactivate Api
```

## Sequence：非同步事件與接收確認

假設是推送式交付。入列確認與稍後的業務結果分開；未提供 ACK 規格時不額外畫消費確認。

```mermaid
sequenceDiagram
    participant Producer as Producer
    participant Queue as Queue
    participant Worker as Consumer
    participant Store as 資料庫
    Producer-)Queue: 發布訂單事件
    Queue-->>Producer: 入列確認
    Queue-)Worker: 交付事件
    Worker->>Store: 保存處理結果
    Store-->>Worker: 寫入結果
    Note over Producer,Worker: 入列確認不代表業務處理完成
```

## Sequence：重試與逾時

假設 Client 會在仍未成功且未達設定上限時重試。逾時由 Client 察覺，不捏造遠端失敗回傳；成功後不再滿足 loop 條件。

```mermaid
sequenceDiagram
    participant Client as Client
    participant Remote as Remote API
    loop 尚未成功且未達設定上限
        Client->>Remote: 送出請求
        alt 在期限內收到成功結果
            Remote-->>Client: 成功結果
            Client->>Client: 設定成功狀態
        else 等待逾時
            Note over Client: 本地等待逾時，遠端結果未知
            Client->>Client: 記錄嘗試次數並判斷是否再試
        end
    end
```

## Sequence：平行、可選動作與中止

只有來源證明兩項檢查並行時才用 `par`。拒絕時 `break` 中止後續保存；通知為可選步驟。

```mermaid
sequenceDiagram
    participant Api as API
    participant Stock as 庫存服務
    participant Risk as 風控服務
    participant Store as Repository
    par 查庫存
        Api->>Stock: 檢查庫存
        Stock-->>Api: 庫存結果
    and 查資格
        Api->>Risk: 檢查資格
        Risk-->>Api: 資格結果
    end
    break 任一檢查不通過
        Note over Api: 結束本次處理
    end
    Api->>Store: 保存訂單
    Store-->>Api: 保存結果
    opt 啟用通知
        Note over Api: 進入已定義的通知流程
    end
```

## Flowchart：快取決策

HIT 直接匯入使用資料，MISS 才查來源；不畫成命中後又未命中的串行步驟。

```mermaid
flowchart TB
    Lookup["查詢快取"] --> Hit{"命中？"}
    Hit -->|是| Use["使用資料"]
    Hit -->|否| Source["查詢來源"]
    Source --> Fill["回填快取"]
    Fill --> Use
```

## 泳道式示意：跨責任建置交接

subgraph 是責任分區，不宣稱是 BPMN。箭頭上的交付物讓跨責任交接可以追蹤；實際排列仍需瀏覽器檢查。

```mermaid
flowchart TB
    subgraph Dev["開發者"]
        Submit["提交程式碼"]
    end
    subgraph CI["CI Runner"]
        Build["建置"] --> Test["測試"]
        Test --> Pass{"通過？"}
        Pass -->|否| Stop["停止發布"]
        Pass -->|是| Artifact["產生產物"]
    end
    subgraph Delivery["部署工作"]
        Deploy["部署已驗證產物"]
    end
    Submit -->|版本提交| Build
    Artifact -->|版本化產物| Deploy
```

## 資料流：來源、轉換與儲存

箭頭表示資料移動，並不宣稱同步執行順序。

```mermaid
flowchart LR
    Input["購物車輸入"] -->|商品識別值清單| Mapping["關聯轉換"]
    Catalog[("商品集合來源")] -->|既有集合關聯| Mapping
    Mapping -->|候選活動識別值| Load["規則載入"]
    Rules[("規則來源")] -->|規則內容| Load
    Load -->|規則快取資料| Cache[("快取")]
```

## State Diagram：任務生命週期

假設規格允許 Failed 重試，Succeeded 才是此模型的終止狀態。

```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Running: 開始處理
    Running --> Succeeded: 處理成功
    Running --> Failed: 處理失敗
    Failed --> Pending: 重試核准
    Succeeded --> [*]
```

## ERD：關聯與基數

假設每個 Order 必屬一個 Customer，而 Customer 可以尚未有 Order。這裡明確畫實體 FK；無約束證據時不能照抄。

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    CUSTOMER {
        int Id PK
    }
    ORDER {
        int Id PK
        int CustomerId FK
    }
```

## Class Diagram：介面與實作

此圖只說明型別實作與依賴，不表示資料儲存關聯。

```mermaid
classDiagram
    class IOrderStore {
        <<interface>>
        Save()
    }
    class SqlOrderStore
    class OrderService
    IOrderStore <|.. SqlOrderStore
    OrderService ..> IOrderStore : 使用
```

## Deployment：特定環境的執行位置

假設 QA 確實只有一個已知 API instance 與一個資料庫服務。副本數未知時不自行補成多台。

```mermaid
flowchart TB
    Client["測試呼叫端"] -->|HTTPS| Api
    subgraph QA["QA 環境"]
        subgraph Host["應用主機"]
            Api["Order API instance"]
        end
        subgraph Data["資料服務"]
            Db[("Order DB")]
        end
        Api -->|資料讀寫| Db
    end
```

## 事件時間表與環境矩陣

這兩種內容不必硬轉成 Mermaid。以下為假設記錄；使用時替換成已驗證資料。

| 時間（Asia/Taipei） | 觀察事件 | 證據 |
| --- | --- | --- |
| 10:00 | 首次偵測錯誤 | 告警記錄 |
| 10:03 | 任務進入重試 | Worker log |

時間先後不代表兩件事必然互為因果。

| 比較面向 | QA | Production |
| --- | --- | --- |
| 部署環境 | 測試 | 正式 |
| 副本數 | 待查設定 | 待查設定 |
| 發布條件 | 待查 pipeline | 待查 pipeline |

矩陣各環境使用同一組欄位；未知就標待查，不以常見配置填入數字。
