---
name: daily-operation-add-ad-account-book
description: 在 NineYi.Sms 專案中新增廣告媒體至廣告帳冊（AdAccountBook）的完整流程，涵蓋 Entity、Enum、Service、TypeScript 定義、型別宣告以及 CSHTML 視圖共 6 個檔案。當使用者說「新增廣告媒體」、「加廣告媒體到帳冊」、「AdAccountBook 新增媒體」、「新增廣告帳冊媒體」、「新增廣告帳簿媒體」、「廣告帳簿新增媒體」時，一律使用此 skill。
---

# 新增廣告媒體至廣告帳冊（AdAccountBook）

在 NineYi.Sms 專案中新增一個廣告媒體，需要同時異動 **6 個檔案**，本 skill 提供端對端標準流程。

> ⚠️ **重要（原因來自 VSTS653214）**：`AdvertiseManagerService.cs` 裡有 **2 個平行、各自獨立維護**的欄位對應方法——`GetDataGroupByAdMediaAccount`（即時餘額，用 `GetOriginalAmount`）與 `GetHistoryDataGroupByAdMediaAccount`（歷史/月結算，用 `GetAdMonthyChargeOffAmount`）。兩者必須**同步**新增新媒體欄位，只改其中一個會導致「其中一種查詢模式該欄位永遠顯示 0」的 bug（VSTS653214 即為此類疏漏）。

---

## Step 1：收集需求資訊

在執行前，向使用者確認以下兩項資訊（對話中已有答案則直接沿用）：

1. **本次要新增的廣告媒體名稱** — 例如 `VM5`（後續以 `{NewMedia}` 表示）
2. **要放在哪個廣告媒體的後面** — 例如 `LineDisplay`（後續以 `{PrevMedia}` 表示）

> 確認完畢後，才進入 Step 2 執行所有異動。

---

## Step 2：依序異動 6 個檔案

### 檔案 1：AdAccountBookDataEntity.cs

**路徑**：`BusinessLogic\BE\AdvertiseManagers\AdAccountBook\AdAccountBookDataEntity.cs`

在 `{PrevMedia}Expense` 屬性的後面，新增：

```csharp
/// <summary>
/// 支出-{NewMedia}
/// </summary>
public decimal {NewMedia}Expense { get; set; }
```

---

### 檔案 2：PaymentTypeEnum.cs

**路徑**：`BusinessLogic\BE\AdvertiseManagers\PaymentTypeEnum.cs`

在 `Expense_{PrevMedia}` 列舉值的後面，新增：

```csharp
/// <summary>
/// 支出-{NewMedia}
/// </summary>
Expense_{NewMedia},
```

> ⚠️ 只能加在指定位置後面，**不可調整現有值的順序**，否則會影響資料對應。

---

### 檔案 3：AdvertiseManagerService.cs

**路徑**：`BusinessLogic\Services\AdvertiseManagers\AdvertiseManagerService.cs`

此檔案有 **2 處** 需要修改，**兩處都必須改，缺一不可**（此檔案內有即時/歷史兩套各自獨立維護的欄位對應清單）：

**第 1 處（`GetDataGroupByAdMediaAccount` 方法 —— 即時餘額）**：

在組裝 `AdAccountBookDataEntity` 的匿名物件中，找到 `{PrevMedia}Expense = this.GetOriginalAmount(...)` 那一行，在其後面新增：

```csharp
{NewMedia}Expense = this.GetOriginalAmount(group, PaymentTypeEnum.Expense_{NewMedia}),
```

**第 2 處（`GetHistoryDataGroupByAdMediaAccount` 方法 —— 歷史/月結算餘額）**：

在同一個檔案中，往下找到**另一個**組裝 `AdAccountBookDataEntity` 的匿名物件（方法名為 `GetHistoryDataGroupByAdMediaAccount`），找到 `{PrevMedia}Expense = this.GetAdMonthyChargeOffAmount(...)` 那一行，在其後面新增：

```csharp
{NewMedia}Expense = this.GetAdMonthyChargeOffAmount(group, PaymentTypeEnum.Expense_{NewMedia}),
```

> ⚠️ **這是 VSTS653214 修復的經驗**：過去曾發生只改了第 1 處（即時）、漏改第 2 處（歷史），導致「廣告投放額度查詢」頁面切到「歷史/月結算報表」時，該媒體的支出永遠顯示 $0，即使資料庫裡有正確金額。務必兩處都確認改到，並比對兩個方法目前已有的欄位清單是否一致（成員數量、順序應完全對應）。

---

