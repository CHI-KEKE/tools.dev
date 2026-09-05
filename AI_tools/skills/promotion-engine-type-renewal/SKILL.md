---
name: promotion-engine-type-renewal
description: >
  促購活動翻新 — NineYi.Sms（OSM 後台）端的改動。
  將既有促購活動類型從舊流程翻新為新流程（改打促購後台 nine1.promotion.web.api），
  涵蓋 PromotionEngineService 支援清單、PromotionEngineBaseValidator 通路/客群驗證、
  PromotionTranslateSettingService 多語系、IOHistory SettingService 新建與 DI 註冊。
  當使用者說「活動翻新」、「促購翻新」、「新增活動類型到新流程」、「改打促購後台」、「promotion renewal」、
  「把某個活動加到 _nine1PromotionSwitchType」、「新增活動到 Collection UI」，應立即使用此 skill。
  注意：Promotion 後台（nine1.promotion.web.api）端的改動請搭配該 repo 的 promotion-engine-type-renewal skill。
---

# 促購活動翻新 Skill — NineYi.Sms（OSM 後台）

## 概述

本 Skill 負責 **NineYi.Sms** 端的改動，將一個既有的促購活動類型（PromotionEngineTypeDefEnum）加入各種「支援清單」，
使其走 nine1.promotion.web.api 後台流程、支援客群（MemberCollection）、支援內容多語系、支援 IO 歷史紀錄、支援 Collection UI Sync。

> **Promotion 後台端**（nine1.promotion.web.api）的改動請使用該 repo 的 `promotion-engine-type-renewal` skill。

## 輸入參數

使用此 skill 前，必須向使用者確認以下資訊：

| 參數 | 說明 | 範例 |
|------|------|------|
| `ENUM_NAME` | PromotionEngineTypeDefEnum 的列舉名稱 | `DiscountNthPieceWithPrice` |
| `CHINESE_NAME` | 活動中文名稱 | `第N件固定價` |
| `VSTS_ID` | VSTS 工作項目編號 | `609183` |

---

## 改動清單總覽

共 **4 步驟**，涉及 **5~6 個檔案**（含 1 個新建檔案）。

---

## Step 1：PromotionEngineService — 新增活動類型到各支援清單

**檔案**：`BusinessLogic/Services/PromotionEngines/PromotionEngineService.cs`

在此檔案中有 **4 個清單**需要加入新的活動類型：

### 1-1. `_nine1PromotionSwitchType` 清單
**位置**：建構子內，搜尋 `_nine1PromotionSwitchType = new List<string>`
**用途**：控制哪些活動類型改打 nine1.promotion.web.api 後台

**操作**：在清單最後一個項目後面加入：
```csharp
nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

### 1-2. `_needRecordPromotionTypeList` 清單
**位置**：建構子內，搜尋 `_needRecordPromotionTypeList = new List<string>`
**用途**：控制哪些活動類型需要「寫入」IO 歷史紀錄（記錄異動）

> ⚠️ **常見漏掉點**：此清單位於 `_needGetRecordPromotionTypeList` 之前，名稱相近容易忽略，請務必兩個都補。（來源：commit b19aa3266 - VSTS623912 補上第N件折現需紀錄IO）

**操作**：在清單最後一個項目後面加入：
```csharp
nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

### 1-3. `_needGetRecordPromotionTypeList` 清單
**位置**：建構子內，搜尋 `_needGetRecordPromotionTypeList = new List<string>`
**用途**：控制哪些活動類型需要「取得」IO 歷史紀錄（查詢顯示）

**操作**：在清單最後一個項目後面加入：
```csharp
nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

### 1-4. `PromotionConditionTypeEnum` 過濾清單
**位置**：搜尋 `PromotionConditionTypeEnum.CartReachPieceExtraPurchase.ToString()`
**用途**：過濾需要紀錄的活動類型條件

**操作**：在 `CartReachPieceExtraPurchase` 後面加入：
```csharp
PromotionConditionTypeEnum.{ENUM_NAME}.ToString(),
```

### 1-5. `IsEnableSwitchToCollectionUI` 方法內的 `promotionTypeDefToCheck` 清單
**位置**：搜尋方法 `IsEnableSwitchToCollectionUI` 或搜尋 `promotionTypeDefToCheck`
**用途**：控制哪些活動類型支援 Collection UI 切換

**操作**：在清單最後一個項目後面加入：
```csharp
nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

