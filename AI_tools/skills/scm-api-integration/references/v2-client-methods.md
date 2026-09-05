# NineYi.Scm.Api.Client.V2 — 各專責 Client

> 套件：`NineYi.Scm.Api.ClientV2`（最新版：`1.2511.325.1047`）
> Namespace：`NineYi.Scm.Api.Client.V2`
> 使用方式：`using (IXxxClient client = new XxxClient(token, key, saltKey, apiUrl)) { ... }`

V2 採用多個專責 Client，每個 Client 對應一個業務領域。

---

## SalePageClient / ISalePageClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Get(IdEntity entity)` | 取得商品頁 |
| `ApiResultEntity GetSkuList(SalePageSkuListRequestEntity entity)` | 取得 SKU 清單 |
| `ApiResultEntity CreateMain(SalePageCreateRequestEntity entity)` | 建立商品頁主資料 |
| `ApiResultEntity UpdateSalePageLimit(UpdateSalePageLimitEntity entity)` | 更新商品頁購買限制 |
| `ApiResultEntity UpdateSalePageStatus(SalePageStatusUpdateRequestEntity entity)` | 更新商品頁狀態 |
| `ApiResultEntity UpdateSalePageCategory(SalePageUpdateCategoryEntity entity)` | 更新商品頁分類 |
| `ApiResultEntity UpdateSalePageActivity(SalePageActivityUpdateEntity entity)` | 更新商品頁活動 |
| `ApiResultEntity UpdateSalePagePayShippingType(SalePageUpdatePayShippingEntity entity)` | 更新付款運送類型 |
| `ApiResultEntity UpdateSellingQty(SalePageSellingQtyRequestEntity entity)` | 更新銷售數量 |
| `ApiResultEntity ExposureSalePage(ExposureSalePageRequestEntity entity)` | 曝光商品頁 |
| `ApiResultEntity UpdateSkuDetail(SalePageSkuUpdateEntity entity)` | 更新 SKU 詳細資料 |
| `ApiResultEntity UpdateSKUImage(ImageInfoEntity entity, string imagePath)` | 更新 SKU 圖片 |
| `ApiResultEntity CreateSaleProductSku(SaleProductSkuCreateRequestEntity entity)` | 建立銷售商品 SKU |
| `ApiResultEntity UpdateSaleProductSku(SaleProductSkuUpdateRequestEntity entity)` | 更新銷售商品 SKU |
| `ApiResultEntity UpdateSaleProductSkuName(SaleProductSkuNameUpdateRequestEntity entity)` | 更新銷售商品 SKU 名稱 |
| `ApiResultEntity DeleteSaleProductSkuImage(IdRequestEntity entity)` | 刪除銷售商品 SKU 圖片 |
| `ApiResultEntity GetSalePageStockList(SalePageStockRequestEntity entity)` | 取得商品頁庫存清單 |
| `ApiResultEntity GetSalePageVideo(IdRequestEntity entity)` | 取得商品頁影片 |
| `ApiResultEntity CreateSalePageVideo(SalePageVideoUpdateRequestEntity entity)` | 建立商品頁影片 |
| `ApiResultEntity UpdateSalePageVideo(SalePageVideoUpdateRequestEntity entity)` | 更新商品頁影片 |
| `ApiResultEntity DeleteSalePageVideo(SalePageVideoDeleteRequestEntity entity)` | 刪除商品頁影片 |
| `ApiResultEntity GetSalePageHiddenUrl(IdRequestEntity entity)` | 取得隱藏商品頁 URL |
| `ApiResultEntity GetHiddenDataList(ListRequestEntity salePageIdList)` | 取得隱藏資料清單 |
| `ApiResultEntity GetSalePagePointsPay(SalePageGetPointsPayRequestEntity entity)` | 取得商品頁點數付款設定 |
| `ApiResultEntity UpdateSalePagePointsPay(SalePageUpdatePointsPayRequestEntity entity)` | 更新商品頁點數付款設定 |

---

## SalePageExtensionInfoClient / ISalePageExtensionInfoClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity AddSpecChartId(AddSpecChartIdRequestEntity entity)` | 新增規格表 ID |
| `ApiResultEntity UpdateSpecChartId(UpdateSpecChartIdRequestEntity entity)` | 更新規格表 ID |
| `ApiResultEntity RemoveSpecChartId(SpecChartIdRequestEntity entity)` | 移除規格表 ID |
| `ApiResultEntity GetSpecChartId(SpecChartIdRequestEntity entity)` | 取得規格表 ID |

---

## SalePageGroup.SalePageGroupClient / ISalePageGroupClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity CreateSalePageGroup(SalePageGroupMainEntity entity)` | 建立商品頁群組 |
| `ApiResultEntity GetSalePageGroupDetail(GetSalePageGroupDetailRequestEntity entity)` | 取得商品頁群組詳情 |
| `ApiResultEntity UpdateSalePageGroup(UpdateSalePageGroupRequestEntity entity)` | 更新商品頁群組 |
| `ApiResultEntity DeleteSalePageGroup(GetSalePageGroupDetailRequestEntity entity)` | 刪除商品頁群組 |
| `ApiResultEntity QuerySalePageGroup(QuerySalePageGroupSearchEntity entity)` | 查詢商品頁群組 |
| `ApiResultEntity ExportSalePageGroup(QuerySalePageGroupSearchEntity entity)` | 匯出商品頁群組 |

