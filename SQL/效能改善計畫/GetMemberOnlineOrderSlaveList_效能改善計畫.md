# GetMemberOnlineOrderSlaveList 查詢效能改善計畫

- **來源專案**：`NineYi.Scm.ApiV2`
- **檔案位置**：`DataAccess\Repositories\SalesOrders\SalesOrderRepository.cs` (line 1480)
- **觸發 API**：`POST /scm/v2/Location/GetLastOmoKeyPromptsFromMemberDimension`
- **關聯 ELMAH 錯誤**：`System.Data.EntityCommandExecutionException` / `System.ComponentModel.Win32Exception`（`Execution Timeout Expired`）
- **文件目的**：完整列出可用於改善此查詢效能、避免 SQL Execution Timeout 的技巧與方法，供評估與排定優先順序使用

---

## 一、問題現況摘要

```csharp
public List<MemberOnlineOrderSlaveEntity> GetMemberOnlineOrderSlaveList(
    long shopId, int memberId, DateTime startDate, DateTime endDate, IEnumerable<string> salesOrderStatusList)
{
    var transactionOptions = new TransactionOptions { IsolationLevel = IsolationLevel.ReadUncommitted };
    using (var transactionScope = new TransactionScope(TransactionScopeOption.Required, transactionOptions))
    {
        var result = from salesOrderSlave in this._erpReadDbContext.SalesOrderSlave.Valids()
                     join orderSlaveFlow in this._erpReadDbContext.OrderSlaveFlow.Valids()
                     on salesOrderSlave.SalesOrderSlave_Id equals orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveId
                     join salesOrderGroup in this._erpReadDbContext.SalesOrderGroup.Valids()
                     on orderSlaveFlow.OrderSlaveFlow_TradesOrderGroupId equals salesOrderGroup.SalesOrderGroup_TradesOrderGroupId
                     join returnGoodsOrderSlave in this._erpReadDbContext.ReturnGoodsOrderSlave.Valids()
                     on orderSlaveFlow.OrderSlaveFlow_ReturnGoodsOrderSlaveId equals returnGoodsOrderSlave.ReturnGoodsOrderSlave_Id
                     into leftJoinReturnGoodsOrderSlave
                     from finishedReturnGoodsOrderSlave in leftJoinReturnGoodsOrderSlave.Where(x => x.ReturnGoodsOrderSlave_StatusDef == "Finish").DefaultIfEmpty()
                     where orderSlaveFlow.OrderSlaveFlow_MemberId == memberId
                     && orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveShopId == shopId
                     && salesOrderGroup.SalesOrderGroup_DateTime >= startDate
                     && salesOrderGroup.SalesOrderGroup_DateTime < endDate
                     && salesOrderStatusList.Contains(orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveStatusDef)
                     select new MemberOnlineOrderSlaveEntity() { /* 5 個欄位 */ };

        return result.ToList();
    }
}
```

**已知問題點**：
1. 4 張表 Join（`SalesOrderSlave` ⋈ `OrderSlaveFlow` ⋈ `SalesOrderGroup` ⟕ `ReturnGoodsOrderSlave`），查詢範圍為會員近 **12 個月**訂單。
2. 呼叫端 `GetMemberOmoOrderKeyPrompt.GetKeyPrompt` 只需要「總金額」（`Sum`），卻用 `.ToList()` 把**每一筆明細**都搬到應用層，再用 LINQ 加總。
3. 此查詢在 `OmoKeyPromptsService.GetOmoKeyPromptsFromMemberDimension` 中，與其他 9 個 `IOmoKeyPrompt` 一起用 `Task.Run` 平行執行，且外層沒有 `try/catch` 保護，任一查詢逾時會讓整支 API 500。
4. ELMAH 六維分析顯示錯誤集中在**訂單量大的少數會員/商店**（ShopId 82、19 佔約 73%），且常與其他平行任務的錯誤（Win32Exception 等）同時間爆發，顯示是「單次請求內多個平行查詢同時撞上資料庫負載尖峰」。

---

## 二、優化技巧總覽表

| # | 技巧類別 | 具體做法 | 預期效果 | 風險/成本 | 建議優先度 |
|---|---|---|---|---|---|
| 1 | 資料庫端聚合 | 把 `.ToList()` 後在記憶體 `.Sum()` 改為讓 EF/SQL 直接在資料庫端算 `SUM()`，只回傳一個總金額 | 大幅減少資料搬移量與記憶體用量，減少 Join 後的實體化成本 | 低，需調整 Repository 回傳型別與呼叫端邏輯 | ★★★★★ |
| 2 | 索引優化 | 確認/新增 `OrderSlaveFlow(MemberId, SalesOrderSlaveShopId, SalesOrderSlaveStatusDef)`、`SalesOrderGroup(TradesOrderGroupId, SalesOrderGroup_DateTime)` 複合索引 | 讓 Join 與篩選條件走 Index Seek 而非 Scan | 低（唯讀索引不影響邏輯），需 DBA 執行與觀察空間/寫入成本 | ★★★★★ |
| 3 | 查詢範圍縮小 | 將 12 個月 / 15 個月時間窗改為可設定（如 3~6 個月）或加上「近期優先、超過門檻才擴大查詢」的分層策略 | 直接降低掃描資料量 | 中，需業務確認跨通路任務判斷邏輯是否受影響 | ★★★★☆ |
| 4 | 快取策略 | 依 `ShopId+MemberId` 快取查詢結果（比照同檔案內 `LoyaltyPointsHelper.GetLoyaltyPointCenterInfo` 使用 `ICacheService` 的做法），TTL 設 3~10 分鐘 | 短時間內重複呼叫不必重複打 DB | 中，需確認資料時效可接受延遲 | ★★★★☆ |
| 5 | 例外處理防護 | `GetMemberOmoOrderKeyPrompt.GetKeyPrompt` 加上 `try/catch`，逾時只讓該提示卡片不顯示 | 避免單一查詢逾時拖垮整支 API（目前是唯一沒有 try/catch 的 KeyPrompt） | 低 | ★★★★★（止血用，不解決效能本身）|
| 6 | 減少 Join 表數 | 評估 `ReturnGoodsOrderSlave` 是否可用 `OrderSlaveFlow` 上既有的彙總欄位（如 `OrderSlaveFlow_ReturnGoodsTotalPayment`）取代即時 Join 退貨表 | 減少一次 Join，降低查詢複雜度 | 中，需確認該欄位是否即時同步、資料正確性 | ★★★☆☆ |
| 7 | 分頁 / TOP 限制 | 若只需近期代表性資料，可加 `OrderBy + Take(N)` 限制筆數 | 降低最壞情況掃描量 | 中，若業務需要「完整加總」則不適用（僅適合列表用途，非加總用途）| ★★☆☆☆（本案不適用加總情境，僅供列表類查詢參考）|
| 8 | 平行架構調整 | 檢視 `OmoKeyPromptsService` 用 `Task.Run` + `Task.WhenAll().Wait()` 平行呼叫 10 個 KeyPrompt 的架構，评估是否造成 ThreadPool/DB Connection Pool 競爭而放大逾時機率 | 降低「單次請求多個查詢同時撞牆」的機率 | 高，屬架構層級調整，需完整迴歸測試 | ★★★☆☆ |
| 9 | 預先彙總表 / 非同步批次計算 | 改為由 NMQ/排程 Job 定期預先計算「會員近12個月線上消費淨額」寫入彙總表，API 直接查表 | 查詢時間從「即時計算」變成「查表」，效能大幅提升 | 高，需新增資料表、批次 Job、資料一致性設計（即時性下降）| ★★★☆☆（長期方案）|
| 10 | CommandTimeout 調整 | 針對此查詢個別調高 `CommandTimeout`（EF `Database.CommandTimeout`） | 短期減少逾時錯誤發生次數 | 低成本但**治標不治本**，反而可能讓使用者等待更久、放大 DB 負載時間 | ★☆☆☆☆（僅建議搭配其他方案作為緩衝，不單獨使用）|
| 11 | Read-Only 隔離層級確認 | 目前已使用 `ReadUncommitted`（NOLOCK）+ 讀取專用 DbContext (`_erpReadDbContext`)，屬正確方向 | 已避免鎖等待問題 | 已實作，無需變動；僅需注意 NOLOCK 可能讀到暫時性不一致資料 | 已完成 |
| 12 | 查詢計畫監控 | 導入 SQL Server Query Store / Extended Events，針對此查詢建立效能基準與告警 | 提早發現效能衰退、確認優化效果 | 低，維運層面的長期措施 | ★★★☆☆ |
| 13 | 讀寫分離 / AlwaysOn Readable Secondary 資源調整 | 確認 `_erpReadDbContext` 對應的唯讀複本硬體資源（CPU/Memory/IO）是否為瓶頸，是否可獨立擴充 | 從基礎設施層面提升承載能力 | 中，涉及 Infra 成本 | ★★☆☆☆ |
| 14 | 非同步重試/斷路器 | 對外部相依（如點數中心 API）导入 Polly 等 retry/circuit breaker（本查詢屬內部 DB，非此類問題，僅供其他外部呼叫參考） | 降低外部服務不穩定造成的連鎖失敗 | 低 | 供其他錯誤類型參考 |

---

## 三、建議導入順序（依 CP 值排序）

### 第一階段：立即止血（低風險、可快速上線）
1. **方案 5**：`GetMemberOmoOrderKeyPrompt.GetKeyPrompt` 補上 `try/catch`，避免整支 API 500。
2. **方案 2**：請 DBA 確認/補上索引（`OrderSlaveFlow`、`SalesOrderGroup` 相關複合索引）。
3. **方案 1**：把 `.ToList()` 後應用層 `.Sum()` 改為資料庫端 `SUM()` 聚合，減少資料搬移。

### 第二階段：中期優化（需評估與確認）
4. **方案 4**：加入短效快取，降低短時間重複查詢頻率。
5. **方案 6**：評估用 `OrderSlaveFlow` 既有彙總欄位取代即時 Join 退貨表。
6. **方案 3**：與業務確認是否可縮短查詢時間範圍。

### 第三階段：長期架構優化
7. **方案 8**：重新檢視 OMO KeyPrompt 平行呼叫架構，評估 ThreadPool/連線池使用狀況。
8. **方案 9**：評估導入預先彙總表，將即時計算改為排程批次計算。
9. **方案 12、13**：建立長期監控機制與基礎設施擴充評估。

---

## 四、各方案技術細節補充

### 4.1 資料庫端聚合（方案1）示意
```csharp
// 現行：搬回全部明細，應用層加總
var list = query.ToList();
var total = list.Sum(x => x.SalesOrderSlaveTotalPayment - x.ReturnGoodsOrderSlaveTotalPayment);

// 建議：讓 SQL Server 端直接算 SUM，只回傳單一數字
var total = query.Sum(x => x.SalesOrderSlaveTotalPayment - x.ReturnGoodsOrderSlaveTotalPayment);
// 或改用 GroupBy 產生彙總結果集，僅在需要「最後一筆訂單時間」等明細欄位時才額外查詢
```
> 注意：若呼叫端同時需要 `OnlineOrderLastTradeDateTime`（最後一筆訂單時間），可用 `GroupBy` 一次取得 `Sum` 與 `Max(DateTime)`，仍比搬全部明細列有效率。

