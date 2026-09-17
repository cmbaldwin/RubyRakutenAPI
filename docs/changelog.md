# Rakuten Pay Order API - Changelog

Full version history for the RakutenPayOrderAPI.

## Version Summary

| Version | Date       | Highlights                                   |
| ------- | ---------- | -------------------------------------------- |
| 8.3     | 2025/12/12 | Test response samples removed                |
| 8.2     | 2025/12/01 | Pay-easy service ended                       |
| 8.1     | 2025/10/23 | Social gift support (version 10)             |
| 8.0     | 2025/09/16 | Drop-off location for updateOrderSender      |
| 7.9     | 2025/06/23 | New carriers (Yamato Yu-Packet, Meitetsu NX) |
| 7.8     | 2024/11/14 | Japan Post Rakuten Warehouse carrier (1029)  |
| 7.7     | 2024/10/03 | Drop-off delivery (version 9)                |
| 7.5     | 2024/03/28 | Same-day shipping flag (version 8)           |
| 6.3     | 2022/07/21 | SKU project - SKU model added (version 7)    |
| 6.0     | 2021/11/15 | Warning display details (version 6)          |
| 4.6     | 2020/07/16 | Receipt, prepay deadline (version 5)         |
| 3.9     | 2019/12/12 | Free shipping line support (version 4)       |
| 2.8     | 2019/04/26 | Tax increase support (version 3)             |
| 1.0     | 2017/12/21 | Initial release                              |

---

## Detailed Changelog

### v8.3 (2025/12/12)

- Removed test response sample `RakutenPayOrderAPI Response Sample`

### v8.2 (2025/12/01)

- Updated `settlementMethod` code 14 name due to ゆうちょ Pay-easy service end
- Affected endpoints: searchOrder, getOrder, updateOrderSender, simulateCouponAmount, getPayment

### v8.1 (2025/10/23)

- **getOrder**: Added version 10 for social gift support
- Added social gift related response parameters
- Added Sample version 10

### v8.0 (2025/09/16)

- Added `dropOffLocation` (置き配場所) to:
  - updateOrderSender
  - updateOrderSenderAfterShipping
  - simulateCouponAmount
- Added error messages in Message Codes Reference
- Added note about ORDER_EXT_API_GET_ORDER_WARNING_101

### v7.9 (2025/06/23)

- Added delivery companies:
  - 1030: ヤマト運輸 クロネコゆうパケット
  - 1031: 名鉄 NX 運輸
- Affected endpoints: getOrder, updateOrderShipping, updateOrderShippingAsync

### v7.8 (2024/11/14)

- Added delivery company 1029: 日本郵便 楽天倉庫出荷
- Renamed 最強配送 service - updated `deliveryCertPrgFlag` description

### v7.7 (2024/10/03)

- **getOrder**: Added version 9 for drop-off delivery
- Added `dropOffFlag` and `dropOffLocation` fields
- Added Sample version 9

### v7.6 (2024/07/05)

- Updated getOrder Sample version 8
- Updated test response samples

### v7.5 (2024/03/28)

- **searchOrder**: Added `oneDayOperationFlag` (注文当日出荷フラグ)
- **getOrder**: Added version 8
  - Added `deliveryCertPrgFlag` (最強配送フラグ)
  - Added `oneDayOperationFlag` (注文当日出荷フラグ)
  - Removed `消費税再計算フラグ`
- Added Sample version 8

### v7.4 (2024/03/14)

- Updated error code descriptions for ORDER_EXT_API_UPDATE_ORDERSENDER_ERROR_115 and related

### v7.3 (2023/11/28)

- Updated error code descriptions for sender update errors

### v7.2 (2023/07/24)

- **getOrder**: Added invoice support notes to `reqPrice` and `reqPriceTax`
- Fixed "Package Model" to "PackageModel" in documentation

### v7.1 (2023/05/10)

- **getOrder**: Updated samples, fixed `couponModel.itemDetailId` description

### v7.0 (2023/04/21)

- **getOrder**:
  - Fixed `expiryDate` Max Byte from 8 to 10
  - Updated `selectedChoice` and `skuInfo` descriptions

### v6.9 (2023/01/16)

- Updated test response samples

### v6.8 (2022/12/22)

- Updated `shippingDetailId` description in updateOrderShipping, getResultUpdateOrderShippingAsync
- Added ORDER_EXT_API_UPDATE_ORDERSHIPPING_WARNING_101

### v6.7 (2022/11/15)

- **getOrder**: Removed payment method code 3 (後払い)

### v6.6 (2022/09/13)

- Updated `afterSettlementMethodCode` description in updateOrderSender, simulateCouponAmount

### v6.5 (2022/08/31)

- Added SKU project samples to getOrder, updateOrderSender, updateOrderSenderAfterShipping, simulateCouponAmount

### v6.4 (2022/08/04)

- Added Alipay (支付宝) payment method
- Updated SKU 管理番号 description

### v6.3 (2022/07/21)

- **SKU Project**: Added SKU model to:
  - getOrder
  - updateOrderSender
  - updateOrderSenderAfterShipping
  - simulateCouponAmount
  - searchOrder

### v6.2 (2022/06/14)

- Renamed 日通トランスポート to NX トランスポート

### v6.1 (2022/02/04)

- **getOrder**: Added calculation methods for 総合計（税込）and 商品小計（税込）
- Updated TaxSummaryModel descriptions for point tax handling

### v6.0 (2021/11/15)

- **getOrder**: Added version 6
  - Added `cautionDisplayDetailType` (警告表示タイプ詳細)
  - Added response parameter `version`
- Added ORDER_EXT_API_UPDATE_ORDERORDERER_ERROR_033

### v5.9 (2021/08/26)

