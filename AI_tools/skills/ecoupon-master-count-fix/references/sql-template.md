# SQL 範本：不預產優惠券主子檔數量不一致修正（主檔少扣）

使用此範本產生 SQL 檔案時，請替換以下佔位符：

| 佔位符 | 說明 | 範例 |
|---|---|---|
| `{ECouponId}` | 使用者輸入的 ECouponId | `34161` |
| `{UpdatedUser}` | `VSTS{TicketNo}_{MMDD}` | `VSTS000000_0525` |
| `{BackupSuffix}` | 同 UpdatedUser | `VSTS000000_0525` |
| `{YYYY-MM-DD}` | 今日執行日期 | `2026-05-25` |

---

## SQL 範本

```sql
USE WebStoreDB
GO

-- ============================================================
-- 目的：修正不預產優惠券主子檔數量不一致（主檔少扣）
-- 前置條件：已確認 Query 結果 [差異張數_正值表示少扣] > 0
--
-- 修正原理：
--   正常不變式: ABS(ECoupon_TakenQty + ECoupon_ReturnQty) = SlaveCount
--   少扣時:     差異量 @Diff = TakenQty + ReturnQty + SlaveCount（結果為正）
--   修正方式:   ECoupon_TakenQty -= @Diff（讓負值補齊子檔實際數量）
--
-- 執行日期：{YYYY-MM-DD}
-- ============================================================

-- ============================================================
-- 【參數設定區】執行前請確認以下兩個參數
-- ============================================================

-- 要修正的 ECoupon Id（請依 Slack 告警填入）
DECLARE @ECouponId   BIGINT      = {ECouponId};

-- UpdatedUser 標記，格式：VSTS{編號}_{MMDD}
DECLARE @UpdatedUser VARCHAR(50) = 'VSTS{UpdatedUser}';

-- ============================================================
-- BACKUP - 備份主檔至 MATempDB
-- 注意：Backup 表名後綴請配合 @UpdatedUser 保持一致
-- ============================================================
SELECT *
INTO MATempDB.dbo.tmpWebStoreDB_ECoupon_{BackupSuffix}
FROM dbo.ECoupon WITH (NOLOCK)
WHERE ECoupon_Id        = @ECouponId
  AND ECoupon_ValidFlag = 1;

-- ============================================================
-- UPDATE - 修正主檔 TakenQty（少扣補正）
-- ============================================================
DECLARE @ECouponTakenQty  BIGINT = 0,
        @ECouponReturnQty BIGINT = 0,
        @SlaveTakenQty    BIGINT = 0,
        @Diff             BIGINT = 0;

-- 讀取主檔已領張數（負值）與已退張數（正值）
SELECT @ECouponTakenQty  = ECoupon_TakenQty,
       @ECouponReturnQty = ECoupon_ReturnQty
FROM dbo.ECoupon WITH (NOLOCK)
WHERE ECoupon_Id        = @ECouponId
  AND ECoupon_ValidFlag = 1;

-- 讀取子檔實際已領張數
SELECT @SlaveTakenQty = COUNT(1)
FROM dbo.ECouponSlave WITH (NOLOCK)
WHERE ECouponSlave_ECouponId = @ECouponId
  AND ECouponSlave_ValidFlag = 1
  AND ECouponSlave_IsTake    = 1;

-- 計算差異量，正常不變式: TakenQty + ReturnQty + SlaveCount = 0
--   結果 > 0 → 主檔少扣（本 SQL 適用），@Diff 即為需補扣的張數
--   結果 = 0 → 主子檔數量一致，無需修正
--   結果 < 0 → 主檔多扣（本 SQL 不適用，請停止執行）
SET @Diff = @ECouponTakenQty + @ECouponReturnQty + @SlaveTakenQty;

IF @Diff = 0
    THROW 50001, N'主子檔數量一致（@Diff = 0），無需修正，已中止執行', 1;

IF @Diff < 0
    THROW 50002, N'此為多扣情境（@Diff < 0），本 SQL 不適用，已中止執行', 1;

-- 少扣補正：將 TakenQty 再往負數扣 @Diff 張，對齊子檔實際數量
UPDATE dbo.ECoupon
SET ECoupon_TakenQty        = ECoupon_TakenQty - @Diff,
    ECoupon_UpdatedDateTime = GETDATE(),
    ECoupon_UpdatedTimes    = ECoupon_UpdatedTimes % 255 + 1,
    ECoupon_UpdatedUser     = @UpdatedUser
WHERE ECoupon_Id        = @ECouponId
  AND ECoupon_ValidFlag = 1;

-- ============================================================
-- VERIFY - 驗證修正結果
-- [差異張數_應為0] 欄位應為 0
-- ============================================================
SELECT
    ECoupon_Id                                                          AS [ECoupon Id],
    ECoupon_TakenQty                                                    AS [主檔已領(負值)_修正後],
    ECoupon_ReturnQty                                                   AS [主檔已退],
    ABS(ECoupon_TakenQty + ECoupon_ReturnQty)                           AS [主檔有效已領數_修正後],
    COUNT(ECouponSlave_Id)                                              AS [子檔實際已領數],
    COUNT(ECouponSlave_Id) - ABS(ECoupon_TakenQty + ECoupon_ReturnQty) AS [差異張數_應為0]
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
    ECoupon_TakenQty,
    ECoupon_ReturnQty;
```