---

## SalePageSpecCharts.SalePageSpecChartClient / ISalePageSpecChartClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity AddSalePage(AddSalePageRequestEntity entity)` | 新增商品頁至規格表 |
| `ApiResultEntity UpdateSalePage(UpdateSalePageRequestEntity entity)` | 更新規格表商品頁 |
| `ApiResultEntity RemoveSalePage(RemoveSalePageRequestEntity entity)` | 從規格表移除商品頁 |
| `ApiResultEntity QuerySpecBySalePage(QuerySpecBySalePageRequestEntity entity)` | 依商品頁查詢規格 |
| `ApiResultEntity Create(CreateSpecChartRequestEntity entity)` | 建立規格表 |
| `ApiResultEntity Update(UpdateSpecChartRequestEntity entity)` | 更新規格表 |
| `ApiResultEntity Delete(SalePageSpecChartDataQueryEntity entity)` | 刪除規格表 |
| `ApiResultEntity Get(SalePageSpecChartDataQueryEntity entity)` | 取得規格表 |
| `ApiResultEntity GetList(ListCriteriaEntity entity)` | 取得規格表清單 |

---

## SaleProductClient / ISaleProductClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UpdateOnceQty(StockUpdateRequestEntity entity)` | 更新單次購買數量 |
| `ApiResultEntity UpdateSafetyStockQty(StockUpdateRequestEntity entity)` | 更新安全庫存數量 |
| `ApiResultEntity UpdateSkuIsShow(SkuIsShowUpdateRequestEntity entity)` | 更新 SKU 顯示狀態 |
| `ApiResultEntity GetSaleProductGiftList(SaleProductGiftRequestEntity entity)` | 取得銷售商品贈品清單 |
| `ApiResultEntity UpdateSaleProductGift(GiftUpdateRequestEntity entity)` | 更新銷售商品贈品 |
| `ApiResultEntity CreateSaleProductGift(GiftUpdateRequestEntity entity)` | 建立銷售商品贈品 |
| `ApiResultEntity GetSaleProductAddInSalePageList(SaleProductAddInSalePageRequestEntity entity)` | 取得加入商品頁的銷售商品清單 |
| `ApiResultEntity EditSaleProductAddInSalePage(SaleProductInSalePageEditRequestEntity entity)` | 編輯銷售商品加入商品頁 |
| `ApiResultEntity GetSalePageAddInSaleProductList(SalePageAddInSaleProductRequestEntity entity)` | 取得加入銷售商品的商品頁清單 |
| `ApiResultEntity EditSalePageInSaleProduct(EditSalePageInSaleProductRequestEntity entity)` | 編輯商品頁加入銷售商品 |
| `ApiResultEntity GetOuterIdInfoList(ListCriteriaEntity entity)` | 取得外部代碼資訊清單 |
| `ApiResultEntity GetOuterIdInfo(SaleProductRebalanceBaseEntity entity)` | 取得外部代碼資訊 |
| `ApiResultEntity SetOuterIdRebalanceStatus(SaleProductRebalancStatusEntity entity)` | 設定外部代碼重新平衡狀態 |
| `ApiResultEntity SetOuterIdRebalanceDateTime(SaleProductRebalanceDateTimeEntity entity)` | 設定外部代碼重新平衡時間 |
| `ApiResultEntity SetOuterIdRebalanceStatusAndAdjustmentQty(SaleProductRebalanceStatusAndAdjustmentQtyEntity entity)` | 設定重新平衡狀態與調整數量 |
| `ApiResultEntity GetOuterIdRebalanceStatus(SaleProductRebalanceBaseEntity entity)` | 取得外部代碼重新平衡狀態 |
| `ApiResultEntity SetOuterIdAdjustmentQty(SaleProductRebalancRequestEntity entity)` | 設定外部代碼調整數量 |
| `ApiResultEntity GetOuterIdRebalanceHistoryList(ListCriteriaEntity entity)` | 取得重新平衡歷程清單 |
| `ApiResultEntity GetOuterIdRebalanceHistoryDetailList(SaleProductRebalanceHistoryDetailSearchEntity entity)` | 取得重新平衡歷程詳細清單 |

---

## SalesOrderClient / ISalesOrderClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UpdateNote(UpdateNoteRequestEntity entity)` | 更新備註 |
| `ApiResultEntity CancelOrder(CancelOrderRequestEntity entity)` | 取消訂單（子單） |
| `ApiResultEntity ShipConfirm(SalesOrderSlaveConfirmEntity entity)` | 確認出貨 |
| `ApiResultEntity GetOrderList(GetOrderListRequestEntity entity)` | 取得訂單清單 |
| `ApiResultEntity SalesOrderGet(SalesOrderGetRequestEntity entity)` | 取得訂單 |
| `ApiResultEntity Cancel(CancelRequestEntity entity)` | 取消訂單（整單） |
| `ApiResultEntity GetPartialPickupList(SalesOrderPartialPickupSearchEntity searchEntity)` | 取得部分取貨清單 |
| `ApiResultEntity CloseOrderReturn(CloseOrderReturnRequestEntity entity)` | 關閉退換貨 |
| `ApiResultEntity GetDiscountInfo(GetDiscountInfoRequestEntity entity)` | 取得折扣資訊 |