### 4.2 索引建議方向（方案2，需 DBA 確認實際執行計畫後調整）
- `OrderSlaveFlow`：`(OrderSlaveFlow_MemberId, OrderSlaveFlow_SalesOrderSlaveShopId)` INCLUDE `(OrderSlaveFlow_SalesOrderSlaveStatusDef, OrderSlaveFlow_TradesOrderGroupId, OrderSlaveFlow_SalesOrderSlaveId, OrderSlaveFlow_ReturnGoodsOrderSlaveId)`
- `SalesOrderGroup`：確認 `SalesOrderGroup_TradesOrderGroupId`（Join Key）與 `SalesOrderGroup_DateTime`（範圍篩選）的索引涵蓋情形
- 實際索引設計仍須以 DBA 依「執行計畫 + 統計資訊」為準，避免過度索引造成寫入負擔

### 4.3 快取策略示意（方案4，比照既有 `LoyaltyPointsHelper` 寫法）
```csharp
var result = this._cacheService.Get<List<MemberOnlineOrderSlaveEntity>>(
    group: "OmoKeyPrompt",
    feature: "MemberOnlineOrderSlaveList",
    key: $"{shopId}_{memberId}",
    expireTime: TimeSpan.FromMinutes(5),
    getDataFunc: () => this.QueryMemberOnlineOrderSlaveListFromDb(shopId, memberId, startDate, endDate, salesOrderStatusList));
```

### 4.4 平行架構風險（方案8）
`OmoKeyPromptsService.GetOmoKeyPromptsFromMemberDimension` 用 `Task.Run` 同時觸發 10 個 KeyPrompt，並用 `Task.WhenAll(...).Wait()` 同步等待。這個模式下：
- 每個 `Task.Run` 會佔用一個 ThreadPool 執行緒，內部又用 `.Result`/`.Wait()` 阻塞（例如 `LoyaltyPointsHelper.PostAsJson` 用 `.Result`），容易造成 **ThreadPool 執行緒耗盡**。
- 多個 KeyPrompt 各自開啟 DB 連線，同時對 DB 施壓，容易在同一次請求內集體撞上 Connection Pool 或 DB 資源上限，這也解釋了 ELMAH 分析中「同一秒內多種例外同時發生」的現象。
- 長期建議評估改用真正的 `async/await`（而非 `Task.Run` 包裝同步方法）搭配 `Task.WhenAll`，減少執行緒佔用。

---

## 五、針對本查詢語法的具體優化方向

以下針對 `GetMemberOnlineOrderSlaveList` 這段 LINQ 查詢本身的寫法，逐項提出可直接落地的語法級優化，皆附「現行寫法 → 建議寫法」對照。

### 5.1 調整查詢起始表與過濾順序（Filter Push-down）

**問題**：目前查詢從 `SalesOrderSlave`（無任何篩選條件的大表）開始 Join，`memberId`/`shopId` 這兩個高選擇性條件卻是掛在 `orderSlaveFlow` 欄位上、寫在最後的 `where`。EF6 的 LINQ-to-Entities 對「起始表」與「篩選條件位置」的翻譯有時無法完全自動下推（predicate pushdown），導致產生的 SQL 可能先做較大範圍的 Join 再篩選。

**為什麼有效（白話說明）**：可以想像成先去全公司員工名單（`SalesOrderSlave`）挨個核對，再慢慢篩出「這位會員」的紀錄；跟先只挑出「這位會員」的資料夾（`OrderSlaveFlow` 篩選後），再去查其他關聯資料，兩者要處理的資料量天差地遠。`memberId` + `shopId` 是本查詢辨識度最高的條件（一次篩到剩幾百筆），理應第一個套用；把它放在查詢最前面、當作起始表，可以讓資料庫盡早縮小戰場，而不是先把大量不相關的資料 Join 起來、算完才丟掉。

```csharp
// 現行：從 SalesOrderSlave 開始，篩選條件在最後
var result = from salesOrderSlave in this._erpReadDbContext.SalesOrderSlave.Valids()
             join orderSlaveFlow in this._erpReadDbContext.OrderSlaveFlow.Valids()
             on salesOrderSlave.SalesOrderSlave_Id equals orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveId
             ...
             where orderSlaveFlow.OrderSlaveFlow_MemberId == memberId
             && orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveShopId == shopId
             ...
```

```csharp
// 建議：從 OrderSlaveFlow 開始，先套用高選擇性條件（MemberId + ShopId + 狀態），再往外 Join
var filteredFlow = this._erpReadDbContext.OrderSlaveFlow.Valids()
    .Where(f => f.OrderSlaveFlow_MemberId == memberId
             && f.OrderSlaveFlow_SalesOrderSlaveShopId == shopId
             && salesOrderStatusList.Contains(f.OrderSlaveFlow_SalesOrderSlaveStatusDef));

var result = from orderSlaveFlow in filteredFlow
             join salesOrderSlave in this._erpReadDbContext.SalesOrderSlave.Valids()
             on orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveId equals salesOrderSlave.SalesOrderSlave_Id
             join salesOrderGroup in this._erpReadDbContext.SalesOrderGroup.Valids()
             on orderSlaveFlow.OrderSlaveFlow_TradesOrderGroupId equals salesOrderGroup.SalesOrderGroup_TradesOrderGroupId
             where salesOrderGroup.SalesOrderGroup_DateTime >= startDate && salesOrderGroup.SalesOrderGroup_DateTime < endDate
             ...
```
**效果**：讓資料庫優先用 `(MemberId, ShopId)` 索引把資料範圍縮到最小，再做後續 Join，減少中間結果集大小。實際效益仍取決於索引是否存在（見方案2），但寫法上更貼近「先篩選、後展開」的最佳實務。

### 5.2 用 `!=` 取代大型 `IN` 清單（`Contains`）

**問題**：呼叫端傳入的 `salesOrderStatusList` 是「排除 Cancel 和 Fail」後的**所有其餘狀態**（`Enum.GetNames(...).Where(x => x != Cancel && x != Fail)`），等於把一個「排除 2 個值」的條件，反向組成一個可能有 8~10 個值的 `IN (...)` 清單再傳給 SQL。

**為什麼有效（白話說明）**：這就像你想說「除了小明和小華以外的人都算」，卻寫成「小美、小強、小英…（把班上其他 8 個人名字都列出來）都算」——結果是一樣的，但後者要資料庫逐一比對 8~10 個字串值，前者只需比對 2 個。狀態欄位通常是字串型別（`StatusDef`），比對的值越多、優化器要評估的分支就越多，也更難有效利用索引的等值查找特性。改成「排除 2 個值」不只是效能問題，更是把程式碼寫成「跟需求描述一致」的樣子（我們要的其實就是「未取消、未失敗」），可讀性也更好。

```csharp
// 現行：呼叫端組出一個大 IN 清單
var orderStatus = Enum.GetNames(typeof(SalesOrderSlaveStatusEnum))
    .Where(x => x != SalesOrderSlaveStatusEnum.Cancel.ToString() && x != SalesOrderSlaveStatusEnum.Fail.ToString())
    .ToList();
// SQL 端：WHERE StatusDef IN ('A','B','C',...多個值)
```

```csharp
// 建議：直接排除，改寫成 NOT IN 兩個值（或直接 != && !=）
where orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Cancel.ToString()
   && orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Fail.ToString()
// SQL 端：WHERE StatusDef NOT IN ('Cancel','Fail')
```
**效果**：`NOT IN (2值)` 對查詢優化器而言比 `IN (8~10值)` 更容易命中索引、產生更精簡的執行計畫，語意也更直接表達「排除已取消/失敗」的意圖，同時也修正了方法簽章可以直接拿掉 `salesOrderStatusList` 參數的間接傳遞成本。

### 5.3 用既有彙總欄位取代 Join `ReturnGoodsOrderSlave`

**問題**：目前用 LEFT JOIN 即時查詢 `ReturnGoodsOrderSlave` 並篩選 `StatusDef == "Finish"`，但 `OrderSlaveFlow` 資料表本身已有 `OrderSlaveFlow_ReturnGoodsTotalPayment`（退貨總金額）與 `OrderSlaveFlow_ReturnGoodsOrderSlaveIsClosed` 等欄位（見 Table 定義）。

**為什麼有效（白話說明）**：每多 Join 一張表，資料庫就要多做一次「配對比對」的工作，資料量越大越明顯（本查詢一次要撈近 1 年資料）。如果別的表格已經幫你「事先算好」退貨金額並存成一個欄位，你直接讀那個欄位就好，不需要每次都重新去退貨明細表現場算一遍——這就像「帳本上已經寫好本月退款總額」，你直接看那一行數字，不用每次都把每張退貨單翻出來重新加總。前提是要先確認那個「已經算好的欄位」跟你即時算出來的結果意義完全一樣（是否只算「已完成」退貨、更新是否即時），這也是為什麼標註需要前置確認。

```csharp
// 現行：多一次 LEFT JOIN + 狀態篩選
join returnGoodsOrderSlave in this._erpReadDbContext.ReturnGoodsOrderSlave.Valids()
on orderSlaveFlow.OrderSlaveFlow_ReturnGoodsOrderSlaveId equals returnGoodsOrderSlave.ReturnGoodsOrderSlave_Id
into leftJoinReturnGoodsOrderSlave
from finishedReturnGoodsOrderSlave in leftJoinReturnGoodsOrderSlave
    .Where(x => x.ReturnGoodsOrderSlave_StatusDef == "Finish").DefaultIfEmpty()
...
ReturnGoodsOrderSlaveTotalPayment = finishedReturnGoodsOrderSlave.ReturnGoodsOrderSlave_TotalPayment ?? 0
```

```csharp
// 建議（需先與資料負責人確認欄位語意/即時性是否等同）：
// 直接使用 OrderSlaveFlow 上已彙總的退貨金額欄位，省去一次 Join
ReturnGoodsOrderSlaveTotalPayment = orderSlaveFlow.OrderSlaveFlow_ReturnGoodsTotalPayment
```
**效果**：4 表 Join 降為 3 表 Join，減少一次資料表存取與篩選成本。
**⚠️ 前置確認**：需先確認 `OrderSlaveFlow_ReturnGoodsTotalPayment` 是否僅計入「已完成（Finish）」的退貨、更新時機是否與即時查詢一致，避免金額計算邏輯跑掉。

### 5.4 評估用 `OrderSlaveFlow` 既有日期欄位取代 Join `SalesOrderGroup`

**觀察**：`OrderSlaveFlow` 資料表已有 `OrderSlaveFlow_TradesOrderSlaveDateTime`（訂單成立日期時間）欄位。若此欄位與 `SalesOrderGroup_DateTime`（購物車訂單成立時間）語意等價，理論上可以省去 Join `SalesOrderGroup` 這張表。

**為什麼有效（白話說明）**：跟 5.3 是同樣的道理——如果「同一張表」上已經有你要的日期欄位，就不需要為了拿一個日期，特地多 Join 一張表（`SalesOrderGroup`）。這裡的差別在於：`SalesOrderGroup` 記的是「整張購物車（一次結帳，可能包含多個明細）」的成立時間，而 `OrderSlaveFlow_TradesOrderSlaveDateTime` 記的是「單一明細流程」的時間。多數情況下同一張購物車內的明細時間會非常接近甚至相同，但這只是「通常如此」，不是資料庫規則保證的「一定如此」。所以這項優化的效益雖高（可以再省一張表的 Join），但風險也最高：如果兩者其實有落差，篩出來的訂單範圍就會跟原本不一樣，等於改變了業務邏輯。這就是為什麼要先請熟悉這兩張表的人確認語意一致，才能安心採用。

