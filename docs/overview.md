# Rakuten Pay Order API - Overview

## API Endpoints

| No  | Japanese Name                  | Endpoint                            | Description                                                                          |
| --- | ------------------------------ | ----------------------------------- | ------------------------------------------------------------------------------------ |
| 1   | 受注検索                       | `searchOrder`                       | Search orders by criteria, returns list of order numbers                             |
| 2   | 注文情報取得                   | `getOrder`                          | Get detailed order information by order number list                                  |
| 3   | 注文確認                       | `confirmOrder`                      | Confirm order and notify Rakuten to proceed with payment                             |
| 4   | 発送完了報告                   | `updateOrderShipping`               | Update shipping info (tracking number, ship date) and close order                    |
| 5   | 発送完了報告（非同期）         | `updateOrderShippingAsync`          | Bulk async shipping updates, returns requestId                                       |
| 6   | 発送完了報告（非同期）結果確認 | `getResultUpdateOrderShippingAsync` | Check async shipping update results (available for 30 days)                          |
| 7   | サブステータス情報取得         | `getSubStatusList`                  | Get list of shop-defined sub-statuses                                                |
| 8   | サブステータス情報更新         | `updateOrderSubStatus`              | Bulk update order sub-statuses                                                       |
| 9   | ひとことメモ更新               | `updateOrderMemo`                   | Update memo, staff, delivery class, customer message, delivery date/time, sub-status |
| 10  | 備考情報更新                   | `updateOrderRemarks`                | Update remarks, gift delivery preference                                             |
| 11  | 送付先情報更新（発送前）       | `updateOrderSender`                 | Update recipient/item info before shipping (status 100/200/300 only)                 |
| 12  | 送付先情報更新（発送後）       | `updateOrderSenderAfterShipping`    | Update recipient/item info after shipping (status 500/600/700)                       |
| 13  | 注文キャンセル（発送前）       | `cancelOrder`                       | Cancel before shipping (status 100/200/300)                                          |
| 14  | 注文キャンセル（発送後）       | `cancelOrderAfterShipping`          | Cancel after shipping (status 500/600/700/800) - use after confirming product return |
| 15  | 注文者情報更新                 | `updateOrderOrderer`                | Update orderer name, address, phone, email, gender, birthday                         |
| 16  | 配送方法更新                   | `updateOrderDelivery`               | Update delivery method                                                               |
| 17  | クーポン利用額シミュレーション | `simulateCouponAmount`              | Simulate coupon amount after order changes (status 100/200/300/500/600/700)          |
| 18  | 決済情報取得                   | `getPayment`                        | Get payment/billing history                                                          |

## Authentication

Uses ESA (Enterprise Service Authentication):

```
Authorization: ESA {Base64(serviceSecret:licenseKey)}
Content-Type: application/json; charset=utf-8
```

**License key validity: 90 days** (expires at 23:59:59 on the 90th day)

### Key Renewal Documentation

- Self-developed systems: https://navi-manual.faq.rakuten.net/service/000010329
- RMS Service Square products: https://navi-manual.faq.rakuten.net/service/000010190#link-07
- Third-party systems: https://navi-manual.faq.rakuten.net/service/000010322

## Rate Limiting

- **Guideline: 1 request per second**
- Traffic throttling may be applied during high load periods
- Search results limited to 15,000 orders (increased from 5,000 in v3.7)

## API Versioning (getOrder)

| Version | Feature                                                                      | Release Date |
| ------- | ---------------------------------------------------------------------------- | ------------ |
| 3       | 消費税増税対応 (Tax increase)                                                | 2019         |
| 4       | 共通の送料込みライン対応 (Free shipping line)                                | 2020/03      |
| 5       | 領収書、前払い期限版 (Receipt, prepay deadline)                              | 2020/08      |
| 6       | 顧客・配送対応注意表示詳細対応 (Customer/delivery warning details)           | 2021/11      |
| 7       | SKU 対応 (SKU support) **Current**                                           | 2023/02      |
| 8       | 最強配送フラグ、注文当日出荷フラグ (Strong delivery flag, same-day shipping) | 2024/03      |
| 9       | 置き配フラグ、置き配場所 (Drop-off delivery flag/location)                   | 2024/10      |
| 10      | ソーシャルギフト対応 (Social gift support)                                   | TBD          |

**Note:** Versions 1 and 2 were deprecated and removed in v4.2/4.3 (2020/02-03)

## Key Constraints

| Constraint                   | Limit                                  |
| ---------------------------- | -------------------------------------- |
| ShippingModelList            | Maximum 151 items per request (v2.7)   |
| Search results               | Maximum 15,000 orders (v3.7)           |
| Order number list (getOrder) | Maximum 100 per request                |
| Async results availability   | 30 days (increased from 10 days, v4.4) |
| Item quantity with coupons   | Up to 10,000 items (v5.3)              |

## Current Implementation in Funabiki

Based on `lib/Rakuten.rb` and `lib/rakuten/order.rb`:

```ruby
base_uri 'https://api.rms.rakuten.co.jp/es/2.0/'
```

- Uses HTTParty for requests
- Authorization via ESA authentication
- Processes orders in batches of 100 (API limit)
- Saves orders to `RakutenOrder` model

## Recent Changes (2024-2025)

| Version | Date       | Key Changes                                  |
| ------- | ---------- | -------------------------------------------- |
| 7.5     | 2024/03/28 | Same-day shipping flag, version 8            |
| 7.6     | 2024/07/05 | Sample updates                               |
| 7.7     | 2024/10/03 | Drop-off delivery (置き配), version 9        |
| 7.8     | 2024/11/14 | Japan Post Rakuten Warehouse carrier         |
| 7.9     | 2025/06/23 | New carriers (Yamato Yu-Packet, Meitetsu NX) |
| 8.0     | 2025/09/16 | Drop-off location for updateOrderSender      |
| 8.1     | 2025/10/23 | Social gift support, version 10              |
| 8.2     | 2025/12/01 | Pay-easy service end                         |
| 8.3     | 2025/12/12 | Test response samples removed                |

## SSL Certificate Update (March 17, 2026)

Rakuten updated the SSL certificate for `api.rms.rakuten.co.jp` on March 17, 2026.
New certificate issued by DigiCert Global G2 TLS RSA SHA256 2020 CA1 (valid through Sep 10, 2026).

**Verified on March 6, 2026:**
- Production server (OpenSSL 3.5.4, Ruby 3.4): `searchOrder` returned 200 via test endpoint `rc.api.rms.rakuten.co.jp`
- Local development (OpenSSL 3.6.0): HTTParty connection successful
- No code changes required — HTTParty handles the new cert chain automatically

## Testing Considerations

### No Sandbox Available

- RMS API does not provide a public sandbox environment
- API access requires active merchant account
- Testing must use WebMock/VCR for HTTP stubbing

### Test Response Samples

- **REMOVED in v8.3 (2025/12/12)**: `RakutenPayOrderAPI Response Sample` was deleted
- Previous versions had test response samples available

### Recommended Testing Approach

1. Use WebMock to stub HTTP responses
2. Create fixture files based on documented response formats
3. Test error handling for documented error codes