---

## PromotionClient / IPromotionClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetPromotionDetail(GetPromotionDetailRequestEntity entity)` | 取得促銷活動詳情 |
| `ApiResultEntity GetPromotions(PromotionGetPromotionsRequestEntity entity)` | 取得促銷活動清單 |
| `ApiResultEntity GetPromotions(PromotionGetPromotionsRequestNewEntity entity)` | 取得促銷活動清單（新版） |
| `ApiResultEntity GetPromotionRegisters(GetPromotionRegistersRequestEntity entity)` | 取得促銷活動登錄 |
| `ApiResultEntity CreatePromotion(PromotionCreateRequestEntity entity)` | 建立促銷活動 |
| `ApiResultEntity UpdatePromotion(PromotionUpdateRequestEntity entity)` | 更新促銷活動 |
| `ApiResultEntity DeletePromotion(BasicPromotionEntity entity)` | 刪除促銷活動 |
| `ApiResultEntity GetPromotionSalePages(GetPromotionSalePagesRequestEntity entity)` | 取得促銷活動商品頁 |
| `ApiResultEntity ModifyPromotionSalePages(ModifyPromotionSalePagesRequestEntity entity)` | 修改促銷活動商品頁 |
| `ApiResultEntity GetPromotionProductSkuOuterIds(GetPromotionProductSkuOuterIdsRequestEntity entity)` | 取得促銷活動商品 SKU 外部代碼 |
| `ApiResultEntity ModifyPromotionProductSkuOuterIds(ModifyPromotionProductSkuOuterIdsRequestEntity entity)` | 修改促銷活動商品 SKU 外部代碼 |
| `ApiResultEntity UpdatePromotionSpecialPrice(UpdatePromotionSpecialPriceRequestEntity entity)` | 更新促銷特價 |
| `ApiResultEntity ValidatePromotionSpecialPrice(UpdatePromotionSpecialPriceRequestEntity entity)` | 驗證促銷特價 |
| `ApiResultEntity GetPromotionGifts(PromotionGetPromotionGiftRequestEntity entity)` | 取得促銷贈品 |
| `ApiResultEntity UpdatePromotionGifts(PromotionUpdatePromotionGiftsRequestEntity entity)` | 更新促銷贈品 |
| `ApiResultEntity UpdatePromotionAddOnsSalePages(UpdatePromotionAddOnsSalePagesRequestEntity entity)` | 更新促銷加購商品頁 |
| `ApiResultEntity ValidatePromotionAddOnsSalePages(UpdatePromotionAddOnsSalePagesRequestEntity entity)` | 驗證促銷加購商品頁 |
| `ApiResultEntity UploadPromotionImage(ImageInfoExtendsEntity entity, string filename, byte[] data)` | 上傳促銷圖片 |

---

## ShopClient / IShopClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UploadShopFavicon(ImageInfoEntity entity, string imagePath)` | 上傳商店 Favicon |
| `ApiResultEntity UploadShopIcon(ImageInfoEntity entity, string imagePath)` | 上傳商店 Icon |
| `ApiResultEntity UploadShopLogo(ImageInfoEntity entity, string imagePath)` | 上傳商店 Logo |
| `ApiResultEntity UploadShopMobileLayoutLogo(ImageInfoEntity entity, string imagePath)` | 上傳商店行動版 Logo |
| `ApiResultEntity UploadShopDesktopLayoutLogo(ImageInfoEntity entity, string imagePath)` | 上傳商店桌面版 Logo |
| `ApiResultEntity InsertShopCategory(ShopCategoryEntity entity)` | 新增商店類別 |
| `ApiResultEntity InsertShopCategoryGetId(ShopCategoryEntity entity)` | 新增商店類別並取得 ID |
| `ApiResultEntity UpdateShopCategory(ShopCategoryEntity entity)` | 更新商店類別 |
| `ApiResultEntity MoveShopCategory(MoveShopCategoryEntity entity)` | 移動商店類別 |
| `ApiResultEntity UpdateShopCategoryDisplayStatus(UpdateShopCategoryStatusEntity entity)` | 更新商店類別顯示狀態 |
| `ApiResultEntity DeleteShopCategory(IdRequestEntity entity)` | 刪除商店類別 |
| `ApiResultEntity UpdateShopCategorySort(List entity)` | 更新商店類別排序 |
| `ApiResultEntity CreateShopCategory(ShopCategoryMLEntity entity)` | 建立商店類別（多語系） |
| `ApiResultEntity ModifyShopCategory(ShopCategoryMLEntity entity)` | 修改商店類別（多語系） |
| `ApiResultEntity DropShopCategory(IdRequestEntity entity)` | 刪除商店類別（多語系） |
| `ApiResultEntity GenerateShopCategoryAutoDescription(ShopCategoryAutoDescriptionRequestEntity entity)` | 自動生成商店類別描述 |

