-- step 01. 將 DailyVerify 資料全壓成可計算

USE CRMDB;

DECLARE
@User               VARCHAR(50) = '{{VSTS_ID}}',
@CalculateDate      DATE        = {{CALCULATE_DATE}},
@Now                DATETIME    = GETDATE(),
@ShopId             BIGINT      = {{SHOP_ID}};

UPDATE dbo.CrmShopMemberTierDailyVerify
SET CrmShopMemberTierDailyVerify_CalculateEnabled = 1
    , CrmShopMemberTierDailyVerify_ErrorMessage = N''
    , CrmShopMemberTierDailyVerify_Status = 'New'
    , CrmShopMemberTierDailyVerify_UpdatedDateTime = @Now
    , CrmShopMemberTierDailyVerify_UpdatedTimes = CrmShopMemberTierDailyVerify_UpdatedTimes % 255 + 1
    , CrmShopMemberTierDailyVerify_UpdatedUser = @User
WHERE CrmShopMemberTierDailyVerify_ValidFlag = 1
AND CrmShopMemberTierDailyVerify_CalculateDate = @CalculateDate
AND CrmShopMemberTierDailyVerify_ShopId = @ShopId
