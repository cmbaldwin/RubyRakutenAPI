# updateOrderShippingAsync (発送完了報告 - 非同期)

Add, update, or delete shipping information for Rakuten Pay orders. This is an **asynchronous** operation for bulk updates.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShippingAsync/`

## Use Cases

- Bulk update shipping info for multiple orders at once
- Non-blocking updates when processing large batches
- Use with `getResultUpdateOrderShippingAsync` to check results

## Sync vs Async Comparison

| Aspect             | updateOrderShipping (Sync) | updateOrderShippingAsync (Async)        |
| ------------------ | -------------------------- | --------------------------------------- |
| Orders per request | 1                          | Up to 100                               |
| Response           | Immediate result           | Returns `requestId`                     |
| Result retrieval   | In response                | Via `getResultUpdateOrderShippingAsync` |
| Best for           | Single order updates       | Bulk processing                         |

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

### Level 1: Base

| Parameter                | Japanese             | Required | Type                       | Description                                     |
| ------------------------ | -------------------- | -------- | -------------------------- | ----------------------------------------------- |
| `OrderShippingModelList` | 注文番号モデルリスト | **yes**  | List\<OrderShippingModel\> | Max 100 orders. Duplicate order numbers = error |

### Level 2: OrderShippingModel

| Parameter           | Japanese           | Required | Type                  | Description      |
| ------------------- | ------------------ | -------- | --------------------- | ---------------- |
| `orderNumber`       | 注文番号           | **yes**  | String                | Order number     |
| `BasketidModelList` | 送付先モデルリスト | **yes**  | List\<BasketidModel\> | Destination list |

### Level 3: BasketidModel

| Parameter           | Japanese         | Required | Type                  | Description                      |
| ------------------- | ---------------- | -------- | --------------------- | -------------------------------- |
| `basketId`          | 送付先 ID        | **yes**  | Number                | Destination ID (max 10 digits)   |
| `ShippingModelList` | 発送モデルリスト | **yes**  | List\<ShippingModel\> | Max 20 shipping records per dest |

### Level 4: ShippingModel

| Parameter            | Japanese           | Required | Type   | Description                                                   |
| -------------------- | ------------------ | -------- | ------ | ------------------------------------------------------------- |
| `shippingDetailId`   | 発送明細 ID        | no       | Number | Omit to add new, specify to update/delete                     |
| `deliveryCompany`    | 配送会社           | no       | String | Carrier code. Required if param is present                    |
| `shippingNumber`     | お荷物伝票番号     | no       | String | Tracking number (max 120 chars). Omit=no change, empty=delete |
| `shippingDate`       | 発送日             | no       | Date   | Format: YYYY-MM-DD. Omit=no change, empty=delete              |
| `shippingDeleteFlag` | 発送情報削除フラグ | no       | Number | 0=don't delete (default), 1=delete shipping info              |

### Delivery Company Codes

See [update-order-shipping.md](update-order-shipping.md#delivery-company-codes) for full list.

Common codes:
| Code | Company |
| ---- | -------------- |
| 1001 | ヤマト運輸 |
| 1002 | 佐川急便 |
| 1003 | 日本郵便 |

## Response Parameters

### Level 1: Base

| Parameter          | Type                 | Description     |
| ------------------ | -------------------- | --------------- |
| `MessageModelList` | List\<MessageModel\> | Status messages |

### Level 2: MessageModel

| Parameter          | Type   | Description                                    |
| ------------------ | ------ | ---------------------------------------------- |
| `messageType`      | String | INFO / ERROR / WARNING                         |
| `messageCode`      | String | Message code                                   |
| `message`          | String | Human-readable message                         |
| `requestId`        | String | Request ID for checking results (success only) |
| `orderNumber`      | String | Order number (error only)                      |
| `dataNumber`       | Number | Index in request (error only, 1-based)         |
| `shippingDetailId` | Number | Shipping detail ID if specified (error only)   |

## Sample Requests/Responses

### Success - Async request accepted

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShippingAsync/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "OrderShippingModelList": [
        {
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
                        }
                    ]
                }
            ]
        },
        {
            "orderNumber": "123456-20180101-00001901",
            "BasketidModelList": [
                {
                    "basketId": 10746404,
                    "ShippingModelList": [
                        {
                            "shippingDetailId": 15420,
                            "deliveryCompany": "1001",
                            "shippingNumber": "SN111111",
                            "shippingDate": "2018-01-25"
                        }
                    ]
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
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_ASYNC_INFO_101",
      "message": "発送情報の更新を受付けました。",
      "requestId": "ede66c43-9b9d-4222-93ed-5f11c96e08e2_20180101120000",
      "dataNumber": null,
      "shippingDetailId": null
    }
  ]
}
```

### Error - Invalid parameters (validation errors)

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShippingAsync/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "OrderShippingModelList": [
        {
            "orderNumber": "123456-20180101-00001801",
            "BasketidModelList": [
                {
                    "basketId": 10746402,
                    "ShippingModelList": [
                        {
                            "shippingDetailId": 15419,
                            "shippingDate": "2018/01/25"
                        },
                        {
                            "deliveryCompany": "佐川急便"
                        }
                    ]
                }
            ]
        }
    ]
}'
```

**Response (200 OK with errors):**

```json
{
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_ASYNC_ERROR_011",
      "message": "shippingDateの書式が不正です。",
      "orderNumber": "123456-20180101-00001801",
      "dataNumber": 1,
      "shippingDetailId": 15419
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_ASYNC_ERROR_011",
      "message": "deliveryCompanyの書式が不正です。",
      "orderNumber": "123456-20180101-00001801",
      "dataNumber": 2,
      "shippingDetailId": null
    }
  ]
}
```

## Message Codes

| Code                                                 | Type  | Description                  |
| ---------------------------------------------------- | ----- | ---------------------------- |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_ASYNC_INFO_101`  | INFO  | 発送情報の更新を受付けました |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_ASYNC_ERROR_011` | ERROR | 書式が不正です               |

## Workflow

1. **Submit async request** → Receive `requestId`
2. **Poll for results** using `getResultUpdateOrderShippingAsync` with the `requestId`
3. **Results available for 30 days** after submission

## Important Notes

- Duplicate order numbers in a single request will cause an error
- Validation errors are returned immediately (no `requestId`)
- If request is accepted, actual processing errors are only visible via `getResultUpdateOrderShippingAsync`
- Max 100 orders per request
- Max 20 shipping records per destination (basketId)