---

## ShopMemberClient / IShopMemberClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity LockLogin(ShopMemberMergeAccountRequestEntity entity)` | 鎖定登入 |
| `ApiResultEntity UnlockLogin(ShopMemberMergeAccountRequestEntity entity)` | 解鎖登入 |
| `ApiResultEntity Logout(ShopMemberMergeAccountRequestEntity entity)` | 登出 |
| `ApiResultEntity GetVipMemberId(ShopMemberSearchRequestEntity entity)` | 取得 VIP 會員 ID |
| `ApiResultEntity GetMemberVerifyCode(MemberVerifyCodeRequestEntity entity)` | 取得會員驗證碼 |

---

## ShopMemberMergeClient / IShopMemberMergeClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity QueryShopMembers(ShopMemberMergeQueryMembersEntity entity)` | 查詢商店會員 |
| `ApiResultEntity CreateMergeRequest(ShopMemberMergeCreateMergeRequestEntity entity)` | 建立合併請求 |
| `ApiResultEntity QueryMergeRequests(ShopMemberMergeQueryMergeRequestsEntity entity)` | 查詢合併請求 |
| `ApiResultEntity QueryMergeRequestDetail(ShopMemberMergeRequestIdEntity entity)` | 查詢合併請求詳情 |
| `ApiResultEntity QueryMergeRequestSteps(ShopMemberMergeRequestIdEntity entity)` | 查詢合併請求步驟 |
| `ApiResultEntity RecordMergeResult(ShopMemberMergeRequestIdEntity entity)` | 記錄合併結果 |

---

## 物流相關 Clients

### CashOnDeliveryClient / ICashOnDeliveryClient（貨到付款）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Shipping(ShippingRequestEntity entity)` | 出貨 |
| `ApiResultEntity CancelShipping(CancelShippingRequestEntity entity)` | 取消出貨 |
| `ApiResultEntity CancelOrder(CancelOrderRequestEntity entity)` | 取消訂單 |
| `ApiResultEntity ShipConfirm(ShipConfirmRequestEntity entity)` | 確認出貨 |
| `ApiResultEntity PrintTCatTranBill(PrintTCatTranBillRequestEntity entity)` | 列印 TCat 交運單 |
| `ApiResultEntity PrintECanTranBill(PrintECanTranBillRequestEntity entity)` | 列印 ECan 交運單 |

### DeliveryClient / IDeliveryClient（配送）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity AllocateCode(ShippingRequestEntity entity)` | 配碼 |
| `ApiResultEntity UpdateOuterCode(UpdateOuterCodeRequestEntity entity)` | 更新外部代碼 |
| `ApiResultEntity CancelShipping(CancelShippingRequestEntity entity)` | 取消出貨 |
| `ApiResultEntity ConfirmShipping(ConfirmShippingRequestEntity entity)` | 確認出貨 |
| `ApiResultEntity CancelOrder(CancelOrderRequestEntity entity)` | 取消訂單 |
| `ApiResultEntity NotifyShipment(OrderStatusCallbackRequestEntity entity)` | 通知出貨狀態 |
| `ApiResultEntity UpdateStatusToAllocatedCode(CancelShippingProcessingRequestEntity entity)` | 更新狀態為已配碼 |

### LocationPickupClient / ILocationPickupClient（門市取貨）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Shipping(ShippingRequestEntity entity)` | 出貨 |
| `ApiResultEntity ShipConfirm(ShipConfirmRequestEntity entity)` | 確認出貨 |
| `ApiResultEntity CancelShipping(CancelShippingRequestEntity entity)` | 取消出貨 |
| `ApiResultEntity CancelOrder(CancelLocationOrderRequestEntity entity)` | 取消訂單 |
| `ApiResultEntity ArrivedConfirm(ArrivedConfirmRequestEntity entity)` | 確認到店 |
| `ApiResultEntity PickupConfirm(PickupConfirmRequestEntity entity)` | 確認取貨 |
| `ApiResultEntity PrintLocationPickupLabel(PrintLocationPickupLabelRequestEntity entity)` | 列印取貨標籤 |

### StoreClient / IStoreClient（超商配送）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Shipping(ShippingOrderCreateEntity entity)` | 出貨 |
| `ApiResultEntity ShippingWithCode(ShippingOrderCreateForFamilyEntity entity)` | 帶代碼出貨（全家） |
| `ApiResultEntity GetFamilyStoreLabelData(FamilyStoreDataRequestEntity entity)` | 取得全家門市標籤資料 |
| `ApiResultEntity GetFamilyStoreOrderAddData(FamilyStoreDataRequestEntity entity)` | 取得全家門市訂單附加資料 |
| `ApiResultEntity GetFamilyStoreLabelDataWithDetail(FamilyStoreDataRequestEntity entity)` | 取得全家門市標籤詳細資料 |
| `ApiResultEntity GetHiLifeStoreLabelData(HiLifeStoreDataRequestEntity entity)` | 取得萊爾富門市標籤資料 |
| `ApiResultEntity GetHiLifeStoreLabelDataWithDetail(HiLifeStoreDataRequestEntity entity)` | 取得萊爾富門市標籤詳細資料 |
| `byte[] GetOKmartStoreLabelData(OKmartStoreLabelDataRequestEntity entity)` | 取得 OKmart 門市標籤資料（byte 陣列） |

