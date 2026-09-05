---
name: common-91shop-purchase-flow
description: >
  執行 91APP 前台購物完整流程：依價格找商品、加入購物車、登入（手機號碼，支援切換國碼）、前往結帳、在商品頁確認付款方式（信用卡 = Stripe 或 Razer）。
  當使用者說「加入購物車」、「購物流程」、「前台結帳」、「91shop 購買」、「找商品並結帳」、
  「確認 Stripe 付款」、「確認 Razer 付款」、「前台金流確認」、「購物網站加商品」時，立即使用此 skill。
allowed-tools: Bash(playwright-cli:*), Bash(curl:*)
---

# 91APP 前台購物流程

使用 `playwright-cli` 操作 91APP 前台商店，完成「找商品 → 登入 → 加入購物車 → 結帳」的完整流程。

---

## 工具使用原則

### curl vs playwright-cli

| 情境 | 工具 |
|------|------|
| 呼叫 REST API 取得 JSON（無需登入 session） | **curl** |
| 頁面需要 JS 動態渲染 | **playwright-cli** |
| 需要登入 session / Cookie | **playwright-cli** |
| 點擊、填表、UI 互動 | **playwright-cli** |

### 頁面狀態確認：優先 eval / snapshot，避免 screenshot

| 目的 | 優先做法 |
|------|---------|
| 確認頁面跳轉 | `eval "location.href"` |
| 確認頁面標題 | `eval "document.title"` |
| 確認元素結構 / ref | `snapshot` |
| 確認 DOM 文字值 | `eval "document.querySelector(...).textContent"` |
| 確認元素數量 | `eval "document.querySelectorAll(...).length"` |

> **screenshot 僅在以下情境使用**：
> - iframe 座標需要目視確認時
> - 頁面有驗證碼等無法用文字讀取的視覺元素

---

## 環境說明

### Domain 對照表

**前台 `{shopDomain}`**

| 環境 | 類型 | 格式 | 範例 |
|------|------|------|------|
| Prod HK | 官網 domain | `{name}.91app.hk` | `shop2.91app.hk` |
| Prod HK | 自有 domain | 各自不同 | `mart.family.com.tw` |
| QA HK   | 官網 domain | `{name}.shop.qa1.hk.91dev.tw` | `cccrrrmmm1.shop.qa1.hk.91dev.tw` |
| QA HK   | 自有 domain | 各自不同 | — |
| QA MY   | 官網 domain | `{name}.shop.qa1.my.91dev.tw` | `lilychuang2.shop.qa1.my.91dev.tw` |

**WebAPI `{webApiDomain}`**

| 環境 | Domain |
|------|--------|
| Prod HK | `webapi.91app.hk` |
| QA HK   | `webapi.cdn.qa1.hk.91dev.tw` |
| QA MY   | `webapi.cdn.qa1.my.91dev.tw` |

URL 格式：`https://{shopDomain}/{path}`，所有類型的 path 相同，只有 domain 不同。

> **重要**：Production 環境為 Live Mode，不接受測試卡號（如 4242...）。

### 付款金流對照

| 市場 | 付款選項 | 金流 |
|------|---------|------|
| HK | 信用卡（Visa/MC/AMEX/JCB）| Stripe **或** Checkout.com，視商店配置 |
| HK | 線上付款 | 2C2P（QA: `sandbox-pgw-ui.2c2p.com`）|
| HK | AlipayHK / PayMe / WeChat Pay / BoC Pay | 各自閘道 |
| MY | 信用卡一次付款（Visa/MC）| Razer Merchant Services |
| MY | 網路銀行（FPX）/ Touch 'n Go / Boost | 各自閘道 |

> **HK 信用卡金流判斷**：
> - **Stripe**：信用卡欄位直接在頁面 DOM（placeholder `信用卡號碼`）
> - **Checkout.com**：信用卡欄位在 `ct-checkout.np-pay.com` iframe 內（同 MY Razer）

### shopId 查詢方式

shopId 無法從 domain 推導，需從購物車跳轉 URL 取得：

