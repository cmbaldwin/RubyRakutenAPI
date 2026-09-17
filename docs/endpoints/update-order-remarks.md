# updateOrderRemarks (備考情報更新)

Update gift delivery preference and remarks/notes for an order. This is a **synchronous** operation.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderRemarks/`

## Updatable Fields

- ギフト配送 (Gift delivery preference)
- 備考 (Remarks/notes)

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

| Parameter     | Japanese   | Required                  | Type   | Description                         |
| ------------- | ---------- | ------------------------- | ------ | ----------------------------------- |
| `orderNumber` | 注文番号   | **yes**                   | String | Order number                        |
| `giftCheck`   | ギフト配送 | **yes** (one of required) | Number | 0=希望しない (No), 1=希望する (Yes) |
| `remarks`     | コメント   | **yes** (one of required) | String | Remarks/notes (max 4000 chars)      |

**Note:** At least one of `giftCheck` or `remarks` must be provided.

### Character Limits

- `remarks`: Max 4000 characters (full-width or half-width)
- Machine-dependent characters (機種依存文字) are not allowed

## Response Parameters

### Level 1: Base

| Parameter          | Type                 | Description     |
| ------------------ | -------------------- | --------------- |
| `MessageModelList` | List\<MessageModel\> | Status messages |

### Level 2: MessageModel

| Parameter     | Type   | Description            |
| ------------- | ------ | ---------------------- |
| `messageType` | String | INFO / ERROR / WARNING |
| `messageCode` | String | Message code           |
| `message`     | String | Human-readable message |
| `orderNumber` | String | Order number           |

## Sample Requests/Responses

### Success - Update gift delivery and remarks

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderRemarks/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-1241583267",
    "giftCheck": 1,
    "remarks": "[配送日時指定:]\n2018年01月23日\n\n[備考欄です:]\nなにかあればどうぞ"
}'
```

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERREMARKS_INFO_101",
      "message": "備考情報の更新設定が完了しました。",
      "orderNumber": "123456-20180101-1241583267"
    }
  ]
}
```

### Error - Missing order number

**Response (400 Bad Request):**

```json
{
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERREMARKS_ERROR_009",
      "message": "orderNumberの項目を指定して下さい。"
    }
  ]
}
```

## Message Codes

| Code                                          | Type  | Description                      |
| --------------------------------------------- | ----- | -------------------------------- |
| `ORDER_EXT_API_UPDATE_ORDERREMARKS_INFO_101`  | INFO  | 備考情報の更新設定が完了しました |
| `ORDER_EXT_API_UPDATE_ORDERREMARKS_ERROR_009` | ERROR | 必須項目が指定されていません     |

## Important Notes

- `orderNumber` is always required
- At least one of `giftCheck` or `remarks` must be provided
- The `remarks` field supports newlines (`\n`) for formatting
- Machine-dependent characters are prohibited in `remarks`