```csharp
// 建議方向（需先驗證兩欄位資料是否一致，不可貿然替換）：
where orderSlaveFlow.OrderSlaveFlow_TradesOrderSlaveDateTime >= startDate
   && orderSlaveFlow.OrderSlaveFlow_TradesOrderSlaveDateTime < endDate
```
**⚠️ 前置確認**：`SalesOrderGroup` 是購物車（訂單群組）層級的時間，`OrderSlaveFlow` 是單筆明細流程層級的時間，兩者「通常」同值，但不保證 100% 一致（例如同一購物車內多筆明細若有不同異動時間）。**這項優化需要資料/需求方確認語意等價後才能採用**，屬於高效益但需審慎驗證的項目，不建議在未驗證前直接上線。

### 5.5 加上 `AsNoTracking()`（若尚未啟用）

**為什麼有效（白話說明）**：EF 預設會幫每一筆查詢回來的資料「建檔追蹤」，方便你之後修改後呼叫 `SaveChanges()` 能知道哪裡變了。但這份查詢只是「讀資料算金額」，不會修改、也不會存回去，那份「建檔追蹤」的動作就完全是白工——多花 CPU 時間去記錄一份你根本不會用到的變更快照，資料量越大這個多餘負擔越明顯。`AsNoTracking()` 就是告訴 EF「這批資料我只看不改，不用幫我建檔」，讓它省下這道手續。

```csharp
// 建議：讀取專用查詢加上 AsNoTracking()，避免 EF Change Tracker 追蹤查詢結果
var result = (from ... select ...).AsNoTracking();
```
**效果**：此查詢僅供讀取彙總，不需要 EF 追蹤實體異動。加上 `AsNoTracking()` 可降低 Context 的記憶體與 CPU 開銷（尤其在 `.ToList()` 搬回大量列時效果更明顯）。若 `_erpReadDbContext` 已全域設定 `Configuration.AutoDetectChangesEnabled = false` 或使用唯讀 Context，此項可能已生效，建議確認現況。

### 5.6 讓聚合真正下推到資料庫（與方案1呼應，附完整改寫）

**為什麼有效（白話說明）**：目前的寫法是「把近一年所有符合條件的訂單明細一筆一筆搬回應用程式伺服器，再由 C# 程式碼做加總」。但呼叫端最終只需要「一個總金額」和「最後交易時間」這兩個數字，卻要先把可能成千上百筆的明細資料，透過網路傳輸、佔用應用程式記憶體、逐筆迭代加總。這就像你只想知道「這個月花了多少錢」，卻要求銀行把每一筆交易明細都印出來寄給你，你再自己拿計算機加總——不如直接請銀行（資料庫）算好總額，只告訴你一個數字就好。資料庫本身就是為了「大量資料聚合計算」而生的高效引擎（有索引、有平行處理），讓它做 `SUM`/`MAX` 遠比把資料搬到應用層再迭代快得多，也大幅減少網路傳輸量與應用程式記憶體壓力。

```csharp
// 建議：查詢直接回傳彙總結果，而非明細列表
public MemberOnlineOrderSummaryEntity GetMemberOnlineOrderSummary(
    long shopId, int memberId, DateTime startDate, DateTime endDate, IEnumerable<string> excludedStatusList)
{
    var transactionOptions = new TransactionOptions { IsolationLevel = IsolationLevel.ReadUncommitted };
    using (var transactionScope = new TransactionScope(TransactionScopeOption.Required, transactionOptions))
    {
        var query = from orderSlaveFlow in this._erpReadDbContext.OrderSlaveFlow.Valids()
                    join salesOrderSlave in this._erpReadDbContext.SalesOrderSlave.Valids()
                    on orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveId equals salesOrderSlave.SalesOrderSlave_Id
                    join salesOrderGroup in this._erpReadDbContext.SalesOrderGroup.Valids()
                    on orderSlaveFlow.OrderSlaveFlow_TradesOrderGroupId equals salesOrderGroup.SalesOrderGroup_TradesOrderGroupId
                    where orderSlaveFlow.OrderSlaveFlow_MemberId == memberId
                       && orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveShopId == shopId
                       && salesOrderGroup.SalesOrderGroup_DateTime >= startDate
                       && salesOrderGroup.SalesOrderGroup_DateTime < endDate
                       && orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Cancel.ToString()
                       && orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Fail.ToString()
                    select new
                    {
                        salesOrderSlave.SalesOrderSlave_TotalPayment,
                        orderSlaveFlow.OrderSlaveFlow_ReturnGoodsTotalPayment,
                        salesOrderGroup.SalesOrderGroup_DateTime
                    };

        // 資料庫端直接算總金額與最後交易時間，只回傳一列彙總結果
        var summary = query
            .GroupBy(x => 1)
            .Select(g => new MemberOnlineOrderSummaryEntity
            {
                TotalNetAmount = g.Sum(x => (x.SalesOrderSlave_TotalPayment ?? 0) - (x.OrderSlaveFlow_ReturnGoodsTotalPayment)),
                LastTradeDateTime = g.Max(x => (DateTime?)x.SalesOrderGroup_DateTime)
            })
            .FirstOrDefault();

        return summary ?? new MemberOnlineOrderSummaryEntity();
    }
}
```
**效果**：新增一個 `MemberOnlineOrderSummaryEntity`（僅含 `TotalNetAmount`、`LastTradeDateTime` 兩欄），查詢結果從「N 筆明細」變成「1 筆彙總」，資料庫只需回傳一個數字與一個時間，網路傳輸與應用層記憶體成本趨近於零。
**⚠️ 影響範圍**：呼叫端 `GetMemberOmoOrderKeyPrompt.GetKeyPrompt` 需同步調整，改為直接讀取 `TotalNetAmount`/`LastTradeDateTime`，不再走 `.Sum()`/`.OrderByDescending().First()`；需補上對應單元測試（依團隊規範需使用 NSubstitute mock Repository）。

### 5.7 若語法優化仍不足：Dapper 手寫 SQL 作為最後手段

**為什麼有效（白話說明）**：EF6 是透過「翻譯」把 LINQ 轉成 SQL，翻譯的過程有時候會「詞不達意」——尤其是多表 Join 又加上 GroupBy 這種複雜組合，EF6 產生出來的 SQL 語法結構，不一定是資料庫執行效率最好的寫法（例如可能多包了一層子查詢、或沒有用上你期望的索引）。Dapper 則是讓你直接手寫 SQL、掌控每一個細節，就像自己開車 vs. 坐別人開的車：你能精準控制轉彎時機、加速煞車，而不是依賴翻譯層的自動決策。但這也表示要自己維護 SQL 字串、失去 EF 的型別安全與自動化好處，屬於效益最大但改動與維護成本也最高的手段，因此建議留到前面幾項都做完仍不夠快時才考慮。

若上述 LINQ 層級優化後，實際執行計畫仍不理想（例如 EF6 對多表 Join + GroupBy 產生的 SQL 不夠精簡），可評估針對此單一高風險查詢，改用 Dapper 撰寫手工優化過的 SQL（專案已引入 Dapper 1.50.2），直接控制 Join 順序、索引提示、聚合方式，作為效能優化的最後一道手段。此作法變動較大，建議排在前述語法優化與索引調整都驗證無效後再考慮。

### 5.8 「先篩選出子集合、再 Join」是否有效？（拆分查詢討論）

**問題發想**：能不能先查出符合條件的 `OrderSlaveFlow`（或其 `SalesOrderSlaveId`）子集合，再拿這批 ID 去跟其他表 Join，藉此縮小 Join 的資料量？

**結論：這個直覺是對的，但「拆」的位置很關鍵，拆錯地方效果適得其反。**

| 拆法 | 是否有效 | 原因 |
|---|---|---|
| LINQ 兩段查詢，但中間沒有 `.ToList()` 中斷 | ❌ 無效 | EF6 仍會把兩段組合翻譯成同一支 SQL，對資料庫來說跟寫一支查詢完全一樣 |
| LINQ 兩段查詢，中間 `.ToList()` 真的拆成兩次 DB 往返 | ⚠️ 視資料量，會員訂單量大時反而更差 | 第二步 `Contains(idList)` 會被翻成巨大的 `IN (@p0...@p3000)`，SQL Server 單一查詢參數上限 2100 個，超過會直接壞掉；即使沒超過，龐大且每次不同的 IN 清單也會讓執行計畫無法有效複用/快取。而且資料庫實際要碰觸的 row 數並沒有減少，多一次往返沒省到工 |
| **同一支 SQL 內用 CTE / 子查詢表達「先篩選、再 Join」的順序**（見 Tier 3 範例） | ✅ 有效，風險最低 | 仍是單一執行計畫、單一次往返，優化器可以先執行篩選幅度最大的那段（如果索引夠好會是 Index Seek），再對縮小後的集合做 Join，沒有 IN 清單爆炸的風險 |
| 真正縮小查詢範圍（縮短月份、加索引） | ✅ 效果最直接 | 從根本減少資料庫要碰觸的實際 row 數，其他拆法都只是「換個方式碰觸差不多量的資料」 |

**白話總結**：拆分的價值不在「C# 程式碼分兩段寫」，而在於「SQL 執行計畫能不能先鎖定小範圍再做後續工作」。在 EF6 LINQ 裡，只要把高選擇性條件放在起始表（見 5.1），優化器通常會自動做到「先篩選、再 Join」；如果還是不夠快，正確的下一步是把「先篩選」用 CTE/暫存表的方式直接寫進 SQL 裡（見六、Tier 3 範例），而不是在應用層真的切成兩次資料庫呼叫並傳一串 ID 清單回去，那樣反而容易踩到 IN 清單上限與執行計畫快取失效的地雷。

---

## 六、最佳優化寫法完整示範（三層式）

以下依「風險與效益」分成三層，建議由 Tier 1 開始導入，觀察效果後再評估是否往下一層走。

### Tier 1：安全立即可用版本（不改變任何業務語意，純查詢結構優化）

套用範圍：起始表改為 `OrderSlaveFlow`（5.1 filter push-down）、`!=` 取代大 IN 清單（5.2）、`AsNoTracking()`（5.5）、聚合下推到資料庫（5.6）。**保留** Join `ReturnGoodsOrderSlave` 與 `SalesOrderGroup`，因為省略它們（5.3/5.4）需要業務方驗證欄位語意，這裡先不冒險。

