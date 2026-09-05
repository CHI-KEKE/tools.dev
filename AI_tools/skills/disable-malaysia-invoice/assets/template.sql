/*
 {SHOP_DESCRIPTION} 不使用MY電子發票
 新增 WebStoreDB ShopStaticSetting 資料
 Group: SalesOrderSystemInfo / SalesOrderCustomInfo
 Key: MalaysiaInvoice / SalesOrderMemo
*/
USE WebStoreDB

DECLARE @shopId BIGINT = {SHOP_ID}; -- {SHOP_DESCRIPTION}

-- SELECT (若有查詢到內容，則通知 PR owner)
SELECT *
FROM dbo.ShopStaticSetting WITH (NOLOCK)
WHERE ShopStaticSetting_ValidFlag = 1
    AND ShopStaticSetting_GroupName = 'SalesOrderSystemInfo'
    AND ShopStaticSetting_Key = 'MalaysiaInvoice'
    AND ShopStaticSetting_ShopId = @shopId;

-- INSERT
INSERT INTO dbo.ShopStaticSetting
    (
    ShopStaticSetting_ShopId,
    ShopStaticSetting_GroupName,
    ShopStaticSetting_Key,
    ShopStaticSetting_Value,
    ShopStaticSetting_ValidFlag,
    ShopStaticSetting_CreatedUser,
    ShopStaticSetting_CreatedDateTime,
    ShopStaticSetting_UpdatedDateTime,
    ShopStaticSetting_UpdatedUser,
    ShopStaticSetting_UpdatedTimes
    )
VALUES
    (
        @shopId,
        'SalesOrderSystemInfo',
        'MalaysiaInvoice',
        '{"PrimaryKey":"Custom/MalaysiaInvoice/{SHOP_ID}","Sort":1,"IsEnable":false}',
        1,
        '{VSTS_ID}',
        GETDATE(),
        GETDATE(),
        '{VSTS_ID}',
        0
);

-- VERIFY (Should return 1 row)
SELECT *
FROM dbo.ShopStaticSetting WITH (NOLOCK)
WHERE ShopStaticSetting_ValidFlag = 1
    AND ShopStaticSetting_GroupName = 'SalesOrderSystemInfo'
    AND ShopStaticSetting_Key = 'MalaysiaInvoice'
    AND ShopStaticSetting_ShopId = @shopId;
