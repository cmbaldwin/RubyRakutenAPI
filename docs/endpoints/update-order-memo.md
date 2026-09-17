# updateOrderMemo (ひとことメモ更新)

Update memo, staff assignment, delivery preferences, and other order metadata. This is a **synchronous** operation.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderMemo/`

## Updatable Fields

- ひとことメモ (Memo/notes)
- 担当者 (Staff/operator)
- 利用サービス名/配送区分 (Delivery class)
- メール差込文 (Customer message for email)
- お届け日指定 (Requested delivery date)
- お届け時間帯 (Delivery time slot)
- サブステータス ID (Sub-status)

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

| Parameter          | Japanese                           | Required | Type   | Default | Description                                  |
| ------------------ | ---------------------------------- | -------- | ------ | ------- | -------------------------------------------- |
| `orderNumber`      | 注文番号                           | **yes**  | String | -       | Order number                                 |
| `subStatusId`      | サブステータス ID                  | no       | Number | -       | Sub-status ID                                |
| `deliveryClass`    | 配送区分                           | no       | Number | 0       | Delivery class (see table below)             |
| `deliveryDate`     | お届け日指定                       | no       | Date   | -       | Format: YYYY-MM-DD                           |
| `shippingTerm`     | お届け時間帯                       | no       | Number | 0       | Time slot (see table below)                  |
| `memo`             | ひとことメモ                       | no       | String | -       | Notes (max 1000 chars)                       |
| `operator`         | 担当者                             | no       | String | -       | Staff name (max 6 chars)                     |
| `mailPlugSentence` | メール差込文(お客様へのメッセージ) | no       | String | -       | Customer message for emails (max 1024 chars) |

### Delivery Class (deliveryClass)

| Code | Description     |
| ---- | --------------- |
| 0    | 選択なし (None) |
| 1    | 普通 (Normal)   |
| 2    | 冷蔵 (Chilled)  |
| 3    | 冷凍 (Frozen)   |
| 4    | その他 1        |
| 5    | その他 2        |
| 6    | その他 3        |
| 7    | その他 4        |
| 8    | その他 5        |

### Shipping Term (shippingTerm)

| Code | Description                    |
| ---- | ------------------------------ |
| 0    | なし (None)                    |
| 1    | 午前 (Morning)                 |
| 2    | 午後 (Afternoon)               |
| 9    | その他 (Other)                 |
| h1h2 | Custom time range: h1 時-h2 時 |

**Custom time format:** `h1h2` where:

- h1 = start hour (7-24)
- h2 = end hour (07-24, two digits)

Examples:

- `724` = 7:00 - 24:00
- `1014` = 10:00 - 14:00
- `2324` = 23:00 - 24:00

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

### Success - Update all fields

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderMemo/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "orderNumber": "123456-20180101-1241583267",
    "subStatusId": "3601",
    "deliveryClass": "2",
    "deliveryDate": "2018-01-15",
    "shippingTerm": 724,
    "memo": "ひとことメモです",
    "operator": "楽天担当",
    "mailPlugSentence": "お買い上げ頂きまして誠に有難うございます。"
}'
```

**Response (200 OK):**

```json
{
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERMEMO_INFO_101",
      "message": "ひとことメモ、担当者情報等の更新設定が完了しました。",
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
      "messageCode": "ORDER_EXT_API_UPDATE_ORDERMEMO_ERROR_009",
      "message": "orderNumberの項目を指定して下さい。"
    }
  ]
}
```

## Message Codes

| Code                                       | Type  | Description                                        |
| ------------------------------------------ | ----- | -------------------------------------------------- |
| `ORDER_EXT_API_UPDATE_ORDERMEMO_INFO_101`  | INFO  | ひとことメモ、担当者情報等の更新設定が完了しました |
| `ORDER_EXT_API_UPDATE_ORDERMEMO_ERROR_009` | ERROR | 必須項目が指定されていません                       |
| `ORDER_EXT_API_UPDATE_ORDERMEMO_ERROR_107` | ERROR | (Added v4.4)                                       |
| `ORDER_EXT_API_UPDATE_ORDERMEMO_ERROR_108` | ERROR | (Added v4.5)                                       |
| `ORDER_EXT_API_UPDATE_ORDERMEMO_ERROR_109` | ERROR | (Added v4.7)                                       |

## Important Notes

- Only `orderNumber` is required - all other fields are optional
- Only specified fields are updated; omitted fields remain unchanged
- Character limits apply:
  - `memo`: 1000 characters (full/half-width)
  - `operator`: 6 characters (full/half-width)
  - `mailPlugSentence`: 1024 characters (full/half-width)
- Machine-dependent characters (機種依存文字) are not allowed
