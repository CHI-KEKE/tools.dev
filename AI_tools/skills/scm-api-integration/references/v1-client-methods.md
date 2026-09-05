# NineYi.Scm.Api.Client.V1 — IScmClient / ScmClientV1

> 套件：`NineYi.Scm.Api.Client`（最新版：`1.2511.325.1047`）
> Namespace：`NineYi.Scm.Api.Client.V1`
> 使用方式：`using (IScmClient client = new ScmClientV1(token, key, saltKey, apiUrl)) { ... }`

V1 是單一大型 Client，所有功能集中在 `IScmClient`。

## 商品頁（SalePage）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetMain(IdEntity entity)` | 取得商品頁主資料 |
| `ApiResultEntity GetMainDetail(IdEntity entity)` | 取得商品頁完整詳細資料 |
| `ApiResultEntity SubmitMain(SalePageCreateEntity entity)` | 建立商品頁 |
| `ApiResultEntity UpdateMainDetail(SalePageUpdateEntity entity)` | 更新商品頁詳細資料 |
| `ApiResultEntity UpdateListing(SalePageUpdateIsClosedEntity entity)` | 更新上下架狀態 |
| `ApiResultEntity UpdatePrice(SalePageUpdatePriceEntity entity)` | 更新售價 |
| `ApiResultEntity UpdateTitle(SalePageUpdateTitleEntity entity)` | 更新商品頁標題 |
| `ApiResultEntity UpdateSalePageStatus(SalePageUpdateStatusEntity entity)` | 更新商品頁狀態 |
| `ApiResultEntity UpdateSellingDateTime(SalePageUpdateSellingDateTimeEntity entity)` | 更新銷售起迄時間 |
| `ApiResultEntity UpateSalePageSEO(SalePageUpdateSEOEntity entity)` | 更新 SEO 設定 |
| `ApiResultEntity UpdateTemperatureInfo(SalePageTemperatureUpdateEntity entity)` | 更新溫層資訊 |
| `ApiResultEntity UpdateShippingTypeDef(SalePageUpdateShippingTypeDefEntity entity)` | 更新運送方式設定 |
| `ApiResultEntity DeleteSalePage(SalePageDeleteEntity entity)` | 刪除商品頁 |

