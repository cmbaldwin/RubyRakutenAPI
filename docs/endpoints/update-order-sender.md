# updateOrderSender

Update sender information, product details, and payment method for pre-shipping Rakuten Pay orders.

## Endpoint

```
POST https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/
```

## Overview

This synchronous API allows updating:

- **Product Information**: Name, number, options, unit price, tax rate, tax inclusion, shipping inclusion
- **Shipping Fees**: Postage, postage tax rate, COD fee, COD tax rate, COD fee inclusion
- **Wrapping**: Paper/ribbon, name, price, tax inclusion, tax rate (add/update/delete)
- **Sender Address**: Name, furigana, address, phone number
- **Delivery Options**: Noshi (gift tag), quantity, inventory sync, consumption tax, postage, drop-off location
- **SKU Information**: System SKU number, SKU details
- **Payment Method**: Change settlement method (with restrictions)

### Valid Order Statuses

| Status Code | Description                                |
| ----------- | ------------------------------------------ |
| 100         | 注文確認待ち (Awaiting order confirmation) |
| 200         | 楽天処理中 (Rakuten processing)            |
| 300         | 発送待ち (Awaiting shipment)               |

## Request

### Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

### Request Parameters

#### Level 1: Base

| Parameter                 | Japanese             | Required    | Type   | Description                                                                                     |
| ------------------------- | -------------------- | ----------- | ------ | ----------------------------------------------------------------------------------------------- |
| orderNumber               | 注文番号             | Yes         | String | Order number                                                                                    |
| reductionReason           | 変更理由             | Conditional | Number | Required when reducing amount. See [Reduction Reasons](#reduction-reasons)                      |
| taxRecalcFlag             | 消費税再計算フラグ   | No          | Number | `0`: Don't recalculate, `1`: Recalculate (default). Note: Deprecated after July 2019 tax reform |
| WrappingModel1            | ラッピングモデル 1   | Conditional | Object | Required if wrapping specified                                                                  |
| WrappingModel2            | ラッピングモデル 2   | Conditional | Object | Required if wrapping specified                                                                  |
| PackageModelList          | 送付先モデルリスト   | Yes         | Array  | List of delivery destinations                                                                   |
| CouponModelList           | クーポンモデルリスト | Conditional | Array  | Required for coupon orders                                                                      |
| afterSettlementMethodCode | 変更後支払方法コード | No          | Number | New payment method. See [Payment Method Codes](#payment-method-codes)                           |

#### Reduction Reasons

**Customer reasons:**
| Code | Description |
|------|-------------|
| 1 | キャンセル (Cancellation) |
| 2 | 受取後の返品 (Return after receipt) |
| 3 | 長期不在による受取拒否 (Refusal due to long absence) |
| 4 | 未入金 (Non-payment) |
| 5 | 代引決済の受取拒否 (COD refusal) |
| 6 | その他 (Other) |

**Shop reasons:**
| Code | Description |
|------|-------------|
| 8 | 欠品 (Out of stock) |
| 10 | その他 (Other) |
| 13 | 発送遅延 (Shipping delay) |
| 14 | 顧客・配送対応注意表示 (Customer/delivery caution) |
| 15 | 返品（破損・品間違い）(Return - damage/wrong item) |

#### Payment Method Codes

| Code | Description                          | Notes                                  |
| ---- | ------------------------------------ | -------------------------------------- |
| 2    | 代金引換 (Cash on delivery)          |                                        |
| 4    | ショッピングクレジット／ローン       |                                        |
| 5    | オートローン                         |                                        |
| 6    | リース                               |                                        |
| 7    | 請求書払い (Invoice)                 |                                        |
| 9    | 銀行振込 (Bank transfer)             |                                        |
| 13   | セブンイレブン（前払）               |                                        |
| 14   | ファミリーマート、ローソン等（前払） | Name changes 2026/1/22                 |
| 16   | Alipay                               | Cannot change to this after 2022/10/13 |
| 27   | Alipay（支付宝）                     |                                        |

**Payment Method Change Rules:**

- Only changeable when status is `100` or settlement status is `30400`
- When status `100`: All amounts and items can be changed
- When settlement status `30400` with market common settlement (9, 13, 14, 16): Amounts cannot be changed
- When settlement status `30400` with selective settlement (2, 4, 5, 6, 7): Only postage and COD fee changeable
- Cannot change if increase results in `30400` status

#### Level 2: WrappingModel

| Parameter          | Japanese             | Required | Type   | Description                          |
| ------------------ | -------------------- | -------- | ------ | ------------------------------------ |
| title              | ラッピングタイトル   | Yes      | Number | `1`: Wrapping paper, `2`: Ribbon     |
| name               | ラッピング名         | Yes      | String | Wrapping name (max 125 chars)        |
| price              | 料金                 | No       | Number | Price (default: 0)                   |
| taxRate            | ラッピング税率       | Yes      | Number | `0`, `0.0`, `0.08`, `0.1`            |
| includeTaxFlag     | 税込別               | Yes      | Number | `0`: Tax excluded, `1`: Tax included |
| deleteWrappingFlag | ラッピング削除フラグ | No       | Number | `0`: Keep (default), `1`: Delete     |

#### Level 2: PackageModel

| Parameter         | Japanese               | Required    | Type   | Description                                                      |
| ----------------- | ---------------------- | ----------- | ------ | ---------------------------------------------------------------- |
| basketId          | 送付先 ID              | Yes         | Number | Basket/destination ID                                            |
| postagePrice      | 送料                   | No          | Number | Postage. Use `-9999` to set null                                 |
| postageTaxRate    | 送料税率               | Yes         | Number | `0`, `0.0`, `0.08`, `0.1`                                        |
| deliveryPrice     | 代引料                 | Conditional | Number | COD fee. Required if payment is COD. Use `-9999` for null        |
| deliveryTaxRate   | 代引料税率             | Conditional | Number | Required for COD payment                                         |
| goodsTax          | 消費税                 | No          | Number | Deprecated after July 2019                                       |
| noshi             | のし                   | No          | String | Gift tag message                                                 |
| packageDeleteFlag | 送付先モデル削除フラグ | No          | Number | `0`: Keep (default), `1`: Delete                                 |
| SenderModel       | 送付者モデル           | Yes         | Object | Sender address details                                           |
| ItemModelList     | 商品モデルリスト       | Yes         | Array  | Product list                                                     |
| dropOffLocation   | 置き配場所             | No          | String | Drop-off location. See [Drop-off Locations](#drop-off-locations) |

#### Drop-off Locations

| Value            | Description                  |
| ---------------- | ---------------------------- |
| 利用しない       | Not used                     |
| 宅配ボックス     | Delivery box                 |
| 玄関前           | Front entrance               |
| 玄関前鍵付容器   | Locked container at entrance |
| メーターボックス | Meter box                    |
| 物置             | Storage shed                 |
| 車庫             | Garage                       |

**Notes:**

- No parameter: Value not updated
- Empty value: Existing value deleted
- Null or empty string: Sets to "利用しない"

#### Level 3: SenderModel

| Parameter      | Japanese       | Required | Type   | Description                                                                            |
| -------------- | -------------- | -------- | ------ | -------------------------------------------------------------------------------------- |
| zipCode1       | 郵便番号 1     | Yes      | String | Postal code part 1 (combined max 20 bytes)                                             |
| zipCode2       | 郵便番号 2     | Yes      | String | Postal code part 2                                                                     |
| prefecture     | 都道府県       | Yes      | String | Prefecture (max 127 chars). Must be valid 47 prefectures or "国外" for domestic orders |
| city           | 郡市区         | Yes      | String | City/ward (max 127 chars)                                                              |
| subAddress     | それ以降の住所 | Yes      | String | Street address (max 127 chars)                                                         |
| familyName     | 姓             | Yes      | String | Family name (max 127 chars)                                                            |
| firstName      | 名             | No       | String | First name (max 127 chars)                                                             |
| familyNameKana | 姓カナ         | No       | String | Family name kana (max 127 chars)                                                       |
| firstNameKana  | 名カナ         | No       | String | First name kana (max 127 chars)                                                        |
| phoneNumber1   | 電話番号 1     | Yes      | String | Phone part 1 (total max 32 bytes)                                                      |
| phoneNumber2   | 電話番号 2     | Yes      | String | Phone part 2                                                                           |
| phoneNumber3   | 電話番号 3     | Yes      | String | Phone part 3                                                                           |

#### Level 3: ItemModel

| Parameter                        | Japanese           | Required | Type   | Description                                                                 |
| -------------------------------- | ------------------ | -------- | ------ | --------------------------------------------------------------------------- |
| itemDetailId                     | 商品明細 ID        | Yes      | Number | Item detail ID                                                              |
| itemName                         | 商品名             | Yes      | String | Product name (max 1000 chars)                                               |
| itemNumber                       | 商品番号           | No       | String | Product number (max 125 chars)                                              |
| price                            | 単価               | Yes      | Number | Unit price (0-999999999)                                                    |
| taxRate                          | 商品税率           | Yes      | Number | `0`, `0.0`, `0.08`, `0.1`                                                   |
| units                            | 個数               | Yes      | Number | Quantity (0-999999999)                                                      |
| includePostageFlag               | 送料込別           | Yes      | Number | `0`: Shipping separate, `1`: Shipping included                              |
| includeTaxFlag                   | 税込別             | Yes      | Number | `0`: Tax excluded, `1`: Tax included                                        |
| includeCashOnDeliveryPostageFlag | 代引手数料込別     | Yes      | Number | `0`: COD fee separate, `1`: COD fee included                                |
| selectedChoice                   | 項目・選択肢       | No       | String | Options/choices (max 4000 chars)                                            |
| restoreInventoryFlag             | 在庫連動オプション | No       | Number | `0`: Follow product setting (default), `1`: Sync inventory, `2`: Don't sync |
| deleteItemFlag                   | 商品削除フラグ     | No       | Number | `0`: Keep (default), `1`: Delete                                            |
| SkuModelList                     | SKU モデルリスト   | No       | Array  | SKU details (for SKU-migrated orders)                                       |

#### Level 2: CouponModel

| Parameter   | Japanese              | Required | Type   | Description                                                 |
| ----------- | --------------------- | -------- | ------ | ----------------------------------------------------------- |
| couponCode  | クーポンコード        | Yes      | String | Coupon code                                                 |
| couponPrice | クーポン割引単価      | Yes      | Number | Discount per unit                                           |
| couponUnit  | クーポン利用数        | Yes      | Number | Usage count (cannot increase)                               |
| itemId      | クーポン対象の商品 ID | Yes      | Number | Target product ID. Use `0` for non-product-specific coupons |

#### Level 4: SkuModel

| Parameter            | Japanese                | Required | Type   | Description                                                     |
| -------------------- | ----------------------- | -------- | ------ | --------------------------------------------------------------- |
| variantId            | SKU 管理番号            | Yes      | String | SKU variant ID (cannot be changed)                              |
| merchantDefinedSkuId | システム連携用 SKU 番号 | No       | String | Merchant SKU ID (only for SKU-migrated orders)                  |
| skuInfo              | SKU 情報                | No       | String | SKU info (required for multi-SKU, only for SKU-migrated orders) |

## Response

### HTTP Status Codes

| Code | Status                | Description                     |
| ---- | --------------------- | ------------------------------- |
| 200  | OK                    | Success                         |
| 400  | Bad Request           | Invalid request                 |
| 404  | Not Found             | Order not found                 |
| 405  | Method Not Allowed    | Invalid HTTP method             |
| 500  | Internal Server Error | Server error                    |
| 503  | Service Unavailable   | Service temporarily unavailable |

### Response Parameters

| Parameter        | Japanese               | Type  | Description      |
| ---------------- | ---------------------- | ----- | ---------------- |
| MessageModelList | メッセージモデルリスト | Array | List of messages |

#### MessageModel

| Parameter   | Japanese         | Type   | Description                |
| ----------- | ---------------- | ------ | -------------------------- |
| messageType | メッセージ種別   | String | `INFO`, `ERROR`, `WARNING` |
| messageCode | メッセージコード | String | Message code               |
| message     | メッセージ       | String | Message text               |
| orderNumber | 注文番号         | String | Order number (optional)    |

## Examples

### Success: Update with SKU Information

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-1241583267",
    "PackageModelList": [
      {
        "basketId": 10666496,
        "postagePrice": 100,
        "postageTaxRate": 0.1,
        "deliveryPrice": 100,
        "deliveryTaxRate": 0.1,
        "noshi": "出産祝い",
        "packageDeleteFlag": 0,
        "SenderModel": {
          "zipCode1": "140",
          "zipCode2": "0002",
          "prefecture": "東京都",
          "city": "世田谷区",
          "subAddress": "玉川一丁目14番1号",
          "familyName": "楽天",
          "firstName": "太郎",
          "familyNameKana": "ラクテン",
          "firstNameKana": "タロウ",
          "phoneNumber1": "03",
          "phoneNumber2": "1234",
          "phoneNumber3": "5678"
        },
        "ItemModelList": [
          {
            "itemDetailId": 10666496,
            "itemName": "シングル、項目選択肢あり×２",
            "itemNumber": "12345",
            "price": 1000,
            "taxRate": 0.1,
            "units": 1,
            "includePostageFlag": 1,
            "includeTaxFlag": 0,
            "includeCashOnDeliveryPostageFlag": 1,
            "selectedChoice": "確認項目:了承しました\n名入れ:しません",
            "restoreInventoryFlag": 0,
            "deleteItemFlag": 0,
            "SkuModelList": [
              {
                "variantId": "normal-inventory",
                "merchantDefinedSkuId": null,
                "skuInfo": null
              }
            ]
          },
          {
            "itemDetailId": 10666497,
            "itemName": "マルチ、項目選択肢あり×２",
            "itemNumber": "123456",
            "price": 1000,
            "taxRate": 0.1,
            "units": 1,
            "includePostageFlag": 1,
            "includeTaxFlag": 0,
            "includeCashOnDeliveryPostageFlag": 1,
            "selectedChoice": "名入れ：しません\n確認項目:了承しました。",
            "restoreInventoryFlag": 0,
            "deleteItemFlag": 0,
            "SkuModelList": [
              {
                "variantId": "201",
                "merchantDefinedSkuId": "horizontalvertical",
                "skuInfo": "size:S\ncolor:Red"
              }
            ]
          }
        ],
        "dropOffLocation": "宅配ボックス"
      }
    ]
}'
```

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSENDER_INFO_101",
      "message": "送付先情報の更新設定が完了しました。",
      "orderNumber": "123456-20180101-1241583267"
    }
  ]
}
```

### Success: Change Payment to 7-Eleven Prepay with Wrapping

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-1241583267",
    "afterSettlementMethodCode": 13,
    "WrappingModel1": {
      "title": 2,
      "name": "赤いリボン",
      "price": "150",
      "taxRate": 0.1,
      "includeTaxFlag": 1,
      "deleteWrappingFlag": 0
    },
    "PackageModelList": [
      {
        "basketId": 10666496,
        "postagePrice": 100,
        "postageTaxRate": 0.1,
        "deliveryPrice": 0,
        "deliveryTaxRate": 0.1,
        "noshi": "出産祝い",
        "packageDeleteFlag": 0,
        "SenderModel": {
          "zipCode1": "140",
          "zipCode2": "0002",
          "prefecture": "東京都",
          "city": "世田谷区",
          "subAddress": "玉川一丁目14番1号",
          "familyName": "楽天",
          "firstName": "太郎",
          "familyNameKana": "ラクテン",
          "firstNameKana": "タロウ",
          "phoneNumber1": "03",
          "phoneNumber2": "1234",
          "phoneNumber3": "5678"
        },
        "ItemModelList": [
          {
            "itemDetailId": 10666496,
            "itemName": "商品名",
            "itemNumber": "ITEM_NUMBER",
            "price": 1000,
            "taxRate": 0.1,
            "units": 2,
            "includePostageFlag": 1,
            "includeTaxFlag": 0,
            "includeCashOnDeliveryPostageFlag": 1,
            "selectedChoice": "項目選択肢Ａ: 項目選択肢Ａの１",
            "restoreInventoryFlag": 0,
            "deleteItemFlag": 0
          }
        ]
      }
    ]
}'
```

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSENDER_INFO_101",
      "message": "送付先情報の更新設定が完了しました。",
      "orderNumber": "123456-20180101-1241583267"
    }
  ]
}
```

### Error: Multi-SKU Missing skuInfo

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-1241583267",
    "PackageModelList": [
      {
        "basketId": 10666496,
        "SenderModel": { ... },
        "ItemModelList": [
          {
            "itemDetailId": 10666497,
            "SkuModelList": [
              {
                "variantId": "201",
                "merchantDefinedSkuId": "horizontalvertical",
                "skuInfo": null
              }
            ]
          }
        ]
      }
    ]
}'
```

**Response (400 Bad Request):**

```json
{
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSENDER_ERROR_139",
      "message": "マルチSKUの場合、SKU情報は必須です。"
    }
  ]
}
```

### Error: Missing COD Fee When Changing to COD Payment

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-1241583267",
    "afterSettlementMethodCode": 2,
    "PackageModelList": [
      {
        "basketId": 10666496,
        "deliveryPrice": -9999,
        "ItemModelList": [
          {
            "itemDetailId": 10666496,
            "includeCashOnDeliveryPostageFlag": 0
          }
        ]
      }
    ]
}'
```

