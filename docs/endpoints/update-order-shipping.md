# updateOrderShipping (発送完了報告)

Add or update shipping information for Rakuten Pay orders. This is a synchronous operation.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShipping/`

## Use Cases

- Add new shipping/tracking information to an order
- Update existing shipping details (tracking number, carrier, ship date)
- Delete shipping information

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

### Level 1: Base

| Parameter           | Japanese           | Required | Type                  | Description                        |
| ------------------- | ------------------ | -------- | --------------------- | ---------------------------------- |
| `orderNumber`       | 注文番号           | **yes**  | String                | e.g., "341680-22222222-1241583267" |
| `BasketidModelList` | 送付先モデルリスト | **yes**  | List\<BasketidModel\> | Destination list                   |

### Level 2: BasketidModel

| Parameter           | Japanese         | Required | Type                  | Description                      |
| ------------------- | ---------------- | -------- | --------------------- | -------------------------------- |
| `basketId`          | 送付先 ID        | **yes**  | Number                | Destination ID (max 10 digits)   |
| `ShippingModelList` | 発送モデルリスト | **yes**  | List\<ShippingModel\> | Max 20 shipping records per dest |

### Level 2: ShippingModel

| Parameter            | Japanese           | Required | Type   | Description                                                            |
| -------------------- | ------------------ | -------- | ------ | ---------------------------------------------------------------------- |
| `shippingDetailId`   | 発送明細 ID        | no       | Number | Omit to add new, specify to update/delete                              |
| `deliveryCompany`    | 配送会社           | no       | String | Carrier code (see table below). Required if param is present           |
| `shippingNumber`     | お荷物伝票番号     | no       | String | Tracking number (max 120 chars). Omit=no change, empty=""=delete value |
| `shippingDate`       | 発送日             | no       | Date   | Format: YYYY-MM-DD. Omit=no change, empty=delete value                 |
| `shippingDeleteFlag` | 発送情報削除フラグ | no       | Number | 0=don't delete (default), 1=delete shipping info                       |

### Delivery Company Codes

| Code | Company                         |
| ---- | ------------------------------- |
| 1000 | その他                          |
| 1001 | ヤマト運輸                      |
| 1002 | 佐川急便                        |
| 1003 | 日本郵便                        |
| 1004 | 西濃運輸                        |
| 1005 | セイノースーパーエクスプレス    |
| 1006 | 福山通運                        |
| 1007 | 名鉄運輸                        |
| 1008 | トナミ運輸                      |
| 1009 | 第一貨物                        |
| 1010 | 新潟運輸                        |
| 1011 | 中越運送                        |
| 1012 | 岡山県貨物運送                  |
| 1013 | 久留米運送                      |
| 1014 | 山陽自動車運送                  |
| 1015 | NX トランスポート               |
| 1016 | エコ配                          |
| 1017 | EMS                             |
| 1018 | DHL                             |
| 1019 | FedEx                           |
| 1020 | UPS                             |
| 1021 | 日本通運                        |
| 1022 | TNT                             |
| 1023 | OCS                             |
| 1024 | USPS                            |
| 1025 | SF エクスプレス                 |
| 1026 | Aramex                          |
| 1027 | SGH グローバル・ジャパン        |
| 1028 | Rakuten EXPRESS                 |
| 1029 | 日本郵便 楽天倉庫出荷           |
| 1030 | ヤマト運輸 クロネコゆうパケット |
| 1031 | 名鉄 NX 運輸                    |

## Parameter Behavior

| Scenario                     | Result                     |
| ---------------------------- | -------------------------- |
| `shippingDetailId` omitted   | Add new shipping record    |
| `shippingDetailId` specified | Update existing record     |
| `shippingDeleteFlag: 1`      | Delete the shipping record |
| Parameter omitted            | Value unchanged            |
| Parameter present but empty  | Delete existing value      |

## Response Parameters

### Level 1: Base

| Parameter          | Type                 | Description     |
| ------------------ | -------------------- | --------------- |
| `MessageModelList` | List\<MessageModel\> | Status messages |

### Level 2: MessageModel

| Parameter          | Type   | Description                                           |
| ------------------ | ------ | ----------------------------------------------------- |
| `messageType`      | String | INFO / ERROR / WARNING                                |
| `messageCode`      | String | Message code                                          |
| `message`          | String | Human-readable message                                |
| `dataNumber`       | Number | Index of item in request (1-based)                    |
| `shippingDetailId` | Number | Existing ID if specified, or new ID for added records |

## Sample Requests/Responses

### Success - Add and update shipping info

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShipping/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-00001801",
    "BasketidModelList": [
        {
            "basketId": 10746402,
            "ShippingModelList": [
                {
                    "shippingDetailId": 15419,
                    "deliveryCompany": "1001",
                    "shippingNumber": "SN111111",
                    "shippingDate": "2018-01-25"
                },
                {
                    "deliveryCompany": "1001"
                },
                {
                    "deliveryCompany": "1002",
                    "shippingDate": "2018-01-30"
                },
                {
                    "deliveryCompany": "1002",
                    "shippingNumber": "SN222222"
                }
            ]
        },
        {
            "basketId": 10746403,
            "ShippingModelList": [
                {
                    "shippingDetailId": null,
                    "deliveryCompany": "1001",
                    "shippingNumber": "SN333333",
                    "shippingDate": "2018-02-01"
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
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_102",
      "message": "発送情報の更新設定が完了しました。",
      "dataNumber": 1,
      "shippingDetailId": 15419
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_101",
      "message": "発送情報の追加設定が完了しました。",
      "dataNumber": 2,
      "shippingDetailId": 15420
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_101",
      "message": "発送情報の追加設定が完了しました。",
      "dataNumber": 3,
      "shippingDetailId": 15421
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_101",
      "message": "発送情報の追加設定が完了しました。",
      "dataNumber": 4,
      "shippingDetailId": 15422
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_101",
      "message": "発送情報の追加設定が完了しました。",
      "dataNumber": 5,
      "shippingDetailId": 15423
    }
  ]
}
```

### Error - Invalid parameters

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShipping/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-00001801",
    "BasketidModelList": [
        {
            "basketId": 10746402,
            "ShippingModelList": [
                {
                    "shippingDetailId": 15419,
                    "deliveryCompany": "1001",
                    "shippingNumber": "SN111111",
                    "shippingDate": "2018/01/25"
                },
                {
                    "deliveryCompany": "佐川急便"
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
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_ERROR_011",
      "message": "shippingDateの書式が不正です。",
      "dataNumber": 1,
      "shippingDetailId": 15419
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_ERROR_011",
      "message": "deliveryCompanyの書式が不正です。",
      "dataNumber": 2,
      "shippingDetailId": null
    }
  ]
}
```

## Message Codes

| Code                                           | Type  | Description                      |
| ---------------------------------------------- | ----- | -------------------------------- |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_101`  | INFO  | 発送情報の追加設定が完了しました |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_102`  | INFO  | 発送情報の更新設定が完了しました |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_ERROR_011` | ERROR | 書式が不正です                   |

## Common Errors

| Error                          | Cause                                                |
| ------------------------------ | ---------------------------------------------------- |
| Invalid date format            | Use YYYY-MM-DD, not YYYY/MM/DD                       |
| Invalid delivery company       | Use code (e.g., "1002"), not name (e.g., "佐川急便") |
| Invalid characters in tracking | No machine-dependent characters allowed              |
| Tracking number too long       | Max 120 characters (full-width or half-width)        |
