# Phase 4 — 費用報表

> 讀完本文件後再開始修改對應檔案。
> 四個檔案的屬性命名必須**完全一致**：`Total{NewPayTypeName}Fee`（如 `TotalPayNowRazerFee`）

---

## 屬性命名規則

| PayType | Fee 屬性名稱 |
|---------|------------|
| `PayNow_Razer` | `TotalPayNowRazerFee` |
| `GrabPay_AsiaPay` | `TotalGrabPayAsiaPayFee` |
| `OnlineBanking_Razer` | `TotalOnlineBankingRazerFee` |
| `{Method}_{Provider}` | `Total{Method}{Provider}Fee` |

---

## 檔案 1：Csp_GetExpenseOrderReportReturnModel.cs

**路徑：** `DataAccess/ErpDB/Extends/Csp_GetExpenseOrderReportReturnModel.cs`

**動作：** 加入新的費用屬性，依 Provider 群組歸位。

**範例：**
```csharp
/// <summary>
/// Razer PayNow 系統使用費
/// </summary>
public decimal TotalPayNowRazerFee { get; set; }
```

**插入位置：**
- Razer 系列：在最後一個 Razer fee 屬性之後（`TotalGrabPayRazerFee` 後）
- AsiaPay 系列：在最後一個 AsiaPay fee 屬性之後
- 其他 Provider：依邏輯排列，在 `TotalStripeFee` / `TotalCashOnDeliveryFee` 之前

**驗證：**
- [ ] XML 文件完整
- [ ] 屬性名稱格式正確：`Total{PayTypeName}Fee`
- [ ] 插入位置依 Provider 分組合理

---

## 檔案 2：ExpenseOrderReportResultEntity.cs

**路徑：** `BusinessLogic/BE/ExpenseOrders/ExpenseOrderReportResultEntity.cs`

**動作：** 加入與 DataAccess 層**完全相同**的屬性。

**範例：**
```csharp
/// <summary>
/// Razer PayNow 系統使用費
/// </summary>
public decimal TotalPayNowRazerFee { get; set; }
```

**插入位置：** 與 `Csp_GetExpenseOrderReportReturnModel` 的順序保持一致。

**驗證：**
- [ ] 屬性名稱與 `Csp_GetExpenseOrderReportReturnModel` 完全相同
- [ ] 屬性型別一致（`decimal`）
- [ ] 順序與 DataAccess 層一致

---

## 檔案 3：ExpenseOrderEntityMappingProfile.cs

**路徑：** `CrossLayer/Mappers/ExpenseOrders/ExpenseOrderEntityMappingProfile.cs`

**動作：** 在 `CreateMap<Csp_GetExpenseOrderReportReturnModel, ExpenseOrderReportResultEntity>()` 的 mapping 中加入 `ForMember`。

**範例：**
```csharp
this.CreateMap<Csp_GetExpenseOrderReportReturnModel, ExpenseOrderReportResultEntity>()
    // ... 既有 mapping ...
    .ForMember(i => i.TotalGrabPayRazerFee, s => s.MapFrom(i => i.TotalGrabPayRazerFee))
    .ForMember(i => i.TotalPayNowRazerFee, s => s.MapFrom(i => i.TotalPayNowRazerFee))  // ← 加入
    .ForMember(i => i.TotalTNGAsiaPayFee, s => s.MapFrom(i => i.TotalTNGAsiaPayFee))
    // ...
```

**插入位置：** 與兩個 entity 檔案的屬性順序保持一致。

**驗證：**
- [ ] 屬性名稱兩邊完全一致（source 與 destination）
- [ ] 加入在正確的 `CreateMap` 語句內
- [ ] 無重複 mapping

---

## 檔案 4：ExpenseOrderService.cs

**路徑：** `BusinessLogic/Services/ExpenseOrders/ExpenseOrderService.cs`

**⚠️ 執行前請先與使用者確認：**
> 「費用報表的 `GetExpenseOrderReportDetailExportList()` 需要更新哪些市場的 switch-case？
> 目前你說的市場為 `{Step 1 Q8 答案}`，確認：
> 1. 只更新這個市場的 totalAmount 計算？
> 2. 是否同時需要更新多個市場（如 MY 和 HK 都要加）？
> 3. dataTable 顯示列的翻譯 key 命名為 `SystemUsageFee{PayTypeName}`，確認？」

**動作：** 更新 `GetExpenseOrderReportDetailExportList()` 方法中的**兩個區塊**。

---

### 4.1 更新 `totalAmount` 計算

找到對應市場的 `switch (SettingHelper.DefaultCountry)` case，加入新費用：

**MY 市場範例：**
```csharp
case "MY":
    totalAmount = summaryResult.TotalGlobalPayFee
                + summaryResult.TotalCreditCardOnceRazerFee
                + summaryResult.TotalOnlineBankingRazerFee
                + summaryResult.TotalGrabPayRazerFee
                + summaryResult.TotalPayNowRazerFee  // ← 加入
                + summaryResult.TotalCreditCardOnceAsiaPayFee
                + summaryResult.TotalOnlineBankingAsiaPayFee
                + summaryResult.TotalShortMessageFee;
```

**SG / HK 市場範例：**
```csharp
case "SG":
    totalAmount = summaryResult.TotalCreditCardOnceRazerFee
                + summaryResult.TotalGrabPayRazerFee
                + summaryResult.TotalPayNowRazerFee  // ← 加入
                + summaryResult.TotalShortMessageFee;
```

---

### 4.2 加入 DataTable 顯示列

在費用清單對應市場的 dataTable 加入顯示列：

```csharp
dataTable.Rows.Add(new string[] {
    string.Empty, string.Empty, string.Empty,
    Translations.Backend.Entity.ExpenseOrderSlaveExport.SystemUsageFeePayNowRazer,
    summaryResult.TotalPayNowRazerFee.ToString()
});
```

**插入位置：** 在同 Provider 的最後一筆之後（如 Razer 群組的 `GrabPay_Razer` 行之後），在下一個 Provider 群組之前。

**翻譯 key 命名格式：** `SystemUsageFee{PayTypeName}`（如 `SystemUsageFeePayNowRazer`）

> ⚠️ 翻譯文字本身需手動加入翻譯資源，此 Skill 不處理翻譯檔。

---

**驗證：**
- [ ] `totalAmount` 計算已加入新費用（正確市場）
- [ ] dataTable 顯示列已加入（對應相同市場）
- [ ] 翻譯 key 命名格式正確
- [ ] 兩個區塊的市場範圍一致