---

## Step 2：PromotionEngineBaseValidator — 新增略過可折抵通路檢查與客群支援

**檔案**：`CrossLayer/Validators/PromotionEngines/PromotionEngineBaseValidator.cs`

在此檔案中有 **3 個地方**需要加入新的活動類型：

### 2-1. TargetPlatformTypeList 略過檢查
**位置**：搜尋 `TargetPlatformTypeList` 附近的 `When()` 條件，有多個 `promotionEngineBase.TypeDef != nameof(...)` 串接
**用途**：這些活動類型不需要做可折抵通路（TargetPlatformTypeList）檢查

**操作**：在最後一個 `&&` 條件後面加入：
```csharp
promotionEngineBase.TypeDef != nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

> **注意**：前一行的結尾要從 `,` 改為 ` &&`

### 2-2. 支援客群的活動類型清單（Member Collection Support）
**位置**：搜尋建構子內的清單，包含 `DiscountReachPieceWithFreeGift` 等（約在建構子開頭的靜態清單）
**用途**：控制哪些活動類型支援指定客群（MemberCollection）

**操作**：在清單最後一個項目後面加入：
```csharp
nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

### 2-3. ValidateDisplaySetting 的 switch case
**位置**：搜尋 `targetMemberTypeDef` 的 switch 區塊（約 line 1508）
**用途**：客群指定時的顯示設定驗證

**操作**：在現有的 `case nameof(PromotionEngineTypeDefEnum.DiscountReachPieceWithFreeGift):` 後面加入新的 case：
```csharp
case nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}):
```

---

## Step 3：PromotionTranslateSettingService — 支援內容多語系

**檔案**：`BusinessLogic/Services/Translate/TranslateSetting/PromotionTranslateSettingService.cs`

### 3-1. `_promotionSupportMemberCollection` 清單
**位置**：搜尋 `_promotionSupportMemberCollection` 清單
**用途**：控制哪些活動類型的客群內容支援多語系翻譯

**操作**：在清單最後一個項目後面加入：
```csharp
nameof(PromotionEngineTypeDefEnum.{ENUM_NAME}),
```

---

## Step 4：IO 歷史紀錄（IOHistory）— 新增 SettingService

此步驟涉及 **3 個檔案**（含 1 個新建）。

### 4-1. 新增 IOHistoryModuleTypeEnum 列舉值
**檔案**：`BusinessLogic/BE/IOHistory/IOHistoryModuleTypeEnum.cs`

**操作**：在最後一個列舉值後面加入：
```csharp
/// <summary>
/// 促購活動_{CHINESE_NAME}
/// </summary>
PromotionEngine_{ENUM_NAME},
```

### 4-2. 新建 IOHistory SettingService 類別（新檔案）
**檔案**：`BusinessLogic/Services/IOHistory/IOHistorySetting/PromotionEngine/PromotionEngine{ENUM_NAME}SettingService.cs`

**模板**：複製任一既有的 SettingService（推薦 `PromotionEngineDiscountReachPieceWithAmountSettingService.cs`），只需替換：
1. 類別名稱 → `PromotionEngine{ENUM_NAME}SettingService`
2. XML 註解的中文名稱 → `{CHINESE_NAME}`
3. 建構子名稱 → `PromotionEngine{ENUM_NAME}SettingService`

