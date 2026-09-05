---
name: promotion-activity-renewal
description: >
  在 nine1.cart 為新活動類型加入成單前的客群驗證白名單。
  當使用者說「活動翻新」、「為某活動加客群支援」、「cart 活動翻新」、
  「成單前客群檢查」、「MergeRequestAndOldPayProcessContextProcessor 加活動」時，立即使用此 skill。

  > ⚠️ 提醒：nine1.shopping 也需要同步加入新活動類型到兩個顯示清單，
  > 請在完成此 repo 改動後，確認 nine1.shopping 也已同步更新。
---

# Promotion Rule 活動翻新 - 成單前客群驗證（nine1.cart）

此 skill 用於在 `nine1.cart` 的成單流程處理器中，為新活動類型加入客群支援的白名單，使成單前能正確驗證會員資格。

## 需要修改的檔案

```
src/BusinessLogic/Nine1.Cart.BL.Services/Processor/Checkout/Complete/MergeRequestAndOldPayProcessContextProcessor.cs
```

## 改動步驟

### Step 1：確認目標活動是否已在清單中

先搜尋目標活動 Enum 是否已在檔案中出現：

```powershell
Select-String -Path "src/BusinessLogic/Nine1.Cart.BL.Services/Processor/Checkout/Complete/MergeRequestAndOldPayProcessContextProcessor.cs" -Pattern "{NewTypeName}"
```

若已存在則跳過，不需重複加入。

### Step 2：加入 `_promotionSupportMemberCollection` 清單

找到 `_promotionSupportMemberCollection` 欄位定義處（說明為「折扣活動支援客群」），在清單最後加入新活動：

```csharp
//// {活動中文名}
PromotionEngineTypeDefEnum.{NewType},
```

## 注意事項

- 此清單控制「成單前是否對此活動做 MemberCollection 客群驗證」。
- 只需加入一個清單，加入時附上 `////` 中文注解，格式對齊其他項目。
- `new List<PromotionEngineTypeDefEnum>()` 格式（非 `new()`），請維持原始 C# 6 格式不要改。

## 完成後的下一步

> ⚠️ **必要確認：** 切換到 `nine1.shopping` 確認 `GetSalepagePromotionDisplayTextProcessor.cs`
> 的以下兩個清單都已加入新活動 Enum：
> - `_salepageHiddenPromotionTag`
> - `_promotionSupportMemberCollectionTypes`