- Updated WrappingModel1, WrappingModel2, CouponModelList descriptions
- Fixed ORDER_EXT_API_UPDATE_ORDERSENDER_ERROR_114

### v5.8 (2021/08/18)

- Updated deliveryCompany, shippingNumber, shippingDate descriptions
- Added ORDER_EXT_API_SEARCH_ORDER_ERROR_023

### v5.7 (2021/06/16)

- Removed coupon quantity limit for updateOrderSender, updateOrderSenderAfterShipping

### v5.6 (2021/04/09)

- Made `version` parameter required for getOrder and getPayment

### v5.5 (2021/03/09)

- Updated subStatusIdList description in searchOrder
- Added delivery error codes ORDER_EXT_API_UPDATE_ORDERDELIVERY_ERROR_901/902/903

### v5.4 (2021/02/25)

- Updated shippingDetailId description in updateOrderShipping response

### v5.3 (2021/01/15)

- Added multiple error codes
- Added payment charge totals to simulateCouponAmount
- Coupon orders: item quantity limit increased to 10,000

### v5.2 (2021/01/06)

- updateOrderSenderAfterShipping: Payment method change no longer supported after shipping

### v5.1 (2020/12/15)

- Updated multiple error code messages
- Added simulateCouponAmount samples

### v5.0 (2020/11/26)

- **getOrder**: Added changeTypeDetail values 11, 12 for payment method changes
- Added `afterSettlementMethodCode` to updateOrderSender, updateOrderSenderAfterShipping, simulateCouponAmount
- Added paymentChargeBefore/After to simulateCouponAmount

### v4.9 (2020/11/06)

- Updated membershipType description
- Removed 学割クーポン sample

### v4.8 (2020/10/29)

- **New endpoint**: simulateCouponAmount

### v4.7 (2020/08/27)

- Updated character limits for search keyword and memo
- Updated shipping model limits

### v4.6 (2020/07/16)

- **getOrder**: Added version 5 for receipt and prepay deadline support

### v4.5 (2020/06/25)

- Added multiple error codes
- Fixed ORDER_EXT_API_UPDATE_ORDERSHIPPING_ERROR_101

### v4.4 (2020/05/21)

- Extended async result availability from 10 to 30 days
- Added error codes for memo and shipping updates

### v4.3 (2020/03/16)

- Removed getPayment version 1 and 2 samples

### v4.2 (2020/02/20)

- Removed getOrder version 1 and 2 samples

### v4.1 (2020/01/31)

- Added getOrder version 4 samples for free shipping line

### v4.0 (2020/01/16)

- Removed tax reform highlighting
- Removed some error codes

### v3.9 (2019/12/12)

- **getOrder**: Added version 4 for free shipping line support
- Added `defaultDeliveryCompanyCode` and `isSingleItemShipping`
- Renamed 西部運輸 to セイノースーパーエクスプレス

### v3.8 (2019/11/26)

- Added PayPal/Alipay samples to getOrder version 3

### v3.7 (2019/11/13)

- **searchOrder**: Increased result limit from 5,000 to 15,000

### v3.6 (2019/10/31)

- **getPayment**: Added version 4 for PayPal/Alipay
- Added PayPal/Alipay to searchOrder settlementMethod

### v3.5 (2019/09/20)

- Tax rate fields can now be set to 0.0
- searchOrder: Results capped at 5,000

### v3.4 (2019/07/24)

- Removed coupon validation error codes

### v3.3 (2019/07/12)

- Updated TaxSummaryModelList description

### v3.2 (2019/06/27)

- Fixed orderNumberList MaxByte to 40960

### v3.1 (2019/06/21)

- Updated goodsPrice, totalPrice, requestPrice descriptions
- Highlighted tax reform fields in green

### v3.0 (2019/05/29)

- Updated TaxSummaryModel field descriptions

### v2.9 (2019/05/22)

- Added 2019/10 tax increase version to test samples

### v2.8 (2019/04/26)

- Added tax increase related fields to getOrder, getPayment, updateOrderSender, updateOrderSenderAfterShipping

### v2.7 (2019/04/17)

- ShippingModelList limit set to 151

### v2.6 (2019/02/13)

- Removed 400 status from updateOrderSender
- Added 後払い決済 to searchOrder settlementMethod

### v2.5 (2019/01/23)

- **New endpoint**: updateOrderSenderAfterShipping

### v2.4 (2018/12/19)

- Added test response sample RakutenPayOrderAPI Response Sample

### v2.3 (2018/11/27)

- Added Rakuten EXPRESS delivery company

### v2.2 (2018/11/21)

- Added HTTP Status Code column to Message Codes Reference

### v2.1 (2018/10/31)

- Added 後払い (deferred payment) fields to getOrder and getPayment

### v2.0 (2018/10/24)

- Added reductionReason to updateOrderOrderer

### v1.9 (2018/09/26)

- **New endpoint**: cancelOrderAfterShipping
- Added status 900 (キャンセル確定) to searchOrder

### v1.8 (2018/07/25)

- **New endpoints**: getResultUpdateOrderShippingAsync, updateOrderShippingAsync

### v1.7 (2018/07/25)

- **New endpoints**: getSubStatusList, updateOrderSubStatus

### v1.6 (2018/07/25)

- **New endpoint**: cancelOrder

### v1.5 (2018/06/07)

- Added subStatusId to updateOrderMemo

### v1.4 (2018/05/10)

- Added Apple Pay payment method

### v1.3 (2018/04/26)

- Updated Message Codes Reference

### v1.2 (2018/03/28)

- Updated request samples for multiple endpoints
- Added itemDetailId to ItemModel, itemId to CouponModel

### v1.1 (2018/02/19)

- Added Message Codes Reference

### v1.0 (2017/12/21)

- Initial release