```bash
# 前往購物車（未登入會跳轉至登入頁），觀察跳轉 URL 中的 officialShopId
playwright-cli -s=shop91 goto "https://{shopDomain}/V2/ShoppingCart/Index"
# 跳轉後 URL 範例：
# .../V2/Login/Index/?...&officialShopId=5&...  → shopId = 5
# 也可從 API 回應確認：Data.SalePageList[0].ShopId
```

---

## Step 1：查詢符合價格的商品

透過 WebAPI 依價格升冪排列，找出符合條件的商品 Id：

```bash
curl "https://{webApiDomain}/webapi/shopCategory/GetSalePageList/{shopId}/0?order=PriceAsc&startIndex=0&maxCount=100&shopId={shopId}&lang=zh-TW"
```

> ⚠️ **MY 站台**：`lang=zh-TW` 可能回傳 0 筆，改用 `lang=en-US`。
>
> PowerShell 若遇到 `curl` 編碼問題，改用：
> ```powershell
> $resp = Invoke-WebRequest -Uri "https://..." -UseBasicParsing
> ($resp.Content | ConvertFrom-Json).Data.SalePageList | Where-Object { $_.Price -ge 100 }
> ```

回應範例（`Data.SalePageList[]`）：
```json
{ "Id": 600842, "Title": "商品名稱", "Price": 10.0 }
```

---

## Step 2：登入

**先登入再加購物車**，避免登入後購物車被清空。

```bash
# 前往購物車（觸發登入橫幅）
playwright-cli -s=shop91 goto "https://{shopDomain}/V2/ShoppingCart/Index?shopId={shopId}"

# 關閉 Cookie 通知（如有）
# ⚠️ click 可能被 Backdrop 攔截，改用 eval 更可靠
playwright-cli -s=shop91 eval "document.querySelector('.sc-fbbtMj')?.click()"

# 點擊登入橫幅
playwright-cli -s=shop91 click "getByText('登入會員，立即享有完整的會員專屬優惠')"

# 切換國碼（預設 HK+852 或 MY+60，台灣帳號切換 TW+886）
playwright-cli -s=shop91 click "getByText('HK+852')"   # 或 'MY+60'
playwright-cli -s=shop91 click "getByText('Taiwan 台灣+')"

# 輸入手機號碼
# ⚠️ QA 登入頁：Header 有額外輸入框導致 strict mode 失敗
#    先 snapshot 確認登入表單 ref，再用 ref 填入
playwright-cli -s=shop91 snapshot --depth=3
playwright-cli -s=shop91 fill {ref} "911222333"

playwright-cli -s=shop91 click "getByRole('button', { name: '登入/註冊' })"
playwright-cli -s=shop91 fill "getByRole('textbox', { name: '請輸入密碼' })" "123456"
playwright-cli -s=shop91 click "getByRole('button', { name: '登入' })"
```

---

## Step 3：加入購物車

```bash
# 前往商品頁（{salePageId} 替換為 Step 1 找到的 Id）
playwright-cli -s=shop91 goto "https://{shopDomain}/SalePage/Index/{salePageId}"

# 加入購物車
playwright-cli -s=shop91 click "getByRole('button', { name: '加入購物車' })"
# 確認加入成功：購物車 icon 數量應增加
playwright-cli -s=shop91 eval "document.querySelector('[data-qe-id*=cart]')?.textContent"
```

> 購物車可能有帳號殘留的舊商品，前往購物車確認並刪除：
> ```bash
> playwright-cli -s=shop91 goto "https://{shopDomain}/V2/ShoppingCart/Index?shopId={shopId}"
> # 依索引刪除（N 從 0 開始）
> playwright-cli -s=shop91 eval "document.querySelectorAll('button[data-qe-id*=delete]')[N].click()"
> playwright-cli -s=shop91 click "getByRole('button', { name: '刪除商品' })"
> ```

---

## Step 4：結帳

```bash
playwright-cli -s=shop91 click "getByRole('button', { name: '前往結帳' })"
# 確認已進入結帳頁（URL 含 /Checkout 或 /V2/Pay/）
playwright-cli -s=shop91 eval "location.href"
```