### StoreToStoreClient / IStoreToStoreClient（超商對超商）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Shipping(StoreToStoreShippingRequestEntity entity)` | 出貨 |
| `ApiResultEntity CancelShipping(StoreToStoreShippingCancelRequestEntity entity)` | 取消出貨 |
| `ApiResultEntity CancelSalesOrder(CancelOrderByOuterCodeRequestEntity entity)` | 取消銷售訂單 |
| `byte[] GetOKmartStoreLabelData(OKmartStoreLabelDataRequestEntity entity)` | 取得 OKmart 門市標籤資料 |

### SevenElevenTCatClient / ISevenElevenTCatClient（7-11 黑貓）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity AllocateCode(SevenElevenTCatAllocateCodeRequestEntity entity)` | 配碼 |
| `ApiResultEntity CancelShipping(SevenElevenTCatStatusUpdateRequestEntity entity)` | 取消出貨 |
| `ApiResultEntity ConfirmShipping(SevenElevenTCatStatusUpdateRequestEntity entity)` | 確認出貨 |
| `ApiResultEntity CancelOrder(SevenElevenTCatStatusUpdateRequestEntity entity)` | 取消訂單 |
| `ApiResultEntity UpdateToAllocatedCode(SevenElevenTCatStatusUpdateRequestEntity entity)` | 更新為已配碼狀態 |
| `Stream GetLabelPdf(SevenElevenTCatGetLabelPdfRequestEntity entity)` | 取得標籤 PDF |

### HomeDeliveryClient / IHomeDeliveryClient（宅配）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity DeliveryShipment(ShipConfirmRequestEntity entity)` | 宅配出貨確認 |

### AgentOverseaClient / IAgentOverseaClient（海外代理）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity AllocateCode(AgentOverseaAllocateCodeRequestEntity entity)` | 配碼 |
| `ApiResultEntity CancelShipping(AgentOverseaCancelShippingRequestEntity entity)` | 取消出貨 |
| `ApiResultEntity ConfirmShipping(AgentOverseaConfirmShippingRequestEntity entity)` | 確認出貨 |
| `ApiResultEntity CancelOrder(AgentOverseaCancelOrderRequestEntity entity)` | 取消訂單 |
| `ApiResultEntity GetShippingLabelUrlList(ShippingLabelUrlListRequestEntity entity)` | 取得出貨標籤 URL 清單 |
| `ApiResultEntity GetShippingInvoiceUrlList(ShippingInvoiceUrlListRequestEntity entity)` | 取得出貨發票 URL 清單 |

### ShippingOrderClient / IShippingOrderClient（出貨單）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UpdateNote(UpdateNoteRequestEntity entity)` | 更新備註 |
| `ApiResultEntity StoreCancelAllocateCode(CancelAllocateCodeRequestEntity entity)` | 取消門市配碼 |
| `ApiResultEntity StoreShipConfirm(ShippingOrderSlaveStatusUpdateEntity entity)` | 門市出貨確認 |
| `ApiResultEntity StoreUpdateStatusToAllocatedCode(ShippingOrderSlaveStatusUpdateEntity entity)` | 更新門市狀態為已配碼 |
| `ApiResultEntity ShippingOrderGet(ShippingOrderGetRequestEntity entity)` | 取得出貨單 |

### LogisticsCenterAgents.LogisticsCenterAgentClient（物流中心代理）

| 方法簽名 | 說明 |
|---------|------|
| `byte[] GetBookingNote(long shopId, List fulfillmentCodeList, string forwarderDef)` | 取得訂艙單 |
| `ApiResultEntity Shipping(LogisticsCenterShippingRequestEntity entity)` | 出貨 |
| `ApiResultEntity ShipConfirm(LogisticsCenterShipConfirmRequestEntity entity)` | 確認出貨 |
| `ApiResultEntity ReturnShipping(LogisticsCenterReturnShippingRequestEntity entity)` | 退貨出貨 |
| `ApiResultEntity CancelReturnShipping(LogisticsCenterCancelReturnShippingRequestEntity entity)` | 取消退貨出貨 |
| `ApiResultEntity GetReturnShipping(LogisticsCenterGetReturnShippingRequestEntity entity)` | 取得退貨出貨 |

---

## 退換貨相關 Clients

