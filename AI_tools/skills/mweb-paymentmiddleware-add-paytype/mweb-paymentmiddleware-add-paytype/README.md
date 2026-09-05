# add-paytype-middleware Skill

> **⚠️ 專案限定**
> 本 Skill 僅適用於 **`nineyi.webstore.mobilewebmall`** 專案
> （solution: `NineYi.WebStore.MallAndApi.sln`）

---

## 簡介

這個 Skill 協助開發者在 91APP WebStore 平台新增一個走 **PaymentMiddleware 路線**的付款方式（PayType）。

PaymentMiddleware 路線的 provider 包含：
Razer、Stripe、CheckoutDotCom、AsiaPay、Cybersource、EftPay、KPay、Atome、SwiftPass、2C2P、QFPay、PayMe 等。

一次完整的新增作業涉及約 **26～30 個檔案**，橫跨 enum 定義、商品頁、購物車、付款流程、訂單退款、Controller 及翻譯資源。Skill 會自動判斷範圍、計算 bit 值、逐步修改，並在最後驗證編譯。

---

## 如何觸發

在 GitHub Copilot CLI 中說：

```
我要新增一個 PaymentMiddleware 金流
```
或
```
幫我加 FPS_Razer 這個新的付款方式
```

Copilot 會自動辨識並載入此 Skill。

---

## 互動流程模擬

> 以新增 `FPS_Razer`（香港 FPS 快速支付，走 Razer provider）為例。

---

### 【觸發 & 專案驗證】

```
👤 使用者：
我要在 webstore 加一個新的 PaymentMiddleware 金流，是 Razer 的 FPS 付款

🤖 Copilot：
讀取 add-paytype-middleware skill...

⚠️ 專案限定確認中：
✅ 找到 NineYi.WebStore.MallAndApi.sln
✅ 找到 WebStore/Frontend/BE/PayProfile/PayProfileTypeDefEnum.cs

確認為 nineyi.webstore.mobilewebmall 專案，開始執行。
```

---

### 【Step 1 — 詢問階段（9 個問題）】

```
🤖 Q1：新 PayType 命名確認 — 建議 `FPS_Razer`，確認或修改？
👤 對，就用 FPS_Razer

🤖 Q2：目標市場？(A) 僅台灣 TW  (B) 僅海外  (C) 兩者都要
👤 B，海外（HK 市場）

🤖 Q3：使用現有 RazerPayChannelService，還是建立新 Provider？
👤 A，用現有 RazerPayChannelService

🤖 Q4：幣別模式？(A) SalesCurrency（多市場）  (B) DefaultPayment.Currency（預設）
👤 A，跟其他 Razer 一樣

🤖 Q5：收付模式？(A) DirectToBank  (B) ThroughPSP  (C) DirectToBankMid
👤 A，DirectToBank

🤖 Q6：需要退款支援？
👤 需要

🤖 Q7：需要取消訂單支援？
👤 需要

🤖 Q8：是否跨境（oversea）付款？
👤 是，HK 市場

🤖 Q9：需要加入複合 flag？收付模式 DirectToBank 通常加 DirectToBankThirdPartyPayType，確認？
👤 對
```

```
🤖 確認彙整如下：
────────────────────────────────
  PayType 名稱   : FPS_Razer
  Provider       : Razer（使用現有 RazerPayChannelService）
  目標市場        : 海外（只加 _sortedPayProfileTypeDef）
  幣別模式        : SalesCurrency
  收付模式        : DirectToBank
  複合 flag       : DirectToBankThirdPartyPayType
  退款            : ✅
  取消訂單        : ✅
  跨境付款        : ✅
────────────────────────────────
確認無誤，開始執行？

👤 確認
```

---

### 【Phase 1 — Core Enum Definitions】