> 若購物金全額抵付導致付款方式隱藏，先關閉 toggle：
> ```bash
> playwright-cli -s=shop91 eval "document.querySelector('[role=switch]').click()"
> ```

### 選擇付款方式

**HK Stripe（欄位在頁面 DOM）**
```bash
playwright-cli -s=shop91 click "getByText('信用卡')"
# 若有儲存的測試卡（**** 4242），直接送出訂單即可；否則填入新卡：
playwright-cli -s=shop91 fill "getByPlaceholder('信用卡號碼')" "4242424242424242"
playwright-cli -s=shop91 fill "getByPlaceholder('月份/年份')" "1228"
playwright-cli -s=shop91 fill "getByPlaceholder('安全碼')" "123"
```

**HK Checkout.com / MY Razer（欄位在 `ct-checkout.np-pay.com` iframe）**
```bash
playwright-cli -s=shop91 click "getByText('信用卡')"
# iframe 父容器可能是 display:none，強制顯示：
playwright-cli -s=shop91 eval "document.querySelectorAll('iframe')[1].parentElement.style.display='block'"
# iframe 內欄位無法 fill，以座標點擊後 keyboard.type（座標依截圖調整）：
playwright-cli -s=shop91 run-code --filename=fill-card.js
```
```js
// fill-card.js
async page => {
  await page.mouse.click(285, 205); await page.waitForTimeout(500);
  await page.keyboard.type('4242424242424242');
  await page.mouse.click(195, 253); await page.waitForTimeout(500);
  await page.keyboard.type('1228');
  await page.mouse.click(371, 253); await page.waitForTimeout(500);
  await page.keyboard.type('123');
}
```
> 若 iframe 被 rate limit（429）無法載入，改選「線上付款」：
> ```bash
> playwright-cli -s=shop91 eval "document.querySelector('.m-modalBox').style.display='none'"
> playwright-cli -s=shop91 click "getByText('線上付款')"
> ```

**2C2P 線上付款（跳轉至 `sandbox-pgw-ui.2c2p.com`）**
```bash
playwright-cli -s=shop91 click "getByText('線上付款')"
# 送出訂單後跳轉至 2C2P，填入信用卡：
playwright-cli -s=shop91 fill "getByPlaceholder('0000-0000-0000-0000')" "4242424242424242"
playwright-cli -s=shop91 fill "getByPlaceholder('MM / YY')" "12/28"
playwright-cli -s=shop91 fill "getByLabel('CARDHOLDER NAME')" "Test User"
playwright-cli -s=shop91 fill "getByLabel('EMAIL ADDRESS')" "test@91app.com"
# CVV 無固定 placeholder，用座標點擊後輸入：
playwright-cli -s=shop91 run-code "async page => { await page.mouse.click(790, 410); await page.waitForTimeout(500); await page.keyboard.type('123'); }"
playwright-cli -s=shop91 click "getByRole('button', { name: 'CONTINUE PAYMENT' })"
```

### 送出訂單

```bash
playwright-cli -s=shop91 click "getByRole('button', { name: '送出訂單' })"
# 確認結果：URL 和頁面標題（訂購成功 = 標題含「訂購成功」）
playwright-cli -s=shop91 eval "location.href + ' | ' + document.title"
```

**送出後跳轉（依金流而定）：**

| 金流 | 跳轉目標 | Test / Sandbox 確認 |
|------|---------|-------------------|
| Stripe | `hooks.stripe.com/3d_secure_2/hosted?...` | URL 含 `pk_test_...` |
| Razer | `sandbox.merchant.razer.com/...` → Request OTP → Pay Now | domain = sandbox |
| 2C2P | `sandbox-pgw-ui.2c2p.com` → 填卡 → CONTINUE PAYMENT | domain = sandbox |
| 共同成功頁 | `/V2/Pay/Finish/?k=...&shopId={shopId}#complete` | 頁面標題 = **訂購成功** |

---

## 常見問題

