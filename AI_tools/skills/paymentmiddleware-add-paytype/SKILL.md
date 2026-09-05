---
name: paymentmiddleware-add-paytype
description: >
  Step-by-step guide for adding a new **PaymentMiddleware-based** payment type to the NineYi.Sms backend system.
  ONLY invoke this skill when the user explicitly mentions "PaymentMiddleware", "跨國金流", "跨境金流",
  or names a known PaymentMiddleware provider (Razer, AsiaPay, Stripe, CheckoutDotCom, Cybersource,
  EftPay, KPay, Atome, SwiftPass, 2C2P, QFPay, PayMe, LinePay, JKOPay).
  Do NOT invoke this skill for local TW payment types (e.g., CathayPay, CVS, ATM, offline payments)
  or any payment type that does NOT go through the PaymentMiddleware infrastructure.
  This skill is ONLY applicable to the NineYi.Sms project.
---

# [SMS] Add Payment Type

> ⚠️ **NineYi.Sms 專案限定 Skill**
> 本 Skill 僅適用於 **`NineYi.Sms`** 專案。
> 若目前工作目錄不是此專案，請立即停止並告知使用者。

## Overview

此 Skill 協助在 **NineYi.Sms** 後台系統新增一個付款方式（PayType），涵蓋 **11～12 個 C# 檔案**：

| 類別 | 檔案數 |
|------|--------|
| Enum 定義 | 3 |
| Factory & Service 設定 | 3～4（Razer 系列需額外 1 個） |
| DI 注冊 & 驗證 | 2 |
| 費用報表 | 4 |

支援的 Provider：Razer、AsiaPay、Stripe、LinePay、JKOPay 及其他第三方。

---

## Step 1：驗證輸入 & 確認環境

### 🔴 第一個問題（必問，不可跳過）

> **「請問您要新增的 `{PayTypeName}` 是 PaymentMiddleware 金流嗎？」**
>
> - **是** → 繼續執行此 Skill
> - **否 / 不確定** → 立即停止，回覆：
>   「此 Skill 僅適用於 PaymentMiddleware 架構的金流（Razer / AsiaPay / Stripe / CheckoutDotCom / Cybersource / EftPay / KPay / Atome / SwiftPass / 2C2P / QFPay / PayMe / LinePay / JKOPay）。
>   若是本地金流（如 CathayPay、CVS、ATM、離線付款），請改用對應的 Skill 或手動處理。」

---

**先確認專案環境：**
- 確認 `BusinessLogic/BE/PayProfile/PayProfileTypeEnum.cs` 存在
- 若不存在，**立即停止**並告知使用者：「此 Skill 僅適用於 NineYi.Sms 專案」

**收集以下資訊：**

1. **PayType 名稱** — PascalCase，建議格式 `{Method}_{Provider}`（如 `PayNow_Razer`、`GrabPay_AsiaPay`）
2. **Provider** — Razer / AsiaPay / Stripe / LinePay / JKOPay / 其他
3. **確認不重複** — 讀取 `PayProfileTypeEnum.cs` 確認名稱不存在

**詢問使用者以下問題（轉化為 scope）：**

| # | 問題 | 影響的檔案 |
|---|------|-----------|
| Q1 | **部署環境市場？** TW / MY / SG / HK（此 PayType 在哪個國家的 SMS 環境運行） | 作為背景資訊，影響 AppSettings config 的市場 |
| Q2 | **此 PayType 是否有銷售市場限定？**（與環境市場不同！）<br>例如：「只限 HK 商店可開通」→ 需加入 `SalesMarketSupportedPayProfiles`；「無銷售市場限制」→ 跳過 | `ThirdPartyServicesService.SalesMarketSupportedPayProfiles` |
| Q3 | **若 Q2 有市場限定：限定哪些銷售市場？** TW / MY / SG / HK / 多選 | `ThirdPartyServicesService.SalesMarketSupportedPayProfiles` |
| Q4 | **Provider 是否已有現有 ShopSecretSetting class？** | `ShopSecretSettingFactory`（是 → 加 case；否 → Skill 停止，需先手動建立） |
| Q5 | **共用哪個 ShopSecretSetting？**（如 `RazerMSShopSecretSetting`） | `ShopSecretSettingFactory` |
| Q6 | **使用哪個 SettingService？**（通常 `SimpleShopSecretPaymentSettingService`；特殊 Provider 需專屬 class） | `ServiceModule` |
| Q7 | **是否需要 Razer ↔ AsiaPay 互斥設定？** | `ThirdPartyServicesService.PayProfileTypeExclusion` |
| Q8 | **是否為非主要入口 PayType？**（sub-type → 不在 UI 獨立顯示） | `ThirdPartyServicesService.HiddenSettingPayProfileTypes` |
| Q9 | **此 PayType 是否支援數位商品銷售？** | `SalePageCreateRequestEntityValidator.payTypeList` |
| Q10 | **費用報表需更新哪些市場的 switch-case？** MY / HK / SG / 全部 | `ExpenseOrderService` |
| Q11 | **各環境 AppSettings 啟用設定？** 加入 `EnbaleSetting` 清單？`EnabledShopIds` 全開 / 全關 / 指定商店？ | `AppSettings.Debug.{MARKET}.config`、`AppSettings.QABase.config` |

