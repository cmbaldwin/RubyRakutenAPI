# Rakuten API - Reference Codes

## Order Status Codes

| Code | Status (Japanese)  | Status (English)             |
| ---- | ------------------ | ---------------------------- |
| 100  | 注文確認待ち       | Awaiting order confirmation  |
| 200  | 楽天処理中         | Rakuten processing           |
| 300  | 発送待ち           | Awaiting shipment            |
| 400  | 変更確定待ち       | Awaiting change confirmation |
| 500  | 発送済             | Shipped                      |
| 600  | 支払手続き中       | Payment processing           |
| 700  | 支払手続き済       | Payment completed            |
| 800  | キャンセル確定待ち | Awaiting cancel confirmation |
| 900  | キャンセル確定     | Cancel confirmed             |

## Payment Methods (settlementMethod)

| Code | Method                                              |
| ---- | --------------------------------------------------- |
| 1    | クレジットカード (Credit card)                      |
| 2    | 代金引換 (Cash on delivery)                         |
| 4    | 銀行振込 (Bank transfer)                            |
| 5    | コンビニ決済 (Convenience store)                    |
| 6    | Apple Pay                                           |
| 9    | PayPal                                              |
| 10   | Alipay (支付宝)                                     |
| 14   | ゆうちょ Pay-easy (Service ended - v8.2)            |
| 21   | 後払い決済（楽天市場の共通決済） (Deferred payment) |

## Delivery Companies (配送会社)

Current supported carriers (as of v7.9, 2025/06):

| Code | Company                                                       |
| ---- | ------------------------------------------------------------- |
| 1000 | その他                                                        |
| 1001 | ヤマト運輸 (Yamato)                                           |
| 1002 | 佐川急便 (Sagawa)                                             |
| 1003 | 日本郵便 (Japan Post)                                         |
| 1004 | 西濃運輸 (Seino)                                              |
| 1005 | セイノースーパーエクスプレス (Seino Super Express)            |
| 1006 | 福山通運 (Fukuyama)                                           |
| 1015 | NX トランスポート (NX Transport) - Renamed from 日通 in v6.2  |
| 1028 | Rakuten EXPRESS                                               |
| 1029 | 日本郵便 楽天倉庫出荷 (Japan Post - Rakuten Warehouse) - v7.8 |
| 1030 | ヤマト運輸 クロネコゆうパケット (Yamato Yu-Packet) - v7.9     |
| 1031 | 名鉄 NX 運輸 (Meitetsu NX) - v7.9                             |

Other options:

- 自社配送 (Self-delivery)
- バイク便 (Motorcycle courier)
- その他配送方法１～３ (Other delivery methods 1-3)

## Order Type (orderType)

| Code | Type     |
| ---- | -------- |
| 1    | 通常購入 |
| 4    | 定期購入 |
| 5    | 頒布会   |
| 6    | 予約商品 |

## Date Type for Search (dateType)

| Code | Type           |
| ---- | -------------- |
| 1    | 注文日         |
| 2    | 注文確認日     |
| 3    | 注文確定日     |
| 4    | 発送日         |
| 5    | 発送完了報告日 |
| 6    | 決済確定日     |

## Search Keyword Type (searchKeywordType)

| Code | Type                    |
| ---- | ----------------------- |
| 0    | None                    |
| 1    | 商品名                  |
| 2    | 商品番号                |
| 3    | メモ                    |
| 4    | 注文者氏名              |
| 5    | フリガナ                |
| 6    | 送付先氏名              |
| 7    | SKU 管理番号            |
| 8    | システム連携用 SKU 番号 |
| 9    | SKU 情報                |

## Carrier Code (Device Type)

| Code | Device         |
| ---- | -------------- |
| 0    | PC             |
| 11   | iPhone         |
| 12   | Android        |
| 13   | iPad           |
| 14   | Android Tablet |
| 21   | Feature phone  |

## Email Carrier Code

| Code | Carrier  |
| ---- | -------- |
| 0    | PC       |
| 1    | DoCoMo   |
| 2    | au       |
| 3    | SoftBank |
| 99   | Other    |

## Card Payment Type (cardPayType)

| Code | Type         |
| ---- | ------------ |
| 0    | 一括払い     |
| 1    | リボ払い     |
| 2    | 分割払い     |
| 3    | その他       |
| 4    | ボーナス一括 |

## Change Type (changeType)

| Code | Type        |
| ---- | ----------- |
| 0    | cancel 申請 |
| 1    | cancel 確定 |
| 4    | 変更申請    |

## Change Type Detail (changeTypeDetail)

| Code | Detail       |
| ---- | ------------ |
| 0    | 減額         |
| 1    | 増額         |
| 2    | その他       |
| 10   | 支払方法変更 |
| 11   | 支払方法変更 |
| 12   | 支払方法変更 |

## Change Reason (changeReason)

| Code | Reason     |
| ---- | ---------- |
| 0    | 店舗都合   |
| 1    | お客様都合 |

## HTTP Status Codes

| Code | Status                | Description              |
| ---- | --------------------- | ------------------------ |
| 200  | OK                    | Success                  |
| 400  | Bad Request           | Invalid request          |
| 404  | Not Found             | Endpoint not found       |
| 405  | Method Not Allowed    | Wrong HTTP method        |
| 500  | Internal Server Error | Server error             |
| 503  | Service Unavailable   | Service down/maintenance |

## Message Types

| Type    | Description |
| ------- | ----------- |
| INFO    | Success     |
| WARNING | Warning     |
| ERROR   | Error       |
