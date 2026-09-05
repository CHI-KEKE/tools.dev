use webstoredb;

-- =============================================
-- 全域預設（ShopId=0），預設關閉
-- =============================================
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
            0                -- ShopStaticSetting_ShopId
           ,'{GroupName}'    -- ShopStaticSetting_GroupName
           ,'{Key}'          -- ShopStaticSetting_Key
           ,'false'          -- ShopStaticSetting_Value
           ,N'{Description}' -- ShopStaticSetting_Description
           ,GETDATE()        -- ShopStaticSetting_CreatedDateTime
           ,'VSTS{VSTS票號}' -- ShopStaticSetting_CreatedUser
           ,0                -- ShopStaticSetting_UpdatedTimes
           ,GETDATE()        -- ShopStaticSetting_UpdatedDateTime
           ,'VSTS{VSTS票號}' -- ShopStaticSetting_UpdatedUser
           ,1                -- ShopStaticSetting_ValidFlag
           );

-- =============================================
-- Pilot 商店（每間商店複製此區塊，替換 {ShopId}）
-- =============================================
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
            {ShopId}         -- ShopStaticSetting_ShopId
           ,'{GroupName}'    -- ShopStaticSetting_GroupName
           ,'{Key}'          -- ShopStaticSetting_Key
           ,'true'           -- ShopStaticSetting_Value
           ,N'{Description}' -- ShopStaticSetting_Description
           ,GETDATE()        -- ShopStaticSetting_CreatedDateTime
           ,'VSTS{VSTS票號}' -- ShopStaticSetting_CreatedUser
           ,0                -- ShopStaticSetting_UpdatedTimes
           ,GETDATE()        -- ShopStaticSetting_UpdatedDateTime
           ,'VSTS{VSTS票號}' -- ShopStaticSetting_UpdatedUser
           ,1                -- ShopStaticSetting_ValidFlag
           );
