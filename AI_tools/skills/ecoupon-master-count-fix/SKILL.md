---
name: ecoupon-master-count-fix
description: 修正不預產優惠券（ECoupon_IsPreProduce=0）主子檔數量不一致的 SQL 產生流程。當使用者說「優惠券主子檔不一致」、「ECoupon 少扣」、「TakenQty 不對」、「主檔少扣」、「優惠券數量對不起來」、「不預產券主子檔」時使用此 skill。會引導確認情境為「主檔少扣」後，收集 VSTS 單號與 ECouponId，自動產生修正 SQL 檔案。
---

## 🏐 目標

針對不預產優惠券（`ECoupon_IsPreProduce = 0`）發生主子檔數量不一致（主檔少扣）的情況，引導使用者確認情境並自動產生修正 SQL 檔案。

📖 **SOP 文件：** https://wiki.91app.com/pages/viewpage.action?pageId=346357780

**主子檔正常不變式：**
```
ABS(ECoupon_TakenQty + ECoupon_ReturnQty) = COUNT(ECouponSlave WHERE IsTake=1)
```
**少扣定義：** `ABS(TakenQty + ReturnQty)` < SlaveCount，即主檔少記錄了幾張已被領走的紀錄。

---

## 🏐 執行步驟

### Step 0：初始化（靜默執行）

```shell
git rev-parse --show-toplevel
git config user.email
```

將根目錄存為 `REPO_ROOT`，email 存為 `CURRENT_USER_EMAIL`（失敗則用 `santayang@91app.biz`）。

---

### Step 1：🏐 收集基本資訊

#### 1-1 詢問 VSTS 單號

詢問：「�� 請輸入 VSTS Ticket 號碼（若無請輸入 000000）」

透過 Azure DevOps MCP 取得工單標題作為備註（`get_work_item_basic`），若輸入 000000 則跳過查詢。

#### 1-2 詢問 ECouponId

詢問：「🎫 請輸入要修正的 ECouponId」

接受單一整數（本 SQL 為單筆設計）。

---

### Step 2：🔍 確認情境為「主檔少扣」

顯示以下 Query SQL 請使用者在 SSMS 執行，確認情境：

```sql
USE WebStoreDB
GO

DECLARE @ECouponId BIGINT = {ECouponId};

SELECT
    ECoupon_Id,
    ECoupon_TotalQty                                                    AS [總量],
    ECoupon_TakenQty                                                    AS [主檔已領(負值)],
    ECoupon_ReturnQty                                                   AS [主檔已退],
    ABS(ECoupon_TakenQty + ECoupon_ReturnQty)                           AS [主檔有效已領數],
    COUNT(ECouponSlave_Id)                                              AS [子檔實際已領數],
    COUNT(ECouponSlave_Id) - ABS(ECoupon_TakenQty + ECoupon_ReturnQty) AS [差異張數_正值表示少扣]
FROM dbo.ECoupon WITH (NOLOCK)
INNER JOIN dbo.ECouponSlave WITH (NOLOCK)
    ON ECouponSlave_ECouponId = ECoupon_Id
WHERE ECoupon_Id             = @ECouponId
  AND ECoupon_ValidFlag      = 1
  AND ECouponSlave_ValidFlag = 1
  AND ECouponSlave_IsTake    = 1
  AND ECoupon_IsPreProduce   = 0
GROUP BY
    ECoupon_Id,
    ECoupon_TotalQty,
    ECoupon_TakenQty,
    ECoupon_ReturnQty;
```

詢問：「🏐 請在 SSMS 執行以上 Query，確認 [差異張數_正值表示少扣] 欄位的值為何？」並提供以下選項：

- `> 0（正值）` → ✅ 確認為少扣，繼續執行！
- `= 0` → 😅 主子檔數量一致，無需修正，**停止並告知使用者**
- `< 0（負值）` → 🚫 此為多扣情境，本 skill 不適用，**停止並告知使用者**

---

### Step 3：📋 摘要確認

顯示執行計畫，詢問是否確認：

```
🏐 執行計畫確認
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎫 VSTS 單號：{TicketNo}
🔑 ECouponId：{ECouponId}
✅ 確認情境：主檔少扣（差異張數 > 0）
📁 目標資料夾：VSTS\VSTS000000-不預產優惠券主子檔數量不一致\
📄 SQL 檔案：step01-Update_ECoupon_{YYYYMMDD}.sql
   UpdatedUser：VSTS{TicketNo}_{MMDD}
📖 SOP：https://wiki.91app.com/pages/viewpage.action?pageId=346357780
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
確認執行？(Y/N)
```

---

### Step 4：⚡ 產生 SQL 檔案

確認後，在以下固定資料夾建立 SQL 檔案（此為共用範本資料夾，無需每次建立新資料夾）：

```
{REPO_ROOT}\VSTS\VSTS000000-不預產優惠券主子檔數量不一致\
```

檔名格式：`step01-Update_ECoupon_{YYYYMMDD}.sql`

SQL 內容請讀取 `references/sql-template.md` 的範本，填入以下參數：
- `@ECouponId` = 使用者輸入的 ECouponId
- `@UpdatedUser` = `VSTS{TicketNo}_{MMDD}`（例：`VSTS000000_0525`）
- Backup 表名後綴 = 同 `@UpdatedUser`（例：`tmpWebStoreDB_ECoupon_VSTS000000_0525`）
- 檔案頂部執行日期 = 今日日期

---

### Step 5：🎉 回傳結果

```
🏐 完成！優惠券主子檔修正 SQL 已就位！

📁 資料夾：VSTS\VSTS000000-不預產優惠券主子檔數量不一致\
📄 已建立：step01-Update_ECoupon_{YYYYMMDD}.sql

📌 執行提醒：
  1. 確認參數區的 @ECouponId 與 @UpdatedUser 正確
  2. 逐段執行：BACKUP → 確認備份成功 → UPDATE
     （若 @Diff ≤ 0 會自動 THROW 錯誤停止，無需手動判斷）
  3. 執行 VERIFY，確認 [差異張數_應為0] 欄位為 0

📖 SOP 參考：https://wiki.91app.com/pages/viewpage.action?pageId=346357780
```

---

## 注意事項

- 本 skill **僅適用主檔少扣**情境，多扣情境請另行處理
- Backup 表名後綴與 `@UpdatedUser` 後綴**必須一致**，方便追蹤
- SQL 內已有 `THROW` 防呆：若 `@Diff ≤ 0` 會自動中斷，不會執行錯誤更新
- 此資料夾（`VSTS000000-不預產優惠券主子檔數量不一致`）為共用資料夾，**不需為每次修正建立新資料夾**
