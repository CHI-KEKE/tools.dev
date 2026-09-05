WITH InputOrders AS
(
    SELECT 
        [{ORDER_NUMBER_LIST}] AS tids, 
        DATE('{START_DATE}') AS StartDate,    
        DATE('{END_DATE}') AS EndDate
),
VerifiedOrders AS 
(
    SELECT 
        TID  
    FROM InputOrders, 
        UNNEST(TIDs) TID
),
OrderSource AS 
(
    SELECT    
        lst.ShopId,    
        lst.TradesGroupCode,    
        lst.TradesDateTime,    
        lst.TotalSalesAmount,    
        lst.ChannelType,    
        lst.ChannelDetail,    
        lst.PaymentMethodDef,    
        lst.PaymentTypeDef,    
        lst.TotalReturnedAmount < 0 AS HasReturned,    
        lst.TrackingInfo.TrafficSource.source AS UtmSource,    
        lst.TrackingInfo.TrafficSource.medium AS UtmMedium,    
        IFNULL(
            TRIM(lst.TrackingInfo.TrafficSource.tripId), 
            TRIM(lst.TrackingInfo.TrafficSource.aclId)
        ) AS CampaignCode  
    FROM `target-audience-001.hk_dp_order_data.LineItemOrderSummary_Online` lst  
    WHERE    
        DATE(lst.TradesDateTime, 'Asia/Taipei') >= (SELECT StartDate FROM InputOrders)    
        AND DATE(lst.TradesDateTime, 'Asia/Taipei') <= (SELECT EndDate FROM InputOrders)
)
SELECT  
    os.TradesGroupCode AS order_number,  
    os.ShopId AS shop_id,  
    DATETIME(os.TradesDateTime, 'Asia/Taipei') AS TradesDateTime,  
    os.ChannelType,  
    os.ChannelDetail,  
    os.TotalSalesAmount,  
    os.PaymentMethodDef,  
    os.PaymentTypeDef,  
    os.HasReturned,  
    os.UtmSource,  
    os.UtmMedium,  
    os.CampaignCode,  
    CASE    
        WHEN os.TradesGroupCode IS NULL THEN 'rejected'    
        WHEN os.ChannelDetail = 'APP' THEN 'rejected'
        WHEN os.HasReturned THEN 'rejected'    
        WHEN os.CampaignCode IS NULL OR os.CampaignCode LIKE '91app%' THEN 'rejected'    
        WHEN os.UtmSource = 'affiliate' AND os.UtmMedium = 'shopback' THEN 'approved'    
        WHEN os.UtmSource LIKE '%iQ-site%' OR os.UtmMedium LIKE '%IQFB%' THEN 'approved'    
        ELSE 'rejected'  
    END AS status,  
    CASE    
        WHEN os.TradesGroupCode IS NULL THEN '此為無效的訂單編號 (請提供 TG 字母開頭的有效訂單編號)'    
        WHEN os.HasReturned THEN '此訂單有退貨的情況故不在認列範圍之內'    
        WHEN os.CampaignCode IS NULL OR os.CampaignCode LIKE '91app%' THEN 'CampaignCode為空或是為91app開頭'    
        ELSE ''  
    END AS rejection_reason,  
    CASE    
        WHEN os.TradesGroupCode IS NULL THEN '此為無效的訂單編號 (請提供 TG 字母開頭的有效訂單編號)'    
        WHEN os.HasReturned THEN '此訂單有退貨的情況故不在認列範圍之內'    
        WHEN os.CampaignCode IS NULL OR os.CampaignCode LIKE '91app%' THEN 'CampaignCode為空或是為 91app 開頭'    
        WHEN os.UtmSource = 'affiliate' AND os.UtmMedium = 'shopback' THEN '此訂單已透過系統通知 ShopBack'    
        WHEN os.UtmSource LIKE '%iQ-site%' OR os.UtmMedium LIKE '%IQFB%' THEN 'iQueen 內站埋設 utm 參數導致無法認列此訂單'    
        ELSE '此訂單已被其他流量來源截斷或未透過 ShopBack 導流'  
    END AS real_reason
FROM OrderSource os
WHERE  
    os.TradesGroupCode IN (SELECT TID FROM VerifiedOrders)

UNION ALL

-- 處理找不到的訂單（無效訂單編號）
SELECT  
    vo.TID AS order_number,  
    NULL AS shop_id,  
    NULL AS TradesDateTime,  
    NULL AS ChannelType,  
    NULL AS ChannelDetail,  
    NULL AS TotalSalesAmount,  
    NULL AS PaymentMethodDef,  
    NULL AS PaymentTypeDef,  
    NULL AS HasReturned,  
    NULL AS UtmSource,  
    NULL AS UtmMedium,  
    NULL AS CampaignCode,  
    'rejected' AS status,  
    '此為無效的訂單編號 (請提供 TG 字母開頭的有效訂單編號)' AS rejection_reason,  
    '此為無效的訂單編號 (請提供 TG 字母開頭的有效訂單編號)' AS real_reason
FROM VerifiedOrders vo
WHERE NOT EXISTS (
    SELECT 1 
    FROM OrderSource os 
    WHERE os.TradesGroupCode = vo.TID
)
