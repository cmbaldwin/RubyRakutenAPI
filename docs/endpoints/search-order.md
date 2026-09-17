# searchOrder (受注検索)

Search orders by various criteria. Returns list of order numbers.

**Endpoint:** `POST https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/`

## Constraints

- Maximum 15,000 results (orders 15,001+ cannot be retrieved)
- Date range: Up to 730 days (2 years) in the past
- Date span: Maximum 63 days between start and end
- Results per page: Maximum 1,000

## Request Headers

| Key           | Value                                  |
| ------------- | -------------------------------------- |
| Authorization | `ESA Base64(serviceSecret:licenseKey)` |
| Content-Type  | `application/json; charset=utf-8`      |

## Request Parameters

### Level 1: Base

| Parameter                 | Japanese                 | Required | Type           | Description                                                                                                                         |
| ------------------------- | ------------------------ | -------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `orderProgressList`       | ステータスリスト         | no       | List\<Number\> | Status codes: 100/200/300/400/500/600/700/800/900                                                                                   |
| `subStatusIdList`         | サブステータス ID リスト | no       | List\<Number\> | Custom sub-statuses. Use `[-1]` for orders without sub-status (requires `orderProgressList`)                                        |
| `dateType`                | 期間検索種別             | **yes**  | Number         | 1=注文日, 2=注文確認日, 3=注文確定日, 4=発送日, 5=発送完了報告日, 6=決済確定日                                                      |
| `startDatetime`           | 期間検索開始日時         | **yes**  | Datetime       | Format: `2017-10-14T00:00:00+0900`                                                                                                  |
| `endDatetime`             | 期間検索終了日時         | **yes**  | Datetime       | Must be within 63 days of start                                                                                                     |
| `orderTypeList`           | 販売種別リスト           | no       | List\<Number\> | 1=通常購入, 4=定期購入, 5=頒布会, 6=予約商品                                                                                        |
| `settlementMethod`        | 支払方法名               | no       | Number         | See payment method codes                                                                                                            |
| `deliveryName`            | 配送方法                 | no       | String         | Delivery method name                                                                                                                |
| `shippingDateBlankFlag`   | 発送日未指定有無         | no       | Number         | 0=all, 1=unspecified only                                                                                                           |
| `shippingNumberBlankFlag` | 伝票番号未指定有無       | no       | Number         | 0=all, 1=unspecified only                                                                                                           |
| `searchKeywordType`       | 検索キーワード種別       | no       | Number         | 0=none, 1=商品名, 2=商品番号, 3=メモ, 4=注文者氏名, 5=フリガナ, 6=送付先氏名, 7=SKU 管理番号, 8=システム連携用 SKU 番号, 9=SKU 情報 |
| `searchKeyword`           | 検索キーワード           | no       | String         | Max 4000 bytes                                                                                                                      |
| `mailSendType`            | 注文メールアドレス種別   | no       | Number         | 0=PC/Mobile, 1=PC, 2=Mobile                                                                                                         |
| `ordererMailAddress`      | 注文者メールアドレス     | no       | String         | Exact match                                                                                                                         |
| `phoneNumberType`         | 電話番号種別             | no       | Number         | 1=注文者, 2=送付先                                                                                                                  |
| `phoneNumber`             | 電話番号                 | no       | String         | Exact match                                                                                                                         |
| `reserveNumber`           | 申込番号                 | no       | String         | Exact match                                                                                                                         |
| `purchaseSiteType`        | 購入サイトリスト         | no       | Number         | 0=all, 1=PC, 2=Mobile, 3=Smartphone, 4=Tablet                                                                                       |
| `asurakuFlag`             | あす楽希望フラグ         | no       | Number         | 0=all, 1=あす楽 only                                                                                                                |
| `couponUseFlag`           | クーポン利用有無         | no       | Number         | 0=all, 1=with coupon only                                                                                                           |
| `drugFlag`                | 医薬品受注フラグ         | no       | Number         | 0=all, 1=with drugs only                                                                                                            |
| `overseasFlag`            | 海外カゴ注文フラグ       | no       | Number         | 0=all, 1=overseas only (deprecated after 2020/06/30)                                                                                |
| `oneDayOperationFlag`     | 注文当日出荷フラグ       | no       | Number         | 0=all, 1=same-day shipping only                                                                                                     |
| `PaginationRequestModel`  | ページングリクエスト     | no       | Object         | Pagination settings                                                                                                                 |

### Level 2: PaginationRequestModel