> 💡 **Q1 vs Q2 的關鍵區別：**
> - **Q1 環境市場** = SMS 系統部署在哪個國家（TW 站、HK 站等）
> - **Q2 銷售市場限定** = 此金流是否只允許特定「銷售市場（SalesMarket）」的商店開通，與環境無關。
> 例如：HK 環境中可能同時存在 HK 與 SG 銷售市場的商店，`SalesMarketSupportedPayProfiles` 控制哪些市場的商店**看得到**此金流選項。

> ⚠️ 執行前需彙整上述所有答案，並請使用者確認後才開始修改檔案。

---

## Step 2：計算 Enum Bit-Shift 值

讀取以下三個檔案，分別找出**各自獨立 bit space** 的下一個可用值：

→ 詳見 **[references/enum-files.md](references/enum-files.md)**

- `BusinessLogic/BE/PayProfile/PayProfileTypeEnum.cs`
- `BusinessLogic/BE/PayProfile/PayProfileStatisticsTypeEnum.cs`
- `BusinessLogic/BE/RefundRequests/RefundRequestTypeDefEnum.cs`

> ⚠️ 三個 enum 使用**各自獨立**的 bit space，不可共用相同數值。

---

## Workflow

### Phase 1 — Enum 定義（3 個檔案）
→ 讀取 **[references/enum-files.md](references/enum-files.md)**

| 檔案 | 動作 |
|------|------|
| `BusinessLogic/BE/PayProfile/PayProfileTypeEnum.cs` | 加 enum value（bit-shift）；需在 `CommonThirdPartyPayType` 之前 |
| `BusinessLogic/BE/PayProfile/PayProfileStatisticsTypeEnum.cs` | 加對應統計 enum value；通常**不加入** `CommonThirdPartyPayType` |
| `BusinessLogic/BE/RefundRequests/RefundRequestTypeDefEnum.cs` | 加退款 enum value |

---

### Phase 2 — Factory & Service 設定（3～4 個檔案）
→ 讀取 **[references/service-factory-files.md](references/service-factory-files.md)**

| 檔案 | 動作 |
|------|------|
| `BusinessLogic/Services/ThirdPartyServices/Payments/ShopSecretSettings/ShopSecretSettingFactory.cs` | 在 `GetInstance()` switch 加 case |
| `BusinessLogic/Services/ThirdPartyServices/ThirdPartyServicesService.cs` | 更新 4 個子區塊（Mapping / Exclusion / Hidden / Market） |
| `BusinessLogic/Services/ThirdPartyServices/Payments/ShopSecretSettings/PayTypeSettings/RazerMSShopSecretSetting.cs` | ⚠️ **僅 Razer 系列需要**：更新 `_payTypeDisplayNameDic` 與 `SalesMarketSupportedPayMethods` |

---

### Phase 3 — DI 注冊 & 驗證（2 個檔案）
→ 讀取 **[references/validator-files.md](references/validator-files.md)**

| 檔案 | 動作 |
|------|------|
| `CrossLayer/Modules/BL/ServiceModule.cs` | 在 `ThirdPartyServicesSettings()` 加 Autofac keyed 注冊 |
| `CrossLayer/Validators/SalePages/SalePageCreateRequestEntityValidator.cs` | 在 `payTypeList` 加入新 PayType，允許數位商品銷售 |

---

### Phase 3.5 — 退貨退款流程（條件性，0～1 個檔案）
→ 讀取 **[references/validator-files.md](references/validator-files.md)**（ReturnGoods 段落）

**⚠️ 先與使用者確認再決定是否需要修改此檔。**

| 檔案 | 條件 | 動作 |
|------|------|------|
| `BusinessLogic/Services/ReturnGoodsOrders/ReturnGoodsOrderService.cs` | 需要蒐集匯款退款資訊（顧客提供銀行帳號） | 在 `IsRefundInfoCollectingEnabled()` switch 加 case；同步設定 AppSettings config |