### ReturnGoodsOrderClient / IReturnGoodsOrderClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Finish(ReturnGoodsOrderFinishRequestEntity entity)` | 完成退貨訂單 |
| `ApiResultEntity Cancel(ReturnGoodsOrderFinishRequestEntity entity)` | 取消退貨訂單 |
| `ApiResultEntity Deny(ReturnGoodsOrderFinishRequestEntity entity)` | 拒絕退貨訂單 |
| `ApiResultEntity AllowReturn(StringRequestEntity entity)` | 允許退貨 |
| `ApiResultEntity UpdateNote(UpdateNoteRequestEntity entity)` | 更新備註 |
| `ApiResultEntity GetList(ReturnGoodsListQueryEntity entity)` | 取得退貨訂單清單 |
| `ApiResultEntity Get(ReturnGoodsDetailQueryEntity entity)` | 取得退貨訂單詳情 |

### RefundRequestClient / IRefundRequestClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity ReturnSalesOrderFee(ReturnSalesOrderFeeRequestEntity entity)` | 退還銷售訂單費用 |
| `ApiResultEntity GlobalPayRefund(GlobalPayRefundRequestEntity entity)` | GlobalPay 退款 |

### ChangeGoodsOrderClient / IChangeGoodsOrderClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Finish(IdEntity entity)` | 完成換貨訂單 |
| `ApiResultEntity Cancel(IdEntity entity)` | 取消換貨訂單 |
| `ApiResultEntity Deny(IdEntity entity)` | 拒絕換貨訂單 |
| `ApiResultEntity UpdateNote(UpdateNoteRequestEntity entity)` | 更新備註 |
| `ApiResultEntity Confirm(IdEntity entity)` | 確認換貨訂單 |

---

## 優惠券 / 電子票券相關 Clients

### ECouponClient / IECouponClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetList(GetListRequestEntity entity)` | 取得電子票券清單 |
| `ApiResultEntity GetDispatchData(ECouponBaseRequestEntity entity)` | 取得發送資料 |
| `ApiResultEntity GetBinding(GetECouponBindingRequestEntity entity)` | 取得綁定 |
| `ApiResultEntity CreateBinding(ECouponBindingRequestEntity entity)` | 建立綁定 |
| `ApiResultEntity DeleteBinding(ECouponBindingRequestEntity entity)` | 刪除綁定 |
| `ApiResultEntity Dispatch(DispatchRequestEntity entity)` | 發送電子票券 |
| `ApiResultEntity Produce(ECouponProduceRequestEntity entity)` | 產生電子票券 |
| `ApiResultEntity ProduceAndDispatch(ECouponProduceAndDispatchRequestEntity entity)` | 產生並發送電子票券 |
| `ApiResultEntity GetMemberDispatchData(GetMemberDispatchDataRequestEntity entity)` | 取得會員發送資料 |

---

## 品牌 / 商品徽章相關 Clients

### Brands.BrandClient / IBrandClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity CreateBrand(BrandCreateRequestEntity entity)` | 建立品牌 |
| `ApiResultEntity UpdateBrand(BrandUpdateRequestEntity entity)` | 更新品牌 |
| `ApiResultEntity SearchBrand(SearchBrandRequestEntity entity)` | 搜尋品牌 |
| `ApiResultEntity DeleteBrand(BrandDeleteRequestEntity entity)` | 刪除品牌 |
| `ApiResultEntity OperateBrand(OperateBrandRequestEntity entity)` | 操作品牌（啟用/停用） |
| `ApiResultEntity GetBrand(GetBrandRequestEntity entity)` | 取得品牌 |
| `ApiResultEntity UploadBrandImage(ImageInfoEntity entity, string imagePath)` | 上傳品牌圖片 |
| `ApiResultEntity QueryBrandCuratorSort(QueryBrandCuratorSortRequestEntity entity)` | 查詢品牌策展排序 |

### ProductBadges.ProductBadgeClient / IProductBadgeClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity CreateProductBadge(ProductBadgeCreateRequestEntity entity)` | 建立商品徽章 |
| `ApiResultEntity SearchProductBadge(SearchProductBadgeRequestEntity entity)` | 搜尋商品徽章 |
| `ApiResultEntity UpdateProductBadge(ProductBadgeUpdateRequestEntity entity)` | 更新商品徽章 |
| `ApiResultEntity GetProductBadge(GetProductBadgeRequestEntity entity)` | 取得商品徽章 |
| `ApiResultEntity DeleteProductBadge(ProductBadgeDeleteRequestEntity entity)` | 刪除商品徽章 |
| `ApiResultEntity GetProductBadgeSalePage(ProductBadgeSalePageRequestEntity entity)` | 取得商品徽章商品頁 |
| `ApiResultEntity BatchGetProductBadgeSalePage(ProductBadgeSalePageRequestEntity entity)` | 批次取得商品徽章商品頁 |

---

## CRM / 會員相關 Clients

### CrmMemberClient / ICrmMemberClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UpdateMemberTierInfo(UpdateMemberTierInfoRequestEntity entity)` | 更新會員等級資訊 |
| `ApiResultEntity UpdateMemberTierInfoForInside(UpdateMemberTierInfoRequestEntity entity)` | 更新會員等級資訊（內部） |
| `ApiResultEntity UpdateCRMMemberRegisterColumns(RegisterColumnsRequestEntity entity)` | 更新 CRM 會員登錄欄位 |