完整模板如下：
```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using NineYi.Common.Utility.IOHistory.Client.Entities;
using NineYi.Sms.BL.BE.IOHistory;
using NineYi.Sms.BL.BE.IOHistory.PromotionEngine;
using NineYi.Sms.BL.BE.PromotionEngines.Enums;
using NineYi.Translation.Client.Utility;

namespace NineYi.Sms.BL.Services.IOHistory.IOHistorySetting.PromotionEngine
{
    /// <summary>
    /// {CHINESE_NAME} IOHistorySettingService
    /// </summary>
    public class PromotionEngine{ENUM_NAME}SettingService : PromotionEngineBaseSettingService
    {
        /// <summary>
        /// Constructor
        /// </summary>
        public PromotionEngine{ENUM_NAME}SettingService()
        {
        }

        /// <summary>
        /// 取得列表
        /// </summary>
        /// <param name="entity">The Entity</param>
        /// <returns>The Result</returns>
        public override IEnumerable<IOHistoryListResultEntity> GetList(IEnumerable<HistoryEntity> entity)
        {
            var result = new List<IOHistoryListResultEntity>();

            foreach (var history in entity)
            {
                var content = JsonConvert.DeserializeObject<PromotionEngineSharedIoHistoryEntity>(history.Content);

                PromotionEngineHistoryItemTypeEnum type;

                var parse = Enum.TryParse(history.ItemType, out type);

                var beforeContent = this.GetDisplayText(type, content.BeforeContent);
                var afterContent = this.GetDisplayText(type, content.AfterContent);

                result.Add(
                    new IOHistoryListResultEntity
                    {
                        UpdatedDateTime = history.UpdatedDateTime,
                        UpdatedUser = history.UpdatedUser,
                        Type = parse == true ? type.ToString() : default(string),
                        BeforeContent = beforeContent,
                        AfterContent = afterContent,
                        Guid = history.Guid,
                        CollectionId = content.AfterContent.FirstOrDefault()?.CollectionId
                    });
            }

            return result;
        }

        /// <summary>
        /// 取得明細
        /// </summary>
        /// <param name="entity">HistoryEntity</param>
        /// <returns>Detail</returns>
        public override IEnumerable<T> GetDetail<T>(IEnumerable<HistoryEntity> entity)
        {
            return Enumerable.Empty<T>();
        }

        /// <summary>
        /// 取得明細
        /// </summary>
        /// <param name="ioHistoryContent">IoHistory Content</param>
        /// <typeparam name="T">型別</typeparam>
        /// <returns>反序列化內容</returns>
        public override T GetDetail<T>(string ioHistoryContent)
        {
            var content = JsonConvert.DeserializeObject<T>(ioHistoryContent);

            return content;
        }

        /// <summary>
        /// 取得文案
        /// </summary>
        /// <param name="type">PromotionEngineHistoryItemTypeEnum</param>
        /// <param name="contentList">文案列表</param>
        /// <returns>Detail</returns>
        private string GetDisplayText(PromotionEngineHistoryItemTypeEnum type, IEnumerable<PromotionEngineContentEntity> contentList)
        {
            switch (type)
            {
                case PromotionEngineHistoryItemTypeEnum.MustProduct:
                    return StringUtility.PeacefulFormat(
                        Translations.Backend.Service.Iohistory.PromotionEngine.CommoditiesTotalItemsCount,
                        contentList.FirstOrDefault()?.Count.ToString());

                default:
                    return contentList.FirstOrDefault()?.Count.ToString();
            }
        }
    }
}
```

### 4-3. 註冊 .csproj
**檔案**：`BusinessLogic/Services/NineYi.Sms.BL.Services.csproj`

**操作**：在 `<ItemGroup>` 中找到其他 IOHistory PromotionEngine 的 `<Compile Include>` 項目，按字母順序插入：
```xml
<Compile Include="IOHistory\IOHistorySetting\PromotionEngine\PromotionEngine{ENUM_NAME}SettingService.cs" />
```

### 4-4. 註冊 DI（Autofac）
**檔案**：`CrossLayer/Modules/BL/ServiceModule.cs`

**位置**：搜尋最後一個 `Keyed<IIOHistorySettingService>` 的註冊，在其後面加入：