| 問題 | 解法 |
|------|------|
| 信用卡填寫後出現「有效期格式錯誤」 | 效期欄位用座標點擊後 `keyboard.type('1228')`，不要用 `fill` |
| 信用卡送出後 400 錯誤 | Production 不接受測試卡；QA 用 `4242424242424242` |
| QA 登入頁手機號碼 strict mode 失敗 | Header 有額外輸入框；先 `snapshot` 確認登入表單 ref，再用 ref 填入 |
| 找不到 shopId | 前往 `/V2/ShoppingCart/Index`，觀察跳轉 URL 中 `officialShopId=N`；或看 API 回應 `SalePageList[0].ShopId` |
| 結帳頁不顯示付款方式（購物金全額） | 用 `eval "document.querySelector('[role=switch]').click()"` 關閉購物金 toggle |
| Cookie 通知 click 被 Backdrop 攔截 | 改用 `eval "document.querySelector('.sc-fbbtMj')?.click()"` |
| 信用卡 iframe（ct-checkout.np-pay.com）問題 | 三種情況：① 父容器 `display:none` → `eval "document.querySelectorAll('iframe')[1].parentElement.style.display='block'"` ② 被 rate limit（429）→ 改選「線上付款」走 2C2P ③ overlay 攔截點擊 → `eval "document.querySelector('.m-modalBox').style.display='none'"` 後再點 |
| MY 購物車廣告 popup 擋住 | 用座標點擊關閉 X（**先用 snapshot 確認位置**，約 `(432, 191)`，僅在無法用 selector 點擊時才 screenshot） |
| MY 前往結帳按鈕被 overlay 遮擋 | `eval "document.querySelector('[data-qe-id=fixed-bottom-to-checkout-btn]').click()"` |
| MY 站台 API 查不到商品 | 改用 `lang=en-US`，`lang=zh-TW` 可能回傳 0 筆 |
| 查詢價格區間無商品 | 先查出全部可用價格：`python -c "import sys,json; data=json.load(sys.stdin); print(sorted(set(x['Price'] for x in data['Data']['SalePageList'])))"` 再選最接近的 |

---

## 完整流程範例

### HK QA（Stripe 信用卡，shop2）

> shopDomain = `shop2.shop.qa1.hk.91dev.tw`、webApiDomain = `webapi.cdn.qa1.hk.91dev.tw`、shopId = 2

```bash
curl "https://webapi.cdn.qa1.hk.91dev.tw/webapi/shopCategory/GetSalePageList/2/0?order=PriceAsc&startIndex=0&maxCount=50&shopId=2&lang=zh-TW"
# → Id: 65643 (HK$10)

playwright-cli -s=shop91qa open "https://shop2.shop.qa1.hk.91dev.tw/"
playwright-cli -s=shop91qa goto "https://shop2.shop.qa1.hk.91dev.tw/V2/ShoppingCart/Index?shopId=2"
playwright-cli -s=shop91qa click "getByText('登入會員，立即享有完整的會員專屬優惠')"
playwright-cli -s=shop91qa click "getByText('HK+')"
playwright-cli -s=shop91qa click "getByText('Taiwan 台灣+')"
playwright-cli -s=shop91qa snapshot --depth=3
playwright-cli -s=shop91qa fill {ref} "911222333"
playwright-cli -s=shop91qa click "getByRole('button', { name: '登入/註冊' })"
playwright-cli -s=shop91qa fill "getByRole('textbox', { name: '請輸入密碼' })" "123456"
playwright-cli -s=shop91qa click "getByRole('button', { name: '登入' })"

playwright-cli -s=shop91qa goto "https://shop2.shop.qa1.hk.91dev.tw/SalePage/Index/65643"
playwright-cli -s=shop91qa click "getByRole('button', { name: '加入購物車' })"

playwright-cli -s=shop91qa goto "https://shop2.shop.qa1.hk.91dev.tw/V2/ShoppingCart/Index?shopId=2"
playwright-cli -s=shop91qa click "getByRole('button', { name: '前往結帳' })"
# Stripe：QA 有儲存測試卡，直接送出
playwright-cli -s=shop91qa click "getByRole('button', { name: '送出訂單' })"
# → hooks.stripe.com（pk_test_... = Test Mode）→ 訂購成功
playwright-cli -s=shop91qa close
```