```
🤖 讀取三個 enum 檔，計算下一個可用 bit 值...
  PayProfileTypeDefEnum  → FPS_Razer = 1152921504606846976（2^60）
  StatisticsTypeDefEnum  → FPS_Razer = 576460752303423488（2^59）
  SearchShopPayTypeEnum  → FPS_Razer = 144115188075855872（2^57）

[1/3] PayProfileTypeDefEnum.cs
  → 加入 FPS_Razer 值
  → 更新 All（append FPS_Razer）
  → 更新 DirectToBankThirdPartyPayType（append FPS_Razer）
  ✅ 完成

[2/3] StatisticsTypeDefEnum.cs
  → 加入 FPS_Razer 值（不加 CommonThirdPartyPayType 複合 flag）
  ✅ 完成

[3/3] RefundRequestTypeDefEnum.cs（需退款）
  → 加入 FPS_Razer
  ✅ 完成

Phase 1 完成 ✅
```

---

### 【Phase 2 — Sale Page & Search】

```
🤖
[1/4] PayProfileTypeDefComparer.cs
  目標市場：海外 → 只修改 _sortedPayProfileTypeDef
  → GrabPay_Razer 後面加入 FPS_Razer（同 Razer 群組）
  ✅（_sortedPayProfileTypeDefTW 不動）

[2/4] GetPayTypeProcessor.cs  ✅
[3/4] SearchShopPayTypeEnum.cs（附 [LocalizableDescription]）  ✅
[4/4] SearchService.cs（Razer 群組附近）  ✅

Phase 2 完成 ✅
```

---

### 【Phase 3 — Shopping Cart】

```
🤖
[1/3] ShoppingCartClientPayTypeGroupEntity.cs  ✅
[2/3] StatisticsTypeDefComparer.cs（海外 list）  ✅
[3/3] PickupShoppingCartCheckoutTypeV2Processor.cs  ✅

Phase 3 完成 ✅
```

---

### 【Phase 4 — Payment Processing】

```
🤖
[1/5] GetPayProcessDataProcessor.cs（兩個 switch）  ✅
[2/5] ThirdPartyPayApiProcessor.cs  ✅
[3/5] CreateTradesOrderProcessor.cs
  → [switch 1/3] 第三方判斷（~行 241）  ✅
  → [switch 2/3] 退款資訊（~行 618）  ✅
  → [switch 3/3] 幣別設定（~行 1107，SalesCurrency 模式）  ✅
[4/5] PaymentMiddlewareService.cs（GetSalesCurrency + GetSalesMarket → HK）  ✅
[5/5] RazerPayChannelService.cs — GetChannel() 加新 case：

  ⚠️ 請確認 Razer API 文件，FPS 的 txn_channel code 是 "FPS" 嗎？

👤 是的，就是 "FPS"

  → case PayProfileTypeDefEnum.FPS_Razer: return "FPS";  ✅
  （ServiceModule.cs 不需要動，使用現有 RazerPayChannelService）

Phase 4 完成 ✅
```

---

### 【Phase 5 — Order & Refund】

```
🤖
[1/5] MemberTradesOrderGroupEntity.cs  ✅
[2/5] MemberTradesOrderGroupPayInfoForDetailEntity.cs  ✅
[3/5] GetMemberTradesOrderRefundProcessor.cs（需退款）  ✅
[4/5] MemberTradesOrderService.cs（需退款）  ✅
[5/5] CancelRequestService.cs（需取消訂單）  ✅
[+1] OverseaPayHelper.cs（跨境付款）  ✅

Phase 5 完成 ✅
```

---

### 【Phase 6 — WebAPI Controllers】

```
🤖
[1/4] GlobalPayController.cs  ✅
[2/4] TradesOrderLiteController.cs（if 條件 + switch-case）  ✅
[3/4] TradesOrderV2Controller.cs（同上）  ✅
[4/4] CancelRequestV2Controller.cs（需取消訂單）  ✅

Phase 6 完成 ✅
```

---

### 【Phase 7 — Translation Resources】

