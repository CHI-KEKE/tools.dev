-- step 02. 把需要等級計算的會員塞進 Pool

USE CRMDB;

DECLARE
@User               VARCHAR(50) = '{{VSTS_ID}}',
@Status             VARCHAR(20) = 'Redo',
@StartDate          DATETIME    = '{{START_DATE}}',
@EndDate            DATETIME    = {{END_DATE}},
@CalculateDate      DATE        = {{CALCULATE_DATE}},
@Now                DATETIME    = GETDATE(),
@ShopId             BIGINT      = {{SHOP_ID}};

--============================================================================

DROP TABLE IF EXISTS #tmpCrmSalesOrderSlaveIds
CREATE TABLE #tmpCrmSalesOrderSlaveIds
(
    tmpCrmSalesOrderSlave_Id BIGINT PRIMARY KEY
);

-- 找出起訖日期內的 CrmSalesOrderSlaveId

INSERT INTO #tmpCrmSalesOrderSlaveIds
    SELECT
        CrmSalesOrderSlave_Id
    FROM dbo.CrmSalesOrderSlave WITH (NOLOCK)
    WHERE CrmSalesOrderSlave_ValidFlag = 1
    AND CrmSalesOrderSlave_ShopId = @ShopId
    AND CrmSalesOrderSlave_CalculateMemberTierDateTime >= @StartDate
    AND CrmSalesOrderSlave_CalculateMemberTierDateTime < @EndDate;

DROP TABLE IF EXISTS #tmpCrmMemberTargets
CREATE TABLE #tmpCrmMemberTargets
(
    tmpShopId           BIGINT,
    tmpCrmMemberId      BIGINT,
    tmpOccurrenceType   VARCHAR(100)
);

-- 將 1、2、3、4、5 的結果 INSERT 到 tmpCrmMemberTargets
INSERT INTO #tmpCrmMemberTargets

    -- 1 - 有消費/退貨的會員
    SELECT DISTINCT
        CrmSalesOrderSlave_ShopId
        ,CrmSalesOrderSlave_CrmMemberId
        ,'FromOrders'
    FROM #tmpCrmSalesOrderSlaveIds
    INNER JOIN dbo.CrmSalesOrderSlave WITH (NOLOCK)
        ON CrmSalesOrderSlave_Id = tmpCrmSalesOrderSlave_Id
    WHERE CrmSalesOrderSlave_ValidFlag = 1
    AND CrmSalesOrderSlave_ShopId = @ShopId

    UNION ALL

    -- 2 - 等級內累積金額有效日期結束日小於結束日期
    SELECT DISTINCT
        CrmMemberTierSummary_ShopId
        ,CrmMemberTierSummary_CrmMemberId
        ,'FromTradeSumEndDateTime'
    FROM dbo.CrmMemberTierSummary WITH (NOLOCK)
    WHERE CrmMemberTierSummary_ValidFlag = 1
    AND CrmMemberTierSummary_ShopId = @ShopId
    AND CrmMemberTierSummary_CrmShopMemberCardTradeSumsExpireDay > 0 -- 排除未設定
    AND CrmMemberTierSummary_TradesSumEndDateTime < @EndDate

    UNION ALL

    -- 3 - 等級內續等累積金額有效日期結束日小於結束日期
    SELECT DISTINCT
        CrmMemberTierSummary_ShopId
        ,CrmMemberTierSummary_CrmMemberId
        ,'FromTradeSumEndDateTime'
    FROM dbo.CrmMemberTierSummary WITH (NOLOCK)
    WHERE CrmMemberTierSummary_ValidFlag = 1
    AND CrmMemberTierSummary_ShopId = @ShopId
    AND CrmMemberTierSummary_RenewTradesSumEndDateTime > '1900-01-01' -- 排除未設定
    AND CrmMemberTierSummary_RenewTradesSumEndDateTime < @EndDate

    UNION ALL

    -- 4 - 等級效期過期
    SELECT DISTINCT
        CrmMemberTier_ShopId
        ,CrmMemberTier_CrmMemberId
        ,'FromTierEndDateTime'
    FROM dbo.CrmMemberTier WITH (NOLOCK)
    WHERE CrmMemberTier_ValidFlag = 1
    AND CrmMemberTier_ShopId = @ShopId
    AND CrmMemberTier_CrmShopMemberCardEndDateTime < @EndDate

    UNION ALL

    -- 5 - 手動異動會員
    SELECT DISTINCT
        CrmManualChangeMemberTier_ShopId
        ,CrmManualChangeMemberTier_CrmMemberId
        ,'FromManual'
    FROM dbo.CrmManualChangeMemberTier WITH (NOLOCK)
    WHERE CrmManualChangeMemberTier_ValidFlag = 1
    AND CrmManualChangeMemberTier_ShopId = @ShopId
    AND CrmManualChangeMemberTier_CalculateMemberTierDateTime >= @StartDate
    AND CrmManualChangeMemberTier_CalculateMemberTierDateTime < @EndDate;

--============================================================================

DROP TABLE IF EXISTS #tmpCalculateTierCrmMemberTargets
CREATE TABLE #tmpCalculateTierCrmMemberTargets
(
    tmpShopId           BIGINT,
    tmpCrmMemberId      BIGINT,
    tmpOccurrenceType   VARCHAR(100)
);

-- 去重複的 ShopId, CrmMemberId, OccurrenceType
INSERT INTO #tmpCalculateTierCrmMemberTargets
    SELECT DISTINCT
        tmpShopId
        ,tmpCrmMemberId
        ,STUFF((SELECT DISTINCT
                ',' + t2.[tmpOccurrenceType]
            FROM #tmpCrmMemberTargets t2
            WHERE t2.tmpShopId = t.tmpShopId
            AND t2.tmpCrmMemberId = t.tmpCrmMemberId
            FOR XML PATH (''))
        , 1, 1, '') AS tmpOccurrenceType
    FROM #tmpCrmMemberTargets t;

-- 寫入每日會員等級計算池
INSERT INTO dbo.CrmShopMemberTierPool
(
    CrmShopMemberTierPool_ShopId,
    CrmShopMemberTierPool_CrmMemberId,
    CrmShopMemberTierPool_CalculateDateStart,
    CrmShopMemberTierPool_CalculateDateEnd,
    CrmShopMemberTierPool_OccurrenceTypes,
    CrmShopMemberTierPool_Sort,
    CrmShopMemberTierPool_Status,
    CrmShopMemberTierPool_StatusUpdatedDateTime,
    CrmShopMemberTierPool_CreatedDateTime,
    CrmShopMemberTierPool_CreatedUser,
    CrmShopMemberTierPool_UpdatedTimes,
    CrmShopMemberTierPool_UpdatedDateTime,
    CrmShopMemberTierPool_UpdatedUser,
    CrmShopMemberTierPool_ValidFlag
)
    SELECT DISTINCT
        t.tmpShopId
        ,t.tmpCrmMemberId
        ,DATEADD(DAY, 1, @StartDate)
        ,@CalculateDate
        ,t.tmpOccurrenceType
        ,CrmShopMemberTierRuleSetting_Sort
        ,@Status
        ,@Now
        ,@Now
        ,@User
        ,0
        ,@Now
        ,@User
        ,1
    FROM #tmpCalculateTierCrmMemberTargets t
    INNER JOIN CrmShopMemberTierRuleSetting WITH (NOLOCK)
        ON t.tmpShopId = CrmShopMemberTierRuleSetting_ShopId
    WHERE CrmShopMemberTierRuleSetting_ValidFlag = 1;