| Parameter              | Japanese                   | Required | Type   | Default | Description                         |
| ---------------------- | -------------------------- | -------- | ------ | ------- | ----------------------------------- |
| `requestRecordsAmount` | 1 ページあたりの取得結果数 | yes      | Number | 30      | Max 1000                            |
| `requestPage`          | リクエストページ番号       | yes      | Number | 1       | Page number                         |
| `SortModelList`        | 並び替えモデルリスト       | no       | List   | -       | Currently only order date supported |

### Level 3: SortModel

| Parameter       | Japanese     | Required | Type   | Description               |
| --------------- | ------------ | -------- | ------ | ------------------------- |
| `sortColumn`    | 並び替え項目 | yes      | Number | 1=注文日時 (only option)  |
| `sortDirection` | 並び替え方法 | yes      | Number | 1=ascending, 2=descending |

## Response Parameters

| Parameter                 | Japanese               | Type           | Description                     |
| ------------------------- | ---------------------- | -------------- | ------------------------------- |
| `MessageModelList`        | メッセージモデルリスト | List           | Status messages                 |
| `orderNumberList`         | 注文番号リスト         | List\<String\> | Order numbers (max 40960 bytes) |
| `PaginationResponseModel` | ページングレスポンス   | Object         | Pagination info                 |

### MessageModel

| Parameter     | Type   | Description            |
| ------------- | ------ | ---------------------- |
| `messageType` | String | INFO / ERROR / WARNING |
| `messageCode` | String | Error/info code        |
| `message`     | String | Human-readable message |

### PaginationResponseModel

| Parameter            | Type   | Description           |
| -------------------- | ------ | --------------------- |
| `totalRecordsAmount` | Number | Total matching orders |
| `totalPages`         | Number | Total pages           |
| `requestPage`        | Number | Current page          |

## Sample Requests/Responses

### Success with results

```bash
curl -X POST \
  https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/ \
  -H 'Authorization: ESA xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "dateType": 1,
    "startDatetime": "2017-12-14T00:00:00+0900",
    "endDatetime": "2018-01-14T00:00:00+0900",
    "PaginationRequestModel": {
        "requestRecordsAmount": 30,
        "requestPage": 1,
        "SortModelList": [
            {
                "sortColumn": 1,
                "sortDirection": 1
            }
        ]
    }
}'
```

```json
{
  "orderNumberList": [
    "123456-20180101-00068801",
    "123456-20180101-00067801",
    "123456-20180101-00062801"
  ],
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_SEARCH_ORDER_INFO_101",
      "message": "注文検索に成功しました。"
    }
  ],
  "PaginationResponseModel": {
    "totalRecordsAmount": 79,
    "totalPages": 3,
    "requestPage": 1
  }
}
```

### Success with no results

```json
{
  "orderNumberList": [],
  "MessageModelList": [
    {
      "messageType": "INFO",
      "messageCode": "ORDER_EXT_API_SEARCH_ORDER_INFO_102",
      "message": "注文検索に成功しました。(検索結果０件)"
    }
  ],
  "PaginationResponseModel": {
    "totalRecordsAmount": null,
    "totalPages": null,
    "requestPage": null
  }
}
```

### Error response (400 Bad Request)

```json
{
  "orderNumberList": null,
  "MessageModelList": [
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_SEARCH_ORDER_ERROR_009",
      "message": "dateTypeの項目を指定して下さい。"
    },
    {
      "messageType": "ERROR",
      "messageCode": "ORDER_EXT_API_SEARCH_ORDER_ERROR_011",
      "message": "startDatetimeの書式が不正です。"
    }
  ],
  "PaginationResponseModel": null
}
```

## Message Codes

| Code                                   | Type  | Description                            |
| -------------------------------------- | ----- | -------------------------------------- |
| `ORDER_EXT_API_SEARCH_ORDER_INFO_101`  | INFO  | 注文検索に成功しました                 |
| `ORDER_EXT_API_SEARCH_ORDER_INFO_102`  | INFO  | 注文検索に成功しました。(検索結果０件) |
| `ORDER_EXT_API_SEARCH_ORDER_ERROR_009` | ERROR | dateType の項目を指定して下さい        |
| `ORDER_EXT_API_SEARCH_ORDER_ERROR_011` | ERROR | startDatetime の書式が不正です         |
| `ORDER_EXT_API_SEARCH_ORDER_ERROR_023` | ERROR | (Added v5.8)                           |