### CrmMemberTierChangeHistoryClient / ICrmMemberTierChangeHistoryClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity HasCrmOccurrenceHistory(IdEntity entity)` | 是否有 CRM 發生歷程 |
| `ApiResultEntity GetList(CrmMemberTierChangeRequestEntity entity)` | 取得會員等級異動清單 |
| `ApiResultEntity GetOrderCalculateHistory(CrmMemberTierChangeRequestEntity entity)` | 取得訂單計算歷程 |

### ThirdPartyMemberClient / IThirdPartyMemberClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UpdateOuterMember(UpdateOuterMembersRequestEntity entity)` | 更新外部會員 |
| `ApiResultEntity UpdateMemberInfoAndSetting(UpdateMemberInfoAndSettingRequestEntity entity)` | 更新會員資訊與設定 |
| `ApiResultEntity CreateMemberLogoutRequest(MemberLogoutRequestEntity entity)` | 建立會員登出請求 |

---

## 門市地點相關 Clients

### LocationClient / ILocationClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity Create(LocationRequestEntity entity)` | 建立地點 |
| `ApiResultEntity Update(LocationRequestEntity entity)` | 更新地點 |
| `ApiResultEntity Delete(LocationDeleteRequestEntity entity)` | 刪除地點 |
| `ApiResultEntity GetAllSetting(IdEntity entity)` | 取得所有設定 |
| `ApiResultEntity UpdateSetting(LocationSettingUpdateEntity entity)` | 更新設定 |
| `ApiResultEntity TriggerBindLocationMemberApi(LocationOuterMemberApiRequestEntity entity)` | 觸發綁定地點會員 API |
| `ApiResultEntity TriggerCreateLocationMemberApi(LocationOuterMemberApiRequestEntity entity)` | 觸發建立地點會員 API |
| `ApiResultEntity SearchCrmMemberByCellPhone(SearchMemberByCellPhoneRequestEntity entity)` | 依手機號碼搜尋 CRM 會員 |
| `ApiResultEntity UpdateCrmMemberInfo(VipMemberInfoRequestEntity entity)` | 更新 CRM 會員資訊 |
| `ApiResultEntity UpdateMemberInfo(VipMemberInfoRequestEntity entity)` | 更新會員資訊 |
| `ApiResultEntity GetLocationExtension(IdEntity entity)` | 取得地點擴充資訊 |
| `ApiResultEntity GetAvailableECoupon(GetAvailableECouponRequestEntity entity)` | 取得可用電子票券 |
| `ApiResultEntity RedeemPointExchangeECoupon(RedeemPointExchangeECouponRequestEntity entity)` | 兌換點數換電子票券 |
| `ApiResultEntity GetMemberAvailableECouponList(MemberAvailableECouponRequestEntity entity)` | 取得會員可用電子票券清單 |

### OuterLocationClient / IOuterLocationClient

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity RegisterMember(OuterLocationRegisterMemberRequestEntity entity)` | 登錄外部地點會員 |
| `ApiResultEntity GetMemberAvailableCouponList(OuterLocationMemberRequestEntity entity)` | 取得會員可用優惠券清單 |

---

## 其他 Clients

### TaggingClient / ITaggingClient（標籤系統）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity SearchTagGroups / QueryTagGroups / GetTagGroups / GetTagGroup` | 搜尋/查詢/取得標籤群組 |
| `ApiResultEntity CreateTagGroup / UpdateTagGroup / DeleteTagGroup` | 建立/更新/刪除標籤群組 |
| `ApiResultEntity GetTagKeys / BatchGetTagKeys / CreateTagKey / UpdateTagKey / DeleteTagKey` | 標籤鍵 CRUD |
| `ApiResultEntity GetTagValue(s) / ValidateTagValues` | 取得/驗證標籤值 |
| `ApiResultEntity QueryItems / GetItem(s) / ApplyTags / ClearItemTags` | 項目標籤操作 |

### IntelligentRecommendation.IntelligentRecommendationClient（智慧推薦）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetShopSetting(IntelligentRecommendationQueryEntity entity)` | 取得商店推薦設定 |
| `ApiResultEntity UpdateShopSettingByPage(UpdateByPageRequestEntity entity)` | 依頁面更新推薦設定 |
| `ApiResultEntity UpdateShopSettingBySource(UpdateBySourceRequestEntity entity)` | 依來源更新推薦設定 |
| `ApiResultEntity GetDefaultRecommendationSetting(RecommendationConfigGetSettingQueryEntity entity)` | 取得預設推薦設定 |
| `ApiResultEntity GetRecommendationSetting(RecommendationConfigGetSettingQueryEntity entity)` | 取得推薦設定 |
| `ApiResultEntity UpdateShopRecommendationSettingAsync(RecommendationConfigUpdateSettingRequestEntity entity)` | 更新商店推薦設定 |