## SKU

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity SubmitSku(SkuAddEntity entity)` | 新增 SKU |
| `ApiResultEntity UpdateSkuDetail(SalePageSkuUpdateEntity entity)` | 更新 SKU 詳細資料 |
| `ApiResultEntity UpdateSKUImage(ImageInfoEntity entity, string imagePath)` | 更新 SKU 圖片 |
| `ApiResultEntity GetSkuList(SalePageGetSKUListRequestEntity entity)` | 取得商品頁 SKU 清單 |
| `ApiResultEntity GetSkuListByOuterId(SalePageGetSKUListByOuterIdRequestEntity entity)` | 依外部代碼取得 SKU 清單 |
| `ApiResultEntity GetSKUListBySKU(long skuId)` | 依 SKU ID 取得清單 |
| `ApiResultEntity GetSKUListByMain(IdEntity entity)` | 依商品頁取得 SKU 清單 |
| `ApiResultEntity DeleteSku(SkuDeleteEntity entity)` | 刪除 SKU |

## 圖片

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity UpdateMainImage(ImageInfoEntity entity, string imagePath)` | 更新主圖（檔案路徑） |
| `ApiResultEntity UpdateMainImageJObject(ImageInfoEntity entity, string imagePath)` | 更新主圖（JObject 格式） |
| `ApiResultEntity UpdateMainImage(ImageInfoEntity entity, string filename, byte[] data)` | 更新主圖（byte 陣列） |
| `Task UpdateMainImageAsync(ImageInfoEntity entity, string imagePath)` | 非同步更新主圖（注意：此專案偏好同步方法） |
| `ApiResultEntity UpdateSalePageDescImage(ImageInfoEntity entity, string imagePath)` | 更新商品頁描述圖片 |
| `ApiResultEntity DeleteSalePageMainImage(SalePageMainImageDeleteEntity entity)` | 刪除商品頁主圖 |
| `ApiResultEntity UpdateAlbumImage(ImageInfoEntity entity, string imagePath)` | 更新相簿主圖 |
| `ApiResultEntity UpdateAlbumGalleryImage(ImageInfoEntity entity, string imagePath)` | 更新相簿 Gallery 圖片 |
| `ApiResultEntity DeleteAlbumGalleryImage(AlbumGalleryImageDeleteEntity entity)` | 刪除相簿 Gallery 圖片 |
| `ApiResultEntity UpdateArticleImage(ImageInfoEntity entity, string imagePath)` | 更新文章圖片 |
| `ApiResultEntity UpdateLocationImage(ImageInfoEntity entity, string imagePath)` | 更新地點圖片 |
| `ApiResultEntity UpdateLocationGalleryImage(ImageInfoEntity entity, string imagePath)` | 更新地點 Gallery 圖片 |
| `ApiResultEntity DeleteLocationGalleryImage(LocationGalleryImageDeleteEntity entity)` | 刪除地點 Gallery 圖片 |
| `ApiResultEntity UpdateLayoutTemplateDataImage(ImageInfoEntity entity, string imagePath)` | 更新版型模板資料圖片 |
| `ApiResultEntity UpdateAppIcon(ImageInfoEntity entity, string imagePath)` | 更新 App Icon |
| `ApiResultEntity UpdateOfficialShopLogo(ImageInfoEntity entity, string imagePath)` | 更新官方商店 Logo |
| `ApiResultEntity SavePromotionImage(ImageInfoEntity entity, string imagePath)` | 儲存促銷圖片 |
| `ApiResultEntity GetPromotionImage(PromotionImageRequestEntity entity)` | 取得促銷圖片 |
| `ApiResultEntity RemovePromotionImage(PromotionRemoveImageRequestEntity entity)` | 移除促銷圖片 |

## 鏡像類別（Mirror Category）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetShopCategory(ShopIdRequestEntity entity)` | 取得商店類別 |
| `ApiResultEntity GetMirrorCategory(IdEntity entity)` | 取得鏡像類別 |
| `ApiResultEntity GetMirrorShopCategory(IdEntity entity)` | 取得鏡像商店類別 |
| `ApiResultEntity GetMirrorShopCategoryList(IdEntity entity)` | 取得鏡像商店類別清單 |
| `ApiResultEntity UpdateMirrorCategory(SalePageUpdateMirrorCategoryEntity entity)` | 更新鏡像類別 |
| `ApiResultEntity UpdateMirrorShopCategory(SalePageUpdateMirrorShopCategoryEntity entity)` | 更新鏡像商店類別 |

## 庫存

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetStock(IdAndSkuIdEntity entity)` | 取得庫存 |
| `ApiResultEntity UpdateStock(SalePageUpdateTotalQtyEntity entity)` | 更新庫存 |
| `ApiResultEntity UpdateCancelStock(CancelOrderUpdateQtyEntity entity)` | 取消訂單更新庫存 |

## 配送 / 物流

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetShipping(IdEntity entity)` | 取得配送設定 |
| `ApiResultEntity GetPayment()` | 取得付款方式 |
| `ApiResultEntity ShippingOrderConfirm(ShippingOrderConfirmRequestEntity entity)` | 確認出貨訂單 |
| `ApiResultEntity HomeDeliveryShipping(HomeDeliveryShippingOrderCreateEntity entity)` | 建立宅配出貨 |

## 優惠券（Coupon）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetCoupon(CouponQueryEntity entity)` | 取得單筆優惠券 |
| `ApiResultEntity GetCouponList(CouponListQueryEntity entity)` | 取得優惠券清單 |
| `ApiResultEntity CreateCoupon(CouponCreateEntity entity)` | 建立優惠券 |
| `ApiResultEntity UpdateCoupon(CouponUpdateEntity entity)` | 更新優惠券 |
| `ApiResultEntity DeleteCoupon(CouponDeleteEntity entity)` | 刪除優惠券 |
| `ApiResultEntity GetShopMemberCoupon(ShopMemberCouponQueryEntity entity)` | 取得會員優惠券 |
| `ApiResultEntity GetShopMemberCouponAr(ShopMemberCouponQueryEntity entity)` | 取得會員優惠券（AR） |
| `ApiResultEntity CreateCouponPoolWithCustomSerialNumberRequest(CreateCouponPoolWithCustomSerialNumberRequestEntity entity)` | 建立自訂序號優惠券池 |

