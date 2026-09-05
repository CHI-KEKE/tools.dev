use webstoredb;

-- 確認資料不存在再 INSERT
SELECT * FROM ShopStaticSetting WITH (NOLOCK)
WHERE ShopStaticSetting_ValidFlag = 1
  AND ShopStaticSetting_GroupName = '{GroupName}'
  AND ShopStaticSetting_Key       = '{Key}'
  AND ShopStaticSetting_ShopId    = 0;

INSERT INTO [dbo].[ShopStaticSetting]
           ([ShopStaticSetting_ShopId]
           ,[ShopStaticSetting_GroupName]
           ,[ShopStaticSetting_Key]
           ,[ShopStaticSetting_Value]
           ,[ShopStaticSetting_Description]
           ,[ShopStaticSetting_CreatedDateTime]
           ,[ShopStaticSetting_CreatedUser]
           ,[ShopStaticSetting_UpdatedTimes]
           ,[ShopStaticSetting_UpdatedDateTime]
           ,[ShopStaticSetting_UpdatedUser]
           ,[ShopStaticSetting_ValidFlag])
     VALUES
           (
            0                              -- ShopStaticSetting_ShopId
           ,'{GroupName}'                  -- ShopStaticSetting_GroupName
           ,'{Key}'                        -- ShopStaticSetting_Key
           ,'{bool}|{shopIds}|{rangeIds}'  -- ShopStaticSetting_Value (例：true|12765|none 或 false|none|none)
           ,N'{Description}'               -- ShopStaticSetting_Description
           ,GETDATE()                      -- ShopStaticSetting_CreatedDateTime
           ,'VSTS{VSTS票號}'               -- ShopStaticSetting_CreatedUser
           ,0                              -- ShopStaticSetting_UpdatedTimes
           ,GETDATE()                      -- ShopStaticSetting_UpdatedDateTime
           ,'VSTS{VSTS票號}'               -- ShopStaticSetting_UpdatedUser
           ,1                              -- ShopStaticSetting_ValidFlag
           );