### MultilingualContent.MultilingualContentClient（多語系內容）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetList / GetMultilingualList` | 取得多語系清單 |
| `ApiResultEntity Get / GetDetail` | 取得多語系詳情 |
| `ApiResultEntity UpdateContent / UpdateMultilingualContent` | 更新多語系內容 |

### NMS.NMSClient（NMS）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity CreateNMS(NMSCreateRequestEntity entity)` | 建立 NMS |
| `ApiResultEntity CreateReturn(NMSCreateReturnRequestEntity entity)` | 建立退貨 |
| `ApiResultEntity ExtendReturn(NMSExtendReturnRequestEntity entity)` | 延長退貨期限 |
| `ApiResultEntity CloseReturn(NMSCloseReturnRequestEntity entity)` | 關閉退貨 |

### Stripes.StripeClient（Stripe 金流）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity IsChargeEnabled(IsChargeEnabledRequestEntity entity)` | 是否可付款 |
| `ApiResultEntity CreateAccount(CreateAccountRequestEntity entity)` | 建立帳號 |
| `ApiResultEntity AccountLink(AccountLinkRequestEntity entity)` | 帳號連結 |
| `ApiResultEntity CreateReportRun(CreateReportRunRequestEntity entity)` | 建立報表執行 |
| `ApiResultEntity GetReportRun(GetReportRunRequestEntity entity)` | 取得報表執行狀態 |
| `ApiResultEntity DownloadFile(DownloadFileRequestEntity entity)` | 下載檔案 |

### ReferrerClient / IReferrerClient（推薦人）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetReferrerBaseBindings` | 取得推薦人基本綁定 |
| `ApiResultEntity GetBaseBindingHistory / GetShortBindingHistory` | 取得綁定歷程 |
| `ApiResultEntity GetBaseBindingHistoryDetail` | 取得綁定歷程詳情 |
| `ApiResultEntity GetReferrerPointDetails` | 取得推薦人點數詳情 |

### 其他小型 Clients

| Client | 說明 | 主要方法 |
|--------|------|---------|
| `DispatchOrderClient` | 調貨單 | `GetResultList`, `Shipping` |
| `DigitalDeliveryClient` | 數位商品發送 | `DigitalDelivery` |
| `GiftClient` | 禮品 | `CreateGift`, `GetDetail`, `UpdateDetail`, `UploadGiftImage` |
| `RechargeReceiptClient` | 儲值收據 | `GetList`, `Get`, `Create` |
| `ElectronicInvoiceClient` | 電子發票 | `Get` |
| `ExpenseManagementClient` | 費用管理 | `IsEnoughCountQuotaForAudienceSMS`, `IsEnoughFixedQuotaForAudienceSMS`, `GetExpenseSetting` |
| `ExpenseOrderClient` | 費用訂單 | `CreateWithSlave`, `CreateBalanceExpenseOrderSlave` |
| `DeepLinkClient` | 深度連結 | `CreateFirebaseDeepLinkForCache` |
| `NotificationClient` | 通知 | `UploadNotificationImage` |
| `QuestionClient` | 問答 | `ReplyQuestion` |
| `ShoppingCartClient` | 購物車 | `RemoveCartAmountPreviewCache` |
| `ShopUpgradeClient` | 商店升級 | `UpgradeForCreditCardPayment` |
| `StickerPointClient` | 貼紙點數 | `StickerPointProcessing` |
| `UrlClient` | 短網址 | `Shorten` |
| `AppRefereeClient` | App 推薦 | `Get` |
| `RetailStoreClient` | 零售門市 | `CancelAllocateCode`, `UpdateDeliveryOrderStatusCache`, `CheckThirdPartyOrderTransferState` |
| `CancelOrderClient` | 取消訂單 | `GetCancelTotalDiscount` |
| `ChangeShopShippingTypeRequestClient` | 換貨物流申請 | `UpdateShopShippingTypeRequest` |
| `ShopAppClient` | 商店 App | `UpdateAppVerifyResult` |
| `OmoReportClient` | OMO 報表 | `GetOMOReport`, `GetOMOReportDetail` |
| `OmoKeyPromptSummaryClient` | OMO 關鍵提示摘要 | `GetLastOmoKeyPromptsFromMemberDimension`, `GenerateOmoKeyPromptSummary` |
| `RecaptchaEnterpriseClient` | reCAPTCHA Enterprise | `CreateRecaptchaEnterpriseSiteKey` |
| `NotIssueInvoiceSalesOrderClient` | 未開票銷售訂單 | `NotIssueInvoiceSalesOrderGet` |
| `ReferrerPromotionClient` | 推薦人促銷 | `GetList`, `GetPerformanceSummary`, `GetSalePageRank` |
| `ReferrerReportClient` | 推薦人報表 | `GetReferrerOrderDetailReports`, `GetReferrerOrderStatisticsReports`, `GetReferrerBindingDetailReports`, `GetReferrerBindingStatisticsReports` |
| `EmployeeClient` | 員工 | `CreateEmployeeInfo`, `DeleteEmployeeInfo`, `EditEmployeeLocations`, `GetEmployeeLocations` |