### HK QA（2C2P 線上付款，shop11）

> shopDomain = `shop11.shop.qa1.hk.91dev.tw`、webApiDomain = `webapi.cdn.qa1.hk.91dev.tw`、shopId = 11
> shop11 的「信用卡」使用 Checkout.com iframe，QA 有 rate limit 問題，改用「線上付款」(2C2P)

```bash
$resp = Invoke-WebRequest -Uri "https://webapi.cdn.qa1.hk.91dev.tw/webapi/shopCategory/GetSalePageList/11/0?order=PriceAsc&startIndex=0&maxCount=100&shopId=11&lang=zh-TW" -UseBasicParsing
($resp.Content | ConvertFrom-Json).Data.SalePageList | Where-Object { $_.Price -ge 100 -and $_.Price -le 125 } | Select-Object Id, Title, Price
# → Id: 62583 (HK$100), Id: 62509 (HK$100)

playwright-cli -s=shop91hk11 open "https://shop11.shop.qa1.hk.91dev.tw/"
playwright-cli -s=shop91hk11 goto "https://shop11.shop.qa1.hk.91dev.tw/V2/ShoppingCart/Index?shopId=11"
playwright-cli -s=shop91hk11 eval "document.querySelector('.sc-fbbtMj')?.click()"
playwright-cli -s=shop91hk11 click "getByText('登入會員，立即享有完整的會員專屬優惠')"
playwright-cli -s=shop91hk11 click "getByText('HK+852')"
playwright-cli -s=shop91hk11 click "getByText('Taiwan 台灣+')"
playwright-cli -s=shop91hk11 fill "getByRole('textbox', { name: '輸入手機號碼' })" "911222333"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: '登入/註冊' })"
playwright-cli -s=shop91hk11 fill "getByRole('textbox', { name: '請輸入密碼' })" "123456"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: '登入' })"

playwright-cli -s=shop91hk11 goto "https://shop11.shop.qa1.hk.91dev.tw/SalePage/Index/62583"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: '加入購物車' })"
playwright-cli -s=shop91hk11 goto "https://shop11.shop.qa1.hk.91dev.tw/SalePage/Index/62509"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: '加入購物車' })"

playwright-cli -s=shop91hk11 goto "https://shop11.shop.qa1.hk.91dev.tw/V2/ShoppingCart/Index?shopId=11"
# 若有舊商品需刪除：
playwright-cli -s=shop91hk11 eval "document.querySelectorAll('button[data-qe-id*=delete]')[N].click()"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: '刪除商品' })"

playwright-cli -s=shop91hk11 click "getByRole('button', { name: '前往結帳' })"
playwright-cli -s=shop91hk11 click "getByText('信用卡')"  # 觸發 iframe 載入
playwright-cli -s=shop91hk11 eval "document.querySelector('.m-modalBox').style.display='none'"
playwright-cli -s=shop91hk11 click "getByText('線上付款')"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: '送出訂單' })"
# → sandbox-pgw-ui.2c2p.com
playwright-cli -s=shop91hk11 fill "getByPlaceholder('0000-0000-0000-0000')" "4242424242424242"
playwright-cli -s=shop91hk11 fill "getByPlaceholder('MM / YY')" "12/28"
playwright-cli -s=shop91hk11 fill "getByLabel('CARDHOLDER NAME')" "Test User"
playwright-cli -s=shop91hk11 fill "getByLabel('EMAIL ADDRESS')" "test@91app.com"
playwright-cli -s=shop91hk11 run-code "async page => { await page.mouse.click(790, 410); await page.waitForTimeout(500); await page.keyboard.type('123'); }"
playwright-cli -s=shop91hk11 click "getByRole('button', { name: 'CONTINUE PAYMENT' })"
# 確認訂購成功
playwright-cli -s=shop91hk11 eval "location.href + ' | ' + document.title"
# → /V2/Pay/Finish/...#complete，訂購成功
playwright-cli -s=shop91hk11 close
```

