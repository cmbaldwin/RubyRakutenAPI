# getOrder (注文情報取得)

Get detailed order information by order number list.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/getOrder/`

## Constraints

- Maximum 100 orders per request
- Orders from past 730 days (2 years) only

## Tax Calculation Note

RMS UI fields "総合計（税込）" and "商品小計（税込）" are not directly returned but can be calculated:

- **総合計（税込）** = `totalPrice - couponAllTotalPrice + deliveryPrice + paymentCharge + additionalFeeOccurAmountToUser`
- **商品小計（税込）** = Sum of `(priceTaxIncl × units)` for all items + wrapping prices

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

| Parameter         | Japanese       | Required | Type           | Description                                            |
| ----------------- | -------------- | -------- | -------------- | ------------------------------------------------------ |
| `orderNumberList` | 注文番号リスト | **yes**  | List\<String\> | Max 100 orders, past 730 days only                     |
| `version`         | バージョン番号 | **yes**  | Number         | 3-10 (see version table below). **Use latest version** |

### API Versions

| Version | Feature                            | Release |
| ------- | ---------------------------------- | ------- |
| 3       | 消費税増税対応 (Tax increase)      | 2019    |
| 4       | 送料込みライン対応 (Free shipping) | 2020/03 |
| 5       | 領収書、前払い期限 (Receipt)       | 2020/08 |
| 6       | 顧客・配送対応注意表示詳細         | 2021/11 |
| 7       | SKU 対応 (SKU support) **Current** | 2023/02 |
| 8       | 配送品質向上制度対応               | 2024/03 |
| 9       | 置き配対応 (Drop-off delivery)     | 2024/10 |
| 10      | ソーシャルギフト対応               | TBD     |

**Note:** Old versions will be deprecated. Always use the latest version.

## Response Structure

### Level 1: Base Response

| Parameter          | Type                 | Description     |
| ------------------ | -------------------- | --------------- |
| `MessageModelList` | List\<MessageModel\> | Status messages |
| `OrderModelList`   | List\<OrderModel\>   | Order details   |
| `version`          | Number               | Version (v6+)   |

### Level 2: OrderModel (Main Order Data)

| Parameter                        | Type     | Description                                                      |
| -------------------------------- | -------- | ---------------------------------------------------------------- |
| `orderNumber`                    | String   | Order number (e.g., "502763-20171027-00006701")                  |
| `orderProgress`                  | Number   | Status: 100/200/300/400/500/600/700/800/900                      |
| `subStatusId`                    | Number   | Custom sub-status ID                                             |
| `subStatusName`                  | String   | Sub-status name                                                  |
| `orderDatetime`                  | Datetime | Order date/time                                                  |
| `shopOrderCfmDatetime`           | Datetime | Order confirmation date/time                                     |
| `orderFixDatetime`               | Datetime | Order finalization date/time                                     |
| `shippingInstDatetime`           | Datetime | Shipping instruction date/time                                   |
| `shippingCmplRptDatetime`        | Datetime | Shipping completion report date/time                             |
| `cancelDueDate`                  | Date     | Cancel deadline                                                  |
| `deliveryDate`                   | Date     | Requested delivery date                                          |
| `shippingTerm`                   | Number   | Delivery time slot (0=none, 1=AM, 2=PM, 9=other, or h1h2 format) |
| `remarks`                        | String   | Order remarks/notes                                              |
| `giftCheckFlag`                  | Number   | 0=not gift, 1=gift order                                         |
| `socialGiftFlag`                 | Number   | 0=not social gift, 1=social gift (v10+)                          |
| `severalSenderFlag`              | Number   | 0=single destination, 1=multiple destinations                    |
| `equalSenderFlag`                | Number   | 0=different address, 1=same as orderer                           |
| `isolatedIslandFlag`             | Number   | 0=no island, 1=includes island destination                       |
| `rakutenMemberFlag`              | Number   | 0=non-member, 1=Rakuten member                                   |
| `carrierCode`                    | Number   | Device type (0=PC, 11=iPhone, 12=Android, etc.)                  |
| `emailCarrierCode`               | Number   | Email carrier (0=PC, 1=DoCoMo, 2=au, 3=SoftBank, etc.)           |
| `orderType`                      | Number   | 1=通常購入, 4=定期購入, 5=頒布会, 6=予約商品                     |
| `reserveNumber`                  | String   | Subscription order number                                        |
| `reserveDeliveryCount`           | Number   | Delivery count for subscription                                  |
| `cautionDisplayType`             | Number   | Warning type (0=none, 1=caution, 2=cancel confirmed)             |
| `cautionDisplayDetailType`       | Number   | Warning detail code (101-105) (v6+)                              |
| `rakutenConfirmFlag`             | Number   | 0=not confirming, 1=Rakuten confirming                           |
| `goodsPrice`                     | Number   | Product total + wrapping (-9999 if unconfirmed)                  |
| `goodsTax`                       | Number   | Tax total (deprecated v8+, use reqPriceTax)                      |
| `postagePrice`                   | Number   | Shipping total (-9999 if unconfirmed)                            |
| `deliveryPrice`                  | Number   | COD fee total (-9999 if unconfirmed)                             |
| `paymentCharge`                  | Number   | Payment fee total (-9999 if unconfirmed)                         |
| `paymentChargeTaxRate`           | Number   | Payment fee tax rate                                             |
| `totalPrice`                     | Number   | goods + shipping + wrapping (-9999 if unconfirmed)               |
| `requestPrice`                   | Number   | Final billing amount (-9999 if unconfirmed)                      |
| `couponAllTotalPrice`            | Number   | Total coupon discount                                            |
| `couponShopPrice`                | Number   | Shop-funded coupon amount                                        |
| `couponOtherPrice`               | Number   | Rakuten-funded coupon amount                                     |
| `additionalFeeOccurAmountToUser` | Number   | Additional fee to user (後払い手数料)                            |
| `additionalFeeOccurAmountToShop` | Number   | Additional fee to shop                                           |
| `asurakuFlag`                    | Number   | 0=no あす楽, 1=あす楽 requested                                  |
| `drugFlag`                       | Number   | 0=no drugs, 1=includes drugs                                     |
| `dealFlag`                       | Number   | 0=no DEAL, 1=includes Rakuten DEAL product                       |
| `membershipType`                 | Number   | 0=none, 1=premium (deprecated), 2=student (deprecated)           |
| `memo`                           | String   | Staff memo (max 1000 chars)                                      |
| `operator`                       | String   | Staff name                                                       |
| `mailPlugSentence`               | String   | Customer message for email                                       |
| `modifyFlag`                     | Number   | 0=no modification, 1=modified from purchase history              |
| `receiptIssueCount`              | Number   | Receipt issue count (v5+)                                        |
| `receiptIssueHistoryList`        | List     | Receipt issue dates (v5+)                                        |
| `deliveryCertPrgFlag`            | Number   | 0=not 最強翌日配送, 1=最強翌日配送 (v8+)                         |
| `oneDayOperationFlag`            | Number   | 0=not same-day, 1=same-day shipping (v8+)                        |
| `OrdererModel`                   | Object   | Orderer information                                              |
| `SettlementModel`                | Object   | Payment information                                              |
| `DeliveryModel`                  | Object   | Delivery method                                                  |
| `PointModel`                     | Object   | Points used                                                      |
| `WrappingModel1`                 | Object   | Wrapping option 1                                                |
| `WrappingModel2`                 | Object   | Wrapping option 2                                                |
| `PackageModelList`               | List     | Destination/package list                                         |
| `CouponModelList`                | List     | Coupons used                                                     |
| `ChangeReasonModelList`          | List     | Change/cancel history                                            |
| `TaxSummaryModelList`            | List     | Tax breakdown by rate                                            |
| `DueDateModelList`               | List     | Payment deadlines (v5+)                                          |

### Level 3: OrdererModel (注文者情報)

| Parameter        | Type   | Description        |
| ---------------- | ------ | ------------------ |
| `zipCode1`       | String | Postal code part 1 |
| `zipCode2`       | String | Postal code part 2 |
| `prefecture`     | String | Prefecture         |
| `city`           | String | City/ward          |
| `subAddress`     | String | Street address     |
| `familyName`     | String | Last name          |
| `firstName`      | String | First name         |
| `familyNameKana` | String | Last name kana     |
| `firstNameKana`  | String | First name kana    |
| `phoneNumber1`   | String | Phone part 1       |
| `phoneNumber2`   | String | Phone part 2       |
| `phoneNumber3`   | String | Phone part 3       |
| `emailAddress`   | String | Email (masked)     |
| `sex`            | String | Gender             |
| `birthYear`      | Number | Birth year         |
| `birthMonth`     | Number | Birth month        |
| `birthDay`       | Number | Birth day          |

### Level 3: SettlementModel (支払方法)

| Parameter              | Type   | Description                                        |
| ---------------------- | ------ | -------------------------------------------------- |
| `settlementMethodCode` | Number | Payment code (1=CC, 2=COD, 9=bank, 12=Apple Pay..) |
| `settlementMethod`     | String | Payment method name                                |
| `rpaySettlementFlag`   | Number | 0=選択制決済, 1=楽天市場共通決済                   |
| `cardName`             | String | Card type (VISA, etc.) - CC only                   |
| `cardNumber`           | String | Card number (masked) - CC only                     |
| `cardOwner`            | String | Card holder name - CC only                         |
| `cardYm`               | String | Card expiry (YYYY-MM) - CC only                    |
| `cardPayType`          | Number | 0=一括, 1=リボ, 2=分割, 3=その他, 4=ボーナス一括   |
| `cardInstallmentDesc`  | String | Installment count (103=3 回, 105=5 回, etc.)       |

### Level 3: PackageModel (送付先)

| Parameter                    | Type   | Description                              |
| ---------------------------- | ------ | ---------------------------------------- |
| `basketId`                   | Number | Destination ID                           |
| `postagePrice`               | Number | Shipping cost for this destination       |
| `postageTaxRate`             | Number | Shipping tax rate                        |
| `deliveryPrice`              | Number | COD fee (-9999 if unset)                 |
| `deliveryTaxRate`            | Number | COD tax rate                             |
| `goodsTax`                   | Number | Tax total (deprecated v8+)               |
| `goodsPrice`                 | Number | Products + wrapping for this destination |
| `totalPrice`                 | Number | Products + shipping + wrapping           |
| `noshi`                      | String | Noshi (gift tag) text                    |
| `packageDeleteFlag`          | Number | 0=keep, 1=delete                         |
| `SenderModel`                | Object | Recipient details                        |
| `ItemModelList`              | List   | Products in this package                 |
| `ShippingModelList`          | List   | Shipping details (tracking, etc.)        |
| `DeliveryCvsModel`           | Object | Convenience store pickup details         |
| `defaultDeliveryCompanyCode` | String | Default carrier code (v4+)               |
| `dropOffFlag`                | Number | 0=no drop-off, 1=drop-off delivery (v9+) |
| `dropOffLocation`            | String | Drop-off location (v9+)                  |
| `SocialGiftModel`            | Object | Social gift info (v10+)                  |

### Level 4: SenderModel (送付先住所)

| Parameter            | Type   | Description                                     |
| -------------------- | ------ | ----------------------------------------------- |
| `zipCode1`           | String | Postal code part 1 (社会ギフト未入力時: "999")  |
| `zipCode2`           | String | Postal code part 2 (社会ギフト未入力時: "9999") |
| `prefecture`         | String | Prefecture (社会ギフト未入力時: "入力待ち")     |
| `city`               | String | City (社会ギフト未入力時: "入力待ち")           |
| `subAddress`         | String | Address (社会ギフト未入力時: "入力待ち")        |
| `familyName`         | String | Last name (社会ギフト未入力時: "入力待ち")      |
| `firstName`          | String | First name                                      |
| `familyNameKana`     | String | Last name kana                                  |
| `firstNameKana`      | String | First name kana                                 |
| `phoneNumber1-3`     | String | Phone number parts                              |
| `isolatedIslandFlag` | Number | 0=not island, 1=island                          |

### Level 4: ItemModel (商品情報)

| Parameter                          | Type   | Description                            |
| ---------------------------------- | ------ | -------------------------------------- |
| `itemDetailId`                     | Number | Item detail ID                         |
| `itemName`                         | String | Product name                           |
| `itemId`                           | Number | Product ID                             |
| `itemNumber`                       | String | Product number                         |
| `manageNumber`                     | String | Management number                      |
| `price`                            | Number | Unit price                             |
| `units`                            | Number | Quantity                               |
| `includePostageFlag`               | Number | 0=送料別, 1=送料込                     |
| `includeTaxFlag`                   | Number | 0=税別, 1=税込                         |
| `includeCashOnDeliveryPostageFlag` | Number | 0=代引手数料別, 1=代引手数料込         |
| `selectedChoice`                   | String | Item options (選択肢)                  |
| `pointRate`                        | Number | Point multiplier                       |
| `pointType`                        | Number | Point type (0=none, 1=shop, 2=product) |
| `inventoryType`                    | Number | 0=none, 1=normal, 2=variant inventory  |
| `delvdateInfo`                     | String | Delivery time info                     |
| `restoreInventoryFlag`             | Number | 0=follow settings, 1=sync, 2=no sync   |
| `dealFlag`                         | Number | 0=not DEAL, 1=DEAL product             |
| `drugFlag`                         | Number | 0=not drug, 1=drug                     |
| `deleteItemFlag`                   | Number | 0=keep, 1=delete                       |
| `taxRate`                          | Number | Tax rate (e.g., 0.1)                   |
| `priceTaxIncl`                     | Number | Tax-inclusive unit price               |
| `isSingleItemShipping`             | Number | 0=no, 1=ships alone (v4+)              |
| `SkuModelList`                     | List   | SKU details (v7+)                      |

### Level 5: SkuModel (SKU 情報) - Version 7+

| Parameter              | Type   | Description                             |
| ---------------------- | ------ | --------------------------------------- |
| `variantId`            | String | SKU 管理番号 (empty for pre-SKU orders) |
| `merchantDefinedSkuId` | String | システム連携用 SKU 番号                 |
| `skuInfo`              | String | SKU variation info (e.g., "容量:560ml") |

### Level 4: ShippingModel (発送情報)

| Parameter             | Type   | Description                               |
| --------------------- | ------ | ----------------------------------------- |
| `shippingDetailId`    | Number | Shipping detail ID (for updates)          |
| `shippingNumber`      | String | Tracking number                           |
| `deliveryCompany`     | String | Carrier code (1001=Yamato, 1002=Sagawa..) |
| `deliveryCompanyName` | String | Carrier name                              |
| `shippingDate`        | Date   | Ship date (YYYY-MM-DD)                    |

### Level 3: CouponModel (クーポン情報)

| Parameter           | Type   | Description                           |
| ------------------- | ------ | ------------------------------------- |
| `couponCode`        | String | Coupon code                           |
| `itemId`            | Number | Target product ID (0 if not specific) |
| `couponName`        | String | Coupon name                           |
| `couponSummary`     | String | Discount summary                      |
| `couponCapital`     | String | ショップ/メーカー/サービス            |
| `couponCapitalCode` | Number | 1=shop, 2=maker, 3=service            |
| `expiryDate`        | Date   | Expiry date                           |
| `couponPrice`       | Number | Discount per unit                     |
| `couponUnit`        | Number | Units applied                         |
| `couponTotalPrice`  | Number | Total discount                        |
| `itemDetailId`      | Number | Target item detail ID                 |

### Level 3: ChangeReasonModel (変更・キャンセル履歴)

| Parameter             | Type     | Description                                    |
| --------------------- | -------- | ---------------------------------------------- |
| `changeId`            | Number   | Change ID                                      |
| `changeType`          | Number   | 0=cancel 申請, 1=cancel 確定, 4=変更申請, etc. |
| `changeTypeDetail`    | Number   | 0=減額, 1=増額, 2=その他, 10-12=支払方法変更   |
| `changeReason`        | Number   | 0=店舗都合, 1=お客様都合                       |
| `changeReasonDetail`  | Number   | Detail code (1-16)                             |
| `changeApplyDatetime` | Datetime | Application date                               |
| `changeFixDatetime`   | Datetime | Confirmation date                              |
| `changeCmplDatetime`  | Datetime | Completion date                                |

### Level 3: TaxSummaryModel (税情報)

| Parameter       | Type   | Description                                 |
| --------------- | ------ | ------------------------------------------- |
| `taxRate`       | Number | Tax rate (e.g., 0.1 for 10%)                |
| `reqPrice`      | Number | Taxable amount at this rate                 |
| `reqPriceTax`   | Number | Tax amount                                  |
| `totalPrice`    | Number | Subtotal at this rate                       |
| `paymentCharge` | Number | Payment fee at this rate                    |
| `couponPrice`   | Number | Coupon discount at this rate                |
| `point`         | Number | Points used (0 for orders after 2022/04/01) |

### Level 3: SocialGiftModel (ソーシャルギフト情報) - Version 10+

| Parameter              | Type     | Description                   |
| ---------------------- | -------- | ----------------------------- |
| `sgMngNumber`          | String   | Social gift management number |
| `inputDueDate`         | Date     | Recipient info input deadline |
| `inputFlag`            | Number   | 0=not entered, 1=entered      |
| `inputCompDatetime`    | Datetime | Input completion date         |
| `receiverEmailAddress` | String   | Recipient email (masked)      |

## Sample Request

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/getOrder/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumberList": ["502763-20171027-00006701", "502763-20171027-00006702"],
    "version": 7
}'
```