```csharp
/// <summary>
/// 取得會員線上訂單彙總（淨消費金額、最後交易時間）
/// </summary>
/// <param name="shopId">商店序號</param>
/// <param name="memberId">會員序號</param>
/// <param name="startDate">起始日期</param>
/// <param name="endDate">結束日期</param>
/// <returns>會員線上訂單彙總</returns>
public MemberOnlineOrderSummaryEntity GetMemberOnlineOrderSummary(
    long shopId, int memberId, DateTime startDate, DateTime endDate)
{
    var transactionOptions = new TransactionOptions { IsolationLevel = IsolationLevel.ReadUncommitted };
    using (var transactionScope = new TransactionScope(TransactionScopeOption.Required, transactionOptions))
    {
        // 先套用高選擇性條件（MemberId + ShopId + 狀態），把起始集合縮到最小
        var filteredFlow = this._erpReadDbContext.OrderSlaveFlow.Valids()
            .Where(f => f.OrderSlaveFlow_MemberId == memberId
                     && f.OrderSlaveFlow_SalesOrderSlaveShopId == shopId
                     && f.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Cancel.ToString()
                     && f.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Fail.ToString());

        var query = from orderSlaveFlow in filteredFlow
                    join salesOrderSlave in this._erpReadDbContext.SalesOrderSlave.Valids()
                    on orderSlaveFlow.OrderSlaveFlow_SalesOrderSlaveId equals salesOrderSlave.SalesOrderSlave_Id
                    join salesOrderGroup in this._erpReadDbContext.SalesOrderGroup.Valids()
                    on orderSlaveFlow.OrderSlaveFlow_TradesOrderGroupId equals salesOrderGroup.SalesOrderGroup_TradesOrderGroupId
                    join returnGoodsOrderSlave in this._erpReadDbContext.ReturnGoodsOrderSlave.Valids()
                    on orderSlaveFlow.OrderSlaveFlow_ReturnGoodsOrderSlaveId equals returnGoodsOrderSlave.ReturnGoodsOrderSlave_Id
                    into leftJoinReturnGoodsOrderSlave
                    from finishedReturnGoodsOrderSlave in leftJoinReturnGoodsOrderSlave
                        .Where(x => x.ReturnGoodsOrderSlave_StatusDef == "Finish").DefaultIfEmpty()
                    where salesOrderGroup.SalesOrderGroup_DateTime >= startDate
                       && salesOrderGroup.SalesOrderGroup_DateTime < endDate
                    select new
                    {
                        salesOrderSlave.SalesOrderSlave_TotalPayment,
                        ReturnPayment = finishedReturnGoodsOrderSlave.ReturnGoodsOrderSlave_TotalPayment,
                        salesOrderGroup.SalesOrderGroup_DateTime
                    };

        // 聚合下推到資料庫，只回傳一列彙總結果，不搬明細回應用層
        var summary = query
            .AsNoTracking()
            .GroupBy(x => 1)
            .Select(g => new MemberOnlineOrderSummaryEntity
            {
                TotalNetAmount = g.Sum(x => (x.SalesOrderSlave_TotalPayment ?? 0) - (x.ReturnPayment ?? 0)),
                LastTradeDateTime = g.Max(x => (DateTime?)x.SalesOrderGroup_DateTime)
            })
            .FirstOrDefault();

        return summary ?? new MemberOnlineOrderSummaryEntity();
    }
}
```
> ⚠️ 呼叫端 `GetMemberOmoOrderKeyPrompt` 需同步從「拿明細清單自己 `.Sum()`」改為直接讀 `TotalNetAmount`/`LastTradeDateTime`；並補上 NSubstitute 單元測試（依團隊規範）。

### Tier 2：業務方驗證欄位語意後可再省 2 張表 Join

若確認 `OrderSlaveFlow_ReturnGoodsTotalPayment` 等同即時 Join 算出的退貨金額、且 `OrderSlaveFlow_TradesOrderSlaveDateTime` 等同 `SalesOrderGroup_DateTime`，可以整段查詢再瘦身成**完全不用 Join**：

```csharp
var summary = this._erpReadDbContext.OrderSlaveFlow.Valids()
    .Where(f => f.OrderSlaveFlow_MemberId == memberId
             && f.OrderSlaveFlow_SalesOrderSlaveShopId == shopId
             && f.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Cancel.ToString()
             && f.OrderSlaveFlow_SalesOrderSlaveStatusDef != SalesOrderSlaveStatusEnum.Fail.ToString()
             && f.OrderSlaveFlow_TradesOrderSlaveDateTime >= startDate
             && f.OrderSlaveFlow_TradesOrderSlaveDateTime < endDate)
    .AsNoTracking()
    .GroupBy(x => 1)
    .Select(g => new MemberOnlineOrderSummaryEntity
    {
        TotalNetAmount = g.Sum(x => x.OrderSlaveFlow_TotalPayment - x.OrderSlaveFlow_ReturnGoodsTotalPayment),
        LastTradeDateTime = g.Max(x => (DateTime?)x.OrderSlaveFlow_TradesOrderSlaveDateTime)
    })
    .FirstOrDefault() ?? new MemberOnlineOrderSummaryEntity();
```
單表查詢＋聚合，理論上只要 `(MemberId, ShopId, StatusDef)` 有索引，執行速度會非常快。**這層要先跟資料負責人確認欄位等價性才能上線**，風險最高但效益也最大。

### Tier 3：終極手段（Dapper + CTE，Tier 1/2 都不夠快時才用）

```csharp
public MemberOnlineOrderSummaryEntity GetMemberOnlineOrderSummary(long shopId, int memberId, DateTime startDate, DateTime endDate)
{
    const string sql = @"
        ;WITH FilteredFlow AS (
            SELECT OrderSlaveFlow_SalesOrderSlaveId, OrderSlaveFlow_TradesOrderGroupId,
                   OrderSlaveFlow_ReturnGoodsOrderSlaveId
            FROM OrderSlaveFlow WITH (NOLOCK)
            WHERE OrderSlaveFlow_MemberId = @MemberId
              AND OrderSlaveFlow_SalesOrderSlaveShopId = @ShopId
              AND OrderSlaveFlow_SalesOrderSlaveStatusDef NOT IN ('Cancel','Fail')
        )
        SELECT
            SUM(s.SalesOrderSlave_TotalPayment - ISNULL(r.ReturnGoodsOrderSlave_TotalPayment, 0)) AS TotalNetAmount,
            MAX(g.SalesOrderGroup_DateTime) AS LastTradeDateTime
        FROM FilteredFlow f
        JOIN SalesOrderSlave s WITH (NOLOCK) ON s.SalesOrderSlave_Id = f.OrderSlaveFlow_SalesOrderSlaveId
        JOIN SalesOrderGroup g WITH (NOLOCK) ON g.SalesOrderGroup_TradesOrderGroupId = f.OrderSlaveFlow_TradesOrderGroupId
                                              AND g.SalesOrderGroup_DateTime >= @StartDate AND g.SalesOrderGroup_DateTime < @EndDate
        LEFT JOIN ReturnGoodsOrderSlave r WITH (NOLOCK) ON r.ReturnGoodsOrderSlave_Id = f.OrderSlaveFlow_ReturnGoodsOrderSlaveId
                                                          AND r.ReturnGoodsOrderSlave_StatusDef = 'Finish';";

    using (var connection = this._erpReadDbContext.Database.Connection)
    {
        return connection.QueryFirstOrDefault<MemberOnlineOrderSummaryEntity>(sql,
            new { MemberId = memberId, ShopId = shopId, StartDate = startDate, EndDate = endDate })
            ?? new MemberOnlineOrderSummaryEntity();
    }
}
```
單一 SQL、單一往返，CTE 讓執行計畫可以先窄化 `OrderSlaveFlow`，聚合完全在 DB 端完成，最大程度控制執行計畫，但失去 EF 型別安全，需自行維護 SQL 字串。

**建議採用順序**：Tier 1（現在就能做，零風險）→ 補索引（DBA 確認 `OrderSlaveFlow(MemberId, ShopId, StatusDef)`）→ 觀察是否解決 timeout → 若還不夠，才考慮 Tier 2（需驗證）或 Tier 3（Dapper）。

---

## 七、附錄：與本次 ELMAH 事件的對應關係

| ELMAH 錯誤類型 | 對應優化方案 |
|---|---|
| `EntityCommandExecutionException`（本查詢逾時且無 try/catch 導致 API 500） | 方案 5（止血）+ 方案 1、2、3（治本）|
| `Win32Exception`（ECoupon 歷程查詢逾時，機制類似） | 可套用相同的方案 1、2、4 於 `ECouponInfoRepository.GeECouponInfoMemberHistoryList` |
| 多種錯誤同一時間點群聚發生 | 方案 8（平行架構調整）能降低群聚效應 |

---

## 八、架構層深入分析：`OmoKeyPromptsService` 平行任務的資源競爭問題

> 本章節整理自對 `/scm/v2/LocationMember/GetOmoKeyPromptsFromMemberDimension`（與 `Location/GetLastOmoKeyPromptsFromMemberDimension` 底層共用同一個 Service）近 1~2 週 ELMAH 時間分布分析後，延伸出的架構層根因討論。與第五、六章「單一查詢語法優化」不同，本章聚焦在「9 個平行任務彼此之間」的交互影響。

### 8.1 時間分布：規律性群聚現象

對近一週（189 筆）與近兩週（實際約 10 天，217 筆，ELMAH Dashboard 資料保留期僅約 10 天）的錯誤記錄做六維分析，兩次獨立觀測結果高度一致：

| 維度 | 近一週 | 近兩週（~10天） |
|---|---|---|
| **分鐘級群聚**：`:11`～`:13` 三分鐘窗口佔比 | 82%（155/189） | 81.6%（177/217） |
| Exception Type 排序 | Win32Exception(67.7%) > EntityCommandExecutionException(23.8%) > TaskCanceledException(5.3%) > FlurlHttpException(3.2%) | 比例幾乎一致 |
| ShopId 集中 | 9、19、82 三家佔約 78% | 比例幾乎一致 |

**結論**：不論發生在哪個小時（10/11/12/18點…），錯誤都高度集中在該小時第 **11~13 分**，兩次觀測比例幾乎相同，代表這是**穩定、規律性的排程/門市裝置心跳觸發**，並非偶發流量尖峰，強烈建議追查固定週期性排程或門市 App 輪詢設定的來源。

### 8.2 驗證：多種 Exception Type 是否「同時發生」

用 ELMAH 記錄的 `queryString`（含 `t`+`ts`+簽章，可視為單一請求的唯一識別碼）分組驗證：

| 指標 | 數字 |
|---|---|
| 10 天內獨立請求數（依 queryString 去重） | 103 次 |
| 其中**同一次請求內同時出現 2 種以上不同 Exception Type** | **64 次（62%）** |

範例：`07/18 11:13:05 Shop=19 => [Win32Exception, EntityCommandExecutionException, Win32Exception, TaskCanceledException]`（同一次請求、4 筆例外）。

**結論**：多數情況下，DB 連線逾時（`Win32Exception`）、SQL 逾時（`EntityCommandExecutionException`）、外部服務逾時（`TaskCanceledException`/`FlurlHttpException`）**是在同一次會員查詢中同時發生**，並非各自獨立巧合，直接對應下方 8.3 的平行任務架構。

### 8.3 `OmoKeyPromptsService` 的 9 個平行任務盤點

`GetOmoKeyPromptsFromMemberDimension` 用 `Task.Run` 同時派出 9 個 `IOmoKeyPrompt` 任務，`Task.WhenAll().Wait()` 阻塞等待彙總：

