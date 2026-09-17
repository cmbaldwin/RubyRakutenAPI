# updateOrderSubStatus (サブステータス情報更新)

Bulk update sub-status for multiple Rakuten Pay orders. This is a **synchronous** operation.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSubStatus/`

## Use Cases

- Assign custom workflow status to orders (e.g., "Awaiting stock", "Ready to ship")
- Clear sub-status from orders
- Bulk update multiple orders to the same sub-status

## Related Endpoint

Use `getSubStatusList` to retrieve available sub-status IDs for your shop.

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

| Parameter         | Japanese          | Required | Type           | Description                                 |
| ----------------- | ----------------- | -------- | -------------- | ------------------------------------------- |
| `subStatusId`     | サブステータス ID | **yes**  | Number         | Sub-status ID to assign, or `null` to clear |
| `orderNumberList` | 注文番号リスト    | **yes**  | List\<String\> | Max 100 orders per request                  |

## Response Parameters

### Level 1: Base

| Parameter          | Type                 | Description     |
| ------------------ | -------------------- | --------------- |
| `MessageModelList` | List\<MessageModel\> | Status messages |

### Level 2: MessageModel

| Parameter     | Type   | Description                      |
| ------------- | ------ | -------------------------------- |
| `messageType` | String | INFO / ERROR / WARNING           |
| `messageCode` | String | Message code                     |
| `message`     | String | Human-readable message           |
| `orderNumber` | String | Order number this message is for |

## Sample Requests/Responses

### Success - All orders updated

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSubStatus/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "subStatusId": 3423,
    "orderNumberList": ["123456-20180101-00111801", "123456-20180101-00112801", "123456-20180101-00113801"]
}'
```

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_INFO_101",
      "message": "サブステータスの更新設定が完了しました。",
      "orderNumber": "123456-20180101-00111801"
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_INFO_101",
      "message": "サブステータスの更新設定が完了しました。",
      "orderNumber": "123456-20180101-00112801"
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_INFO_101",
      "message": "サブステータスの更新設定が完了しました。",
      "orderNumber": "123456-20180101-00113801"
    }
  ]
}
```

### Partial Success - Some orders failed

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_INFO_101",
      "message": "サブステータスの更新設定が完了しました。",
      "orderNumber": "123456-20180101-00111801"
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_102",
      "message": "指定された注文番号、サブステータスでは更新できません。",
      "orderNumber": "123456-20180101-00112801"
    },
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_INFO_101",
      "message": "サブステータスの更新設定が完了しました。",
      "orderNumber": "123456-20180101-00113801"
    }
  ]
}
```

### All Failed - Various error reasons

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_102",
      "message": "指定された注文番号、サブステータスでは更新できません。",
      "orderNumber": "123456-20180101-00111801"
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_102",
      "message": "指定された注文番号、サブステータスでは更新できません。",
      "orderNumber": "123456-20180101-00112801"
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_101",
      "message": "指定された注文番号は既にキャンセルされているため、サブステータスの更新が出来る状態ではありませんでした。",
      "orderNumber": "123456-20180101-00113801"
    }
  ]
}
```

### Error - Missing required parameters

**Response (400 Bad Request):**

```json
{
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_009",
      "message": "subStatusIdの項目を指定して下さい。"
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_009",
      "message": "orderNumberListの項目を指定して下さい。"
    }
  ]
}
```

### Clear Sub-Status

To remove sub-status from orders, set `subStatusId` to `null`:

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSubStatus/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "subStatusId": null,
    "orderNumberList": ["123456-20180101-00111801"]
}'
```

## Message Codes

| Code                                            | Type  | Description                                    |
| ----------------------------------------------- | ----- | ---------------------------------------------- |
| `ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_INFO_101`  | INFO  | サブステータスの更新設定が完了しました         |
| `ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_009` | ERROR | 必須項目が指定されていません                   |
| `ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_101` | ERROR | 注文がキャンセル済みのため更新不可             |
| `ORDER_EXT_API_UPDATE_ORDERSUBSTATUS_ERROR_102` | ERROR | 指定された注文番号、サブステータスでは更新不可 |

## Important Notes

- Returns **200 OK** even when some/all orders fail - check `MessageModelList` for per-order results
- Cannot update sub-status on cancelled orders (status 900)
- Sub-status IDs are shop-specific - use `getSubStatusList` to get valid IDs
- Max 100 orders per request
