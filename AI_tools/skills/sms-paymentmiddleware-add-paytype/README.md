# sms-paymentmiddleware-add-paytype Skill

> **⚠️ 專案限定**
> 本 Skill 僅適用於 **`NineYi.Sms`** 專案

---

## 簡介

此 Skill 協助開發者在 91APP **NineYi.Sms 後台系統**新增一個付款方式（PayType）。

涵蓋的 Provider 包含：
Razer、AsiaPay、Stripe、LinePay、JKOPay 等。

一次完整作業涉及 **11～12 個 C# 檔案**，橫跨 enum 定義、Factory 設定、Service 設定、DI 注冊、驗證器及費用報表。

---

## 如何觸發

在 GitHub Copilot CLI 中說（需包含 **PaymentMiddleware** 或**跨國金流**關鍵字，或明確提到已知 Provider）：

```
我要在 SMS 後台新增一個 PaymentMiddleware 金流
```
```
幫我在 SMS 加 FPS_Razer 這個跨國付款方式
```
```
新增 QFPay 到 SMS 跨境金流
```

> ⛔ **以下情境請勿使用此 Skill：**
> - `CathayPay`、國泰支付等本地 TW 金流
> - ATM、CVS、貨到付款等離線付款
> - 非 PaymentMiddleware 架構的金流
>
> 這些金流的修改範圍與本 Skill 完全不同，強行使用會導致遺漏或錯誤修改。

---

## 互動流程模擬

> 以新增 `PayNow_Razer`（新加坡 PayNow，走 Razer provider）為例。

---

### 【觸發 & 專案驗證】

```
👤 使用者：
我要在 SMS 後台新增 PayNow_Razer

🤖 Copilot：
讀取 sms-paymentmiddleware-add-paytype skill...

⚠️ 專案限定確認中：
✅ 找到 BusinessLogic/BE/PayProfile/PayProfileTypeEnum.cs
確認為 NineYi.Sms 專案，開始執行。
```

---

### 【Step 1 — 詢問階段】

```
🤖 Q1：PayType 名稱確認 — 建議 `PayNow_Razer`，確認或修改？
👤 對，就用 PayNow_Razer

🤖 Q2：目標市場？(A) TW  (B) MY  (C) SG  (D) HK  (E) 其他
👤 C，SG 市場

🤖 Q3：使用現有 RazerMSShopSecretSetting，還是建立新 Provider？
👤 A，用現有 Razer

🤖 Q4：是否需要 Razer ↔ AsiaPay 互斥設定？
👤 需要

🤖 Q5：是否加入 HiddenSettingPayProfileTypes（非主要入口）？
👤 是，PayNow 是 sub-type

🤖 Q6：費用報表需要更新哪個市場的 switch？
👤 SG
```

---

### 【Phase 1 — Enum 定義】

```
🤖 讀取三個 enum 檔，計算下一個可用 bit 值...
  PayProfileTypeEnum      → PayNow_Razer = 1L << 54
  PayProfileStatisticsTypeEnum → PayNow_Razer = 1L << 50
  RefundRequestTypeDefEnum → PayNow_Razer = 1L << 38

[1/3] PayProfileTypeEnum.cs            ✅
[2/3] PayProfileStatisticsTypeEnum.cs  ✅
[3/3] RefundRequestTypeDefEnum.cs      ✅

Phase 1 完成 ✅
```

---

### 【Phase 2 — Factory & Service 設定】

```
🤖
[1/3] ShopSecretSettingFactory.cs  → 加 case PayNow_Razer  ✅
[2/3] ThirdPartyServicesService.cs
  → ProfileShopDefaultGroupMapping: PayNow_Razer → "RazerMS"  ✅
  → PayProfileTypeExclusion: 加互斥 AsiaPay 系列  ✅
  → HiddenSettingPayProfileTypes: PayNow_Razer（non-primary）  ✅
  → SalesMarketSupportedPayProfiles: SG 市場  ✅
[+1] RazerMSShopSecretSetting.cs（Razer 系列）
  → _payTypeDisplayNameDic: 加 PaymentMethodPayNowRazer  ✅
  → SalesMarketSupportedPayMethods: SG 加 PayNow  ✅

Phase 2 完成 ✅
```

---

### 【Phase 3 — DI 注冊 & 驗證】

```
🤖
[1/2] ServiceModule.cs
  → builder.RegisterType<SimpleShopSecretPaymentSettingService>()
         .Keyed<IThirdPartyServiceSettingService>(nameof(PayProfileTypeEnum.PayNow_Razer));  ✅
[2/2] SalePageCreateRequestEntityValidator.cs
  → payTypeList 加入 nameof(PayProfileTypeEnum.PayNow_Razer)  ✅

Phase 3 完成 ✅
```

---

### 【Phase 4 — 費用報表】

```
🤖
[1/4] Csp_GetExpenseOrderReportReturnModel.cs → TotalPayNowRazerFee  ✅
[2/4] ExpenseOrderReportResultEntity.cs       → TotalPayNowRazerFee  ✅
[3/4] ExpenseOrderEntityMappingProfile.cs     → ForMember TotalPayNowRazerFee  ✅
[4/4] ExpenseOrderService.cs
  → SG case: totalAmount += summaryResult.TotalPayNowRazerFee  ✅
  → dataTable.Rows.Add(... SystemUsageFeePayNowRazer ...)  ✅

Phase 4 完成 ✅
```

---

### 【Final Verification】

```
🤖
[1] 三個 enum bit 值各自唯一  ✅
[2] PayNow_Razer 在 CommonThirdPartyPayType 之前  ✅
[3] PayProfileTypeExclusion 互斥設定正確  ✅
[4] HiddenSettingPayProfileTypes 包含 PayNow_Razer  ✅
[5] 費用報表四個檔案屬性命名一致（TotalPayNowRazerFee）  ✅
[6] 比對 OnlineBanking_Razer 的所有出現位置確認無遺漏  ✅

────────────────────────────────────────────────
✅ PayNow_Razer 新增完成！共修改 12 個檔案。

⚠️ 提醒（需手動處理）：
  1. 翻譯資源：PaymentMethodPayNowRazer、SystemUsageFeePayNowRazer
  2. TypeScript Enum：WebSite/WebSite/Scripts/Enums.ts
  3. 前台 HTML / TS Controller（不在 Skill 範圍）
────────────────────────────────────────────────
```

---

## Skill 檔案結構

```
sms-paymentmiddleware-add-paytype/
├── SKILL.md                           # 主控文件（4 Phase workflow）
├── README.md                          # 本說明文件
└── references/
    ├── enum-files.md                  # Phase 1：Enum 定義
    ├── service-factory-files.md       # Phase 2：Factory & Service 設定
    ├── validator-files.md             # Phase 3：DI 注冊 & 驗證
    └── expense-report-files.md        # Phase 4：費用報表
```