| # | Task Name | 型態 | DB 表（去重後） | 外部 API |
|---|---|---|---|---|
| 1 | AppDownloadDataTask | DB + 外部API | `DeviceAPPMapping`、`VipMemberPresentExtendedSummary`、`pub_content`、`coupon_pool` | CampaignService |
| 2 | BirthdayPresentDataTask | DB + 外部API | `VipMember`系列、`ECoupon`系列、`coupon`、`CrmMember`系列（多表）、`ShopMember`(SP) | CampaignService |
| 3 | MemberCouponDataTask | 純 DB | 設定表 + `coupon`/`pub_content`/`ECoupon`系列 + `ShopMember` | 無 |
| 4 | MemberFillInfoTask | 純 DB | `VipMemberInfo`、`CrmMember` | 無 |
| 5 | MemberLoyaltyPointDataTask | 純 DB | 點數帳戶表 + `ECoupon`系列 | 無 |
| 6 | OpenCardPresentTask | DB + 外部API | `VipMemberPresent`、`VipMemberInfo`、`pub_content`、`coupon_pool`、`ShopMember`(SP) | CampaignService |
| 7 | ShoppingCartDataTask | 純 DB（單一SP） | `GetShopMemberShoppingCartList` SP | 無 |
| 8 | MemberLineIdBindingInfoTask | DB + 外部API | `MemberLineMapping` + 合約表 | Omnichat |
| 9 | **OmoOrderDataTask**（唯一無 try/catch） | 純 DB，範圍最大最重 | `SalesOrderSlave`/`OrderSlaveFlow`/`SalesOrderGroup`/`ReturnGoodsOrderSlave`（近1年）+ `CrmMember`、`ShopContractFeature`、`Shop` | 無 |

**觀察**：沒有任何任務是「純外部 API」，全部或多或少都查 DB；`CampaignService` 被 4 個任務重複呼叫，是外部依賴最集中的單點；第 9 個任務（也是唯一沒有 try/catch 的）剛好也是查詢範圍最大、最容易逾時的任務。

### 8.4 「自己撞自己」：同一次請求內的重複查詢

進一步比對 9 個任務的呼叫參數，發現**同一次請求內**，多個任務對**完全相同的 `MemberId`+`ShopId`** 重複查詢同一份資料：

| 重複的資料 | 同時被幾個任務查 | 涉及任務 | 呼叫方法 |
|---|---|---|---|
| `CrmMember`（同一組 MemberId+ShopId） | 3 個 | Birthday、FillInfo、**OmoOrder** | `ICrmMemberRepository.GetCrmMemberWithNoLock(MemberId, ShopId)`，參數完全相同 |
| 會員 ECoupon/Coupon 清單 | 2 個 | Birthday、OpenCardPresent | `IShopMemberRepository.GetShopMemberECouponAndCouponList(ShopId, MemberId)` |
| `pub_content`/`coupon_pool` | 2 個 | AppDownload、OpenCardPresent | `ICouponRepository.GetCouponPoolList` |
| VipMember 系列 | 3 個 | AppDownload、Birthday、OpenCardPresent | `IVipMemberRepository.*` |

`GetCrmMemberWithNoLock` 實作：

```csharp
public CrmMember GetCrmMemberWithNoLock(int nineYiMemberId, long shopId)
{
    var transactionOptions = new TransactionOptions { IsolationLevel = IsolationLevel.ReadUncommitted };
    using (var ts = new TransactionScope(TransactionScopeOption.Required, transactionOptions))
    {
        return this._crmDbContext.CrmMember.Valids()
            .Where(i => i.CrmMember_NineYiMemberId == nineYiMemberId && i.CrmMember_ShopId == shopId)
            .FirstOrDefault();
    }
}
```

同一次請求裡，3 個不同 `Task.Run` 執行緒各自開一個新 `TransactionScope`、各自借一條 DB 連線，去查**完全一樣的一筆資料**。

### 8.5 這是「鎖競爭」還是「資源排隊」？

**釐清一個容易誤解的地方**：這種重複查詢造成的「卡到」，**不是 SQL 鎖等待（lock blocking）**，而是**資源池排隊（resource contention）**：

- `GetCrmMemberWithNoLock` 特意用 `IsolationLevel.ReadUncommitted`（等同 `NOLOCK`），刻意避開了列鎖／被寫入鎖擋到的情況，多個純讀取查詢彼此鎖住的機率本來就低。
- 真正的競爭發生在**應用層與 DB 層的有限資源池**：
  - **ADO.NET 連線池**：每個查詢都要從池子借一條實體連線
  - **.NET ThreadPool**：`Task.Run` 佔用的工作執行緒
  - **DB Server 端 CPU/IO**：重複計算同樣的東西 N 次，浪費算力

### 8.6 是否因連線池壓力導致無法同時送出查詢？

實測確認：`SCMAPIV2` 專案所有 connection string（`CrmDbContext`、`CrmDbARContext` 等）**皆未明確設定 `Max Pool Size`**，代表全部使用 ADO.NET SqlClient 預設值 **`Max Pool Size = 100`**。

推論因果鏈：

1. 單一次 `GetOmoKeyPromptsFromMemberDimension` 請求，9 個任務中至少 6 個查 DB，且部分重複查詢同一資料 → 保守估計**一次請求可能同時消耗 5~8 條連線**
2. 疊加 8.1 發現的「`:11~13分` 多商店同時觸發」現象，若同一秒有 15~20 個會員請求同時發生 → **理論連線需求可達 100~150+，逼近/超過 `Max Pool Size=100`**
3. 這正好解釋 `Win32Exception` 為何是最大宗（67.7%）：其典型訊息為
   > *"Timeout expired. The timeout period elapsed prior to obtaining a connection from the pool. This may have occurred because all pooled connections were in use and max pool size was reached."*
   即**應用程式連 DB 之前，光是排隊等一條可用連線就先逾時**，而非查詢本身跑很慢。
4. 少數擠過連線階段、真的送進 DB 的查詢，又因 DB 端資源同時被打滿，逾時炸出 `EntityCommandExecutionException`（SQL 命令逾時）。

> ⚠️ **重要修正（見 8.8 實測結果）**：實際調閱 ELMAH 完整 Stack Trace 後發現，本節「連線池排隊逾時」的假設**並未獲得直接證據支持**，真正的 Exception 訊息指向的是 **SQL 命令「執行逾時」（Execution Timeout Expired）**，而非連線池等待逾時。詳見 8.8。此節保留作為「原始假設」紀錄，實際根因請以 8.8 修正結論為準。

### 8.7 治本 vs 治標：兩種互補（非互斥）的優化方向

| 方向 | 做法 | 性質 | 效果 |
|---|---|---|---|
| **治本** | 在 `GetOmoKeyPromptsFromMemberDimension` 最上層，把會被多任務共用的資料（`CrmMember`、`GetShopMemberECouponAndCouponList` 結果、`VipMember` 資訊）**查詢一次**，再以參數傳給下面 9 個 `IOmoKeyPrompt.GetKeyPrompt()`，取代各自重複查 | 架構調整，需修改 `IOmoKeyPrompt` 介面簽名 | 直接減少每次請求消耗的連線數與重複查詢量（如 `CrmMember` 從 3 次降到 1 次） |
| **治標** | 調高 `Max Pool Size` 並建立連線數監控（如 SQL Server DMV `sys.dm_exec_connections` 或 APM） | 設定調整 | 讓系統有更多緩衝撐過尖峰，但不解決浪費本身 |
| **止血**（已列於方案5） | `GetMemberOmoOrderKeyPrompt` 補上 try/catch | 低風險 | 避免單一任務逾時直接讓整支 API 500 |
| **追查根因** | 排查固定分鐘級群聚（`:11~13分`）背後的排程/門市裝置心跳來源，評估加入 jitter 分散觸發時間 | 需跨團隊確認（門市 App/排程系統） | 從源頭降低瞬間併發量，是影響最大的長期解法 |

**建議導入順序**：止血（try/catch）→ 追查排程根因（jitter分散）→ 治本（共用資料預查，減少重複）→ 視監控數據決定是否治標（調高連線池）。

### 8.8 實測修正：Timeout 真正原因為何？如何找證據驗證？

#### 修正發現：調閱完整 Stack Trace 後推翻「連線池排隊」假設

實際抓取一筆 `Win32Exception` 的完整 ELMAH detail：

```
Win32Exception: The wait operation timed out
  ← EntityCommandExecutionException
    ← SqlException: Execution Timeout Expired.
      The timeout period elapsed prior to completion of the operation or the server is not responding.
```

再核對全部 217 筆訊息文字分布：

| Exception Type | 筆數 | 訊息內容 |
|---|---|---|
| `Win32Exception` | 146 | **一律**是 `The wait operation timed out` |
| `EntityCommandExecutionException` | 53 | 一律是外層包裝訊息，內層即上方 SqlException |
| `TaskCanceledException` | 12 | `A task was canceled` |
| `FlurlHttpException` | 6 | **`400 Bad Request` 呼叫 CampaignService `GetMemberPresentInfo`**（非 timeout，是業務參數錯誤） |

**修正結論**：`Win32Exception`/`EntityCommandExecutionException` 實際上是 **SQL 命令「執行逾時」（`CommandTimeout` 到期）**——查詢已成功取得連線、送進 DB 開始執行，但跑太久才逾時，訊息中完全沒有出現連線池滿的典型字樣（*"...prior to obtaining a connection from the pool..."*）。真正瓶頸更可能在 **DB Server 端執行資源（CPU/IO/鎖等待）被瞬間打滿**，而非應用層連線池排隊。此結論仍與「9個任務重複查詢、浪費DB算力」的推論相關，但機制描述需修正為「DB端忙不過來」而非「連線池爆了」。另外 `FlurlHttpException` 屬於不同性質的錯誤（CampaignService 業務參數問題），不應與前三種 timeout 類錯誤混在一起分析。

#### 後續驗證方法（如何找證據證實/推翻上述修正結論）

| # | 方法 | 做法 | 用途 |
|---|---|---|---|
| 1 | **DB端歷史數據回溯**（最推薦，免改程式碼） | 若有 Query Store：查 `sys.query_store_runtime_stats`，比對可疑 SQL 在 `:11~13分` vs 其他時間的平均執行時間/CPU/邏輯讀取次數；若無則調閱 PerfMon/Zabbix/Datadog 的 `Batch Requests/sec`、`% CPU`、`Page Life Expectancy`、`Lock Waits/sec` 歷史 | 直接證實「DB端當下是否真的變慢/資源被打滿」 |
| 2 | **即時監控**（下次尖峰現場抓證據） | 請 DBA 開 SQL Server Extended Events session，過濾 `sql_statement_completed`/`rpc_completed` 且 duration 超過門檻；同時查應用端 **Application Insights 的 Dependency 追蹤**（ELMAH log 內已見 `HTTP_APPLICATIONINSIGHTS_REQUESTTRACKINGTELEMETRYMODULE_ROOTREQUEST_ID`，代表 App Insights 已在運作，可直接查） | 確認 `:11~13分` 是否真有大量同類 SQL **同時**被送進執行，且已有現成監控管道 |
| 3 | **程式碼埋點計時**（分辨排隊延遲 vs 真執行慢） | 在 `Task.Run` 內用 `Stopwatch` 分別記錄「dispatch到開始執行的排隊延遲」與「實際查詢/呼叫耗時」兩段時間並記錄 log | `queueDelay` 大 → ThreadPool 執行緒不足；`execTime` 大 → 真的是 DB/外部服務慢，可精確定位問題在應用層還是 DB 層 |
| 4 | **受控實驗**（Staging重現） | 用 JMeter/k6 對 QA/Staging 模擬同一秒 15~20 個不同會員打此 API，觀察能否重現相同 Exception Type 分布比例 | 能重現 → 證實是併發量本身造成；不能重現 → 代表 Prod DB 當下可能疊加其他背景負載（批次工作/報表查詢） |
| 5 | **驗證固定分鐘群聚來源** | 查 IIS Log/CloudFront Log，篩出 `:11~13分` 請求，比對 `User-Agent`/`clientIP` 是否集中特定門市裝置或排程來源 IP；或直接詢問門市 App/NMQ 排程 owner 是否有固定該時段執行的心跳/輪詢任務，並嘗試 A/B 測試延後排程觀察錯誤是否消失 | 找出瞬間高併發的真正觸發源頭，是治本方案中影響最大的一步 |