**Response (400 Bad Request):**

```json
{
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSENDER_ERROR_136",
      "message": "支払方法を代金引換に変更する場合、代引料の設定が必須となります。代引料を設定し、再度リクエストを行ってください。",
      "orderNumber": "123456-20180101-1241583267"
    }
  ]
}
```

## Message Codes

| Code                                       | Type  | Description                                           |
| ------------------------------------------ | ----- | ----------------------------------------------------- |
| ORDER_EXT_API_UPDATE_ORDERSENDER_INFO_101  | INFO  | 送付先情報の更新設定が完了しました (Update completed) |
| ORDER_EXT_API_UPDATE_ORDERSENDER_ERROR_136 | ERROR | COD fee required when changing to COD payment         |
| ORDER_EXT_API_UPDATE_ORDERSENDER_ERROR_139 | ERROR | skuInfo required for multi-SKU products               |

## Important Notes

1. **SKU Project Fields**: Fields related to SKU are highlighted (green background in original docs)
2. **Tax Recalculation**: The `taxRecalcFlag` is deprecated after July 2019 tax reform
3. **Consumption Tax**: The `goodsTax` field cannot be updated after July 2019
4. **Payment Method Changes**: Complex rules apply - review the payment method section carefully
5. **Null Value Pattern**: Use `-9999` to explicitly set numeric fields to null
6. **Inventory Sync**: Use `restoreInventoryFlag` to control inventory synchronization behavior
7. **Alipay Restriction**: Cannot change to Alipay (code 16) after 2022/10/13

## Related Endpoints

- [updateOrderSenderAfterShipping](update-order-sender-after-shipping.md) - Update sender info after shipping
- [updateOrderOrderer](update-order-orderer.md) - Update orderer information
- [updateOrderDelivery](update-order-delivery.md) - Update delivery method
- [getOrder](get-order.md) - Get order details