```
🤖 7 個翻譯檔統一新增 FPS_Razer property：

[1/7] Frontend.SalePage.cs
  → FPSRazer { get { return GetString("fps_razer"); }}  ✅
[2/7] Backend.Webapi.SearchV2.cs  ✅
[3/7] Backend.Entity.ShoppingCartClientPayTypeGroup.cs  ✅
[4/7] Backend.V2.Pay.cs
  → PayProcessFPSRazer { get { return GetString("pay_process_fps_razer"); }}  ✅
[5/7] Backend.Entity.MemberTradesOrderGroup.cs  ✅
[6/7] Backend.Entity.MemberTradesOrderGroupPayInfoForDetail.cs  ✅
[7/7] Frontend.Typescripts.Mixin.PayProfileTypeDisplayName.cs  ✅

Phase 7 完成 ✅
```

---

### 【Phase 8 — AppSettings Config】

```
🤖 收付模式：DirectToBank
更新以下 config（WebStore/WebAPI/ 下）：
  AppSettings.Debug.HK.config
  AppSettings.QA.HK.config
  AppSettings.Prod.HK.config
  → Dev.PayType.DirectToBank value 末尾加上 ,FPS_Razer  ✅

Phase 8 完成 ✅
```

---

### 【Final Verification】

```
🤖
[1] 搜尋 OnlineBanking_Razer 比對覆蓋範圍... ✅ 一致
[2] PayProfileTypeDefEnum.All 包含 FPS_Razer ✅
[3] 三個 enum bit 值唯一 ✅
[4] 7 個翻譯檔均已新增 property ✅
[5] msbuild NineYi.WebStore.MallAndApi.sln /p:Configuration=Debug
    → Build succeeded. 0 Error(s) ✅

────────────────────────────────────────────────
✅ FPS_Razer 新增完成！共修改 26 個檔案。

⚠️ 提醒（不在 Skill 範圍內，需手動處理）：
  1. 翻譯文字（fps_razer、pay_process_fps_razer）
     需由翻譯負責人補入 .resx / 翻譯資料庫
  2. TypeScript enum 同步（CartClientApp / ClientApp / Scripts）
     需手動更新對應 TS 檔案
────────────────────────────────────────────────
```

---

## Skill 檔案結構

```
add-paytype-middleware/
├── SKILL.md                          # 主控文件（8 Phase workflow）
└── references/
    ├── enum-files.md                 # Phase 1：enum 定義與 bit 計算
    ├── salepage-search-files.md      # Phase 2：商品頁 & 搜尋
    ├── shopping-cart-files.md        # Phase 3：購物車
    ├── payment-process-files.md      # Phase 4：付款流程 & DI & Fail 機制
    ├── order-refund-files.md         # Phase 5：訂單退款取消
    └── controller-translation-files.md  # Phase 6+7+8：Controller、翻譯、Config
```

---

## 重要設計決策備忘

| 主題 | 決策 |
|---|---|
| `PayProfileTypeDefComparer` | 兩個 private list 欄位（非方法），依目標市場決定加哪個 |
| `PayChannelService` channel code | 在 `GetPayExtendInfo()` 內的私有 `GetChannel()` 加 case |
| DI 注冊 | 同 provider 新增 paytype **不需要**改 `ServiceModule.cs`，resolver 自動路由 |
| Fail 機制 | PaymentMiddleware 統一用 `PaymentStatusDefEnum.Fail`，**不用** `TradesOrderResultEnum` |
| `CreateTradesOrderProcessor` | 需改 **3 個** switch（第三方判斷 / 退款資訊 / 幣別設定） |
| `StatisticsTypeDefEnum` 複合 flag | `CommonThirdPartyPayType` **不加** PaymentMiddleware 的 paytype |
| AppSettings 位置 | 在 **WebAPI 專案**（非 MobileWebMallV2） |
| TypeScript enum | **不在 Skill 範圍**，需手動更新 |

---

## 版本紀錄

| 版本 | 說明 |
|---|---|
| v1 | 初始版本，基於 nine1-add-paytype.agent.md 轉換 |
| v2 | 修正 G1~G9 共 9 個缺漏：複合 flag、list 欄位結構、DI 路由、channel code 位置、幣別模式、Fail enum、Config 路徑 |
