---
name: promotion-change-guide
description: 當使用者在 NineYi.Sms 專案中要求對促銷活動（Promotion）進行任何異動——包括驗證邏輯、欄位檢核、條件限制、功能行為、資料組裝方式、活動類型支援範圍等——時，使用此 skill 判斷正確的改動位置（NineYi.Sms 或 nine1.promotion.web.api），避免錯誤地修改 SMS 內的路由邏輯。此 skill 特別針對一個高頻錯誤：Agent 在 SMS 中找不到對應邏輯，便誤判為要將呼叫 API 的新流程切回舊流程，必須在任何促銷異動任務開始前主動使用此 skill 確認改動位置。
---

# Nine1 Promotion 改動位置判斷

此 skill 用於在 NineYi.Sms 專案中收到促銷活動相關需求時，正確判斷應在哪個專案進行修改，避免因「在 SMS 找不到對應程式碼」而錯誤地改動路由邏輯。

---

## 架構說明：SMS 與 Promotion API 的分工

```
NineYi.Sms (前端入口)
  └── PromotionEngineService.CreatePromotionEngine()
        │
        ├─── if _nine1PromotionSwitchType.Contains(entity.TypeDef)
        │         └── _nine1PromotionWebApiHttpClient.Create(...)   ← 新流程（呼叫 nine1.promotion.web.api）
        │                  └── 在 API 端執行驗證（FluentValidation）
        │
        └─── else  ← 舊流程（不呼叫 API，直接寫 DB）
```

**關鍵認知**：
- **SMS 不含促銷活動的業務驗證邏輯**。SMS 的 `PromotionEngineService` 主要負責「路由判斷」與「資料組裝」，驗證由下游的 `nine1.promotion.web.api` 執行。
- 驗證規則位於 `nine1.promotion.web.api` 專案的 `Nine1.Promotion.Common.Validators/Promotions/` 目錄中。
- `_nine1PromotionSwitchType` 清單控制哪些活動類型走新流程，**不應因為「找不到驗證邏輯」而移除或修改此清單**。

---

## 高風險錯誤判斷 — 必須避免

當被要求「移除某個促銷活動的指定xxx檢核」時，若 Agent 在 SMS 中找不到對應驗證程式碼，可能做出以下**錯誤判斷**：

> ❌ **錯誤**：「因為 SMS 沒有此驗證邏輯，將該活動類型從 `_nine1PromotionSwitchType` 移除，讓它走舊流程。」

這會把活動從新流程（呼叫 API）切回舊流程（直接寫 DB），導致：
1. 新版 API 的所有功能（客群、集合、獎勵等）全部失效
2. 活動資料可能寫入錯誤的資料表或格式

> ✅ **正確**：「SMS 沒有驗證邏輯是正常的，驗證在 nine1.promotion.web.api 中，應前往該專案修改驗證器。」

---

## 正確執行流程

### Step 1：先確認活動類型的流程歸屬

在 `PromotionEngineService` 的建構子中查閱 `_nine1PromotionSwitchType` 清單，確認目標活動類型所屬流程：

| 狀況 | 流程 | 業務邏輯所在位置 |
|---|---|---|
| 活動類型 **在**清單中 | 新流程（呼叫 `nine1.promotion.web.api`） | `nine1.promotion.web.api` |
| 活動類型 **不在**清單中 | 舊流程（直接寫 DB） | NineYi.Sms |

### Step 2：依流程歸屬判斷修改位置

**新流程（活動類型在 `_nine1PromotionSwitchType` 清單中）**

| 需求描述 | 修改目標 |
|---|---|
| 移除/修改/新增驗證邏輯、欄位限制、條件檢核 | `nine1.promotion.web.api` 的 Validator |
| 修改業務行為、功能邏輯 | `nine1.promotion.web.api` 的 Service |
| 修改傳給 API 的資料組裝方式 | SMS 的 `GetNine1PromotionCreateBody()` 或對應 Update 方法 |
| API 呼叫後的後處理邏輯 | SMS 的 try/catch 區塊後的程式碼 |

**舊流程（活動類型不在 `_nine1PromotionSwitchType` 清單中）**

所有業務邏輯均在 SMS 內部，可直接在 `PromotionEngineService` 及相關類別中修改。

### Step 3：當目標為新流程時，確認 SMS 是否需要一併改動

執行以下確認，若皆為 No，SMS 端不需要任何修改：

- [ ] 是否需要改變「哪些類型走新流程」？→ 若 No，不動 `_nine1PromotionSwitchType`
- [ ] 是否需要改變「傳給 API 的欄位內容」？→ 若 No，不動 `GetNine1PromotionCreateBody()` 等組裝方法
- [ ] 是否需要改變「API 呼叫後的後處理邏輯」？→ 若 No，不動 try/catch 區塊後的程式碼

---

## `_nine1PromotionSwitchType` 清單（走新流程的活動類型）

`PromotionEngineService` 建構子中的 `_nine1PromotionSwitchType` 清單定義了哪些活動類型會呼叫 `nine1.promotion.web.api`。此清單會持續異動，請以程式碼中的實際內容為準。

**核心原則**：清單中的活動類型代表已完全切換至新流程，其驗證邏輯由 API 端負責，**不可因「找不到驗證邏輯」而將類型從清單中移除**。

---

## 範例情境

### 範例一：移除驗證規則（新流程活動）

**情境**：「滿額贈（DiscountReachPriceWithFreeGift）要移除指定金物流的限制檢核。」

1. 查閱 `_nine1PromotionSwitchType`：`DiscountReachPriceWithFreeGift` 在清單中 → **新流程，修改目標為 `nine1.promotion.web.api`**。
2. 確認 SMS 不需要改動（對照 Step 3 檢查航，皆為 No）。
3. 前往 `nine1.promotion.web.api` 專案並讀取 skill `nine1-promotion-validator-change` 進行調整。

**錯誤做法**（Agent 只看 SMS 時容易犯）：
```csharp
// ✖ 不要這樣做
this._nine1PromotionSwitchType = new List<string>
{
    // 把 DiscountReachPriceWithFreeGift 從清單移除
    // nameof(PromotionEngineTypeDefEnum.DiscountReachPriceWithFreeGift),  ← 錯誤刪除
    ...
};
```