### MY QA（Razer 信用卡，lilychuang2）

> shopDomain = `lilychuang2.shop.qa1.my.91dev.tw`、webApiDomain = `webapi.cdn.qa1.my.91dev.tw`、shopId = 4

```bash
curl "https://webapi.cdn.qa1.my.91dev.tw/webapi/shopCategory/GetSalePageList/4/0?order=PriceAsc&startIndex=0&maxCount=100&shopId=4&lang=en-US"
# → Id: 7449 (MYR 99.15)

playwright-cli -s=shop91my open "https://lilychuang2.shop.qa1.my.91dev.tw/"
playwright-cli -s=shop91my goto "https://lilychuang2.shop.qa1.my.91dev.tw/V2/ShoppingCart/Index?shopId=4"
playwright-cli -s=shop91my click "getByText('登入會員，立即享有完整的會員專屬優惠')"
playwright-cli -s=shop91my click "getByText('MY+')"
playwright-cli -s=shop91my click "getByText('Taiwan 台灣+')"
playwright-cli -s=shop91my snapshot --depth=3
playwright-cli -s=shop91my fill {ref} "911222333"
playwright-cli -s=shop91my click "getByRole('button', { name: '登入/註冊' })"
playwright-cli -s=shop91my fill "getByRole('textbox', { name: '請輸入密碼' })" "123456"
playwright-cli -s=shop91my click "getByRole('button', { name: '登入' })"

playwright-cli -s=shop91my goto "https://lilychuang2.shop.qa1.my.91dev.tw/SalePage/Index/7449"
playwright-cli -s=shop91my click "getByRole('button', { name: '加入購物車' })"

playwright-cli -s=shop91my goto "https://lilychuang2.shop.qa1.my.91dev.tw/V2/ShoppingCart/Index?shopId=4"
# 若有舊商品：
playwright-cli -s=shop91my eval "document.querySelectorAll('button[data-qe-id*=delete]')[N].click()"
playwright-cli -s=shop91my click "getByRole('button', { name: '刪除商品' })"
# 若有廣告 popup 擋住，用座標關閉：
playwright-cli -s=shop91my run-code "async page => { await page.mouse.click(432, 191); }"
# 前往結帳（overlay 問題用 eval）：
playwright-cli -s=shop91my eval "document.querySelector('[data-qe-id=fixed-bottom-to-checkout-btn]').click()"

# iframe 填卡：先用 eval 取得 iframe 實際位置，再以相對座標輸入
playwright-cli -s=shop91my eval "JSON.stringify(document.querySelectorAll('iframe')[1].getBoundingClientRect())"
# 根據回傳的 x, y 調整 fill-card.js 中的座標（欄位在 iframe 內的相對偏移固定）
playwright-cli -s=shop91my run-code --filename=fill-card.js

playwright-cli -s=shop91my click "getByText('我已經閱讀並同意以上國家/地區配送權益聲明')"
playwright-cli -s=shop91my click "getByRole('button', { name: '送出訂單' })"
# → sandbox.merchant.razer.com → Request OTP → 截圖取 OTP → 填入 → Pay Now
playwright-cli -s=shop91my click "getByRole('button', { name: 'Request OTP' })"
# 從 DOM 讀取 OTP（sandbox 頁面通常以文字顯示）
playwright-cli -s=shop91my eval "document.body.innerText.match(/\b\d{6}\b/)?.[0]"
# 若上述回傳 null，改用 snapshot 確認 OTP 位置：
# playwright-cli -s=shop91my snapshot --depth=3
playwright-cli -s=shop91my fill "getByRole('textbox')" "{OTP碼}"
playwright-cli -s=shop91my click "getByRole('button', { name: 'Pay Now' })"
# 確認訂購成功
playwright-cli -s=shop91my eval "location.href + ' | ' + document.title"
# → /V2/Pay/Finish/...#complete，訂購成功
playwright-cli -s=shop91my close
```