## 廣告位（Ad Position）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity CreateAdPosition(AdPositionCreateEntity entity)` | 建立廣告位 |
| `ApiResultEntity UpdateAdPosition(AdPositionUpdateEntity entity)` | 更新廣告位 |
| `ApiResultEntity DeleteAdPosition(AdPositionDeleteEntity entity)` | 刪除廣告位 |
| `ApiResultEntity UpdateAdPositionSlaveImage(ImageInfoEntity entity, string imagePath)` | 更新廣告位子圖片 |

## Info 模組

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetInfoList(ListCriteriaEntity entity)` | 取得 Info 清單 |
| `ApiResultEntity GetInfoListCount(IdEntity entity)` | 取得 Info 筆數 |
| `ApiResultEntity CheckInfoModuleHasContent(InfoModuleQueryEntity entity)` | 檢查 Info 模組是否有內容 |

## 相簿（Album）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetAlbum(IdEntity entity)` | 取得相簿 |
| `ApiResultEntity CreateAlbum(AlbumEntity entity)` | 建立相簿 |
| `ApiResultEntity UpdateAlbum(AlbumEntity entity)` | 更新相簿 |
| `ApiResultEntity DeleteAlbum(IdEntity entity)` | 刪除相簿 |

## 文章（Article）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetArticle(IdEntity entity)` | 取得文章 |
| `ApiResultEntity CreateArticle(ArticleEntity entity)` | 建立文章 |
| `ApiResultEntity UpdateArticle(ArticleEntity entity)` | 更新文章 |
| `ApiResultEntity DeleteArticle(IdEntity entity)` | 刪除文章 |

## 影片（Video）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetVideo(IdEntity entity)` | 取得影片 |
| `ApiResultEntity CreateVideo(VideoEntity entity)` | 建立影片 |
| `ApiResultEntity UpdateVideo(VideoEntity entity)` | 更新影片 |
| `ApiResultEntity DeleteVideo(IdEntity entity)` | 刪除影片 |

## 門市地點（Location）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetLocation(IdEntity entity)` | 取得地點 |
| `ApiResultEntity GetLocationList(ListCriteriaEntity entity)` | 取得地點清單 |
| `ApiResultEntity GetLocationListCount(IdEntity entity)` | 取得地點筆數 |
| `ApiResultEntity CreateLocation(LocationEntity entity)` | 建立地點 |
| `ApiResultEntity UpdateLocation(LocationEntity entity)` | 更新地點 |
| `ApiResultEntity DeleteLocation(IdEntity entity)` | 刪除地點 |
| `ApiResultEntity GetAreaList()` | 取得區域清單 |
| `ApiResultEntity GetCityList()` | 取得城市清單 |
| `ApiResultEntity GetO2OLocationCount(IdEntity entity)` | 取得 O2O 地點數量 |

## 版型模板（Layout Template）

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity CreateLayoutTemplateData(LayoutTemplateDataCreateEntity entity)` | 建立版型模板資料 |
| `ApiResultEntity UpdateLayoutTemplateData(LayoutTemplateDataUpdateEntity entity)` | 更新版型模板資料 |
| `ApiResultEntity DeleteLayoutTemplateData(LayoutTemplateDataDeleteEntity entity)` | 刪除版型模板資料 |

## 退貨

| 方法簽名 | 說明 |
|---------|------|
| `ApiResultEntity GetReturnGoodList(GetReturnGoodListQueryEntity entity)` | 取得退貨清單 |
| `ApiResultEntity GetReturnGood(GetReturnGoodQueryEntity entity)` | 取得退貨詳情 |