```csharp
// 方法3 示範：Task.Run 埋點
var dispatchTime = DateTime.UtcNow;
Task.Run(() =>
{
    var startTime = DateTime.UtcNow;
    var queueDelay = (startTime - dispatchTime).TotalMilliseconds; // ThreadPool 排隊延遲
    var sw = Stopwatch.StartNew();
    var result = keyPrompt.GetKeyPrompt(request);
    sw.Stop(); // SQL/外部呼叫實際耗時
    _logger.Info($"{keyPrompt.GetType().Name} queueDelay={queueDelay}ms execTime={sw.ElapsedMilliseconds}ms");
    return result;
});
```

### 8.9 更關鍵的發現：問題不限於單一 API，而是「呼叫端跨 API 同時發動 + 重試風暴」

> 前面 8.1~8.8 的分析都聚焦在 `OmoKeyPromptsService` 這一支 API 內部的架構問題。本節進一步擴大範圍，撈取近 10 天內**整個 `NineYi.ScmApiV2` 應用**所有 URL 的 `Win32Exception`（訊息含 `wait operation`）記錄（共 7,640 筆），驗證「呼叫端是否本來就會一次打多支 API」，結果發現問題規模比單一 API 分析要大得多。

#### 證據 1：同一分鐘、同一商店，多達 8 種完全不同的 API 一起爆

```
07/16 18:12, Shop=9 => 470筆, URLs=[
  GetOmoKeyPromptsFromMemberDimension | GetLocationOfflineSalesOrderList |
  GetMemberConsumptionInfo | GetCouponList | GetMemberTradesOrderInfoAr |
  GetMemberTradesOrderInfo | GetPickupConfirmList | GetArrivedConfirmList
]
07/17 11:12, Shop=9 => 250筆, URLs=[7 種不同 API]
07/18 11:13, Shop=19 => 210筆, URLs=[4 種不同 API]
```

依「date+分鐘+ShopId」分組，10 天內共 171 組錯誤群聚，其中 **62 組（36%）同時出現 2 種以上不同 URL 的 API 一起爆**，證實不只是 `OmoKeyPromptsService` 內部 9 個任務互相影響，**呼叫端本身就會在同一時間點對一整批完全不同的 API 發動請求**。

#### 證據 2：追蹤 `t`（呼叫端身分識別碼）——確認是同一客戶端所為

```
07/16 18:12 Shop=9 這波 470 筆錯誤：
  t=00631528 → 470次（同一client）
  t=62251364 → 280次
```

抽樣看 `t=00631528` 這個呼叫端，同一分鐘內依序打了 `GetLocationOfflineSalesOrderList`（大量重複）→ `GetCouponList` → `GetMemberConsumptionInfo` → ...，**確認是同一個整合端（可能是門市 POS 系統或後台整合帳號）在極短時間內連續呼叫多支不同 API**。

#### 證據 3（更嚴重）：同一支 API 在同一秒內被重複打 10~20 次

```
GetLocationOfflineSalesOrderList，相同 ts=1784254304 → 20次
                                  相同 ts=1784254306 → 20次
                                  相同 ts=1784254313 → 20次
```

同一個簽章時間戳（代表極短時間內）同一支 API 被重複呼叫 10~20 次，高度符合「**逾時後立即重試（Retry Storm）**」的典型反模式：呼叫端缺乏 backoff 機制，一逾時就馬上重打，DB 當下已經在忙、本來就快撐不住，重試瞬間讓負載雪上加霜，形成自我放大的惡性循環。

#### 影響範圍對照（10 天內 Win32Exception 依 URL 統計 Top 5）

| URL | 筆數 |
|---|---|
| `/scm/v2/Location/GetLocationOfflineSalesOrderList` | 1,470 |
| `/scm/v2/LocationMember/GetOmoKeyPromptsFromMemberDimension` | 1,460 |
| `/scm/v2/ShopMember/GetCouponList` | 1,290 |
| `/scm/v2/Location/GetLastOmoKeyPromptsFromMemberDimension` | 930 |
| `/scm/v2/LocationMemberOrder/GetMemberConsumptionInfo` | 690 |

**其他 API（如 `GetLocationOfflineSalesOrderList`、`GetCouponList`）受影響次數甚至比本文件聚焦分析的 OMO KeyPrompt API 還多**，代表這是**跨整個應用層級的共用 DB 資源問題**，並非 `OmoKeyPromptsService` 獨有。

#### 修正後的完整因果鏈

```
少數幾個整合客戶端(t=00631528等)在固定時間點(:11~13分等)
  → 同時對「多支不同API」發起大量請求(非單一API內部問題)
  → 部分請求逾時後，缺乏 backoff 機制立即重試
  → 短時間內同一API被重打10~20次，疊加多支不同API的請求
  → DB Server 執行資源(CPU/IO)被大量重複且無意義的請求瞬間打滿
  → 幾乎「同時」所有觸碰DB的API(不限於OMO KeyPrompt)全部 Win32Exception 逾時
```

#### 建議下一步

1. **找出 `t=00631528`、`t=62251364` 等高頻客戶端對應的實際店家/整合系統**（透過 `SupplierApiProfile` 表反查其 `t` token 對應的商店與系統名稱），了解其呼叫模式（門市 POS？後台批次 job？第三方整合？）
2. **確認呼叫端是否存在無限重試機制**，若有，建議協調對方加入 exponential backoff + 最大重試次數限制
3. **評估是否該對高頻客戶端做 Rate Limiting / 節流**（可在 `ValidateTokenHandler` 或 API Gateway 層依 `t` 做限流），避免單一客戶端的重試風暴拖垮整個共用 DB
4. **本節發現與前述 8.1~8.8 的關係**：`OmoKeyPromptsService` 內部 9 任務重複查詢（8.4）與連線/執行資源競爭（8.6、8.8）依然是真實存在的問題，但它們是在「呼叫端已經先製造出跨 API 高併發」的前提下被放大的次要因子；**真正影響範圍最大、優先度最高的治本方向，應是先處理呼叫端的重試風暴與跨 API 併發，而非只優化單一 API 內部邏輯**。

### 8.10 這幾支 API 會互相影響嗎？逐支拆解「他們是否共用同一個 DB」

> 承接 8.9 節的疑問：既然是不同 API，為什麼會「同時」逾時？本節逐支追蹤程式碼，確認每支 API 實際連到哪一個資料庫（連線字串名稱）與哪個實體 DB Server 叢集，藉此證明「互相影響」不是巧合，而是**架構上原本就共用同一批 DB 資源**。

#### 8.10.1 SCMAPIV2 的 DB 拓樸：兩組實體 DB Server 叢集

從 `WebSite\ConnectionStrings.config` 可看到，SCMAPIV2 同時連接下列多個資料庫，且明顯分屬 **兩個實體 DB Server（Listener）叢集**：

| DB Server 叢集 | 連線字串名稱 | 對應資料庫 |
|---|---|---|
| **Lstn2** | `WebStore` / `WebStore.ReadOnly` | `WebStoreDB` |
| **Lstn2** | `APP` | `APPDB` |
| **Lstn2** | `Info` | `InfoDB` |
| **Lstn2** | `Notification` | `NotificationDB` |
| **Lstn2** | `ExceptionLog` | `ExceptionLogDB` |
| **Lstn3** | `CRM` / `CRM.ReadOnly` | `CRMDB` |
| **Lstn3** | `CRMAR.ReadOnly` | `CRMDBAR`（CRM 歷史封存） |
| **Lstn3** | `ERP` / `ERP.ReadOnly` | `ERPDB` |
| **Lstn3** | `ERPAR.ReadOnly` | `ERPDBAR` |
| **Lstn3** | `Audience` / `Audience.ReadOnly` | `AudienceDB` |
| **Lstn3** | `NineYiDW` / `NineYiDW.ReadOnly` | `NineYiDW`（報表倉儲） |
| **Lstn3** | `Channel` / `Channel.ReadOnly` | `ChannelDB` |
| **Lstn3** | `CRMTemp` | `CRMTempDB` |
| **Lstn3** | `Trace` | `TRACEDB` |
| **Lstn3** | `AuthExternal` | `AuthExternalDB` |

> ⚠️ **關鍵重點**：`Lstn3` 這一組 DB Server，同時扛著 `CRM`、`CRMAR`、`ERP`、`ERPAR`、`Audience`、`NineYiDW`、`Channel`、`CRMTemp`、`Trace`、`AuthExternal` **共 10 個資料庫**。就算 7 支 API 彼此查詢的「資料庫」不同（如一支查 CRM、一支查 ERP），只要都落在 `Lstn3` 這一組實體伺服器上，**依然是共用同一批實體 CPU / IO / TempDB / 連線數**，會互相搶資源。

#### 8.10.2 逐支 API 拆解：查哪個 DB、哪些表

| # | API | 內部關鍵資料流 | 使用的 DB（連線字串） | DB Server 叢集 | 主要資料表（節錄） |
|---|---|---|---|---|---|
| 1 | `GetOmoKeyPromptsFromMemberDimension`（9 個平行任務加總） | `OmoKeyPromptsService` → 9 個 `IOmoKeyPrompt` 任務 | **WebStore**（7 個任務）+ **CRM**（3 個任務）+ **ERP**（1 個任務，`OmoOrderDataTask`） | **Lstn2 + Lstn3 都命中** | WebStore：`ECoupon`/`ECouponSlave`/`VipMember`/`VipMemberPresent`/`Coupon`/`DeviceAPPMapping`/`ShoppingCart`系列；CRM：`CrmMember`/`CrmMemberTier`；ERP：`SalesOrder`/`SalesOrderSlave`/`SalesOrderGroup` |
| 2 | `GetLastOmoKeyPromptsFromMemberDimension` | 同上 9 任務 + 讀取歷史摘要/紀錄 | 同上（WebStore+CRM+ERP）**再加上 Info（`OmoKeyPromptSummary`）+ Trace（`OmoKeyPromptHistory`）** | **Lstn2 + Lstn3 都命中**（範圍比 #1 更廣） | 同上 + `OmoKeyPromptSummary`（Info）、`OmoKeyPromptHistory`（Trace） |
| 3 | `GetAvailableECoupon` | `ECouponService.GetMemberAvailableToTakeECouponList` | **WebStore** | **Lstn2** | `ECoupon`、`ECouponSlave`、`ECouponRelativeSlave`、`VipMember`、`ECouponPromotionTagMapping` |
| 4 | `GetLocationOfflineSalesOrderList` | `CrmOrderService.GetOfflineSalesOrderList` → `CrmOrderRepository` | **CRM** | **Lstn3** | `CrmOrder`、`CrmOrderSlave`、`CrmOrderLocation`、`CrmOrderCustomField`、`CrmShopMemberCard`、`CrmReturnGoodsOrderSlave` |
| 5 | `GetCouponList` | `ShopMemberService.GetShopMemberECouponAndCouponList` | **WebStore**（主查詢）+ **ERP**（`GetShopMemberECouponListFromERP`） | **Lstn2 + Lstn3 都命中** | WebStore：`ECoupon`、`ECouponSlave`、`VipMember`、`ECouponPromotionTagMapping`；ERP：ERP 側優惠券歸檔資料 |
| 6 | `GetMemberConsumptionInfo` | `LocationMemberOrderService.GetMemberConsumptionInfo` | **NineYiDW**（`SalesOrderDMRepository`）+ **CRM**（`CrmMemberRepository`、`CrmSalesOrderRepository`） | **Lstn3** | `SalesOrderDM`（NineYiDW）、`CrmMember`、`CrmMemberSummary`、`CrmSalesOrder`（CRM） |
| 7 | `GetMemberTradesOrderInfoAr` | `MemberTradesOrderService.GetMemberTradesOrderAr` → `SalesOrderRepository.GetMultiTradesOrderListAr` | **ERP**（主查詢）+ **WebStore**（`VipMember`查詢） | **Lstn2 + Lstn3 都命中** | ERP：`SalesOrder`、`SalesOrderSlave`、`SalesOrderGroup`、`OrderSlaveFlow`、`ReturnGoodsOrder`、`ReturnGoodsOrderSlave`、`RefundRequest`、`SalesOrderFee`；WebStore：`VipMember` |

