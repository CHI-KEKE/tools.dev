---
name: daily-operation-add-ad-account-book
description: 在 NineYi.OsmPlus.Console 專案中新增廣告媒體至廣告帳冊（AdAccountBook）的完整流程，涵蓋 Service、Enum 共 6 個檔案。當使用者說「新增廣告媒體」、「加廣告媒體到帳冊」、「AdAccountBook 新增媒體」、「新增廣告帳冊媒體」、「新增廣告帳簿媒體」、「廣告帳簿新增媒體」時，一律使用此 skill。
---

# 新增廣告媒體至廣告帳冊（AdAccountBook）— OsmPlus.Console

在 NineYi.OsmPlus.Console 專案中新增一個廣告媒體，需要同時異動 **6 個檔案**，本 skill 提供端對端標準流程。

---

## Step 1：收集需求資訊

在執行前，向使用者確認以下兩項資訊（對話中已有答案則直接沿用）：

1. **本次要新增的廣告媒體名稱** — 例如 `VM5`（後續以 `{NewMedia}` 表示）
2. **要放在哪個廣告媒體的後面** — 例如 `LineDisplay`（後續以 `{PrevMedia}` 表示）

> 確認完畢後，才進入 Step 2 執行所有異動。

---

## Step 2：依序異動 6 個檔案

### 檔案 1：MediaTypeEnum.cs

**路徑**：`NineYi.OsmPlus.DA.ErpDB\Extends\MediaTypeEnum.cs`

在 `{PrevMedia} = {N},` 後面新增：

```csharp
/// <summary>
/// {NewMedia}
/// </summary>
{NewMedia} = {N+1},
```

> ⚠️ 只能加在最後面，**不可調整現有值的順序**。

---

### 檔案 2：PaymentTypeEnum.cs

**路徑**：`NineYi.OsmPlus.DA.ErpDB\Extends\PaymentTypeEnum.cs`

在 `Expense_{PrevMedia},` 後面新增：

```csharp
/// <summary>
/// 支出-{NewMedia}
/// </summary>
Expense_{NewMedia},
```

> ⚠️ 只能加在指定位置後面，**不可調整現有值的順序**。

---

### 檔案 3：AdAccountBookCommonService.cs

**路徑**：`NineYi.OsmPlus.Console.BL.Service\EtlServices\AdvertisementAutomation\AdAccountBookCommonService.cs`

找到 `MediaTypeDef` 轉換為 `PaymentTypeEnum` 的 switch 區塊，在 `case MediaTypeEnum.{PrevMedia}: return PaymentTypeEnum.Expense_{PrevMedia};` 之後、`default:` 之前加入：

```csharp
case MediaTypeEnum.{NewMedia}:
    return PaymentTypeEnum.Expense_{NewMedia};
```

---

### 檔案 4：AdExpenseOverspendNotificationService.cs

**路徑**：`NineYi.OsmPlus.Console.BL.Service\EtlServices\AdvertisementAutomation\AdExpenseOverspendNotificationService.cs`

在 `this.SetHtmlRowByType(htmlTable, adMonthlyChargeOffGroupByAdOperator, PaymentTypeEnum.Expense_{PrevMedia}.ToString(), "{PrevMedia中文}");` 後面加入：

```csharp
this.SetHtmlRowByType(htmlTable, adMonthlyChargeOffGroupByAdOperator, PaymentTypeEnum.Expense_{NewMedia}.ToString(), "{NewMedia}");
```

---

### 檔案 5：MonthlyAdExpenseNotificationService.cs

**路徑**：`NineYi.OsmPlus.Console.BL.Service\EtlServices\AdvertisementAutomation\MonthlyAdExpenseNotificationService.cs`

在 `this.SetHtmlRowByType(htmlTable, adMonthlyChargeOffGroupByAdOperator, PaymentTypeEnum.Expense_{PrevMedia}.ToString(), "{PrevMedia中文}");` 後面加入：

```csharp
this.SetHtmlRowByType(htmlTable, adMonthlyChargeOffGroupByAdOperator, PaymentTypeEnum.Expense_{NewMedia}.ToString(), "{NewMedia}");
```

---

### 檔案 6：AdvertiseCommonService.cs

**路徑**：`NineYi.OsmPlus.Console.BL.Service\ThirdPartyApis\Advertisement\AdvertiseCommonService.cs`

此檔案有 **2 個 switch 區塊**需要修改，皆是在含有 `case MediaTypeEnum.{PrevMedia}:` 的區塊末端加入：

```csharp
case MediaTypeEnum.{NewMedia}:
```

第 1 處（建立預算的 switch）：
```csharp
case MediaTypeEnum.{PrevMedia}:
case MediaTypeEnum.{NewMedia}:    // ← 新增
    ////TODO 建立預算
    break;
```

第 2 處（另一個 switch）：
```csharp
case MediaTypeEnum.{PrevMedia}:
case MediaTypeEnum.{NewMedia}:    // ← 新增
    break;
```

---

## 完成確認清單

- [ ] `MediaTypeEnum.cs`：已在最後新增 `{NewMedia} = {N+1}`，未異動現有值排序
- [ ] `PaymentTypeEnum.cs`：已在 `Expense_{PrevMedia}` 後新增 `Expense_{NewMedia}`，未異動現有值排序
- [ ] `AdAccountBookCommonService.cs`：已在 switch 中新增 `case MediaTypeEnum.{NewMedia}: return PaymentTypeEnum.Expense_{NewMedia};`
- [ ] `AdExpenseOverspendNotificationService.cs`：已新增 `SetHtmlRowByType` 呼叫
- [ ] `MonthlyAdExpenseNotificationService.cs`：已新增 `SetHtmlRowByType` 呼叫
- [ ] `AdvertiseCommonService.cs`：已在 2 個 switch 區塊中新增 `case MediaTypeEnum.{NewMedia}:`

---

## 常見錯誤與注意事項

- **`PaymentTypeEnum` 順序不可異動**：enum 的順序對應到資料庫，插入中間會導致既有資料錯誤，只能在指定位置後加入。
- **`AdvertiseCommonService.cs` 有 2 個 switch**：兩個都要改，分別是「建立預算」和另一個驗證區塊，若只改一個會造成行為不一致。
- **`SetHtmlRowByType` 的中文顯示名稱**：第二個參數為中文媒體名稱，請與既有媒體名稱命名風格保持一致（例如 `"VM5"`、`"LINE Display"`、`"全媒體"`）。
