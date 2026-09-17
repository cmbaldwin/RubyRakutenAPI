# getResultUpdateOrderShippingAsync (発送完了報告 - 非同期結果確認)

Check the results of an asynchronous shipping update request. This is a **synchronous** operation.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/getResultUpdateOrderShippingAsync/`

## Use Cases

- Check if async shipping update has completed
- Get detailed results per order after bulk update
- Retrieve newly assigned `shippingDetailId` values

## Important Notes

- **Results available for 30 days** after the async request was submitted
- If processing is not yet complete, returns "result does not exist" message
- Same message returned if `requestId` is invalid or expired

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

| Parameter   | Japanese      | Required | Type   | Description                                         |
| ----------- | ------------- | -------- | ------ | --------------------------------------------------- |
| `requestId` | リクエスト ID | **yes**  | String | Request ID from `updateOrderShippingAsync` response |

## Response Parameters

### Level 1: Base

| Parameter                 | Type                        | Description       |
| ------------------------- | --------------------------- | ----------------- |
| `ResultShippingModelList` | List\<ResultShippingModel\> | Results per order |

### Level 2: ResultShippingModel

| Parameter          | Type                 | Description                     |
| ------------------ | -------------------- | ------------------------------- |
| `orderNumber`      | String               | Order number (if results exist) |
| `MessageModelList` | List\<MessageModel\> | Status messages for this order  |

### Level 3: MessageModel

| Parameter          | Type   | Description                                           |
| ------------------ | ------ | ----------------------------------------------------- |
| `messageType`      | String | INFO / ERROR / WARNING                                |
| `messageCode`      | String | Message code                                          |
| `message`          | String | Human-readable message                                |
| `dataNumber`       | Number | Index in original request (1-based)                   |
| `shippingDetailId` | Number | Existing ID if specified, or new ID for added records |

## Sample Requests/Responses

### Success - All orders processed successfully

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/getResultUpdateOrderShippingAsync/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "requestId": "ede66c43-9b9d-4222-93ed-5f11c96e08e2_20180101120000"
}'
```

**Response (200 OK):**

```json
{
  "ResultShippingModelList": [
    {
      "orderNumber": "123456-20180101-00001801",
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
          "shippingDetailId": 15421
        }
      ]
    },
    {
      "orderNumber": "123456-20180101-00001901",
      "MessageModelList": [
        {
          "messageType": "INFO",
          "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_102",
          "message": "発送情報の更新設定が完了しました。",
          "dataNumber": 1,
          "shippingDetailId": 15420
        }
      ]
    }
  ]
}
```

### Partial Success - Some orders have errors

```json
{
  "ResultShippingModelList": [
    {
      "orderNumber": "123456-20180101-00001801",
      "MessageModelList": [
        {
          "messageType": "ERROR",
          "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_ERROR_102",
          "message": "指定された注文番号は既にキャンセルされているため、発送完了報告が出来る状態ではありませんでした。",
          "dataNumber": null,
          "shippingDetailId": null
        }
      ]
    },
    {
      "orderNumber": "123456-20180101-00001901",
      "MessageModelList": [
        {
          "messageType": "INFO",
          "messageCode": "ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_102",
          "message": "発送情報の更新設定が完了しました。",
          "dataNumber": 1,
          "shippingDetailId": 15420
        }
      ]
    }
  ]
}
```

### Processing Not Complete or Request ID Not Found

```json
{
  "ResultShippingModelList": [
    {
      "MessageModelList": [
        {
          "messageType": "INFO",
          "messageCode": "ORDER_EXT_API_GET_RESULT_UPDATEORDERSHIPPING_ASYNC_INFO_101",
          "message": "指定されたリクエストIDの処理結果は存在しませんでした。"
        }
      ]
    }
  ]
}
```

This response indicates one of:

- Async processing is still in progress
- Request ID is invalid
- Request ID has expired (older than 30 days)

### Error - Missing requestId

**Response (400 Bad Request):**

```json
{
  "ResultShippingModelList": [
    {
      "MessageModelList": [
        {
          "messageType": "ERROR",
          "messageCode": "ORDER_EXT_API_GET_RESULT_UPDATEORDERSHIPPING_ASYNC_ERROR_009",
          "message": "requestIdの項目を指定して下さい。"
        }
      ]
    }
  ]
}
```

## Message Codes

| Code                                                           | Type  | Description                                     |
| -------------------------------------------------------------- | ----- | ----------------------------------------------- |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_101`                  | INFO  | 発送情報の追加設定が完了しました                |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_INFO_102`                  | INFO  | 発送情報の更新設定が完了しました                |
| `ORDER_EXT_API_UPDATE_ORDERSHIPPING_ERROR_102`                 | ERROR | 注文がキャンセル済みのため発送完了報告不可      |
| `ORDER_EXT_API_GET_RESULT_UPDATEORDERSHIPPING_ASYNC_INFO_101`  | INFO  | 処理結果が存在しない（処理中/ID 不正/期限切れ） |
| `ORDER_EXT_API_GET_RESULT_UPDATEORDERSHIPPING_ASYNC_ERROR_009` | ERROR | requestId の項目を指定して下さい                |

## Workflow

```
1. Call updateOrderShippingAsync
   └── Returns: requestId

2. Poll getResultUpdateOrderShippingAsync with requestId
   ├── "INFO_101" (result does not exist) → Wait and retry
   └── Results returned → Process per-order results

3. Check each order's MessageModelList
   ├── INFO messages → Success, get new shippingDetailId
   └── ERROR messages → Handle failures
```

## Polling Strategy

Since there's no way to distinguish between "still processing" and "invalid requestId":

1. Store the `requestId` and submission timestamp
2. Poll periodically (e.g., every 5-30 seconds depending on batch size)
3. Set a maximum wait time based on expected processing time
4. If "INFO_101" returned after max wait, assume failure and investigate