#### 8.10.3 共用矩陣：這 7 支 API 到底疊在哪裡

| DB / 連線字串 | Server 叢集 | 命中的 API |
|---|---|---|
| **WebStore**DB | Lstn2 | #1 OmoKeyPrompts、#2 LastOmoKeyPrompts、#3 GetAvailableECoupon、#5 GetCouponList、#7 GetMemberTradesOrderInfoAr（`VipMember`） |
| **CRM**DB | Lstn3 | #1 OmoKeyPrompts、#2 LastOmoKeyPrompts、#4 GetLocationOfflineSalesOrderList、#6 GetMemberConsumptionInfo |
| **ERP**DB | Lstn3 | #1 OmoKeyPrompts（`OmoOrderDataTask`）、#2 LastOmoKeyPrompts、#5 GetCouponList、#7 GetMemberTradesOrderInfoAr |
| **NineYiDW** | Lstn3 | #6 GetMemberConsumptionInfo |
| **Info**DB | Lstn2 | #2 LastOmoKeyPrompts |
| **Trace**DB | Lstn3 | #2 LastOmoKeyPrompts |

結論一目瞭然：

- **`WebStoreDB`（Lstn2）被 5 支 API 共用**：#1、#2、#3、#5、#7 全部都會打到 `WebStoreDB`，且其中 `VipMember`、`ECoupon`/`ECouponSlave` 這幾張表**被 3 支以上不同 API 重複查詢**（不只是同一支 API 內部 9 任務互撞，是跨 API 一起撞同一批表）。
- **`CRMDB`（Lstn3）被 4 支 API 共用**：#1、#2、#4、#6，且 `CrmMember` 這張表在 8.9 節之前的分析中，本來就已知會被單一 API 內部 3 個任務重複查，現在加上跨 API 疊加，實際同時查詢 `CrmMember` 的併發數遠比先前估計還高。
- **`ERPDB`（Lstn3）被 4 支 API 共用**：#1、#2、#5、#7，`SalesOrder`/`SalesOrderSlave`/`SalesOrderGroup` 系列表在 #1（`OmoOrderDataTask`）與 #7（`GetMemberTradesOrderInfoAr`）都會查，且兩者剛好都是 8.9 節驗證出「同一分鐘會一起爆」的 API 組合成員。
- **`Lstn3` 這個實體 DB Server 叢集，是目前 7 支 API 中有 4 支（CRM/ERP/NineYiDW/Trace 相關）共同的實體資源瓶頸**——即使各自查的邏輯資料庫不同，仍是同一台（組）DB Server 在扛所有查詢執行、CPU、IO、TempDB 與連線數。

#### 8.10.4 回答核心問題：這幾支 API 是否會互相影響？

**答案：會，而且有兩層機制同時成立：**

1. **邏輯層共用（DB/表級）**：#1/#2/#3/#5/#7 共用 `WebStoreDB`，#1/#2/#4/#6 共用 `CRMDB`，#1/#2/#5/#7 共用 `ERPDB`。只要其中任兩支 API 同時被高頻呼叫，就會直接對同一顆資料庫、甚至同一張表發起額外的查詢負載，加劇鎖等待/資源排隊。
2. **實體層共用（Server 叢集級）**：即使兩支 API 查詢的是「不同資料庫」（例如一支查 CRM、一支查 ERP），只要都落在 `Lstn3` 這一組實體 DB Server 上，仍會共用同一批 CPU/IO/連線資源，這解釋了為何 8.9 節觀察到「完全不相關的 API 名稱（如 `GetLocationOfflineSalesOrderList` 查 CRM、`GetMemberTradesOrderInfoAr` 查 ERP）會在同一分鐘一起爆」——兩者邏輯資料庫不同，但實體伺服器相同。

換句話說，8.9 節發現的「呼叫端跨 API 同時發動 + 重試風暴」之所以會造成**幾乎所有 API 同時 timeout**，正是因為這些 API 背後的 DB 佈局本來就高度重疊：**沒有任何一支 API 是完全獨立的 DB 資源孤島**，`Lstn3` 這組伺服器尤其是所有 CRM/ERP 系 API 的共同承受點。

#### 8.10.5 表級交叉比對：這 7 支 API 共同查詢了哪些資料表

> 8.10.3 節是「共用同一個 DB」層級的分析，本節更進一步，精確到「共用同一張表」層級，找出被 2 支以上不同 API 同時查詢的實際資料表。

| 資料表 | 命中的 API 數 | 涉及的 API |
|---|---|---|
| **`VipMember`** | **5 支** | `GetOmoKeyPromptsFromMemberDimension`、`GetLastOmoKeyPromptsFromMemberDimension`、`GetCouponList`、`GetMemberTradesOrderInfoAr`、`GetAvailableECoupon` |
| **`ECoupon`** | 4 支 | 上述除 `GetMemberTradesOrderInfoAr` 外的 4 支 |
| **`ECouponSlave`** | 4 支 | 同上 |
| `SalesOrder` | 3 支 | `GetOmoKeyPromptsFromMemberDimension`、`GetLastOmoKeyPromptsFromMemberDimension`、`GetMemberTradesOrderInfoAr` |
| `SalesOrderSlave` | 3 支 | 同上 |
| `SalesOrderGroup` | 3 支 | 同上 |
| `CrmMember` | 3 支 | `GetOmoKeyPromptsFromMemberDimension`、`GetLastOmoKeyPromptsFromMemberDimension`、`GetMemberConsumptionInfo` |
| `ShoppingCart`系列、`CrmMemberTier`、`DeviceAPPMapping`、`VipMemberPresent`、`Coupon` | 2 支 | 僅 `GetOmoKeyPromptsFromMemberDimension` 與 `GetLastOmoKeyPromptsFromMemberDimension`（兩者本來就是同一套 9 任務邏輯的變體） |
| `ECouponPromotionTagMapping` | 2 支 | `GetCouponList`、`GetAvailableECoupon` |

**重點解讀：**

1. **`VipMember` 是全場最熱門的共用表**，被 5 支完全不同用途的 API 同時查詢——這是「多支 API 同時發動 → 同一張表被多重併發打」現象中最直接的物理證據，比 8.10.3 節「同一 DB」層級的推論更進一步、精確到表級。
2. **`ECoupon`/`ECouponSlave`** 被 4 支優惠券相關 API 共用，是次要熱點。
3. **`SalesOrder`/`SalesOrderSlave`/`SalesOrderGroup`** 被 OMO 提示類與訂單查詢類 API 共用，對應到 8.10.3 節「ERPDB 被 4 支 API 共用」的結論在表級的具體落地。
4. `GetLocationOfflineSalesOrderList`（CRM 系）目前是唯一一支**沒有跟其他 API 共用任何實際表**的，它會受影響完全是因為「同一台 `Lstn3` 實體 DB Server」的資源競爭，而非表級鎖競爭。

### 8.11 用實際 ELMAH 資料驗證：這 7 支 API 是否「確實會被同時發動」？

> 8.10 節從程式碼證明了「這幾支 API 共用同一批 DB」，屬於**架構上具備互相影響的條件**。本節換一個角度，直接拿近 10 天內 `elmah_win32_full10d.json`（7,640 筆 Win32Exception）的原始資料，針對前述 7 支 API 逐一檢驗「是否真的會同時發動」，不再只是理論推論。

#### 8.11.1 先確認每支 API 在近 10 天內是否真的有出現

| API | 近 10 天 Win32Exception 筆數 |
|---|---|
| `GetLocationOfflineSalesOrderList` | 1,470 |
| `GetOmoKeyPromptsFromMemberDimension` | 1,460 |
| `GetCouponList` | 1,290 |
| `GetLastOmoKeyPromptsFromMemberDimension` | 930 |
| `GetMemberConsumptionInfo` | 690 |
| `GetMemberTradesOrderInfoAr` | 200 |
| `GetAvailableECoupon` | **0**（近 10 天完全無記錄） |

> ⚠️ **`GetAvailableECoupon` 目前查無資料**，可能已改名、流量極低或呼叫模式改變，因此**本節「同時發動」的驗證僅針對其餘 6 支 API**，`GetAvailableECoupon` 無法用近期資料佐證是否會同時被發動。

#### 8.11.2 以「同商店 + 同分鐘」為單位，統計這 6 支 API 彼此共現的頻率

只保留這 6 支目標 API 的錯誤記錄（共 6,040 筆），依「商店 + 分鐘」分組，共得到 **127 組**錯誤群聚，其中：

- **56 組（44%）同時出現 2 支以上目標 API**
- 依「同一組內出現幾種不同 API」分布：

| 同組內出現的不同 API 數 | 組數 |
|---|---|
| 2 支 | 13 |
| 3 支 | 20 |
| 4 支 | 15 |
| 5 支 | 7 |
| **6 支（全部命中）** | **1** |

**代表性案例（6 支 API 全部同時發動）：**

```
商店 Shop=14，07/19 20:12 這一分鐘，共 140 筆 Win32Exception 同時炸開：
  GetOmoKeyPromptsFromMemberDimension       40 次
  GetCouponList                             20 次
  GetLastOmoKeyPromptsFromMemberDimension   20 次
  GetLocationOfflineSalesOrderList          20 次
  GetMemberConsumptionInfo                  20 次
  GetMemberTradesOrderInfoAr                20 次
```

這證實：**不是巧合、不是理論推導，而是實際發生過「同一分鐘、同一商店，6 支完全不同的 API 全部一起 timeout」的真實案例。**

#### 8.11.3 兩兩配對（Pairwise）共現次數：哪兩支 API 最常一起炸