```csharp
builder.RegisterType<PromotionEngine{ENUM_NAME}SettingService>()
    .Keyed<IIOHistorySettingService>(nameof(IOHistoryModuleTypeEnum.PromotionEngine_{ENUM_NAME}));
```

> **注意**：需要加入對應的 `using` namespace（如果尚未存在）：
> - `using NineYi.Sms.BL.Services.IOHistory.IOHistorySetting.PromotionEngine;`

---

## 改動檢查清單

執行完畢後，請逐一確認：

- [ ] `PromotionEngineService.cs` — `_nine1PromotionSwitchType` ✅
- [ ] `PromotionEngineService.cs` — `_needRecordPromotionTypeList` ✅
- [ ] `PromotionEngineService.cs` — `_needGetRecordPromotionTypeList` ✅
- [ ] `PromotionEngineService.cs` — `PromotionConditionTypeEnum` 過濾清單 ✅
- [ ] `PromotionEngineService.cs` — `IsEnableSwitchToCollectionUI` 的 `promotionTypeDefToCheck` ✅
- [ ] `PromotionEngineBaseValidator.cs` — `TargetPlatformTypeList` 略過條件 ✅
- [ ] `PromotionEngineBaseValidator.cs` — 客群支援清單 ✅
- [ ] `PromotionEngineBaseValidator.cs` — `ValidateDisplaySetting` switch case ✅
- [ ] `PromotionTranslateSettingService.cs` — `_promotionSupportMemberCollection` ✅
- [ ] `IOHistoryModuleTypeEnum.cs` — 新增 enum 值 ✅
- [ ] 新建 `PromotionEngine{ENUM_NAME}SettingService.cs` ✅
- [ ] `.csproj` — 註冊新檔案 ✅
- [ ] `ServiceModule.cs` — DI 註冊 ✅

---

## 五個活動翻新的對照表

| # | 中文名稱 | ENUM_NAME | 狀態 |
|---|---------|-----------|------|
| 1 | 第 N 件固定價 | `DiscountNthPieceWithPrice` | ✅ 已完成 |
| 2 | 第 N 件打折 | `DiscountNthPieceWithRate` | ⬜ 待執行 |
| 3 | 第 N 件折現 | `DiscountNthPieceWithAmount` | 🔄 進行中（_needRecordPromotionTypeList 已補入，commit b19aa3266） |
| 4 | 任選優惠價 | `DiscountReachPieceWithPrice` | ⬜ 待執行 |
| 5 | 紅配綠固定價 | `DiscountReachGroupsPiece` | ⬜ 待執行 |

> **注意**：第 1 個活動（第 N 件固定價）已在 `_nine1PromotionSwitchType` 中和其他 3 個活動一起被加入（commit 1b984d8），但其他步驟（客群、IO、Validator）僅完成了第 1 個活動。
> 
> **教訓（commit b19aa3266）**：翻新時請同時更新 `_needRecordPromotionTypeList`（寫入IO）與 `_needGetRecordPromotionTypeList`（讀取IO），兩個清單名稱相近，容易只改其中一個。

---

## Commit 建議

每個活動翻新建議分成以下幾個 commit（對應 PR）：

1. **改打促購後台**（Step 1-1）— `VSTS{ID} - 改打促購後台`
2. **略過通路檢查**（Step 2-1）— `VSTS{ID} - 可折抵通路檢查略過{CHINESE_NAME}`
3. **支援客群/多語系**（Step 2-2, 2-3, 3-1）— `VSTS{ID} - {CHINESE_NAME}支援客群`
4. **處理 IO**（Step 4）— `VSTS{ID} - 處理 IO Service`

## 執行方式

當使用者說「活動翻新」或「促購翻新」時：

1. 詢問要翻新的活動類型（從上方對照表選擇，或提供新的 ENUM_NAME）
2. 確認 VSTS 編號
3. 依照 Step 1 ~ Step 4 逐步執行改動
4. 每完成一個 Step 就回報進度
5. 全部完成後，使用改動檢查清單確認所有改動點
6. 提醒使用者：Promotion 後台端（nine1.promotion.web.api）也需要執行對應的 skill