> 多數 Razer / AsiaPay 系列走 `default: return false`（直接退刷，不需蒐集），**不需修改**。

---

### Phase 4 — 費用報表（4 個檔案）
→ 讀取 **[references/expense-report-files.md](references/expense-report-files.md)**

| 檔案 | 動作 |
|------|------|
| `DataAccess/ErpDB/Extends/Csp_GetExpenseOrderReportReturnModel.cs` | 加 `Total{NewPayTypeName}Fee` 屬性 |
| `BusinessLogic/BE/ExpenseOrders/ExpenseOrderReportResultEntity.cs` | 加對應 business entity 屬性 |
| `CrossLayer/Mappers/ExpenseOrders/ExpenseOrderEntityMappingProfile.cs` | 加 AutoMapper ForMember 設定 |
| `BusinessLogic/Services/ExpenseOrders/ExpenseOrderService.cs` | 更新費用計算 switch-case 與 dataTable row |

---

### Phase 5 — AppSettings 環境啟用設定

> 💡 **此 Phase 控制金流在各環境是否實際啟用，與 `SalesMarketSupportedPayProfiles`（銷售市場限定）不同。**
> 前者是程式碼層面的市場過濾，此處是**環境 config 層面的開關**，兩者需分別設定。

每個環境的 AppSettings config（`AppSettings.Debug.{MARKET}.config`、`AppSettings.QABase.config` 等）需要設定兩個 key：

**Key 1 — 加入啟用清單：**
```xml
<add key="{Env}.ThirdParty.PayProfile.EnbaleSetting"
     value="...,{NewPayTypeName}" />
```
> ⚠️ 注意：此 key 名稱有拼字錯誤（`Enbabl` 非 `Enable`），**請原樣使用**，不要修正。

**Key 2 — 控制可開通的商店範圍：**
```xml
<add key="{Env}.PayProfileType.{NewPayTypeName}.EnabledShopIds"
     value="{globalEnabled}|{allowedShopIds}|{dateRange}" />
```

**格式說明：**
| 值 | 意義 |
|----|------|
| `false\|none\|none` | 所有商店停用（預設，上線前先設為此值） |
| `true\|none\|none` | 所有商店啟用 |
| `true\|2,5,73\|none` | 僅指定商店 ID 啟用 |
| `true\|none\|20-40` | 依時間範圍啟用（日期區間） |

**⚠️ 執行前請先與使用者確認：**
> 「`{NewPayTypeName}` 在 {環境} 環境的啟用設定為何？
> 1. **EnbaleSetting**：是否加入此環境的啟用清單？
> 2. **EnabledShopIds**：全開（`true|none|none`）/ 全關（`false|none|none`）/ 指定商店 ID？
> ⚠️ 通常新金流先設 `false|none|none`，待測試後再開放。」

**需更新的 config 檔案：**
- `WebSite/WebSite/AppSettings.Debug.{MARKET}.config` — 對應市場的 Debug 環境
- `WebSite/WebSite/AppSettings.QABase.config` — QA 環境（若適用）
- 其他 Prod / Staging config — 依部署流程另行處理

---

## Final Verification

1. 確認三個 enum bit-shift 值在各自 enum 中唯一
2. 確認 `PayProfileTypeEnum` 新值在 `CommonThirdPartyPayType` 定義之前
3. 確認 `PayProfileTypeExclusion` 互斥設定正確（Razer ↔ AsiaPay）
4. 確認 `HiddenSettingPayProfileTypes` 設定正確
5. 確認費用報表四個檔案的屬性命名一致（`Total{NewPayTypeName}Fee`）
6. 編譯確認：查找類似既有 PayType（如 `OnlineBanking_Razer`）在整個 codebase 中出現的位置，確認沒有遺漏

---

## 超出 Skill 範圍（需手動處理）

| 項目 | 說明 |
|------|------|
| 翻譯資源 `.resx` | `PaymentMethod{Name}`、`SystemUsageFee{Name}` 等 key |
| TypeScript Enum | `WebSite/WebSite/Scripts/Enums.ts` |
| 前台 HTML / TS Controller | 不在此 Skill 範圍 |
| 新 ShopSecretSetting class | 需手動建立 |
| 新 SettingService 實作 | 需手動建立 |
| Payment Gateway API 串接 | 需手動實作 |
| 資料庫 stored procedure | 需手動修改 |

---

## 版本紀錄

| 版本 | 說明 |
|------|------|
| v1.0 | 從 `.github/agents/add-paytype/nine1-add-paytype.agent.md`（v2.0.202603）轉化為 Copilot CLI Skill |
