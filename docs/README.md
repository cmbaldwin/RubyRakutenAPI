# RMS API reference

Notes taken from RMS WEB SERVICE: RakutenPayOrderAPI, kept alongside the client so the two stay in step.

**Source version:** 8.3 (2025/12/12) · **Implemented `getOrder` version:** 7 (SKU 対応)

| Document | Covers |
| --- | --- |
| [overview.md](overview.md) | Endpoint list, ESA auth, rate limit, `getOrder` version history |
| [reference-codes.md](reference-codes.md) | Order status, payment methods, carriers, delivery class, message types |
| [changelog.md](changelog.md) | RMS API version history, v1.0 – v8.3 |
| [endpoints/search-order.md](endpoints/search-order.md) | `searchOrder` — **wrapped** by `orders.search` / `orders.search_page` |
| [endpoints/get-order.md](endpoints/get-order.md) | `getOrder` — **wrapped** by `orders.get` |
| [endpoints/update-order-sender.md](endpoints/update-order-sender.md) | `updateOrderSender` — **wrapped** by `orders.update_sender` |
| [endpoints/update-order-shipping.md](endpoints/update-order-shipping.md) | `updateOrderShipping` — **wrapped** by `orders.update_shipping` |
| [endpoints/update-order-memo.md](endpoints/update-order-memo.md) | `updateOrderMemo` — **wrapped** by `orders.update_memo` |
| [endpoints/update-order-shipping-async.md](endpoints/update-order-shipping-async.md) | `updateOrderShippingAsync` — via `client.post` |
| [endpoints/get-result-update-order-shipping-async.md](endpoints/get-result-update-order-shipping-async.md) | `getResultUpdateOrderShippingAsync` — via `client.query` |
| [endpoints/update-order-sub-status.md](endpoints/update-order-sub-status.md) | `updateOrderSubStatus` — via `client.post` |
| [endpoints/update-order-remarks.md](endpoints/update-order-remarks.md) | `updateOrderRemarks` — via `client.post` |

Endpoints without a wrapper are one line away:

```ruby
client.post("order/updateOrderSubStatus/", { "orderNumberList" => ids, "subStatusId" => 15_822 })
```

## Quick reference

```
POST https://api.rms.rakuten.co.jp/es/2.0/order/<endpoint>/
Authorization: ESA Base64(serviceSecret:licenseKey)
Content-Type:  application/json; charset=utf-8
```

| Constraint | Limit |
| --- | --- |
| Order numbers per `getOrder` | 100 |
| `searchOrder` results | 15,000 |
| `searchOrder` date span | 63 days |
| Order history reachable | 730 days |
| Rate limit | 1 req/sec |
| License key validity | 90 days |

## Testing

There is no RMS sandbox — the API needs an active merchant account. Stub it with WebMock or VCR against the response shapes documented here.

---

These are working notes for implementers, not authoritative documentation. See the [official RMS documentation](https://webservice.rms.rakuten.co.jp/merchant-portal/) for that.