### 檔案 4：Enums.ts

**路徑**：`WebSite\WebSite\Scripts\Enums.ts`

找到 `{PrevMedia} = {N}` 的那一行（`N` 為目前最後一個有效的數字），將該行結尾加上逗號（若尚未有），然後在其下方新增：

```typescript
{NewMedia} = {N+1}
```

**範例**（PrevMedia=LineDisplay, N=12, NewMedia=VM5）：
```typescript
LineDisplay = 12,
VM5 = 13
```

---

### 檔案 5：TypeLite.Net4.d.ts

**路徑**：`WebSite\WebSite\Scripts\TypeLite.Net4.d.ts`

在 `AdAccountBookDataEntity` 的介面宣告中，找到 `{PrevMedia}Expense: number;` 這一行，在其後面新增：

```typescript
{NewMedia}Expense: number;
```

---

### 檔案 6：AdAccountBookChargingList.cshtml

**路徑**：`WebSite\WebSite\Views\AdvertiseManager\AdAccountBookChargingList.cshtml`

此檔案有 **2 處** 需要修改，皆是在費用加總運算式的末尾、`{PrevMedia}Expense` 之後，附加 `+ Item.{NewMedia}Expense`（單筆）或 `+ AdAccountBookChargingCtrl.SumOfValue('{NewMedia}Expense')`（加總列）。

**第 1 處（單筆 Item 顯示）**：

```html
<!-- 修改前（{PrevMedia} 為結尾）：-->
+ Item.{PrevMedia}Expense | currency}}

<!-- 修改後：-->
+ Item.{PrevMedia}Expense + Item.{NewMedia}Expense | currency}}
```

**第 2 處（SumOfValue 合計列）**：

```html
<!-- 修改前（{PrevMedia} 為結尾）：-->
+ AdAccountBookChargingCtrl.SumOfValue('{PrevMedia}Expense') | currency}}

<!-- 修改後：-->
+ AdAccountBookChargingCtrl.SumOfValue('{PrevMedia}Expense') + AdAccountBookChargingCtrl.SumOfValue('{NewMedia}Expense') | currency}}
```

---

## 完成確認清單

- [ ] `AdAccountBookDataEntity.cs`：已在 `{PrevMedia}Expense` 後新增 `{NewMedia}Expense` 屬性
- [ ] `PaymentTypeEnum.cs`：已在 `Expense_{PrevMedia}` 後新增 `Expense_{NewMedia}`，未異動現有值排序
- [ ] `AdvertiseManagerService.cs`：**兩處都要改** —— (1) `GetDataGroupByAdMediaAccount`(即時)已補上 `{NewMedia}Expense = this.GetOriginalAmount(...)`；(2) `GetHistoryDataGroupByAdMediaAccount`(歷史/月結算)已補上 `{NewMedia}Expense = this.GetAdMonthyChargeOffAmount(...)`
- [ ] `Enums.ts`：已在 `{PrevMedia}` 後新增 `{NewMedia} = {N+1}`，且 `{PrevMedia}` 行尾已有逗號
- [ ] `TypeLite.Net4.d.ts`：已在 `{PrevMedia}Expense: number;` 後新增 `{NewMedia}Expense: number;`
- [ ] `AdAccountBookChargingList.cshtml`：已更新 2 處加總運算式，加入新媒體欄位

---

## 常見錯誤與注意事項

- **`PaymentTypeEnum` 順序不可異動**：enum 的整數值對應到資料庫資料，插入中間會導致既有資料對應錯誤，只能在指定位置後面新增。
- **`Enums.ts` 末尾逗號**：TypeScript enum 最後一個值加逗號不影響編譯，但倒數第二個值若缺逗號則會編譯錯誤，新增前務必確認 `{PrevMedia}` 那行的結尾已有逗號。
- **CSHTML 有 2 處需改**：一處是單筆 `Item.xxx`，另一處是加總 `SumOfValue('xxx')`，兩處都要改，否則合計列會顯示錯誤金額。
- **此專案僅使用同步方法**，不使用 async/await。
- **`AdvertiseManagerService.cs` 有 2 套獨立維護的欄位對應（即時 vs 歷史/月結算）**：新增媒體時必須同時修改 `GetDataGroupByAdMediaAccount` 與 `GetHistoryDataGroupByAdMediaAccount` 兩個方法，只改一邊會導致另一種查詢模式該欄位永遠顯示 0（詳見 VSTS653214）。建議修改後用 `grep`/搜尋比對兩個方法內的欄位清單，確認成員數量一致。
