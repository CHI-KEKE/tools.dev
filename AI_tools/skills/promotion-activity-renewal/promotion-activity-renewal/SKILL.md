---
name: promotion-activity-renewal
description: >
  在 nine1.shopping 為新活動類型加入顯示與客群支援的白名單設定。
  當使用者說「活動翻新」、「shopping 活動翻新」、「為某活動加客群支援」、
  「新增活動到 shopping 白名單」、「GetSalepagePromotionDisplayTextProcessor 加活動」、
  「購物車要顯示這個活動」時，立即使用此 skill。

  > ⚠️ 提醒：nine1.cart 也需要同步更新，
  > 請在完成此 repo 改動後，切換至 nine1.cart 一起處理。
---

# Promotion Rule 活動翻新（nine1.shopping）

此 skill 用於在 `nine1.shopping` 的購物車顯示處理器中，為新活動類型加入對應的白名單。

## 需要修改的檔案

```
src/BusinessLogic/Nine1.Shopping.BL.Services/CartProcessor/GetSalepagePromotionDisplayTextProcessor.cs
```

## 需要加入的清單（固定兩個）

活動翻新固定只需要修改以下兩個清單：

| 清單名稱 | 用途說明 |
|---------|--------|
| `_salepageHiddenPromotionTag` | 不在商品卡長活動 Tag（改走 SPS 促購中心顯示）的活動清單 |
| `_promotionSupportMemberCollectionTypes` | 需要對 MemberCollection 做客群資格驗證的活動清單 |

> 其他清單（如 `_salepageDisplayPromotionType`、`_salepageDiscountPromotionType` 等）
> 屬於活動「首次上線」時的改動範疇，不在此 skill 的處理範圍。

## 改動步驟

### Step 0：確認目標活動是否已在清單中

```powershell
Select-String -Path "src/BusinessLogic/Nine1.Shopping.BL.Services/CartProcessor/GetSalepagePromotionDisplayTextProcessor.cs" -Pattern "{NewTypeName}"
```

若已出現在某清單中則跳過該清單。

### Step 1：加入 `_salepageHiddenPromotionTag`

找到 `_salepageHiddenPromotionTag` 欄位，在清單末尾加入：

```csharp
//// {活動中文名}
PromotionEngineTypeDefEnum.{NewType},
```

### Step 2：加入 `_promotionSupportMemberCollectionTypes`

找到 `_promotionSupportMemberCollectionTypes` 欄位，在清單末尾加入：

```csharp
//// {活動中文名}
PromotionEngineTypeDefEnum.{NewType},
```

## 加入時的格式規範

- 統一使用 `////` 中文注解說明活動名稱，對齊其他項目
- 加在清單最後一個元素後，末尾帶逗號

## 完成後的下一步

> ⚠️ **必要動作：** 切換到 `nine1.cart`，在 `MergeRequestAndOldPayProcessContextProcessor.cs`
> 的 `_promotionSupportMemberCollection` 清單中，加入相同的新活動 Enum。