| API 配對 | 同分鐘+同商店共現次數 |
|---|---|
| `GetCouponList` + `GetLocationOfflineSalesOrderList` | 43 |
| `GetCouponList` + `GetOmoKeyPromptsFromMemberDimension` | 39 |
| `GetLocationOfflineSalesOrderList` + `GetOmoKeyPromptsFromMemberDimension` | 37 |
| `GetLocationOfflineSalesOrderList` + `GetMemberConsumptionInfo` | 25 |
| `GetCouponList` + `GetMemberConsumptionInfo` | 24 |
| `GetMemberConsumptionInfo` + `GetOmoKeyPromptsFromMemberDimension` | 20 |
| `GetCouponList` + `GetLastOmoKeyPromptsFromMemberDimension` | 9 |
| `GetCouponList` + `GetMemberTradesOrderInfoAr` | 8 |
| `GetLastOmoKeyPromptsFromMemberDimension` + `GetLocationOfflineSalesOrderList` | 8 |
| `GetMemberConsumptionInfo` + `GetMemberTradesOrderInfoAr` | 8 |
| `GetLocationOfflineSalesOrderList` + `GetMemberTradesOrderInfoAr` | 8 |
| `GetLastOmoKeyPromptsFromMemberDimension` + `GetOmoKeyPromptsFromMemberDimension` | 7 |
| `GetLastOmoKeyPromptsFromMemberDimension` + `GetMemberConsumptionInfo` | 6 |
| `GetMemberTradesOrderInfoAr` + `GetOmoKeyPromptsFromMemberDimension` | 4 |
| `GetLastOmoKeyPromptsFromMemberDimension` + `GetMemberTradesOrderInfoAr` | 2 |

**觀察重點**：共現次數前三名（`GetCouponList`、`GetLocationOfflineSalesOrderList`、`GetOmoKeyPromptsFromMemberDimension` 兩兩互配）恰好對應到 8.10.3 節共用矩陣中**同時命中 `WebStoreDB`（`GetCouponList`、`GetOmoKeyPromptsFromMemberDimension`）以及跨 `CRMDB`/`Lstn3`（`GetLocationOfflineSalesOrderList`）** 的組合，證據面（實際共現次數）與架構面（共用 DB／共用 Server）兩者互相吻合，並非各自獨立的巧合。

#### 8.11.4 本節結論

1. **是的，這幾支 API（`GetOmoKeyPromptsFromMemberDimension`、`GetLastOmoKeyPromptsFromMemberDimension`、`GetLocationOfflineSalesOrderList`、`GetCouponList`、`GetMemberConsumptionInfo`、`GetMemberTradesOrderInfoAr`）確實會被同時發動**——近 10 天內有 44% 的錯誤群聚時間點包含 2 支以上這些 API，甚至有 1 個時間點（Shop=14、07/19 20:12）6 支全部同時發動並同時 timeout。
2. **`GetAvailableECoupon` 是唯一無法驗證的例外**——近 10 天無任何 Win32Exception 記錄，若要確認它是否仍會被一起呼叫，需改查其「正常呼叫」的存取記錄（而非只查錯誤記錄），或確認此端點近期是否已被前端/整合端棄用。
3. 這個「確實同時發動」的事實，加上 8.10 節「這些 API 本來就共用同一批 DB / 同一組實體 Server」的架構事實，**兩者疊加起來才是造成大量 API 同時 timeout 的完整成因**：同時發動只是條件之一，若這些 API 各自查詢完全獨立的 DB，就算同時發動也不會互相拖累；正因為它們在架構上共用資源，同時發動才會真正造成資源競爭與連鎖逾時。

### 8.12 每一波爆量是否都是「同一組」API？固定核心 + 變動長尾

> 延伸 8.11 的問題：以 10 天內全部 56 組「同商店＋30秒內、跨 2 支以上 API」的爆量群集為樣本，統計**每一支 API 在這些群集中出現的機率**，藉此判斷「是否每次炸的都是同一批 API」。

#### 8.12.1 各 API 在多 API 爆量群集中的出現機率（56 組樣本）

| API | 出現次數 / 56 組 | 出現機率 | 角色 |
|---|---|---|---|
| `ShopMember/GetCouponList` | 45 | 80.4% | **核心常客** |
| `Location/GetLocationOfflineSalesOrderList` | 43 | 76.8% | **核心常客** |
| `LocationMember/GetOmoKeyPromptsFromMemberDimension` | 39 | 69.6% | **核心常客** |
| `LocationMemberOrder/GetMemberConsumptionInfo` | 25 | 44.6% | 常見 |
| `LocationMemberOrder/GetMemberTradesOrderInfoAr` | 9 | 16.1% | 偶爾 |
| `SalesOrder/GetMemberTradesOrderInfo` | 8 | 14.3% | 偶爾 |
| `Location/GetLastOmoKeyPromptsFromMemberDimension` | 8 | 14.3% | 偶爾 |
| `LocationPickup/GetArrivedConfirmList` | 7 | 12.5% | 偶爾 |
| `LocationPickup/PickupConfirm` | 6 | 10.7% | 偶爾 |
| `LocationPickup/GetPickupConfirmList` | 6 | 10.7% | 偶爾 |
| `SalesOrder/ConfirmSalesOrderSlave` | 2 | 3.6% | **長尾** |
| `Location/RedeemPointExchangeECoupon` | 2 | 3.6% | **長尾** |
| `LocationPickup/GetSalesOrderList` | 2 | 3.6% | **長尾** |
| `Frontline/LoyaltyPoint/GetTransactions` | 1 | 1.8% | **長尾** |

#### 8.12.2 案例對照：2026-07-22 12:15 中午這一波（Shop 14 / 19）

當天 ELMAH 告警內容：

```
Shop 14: LocationPickup/Shipping（Win32Exception ×4）
Shop 14: SalesOrder/ConfirmSalesOrderSlave（Win32Exception ×2）
Shop 19: Location/GetLocationOfflineSalesOrderList（Win32Exception ×4）
Shop 19: Location/RedeemPointExchangeECoupon（Win32Exception ×2）
Shop 19: LocationMember/GetOmoKeyPromptsFromMemberDimension（Win32Exception ×4）
Shop 19: LocationMember/GetOmoKeyPromptsFromMemberDimension（EntityCommandExecutionException ×2）
Shop 19: LocationMemberOrder/GetMemberConsumptionInfo（Win32Exception ×2）
```

對照 8.12.1 的機率表：

- ✅ **核心常客命中**：`GetLocationOfflineSalesOrderList`（77%機率）、`GetOmoKeyPromptsFromMemberDimension`（70%機率）、`GetMemberConsumptionInfo`（45%機率）都出現，符合「幾乎每波都會中獎」的預期。
- ➕ **長尾 API 加入戰局**：`LocationPickup/Shipping`（未在原 56 組樣本統計中出現過）、`SalesOrder/ConfirmSalesOrderSlave`（僅 3.6%機率）、`Location/RedeemPointExchangeECoupon`（僅 3.6%機率）— 這幾支平常很少一起爆的 API，這次也加入了。

#### 8.12.3 結論：不是「劇本重播」，而是「固定核心 + 隨機長尾」

1. **每一波爆量的 API 組成不完全相同**，但存在一組約 3～4 支「幾乎每次壅塞都會中獎」的**核心 API**——`GetCouponList`、`GetLocationOfflineSalesOrderList`、`GetOmoKeyPromptsFromMemberDimension`，這三支很可能是門市裝置/App 畫面**固定會呼叫的常駐輪詢或首頁摘要**，只要 DB 壅塞幾乎必定命中。
2. **長尾 API 隨當下商店的實際操作行為變動**：`Shipping`（出貨）、`ConfirmSalesOrderSlave`（確認訂單）、`RedeemPointExchangeECoupon`（兌點）都是「使用者當下正在做某個動作」才會觸發的 API，並非固定排程，只是剛好撞上壅塞瞬間才被拖下水。
3. 這進一步印證 8.9~8.11 節的結論：問題根源是**共用 DB 連線池/實體 Server 在特定時間點被瞬間打爆**，而不是特定幾支 API 之間有邏輯關聯——核心 API 因為呼叫頻率高、幾乎必然在壅塞當下也在執行，因此每次都「陪榜」；長尾 API 則是視當下商店的業務動作是否剛好也在同一瞬間發生而定，屬於機率性疊加，不代表兩者有依賴或觸發關係。

### 8.13 各 API 的錯誤時間集中度：逐支拆解「每支 API 都集中在什麼時間呼叫」

> 延伸 8.1（單一 API 規律性）與 8.9~8.12（跨 API 同時發動）的發現，本節針對前述 7 支核心/常見 API，逐支統計近 10 天 Win32Exception 的「小時分布」與「每小時內分鐘分布」，確認規律性是否每支都一致。

| API | 最集中的小時（Top1~2） | 最集中的分鐘（Top3合計） | 分鐘集中度 |
|---|---|---|---|
| `GetOmoKeyPromptsFromMemberDimension` | **18時**(570筆)、11時(340筆) | 第11~13分：1,190/1,460 | **81.5%** |
| `GetLastOmoKeyPromptsFromMemberDimension` | **20時**(290筆)、12時(210筆) | 第10~13分+第17分：550/930 | 59%（較分散） |
| `GetLocationOfflineSalesOrderList` | **18時**(490筆)、12時(230筆) | 第11~13分：980/1,470 | **66.7%** |
| `GetCouponList` | **18時**(410筆)、11時(240筆) | 第11~13分：930/1,290 | **72.1%** |
| `GetMemberConsumptionInfo` | **18時**(290筆)、20時(140筆) | 第11~12分：390/690 | 56.5% |
| `GetMemberTradesOrderInfoAr` | **20時**(120筆) | 第10、12、16分：120/200 | 60%（較分散） |
| `GetMemberTradesOrderInfo` | **20時**(80筆)、18時(50筆) | 第12~13分：100/190 | 52.6% |

**觀察重點：**

1. **`18 時（下午6點）是全站共同高峰**——`GetOmoKeyPromptsFromMemberDimension`、`GetLocationOfflineSalesOrderList`、`GetCouponList`、`GetMemberConsumptionInfo` 這 4 支核心 API 都以 18 時為第一高峰，呼應 8.9~8.12 節「多店同時打多支 API」的現象。
2. **「每小時第 11~13 分」規律性在大部分 API 都成立**，尤其 `GetOmoKeyPromptsFromMemberDimension`（81.5%）、`GetCouponList`（72.1%）、`GetLocationOfflineSalesOrderList`（66.7%）最明顯，強烈支持「固定排程/門市心跳在整點後 11~13 分觸發」的推論，且與 8.1 節單一 API 的規律性觀察一致，證實跨 API 也遵循同一套時間規律。
3. **`GetLastOmoKeyPromptsFromMemberDimension`、`GetMemberTradesOrderInfoAr`、`GetMemberTradesOrderInfo`** 這 3 支相對分散，高峰偏向 **20 時**，且分鐘集中度較低（52~60%），可能是不同呼叫來源（例如晚班交接或另一批門市裝置），建議後續調查排程來源時，將 18 時批次與 20 時批次分開追查，不宜混為一談。

---

*文件建立日期：2026-07-21*
*章節八更新日期：2026-07-23（ELMAH 時間分布規律性、多重例外同時性驗證、9個平行任務資源競爭分析、8.8實測修正與驗證方法、8.9跨API呼叫端重試風暴發現、8.10逐支API的DB共用矩陣分析＋8.10.5表級共用資料表交叉比對、8.11實際資料驗證多支API同時發動、8.12每波爆量API組成之固定核心與變動長尾分析＋07/22中午實際案例對照、8.13逐支API時間集中度分析）*
*關聯來源：ELMAH errorId `862aeb8d-aa8a-4ca5-be74-8721c7be996e` 及後續同 API 六維分析、`/scm/v2/LocationMember/GetOmoKeyPromptsFromMemberDimension` 近一週/近兩週時間分布分析、`WebSite\ConnectionStrings.config` 與各 Repository/DbContext 程式碼追蹤、近 10 天全應用 Win32Exception 原始資料（7,640 筆）之同商店+同分鐘共現分析、2026-07-22 12:15 ELMAH 即時告警案例（Shop 14/19）*
