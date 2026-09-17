# rakuten_rms

Ruby client for [Rakuten RMS WEB SERVICE](https://webservice.rms.rakuten.co.jp/merchant-portal/) — the RakutenPay Order API and Item API that 楽天市場 merchants use to read and update their own orders.

No runtime dependencies. `json`, `net/http` and `uri` are stdlib.

```ruby
RakutenRms.configure do |config|
  config.service_secret = ENV["RAKUTEN_SERVICE_SECRET"]
  config.license_key    = ENV["RAKUTEN_LICENSE_KEY"]
end

client  = RakutenRms::Client.new
numbers = client.orders.search(start_date: Date.today - 7, end_date: Date.today,
                               status: :awaiting_confirmation)
orders  = client.orders.get(numbers)

orders.each do |order|
  client.orders.update_memo(order_number: order["orderNumber"],
                            memo: "冷凍便", delivery_class: :frozen,
                            sub_status_id: 15_822)
end
```

## Install

```ruby
gem "rakuten_rms"
```

Requires Ruby 3.2+.

## Credentials

RMS uses ESA authentication: `Authorization: ESA Base64(serviceSecret:licenseKey)`. Both values come from RMS WEB SERVICE → API 利用設定.

Set them globally, per client, or via `RAKUTEN_SERVICE_SECRET` / `RAKUTEN_LICENSE_KEY`:

```ruby
RakutenRms::Client.new(service_secret: "...", license_key: "...")
```

> **License keys expire after 90 days.** When one lapses RMS answers 401 and this gem raises `RakutenRms::AuthenticationError`. Reissue the key in RMS; nothing else needs to change.

Each client holds its own copy of the configuration, so one process can serve several shops without them bleeding into each other.

## Orders

### `search` — 受注検索 (searchOrder)

Returns order numbers, following pagination to the end.

```ruby
client.orders.search(
  start_date: Date.new(2026, 1, 1),
  end_date:   Date.new(2026, 1, 31),
  status:     %i[awaiting_confirmation awaiting_shipment],  # or [100, 300]
  date_type:  :ordered,                                     # 期間検索種別
  shippingDateBlankFlag: 1                                  # any documented filter
)
# => ["274763-20260114-0123456789", ...]
```

Dates accept `Date`, `Time`, `DateTime` or a string. Anything carrying a zone is **converted** to JST; anything without one (a `Date`, `"2026-01-14"`) is **read as** JST, so a server running in UTC still searches the day you meant.

RMS rejects a window wider than 63 days, so `search` raises `ArgumentError` before spending a request. It also cannot return past the 15,000th result — when a search matches more than that, `search` warns through `config.logger` rather than quietly handing back a short list.

For manual paging, `search_page` returns one raw response including `PaginationResponseModel`.

### `get` — 注文情報取得 (getOrder)

```ruby
client.orders.get(numbers)               # => [{"orderNumber" => ..., "PackageModelList" => [...]}, ...]
client.orders.get(numbers, version: 9)   # override the response version
```

RMS caps `getOrder` at 100 order numbers; `get` splits larger lists transparently, deduplicates, and returns one flat array.

### Updates

```ruby
client.orders.update_sender(order_number: id, packages: package_model_list)
client.orders.update_shipping(order_number: id, baskets: basket_id_model_list)
client.orders.update_memo(order_number: id, memo: "冷凍 2D",
                          sub_status_id: 15_822, delivery_class: :frozen,
                          delivery_date: Date.new(2026, 1, 20))
```

`update_memo` distinguishes "leave this alone" from "clear this": omit a keyword and the field is not sent; pass an explicit `nil` and null is sent.

```ruby
client.orders.update_memo(order_number: id, delivery_date: nil)  # clears お届け日指定
```

Any documented field the gem does not name is passed through verbatim:

```ruby
client.orders.update_memo(order_number: id, operator: "船曳", mailPlugSentence: "...")
```

## Items

```ruby
client.items.search(hits: 100, offset: 1)["results"]
```

Query parameters are passed straight through, so this tracks the RMS Item API docs without the gem re-declaring them.

## Endpoints the gem does not wrap

Everything else is one line away. `post` never retries (safe for writes); `query` retries like a read.

```ruby
client.post("order/confirmOrder/", { "orderNumberList" => [id] })
client.query("order/getSubStatusList/")
```

## Named codes

`RakutenRms::Codes` names the numbers you have to *send*. Literal codes still work everywhere a symbol does, so an undocumented or brand-new code is never blocked.

| Table | Used for |
| --- | --- |
| `ORDER_PROGRESS` | `:awaiting_confirmation` → 100 … `:cancelled` → 900 |
| `DATE_TYPE` | `:ordered` → 1 … `:payment_fixed` → 6 |
| `DELIVERY_CLASS` | `:normal` → 1, `:chilled` → 2, `:frozen` → 3 |
| `SHIPPING_TERM` | `:morning` → 1, `:afternoon` → 2 (custom `1416` ranges pass through) |
| `DELIVERY_COMPANY` | `:yamato` → `"1001"`, `:sagawa` → `"1002"`, … |

## Errors

Every failure raises. All of them descend from `RakutenRms::Error`.

| Class | Raised when |
| --- | --- |
| `ConfigurationError` | a credential or setting is missing or misspelled |
| `AuthenticationError` | HTTP 401/403 — usually an expired license key |
| `RateLimitError` | HTTP 429 |
| `ServerError` | HTTP 5xx |
| `HTTPError` | any other non-2xx (parent of the three above; carries `status` and `body`) |
| `ConnectionError` | DNS, TLS, timeout or a dropped connection |
| `APIError` | HTTP 200 with an `ERROR` in `MessageModelList`, or the ESA gateway's `Results.errorCode` envelope |

`APIError` carries the detail RMS gave you:

```ruby
begin
  client.orders.update_shipping(order_number: id, baskets: baskets)
rescue RakutenRms::APIError => e
  e.codes    # => ["ORDER_EXT_API_UPDATE_ORDER_SHIPPING_ERROR_012"]
  e.messages # => [#<struct RakutenRms::Message type="ERROR", code=..., text="発送日が不正です。">]
  e.body     # the full parsed response
end
```

## Throttling and retries

RMS publishes a guideline of **one request per second**. The client enforces it with a monotonic clock, shared across threads, so a pool of workers on one client still paces correctly.

```ruby
RakutenRms::Client.new(request_gap: 0.5)  # seconds; 0 disables
```

Retries are deliberately asymmetric. Reads (`search`, `get`, `items.search`, `client.query`, `client.get`) retry a 429, 5xx or dropped connection up to `max_retries` times with exponential backoff. Writes never retry: RMS may have applied the change before the connection died, and replaying an `updateOrderSender` would add its wrapping models and prices a second time.

```ruby
RakutenRms::Client.new(max_retries: 0)  # turn retries off entirely
```

## Responses

Order payloads come back exactly as RMS sends them — `"orderNumber"`, `"PackageModelList"`, `"SkuModelList"` — so the official RMS field reference *is* the field reference for this gem, and a field added in a future API version needs no gem release to reach you.

## Logging

```ruby
RakutenRms::Client.new(logger: Rails.logger)
```

Logs method, path and status at `debug`, and result-set truncation at `warn`. Credentials, request bodies and customer data are never logged.

## Configuration reference

| Setting | Default | |
| --- | --- | --- |
| `service_secret` | `ENV["RAKUTEN_SERVICE_SECRET"]` | |
| `license_key` | `ENV["RAKUTEN_LICENSE_KEY"]` | 90-day validity |
| `base_url` | `https://api.rms.rakuten.co.jp/es/2.0` | |
| `request_gap` | `1.0` | seconds between requests |
| `order_version` | `7` | `getOrder` response version |
| `open_timeout` / `read_timeout` | `5` / `60` | seconds |
| `max_retries` | `2` | reads only |
| `retry_backoff` | `1.0` | seconds, doubling |
| `logger` | `nil` | |
| `user_agent` | `rakuten_rms/VERSION` | |

## RMS limits worth knowing

| | |
| --- | --- |
| `getOrder` order numbers per request | 100 (handled for you) |
| `searchOrder` results per page | 1,000 (capped for you) |
| `searchOrder` total results | 15,000 (warned about) |
| `searchOrder` date span | 63 days (rejected early) |
| Order history reachable | 730 days |
| Rate limit | 1 request/second (enforced) |
| License key validity | 90 days |

## Testing against this gem

There is no RMS sandbox — the API needs a live merchant account. Stub it with WebMock or VCR, which is what this gem's own suite does:

```ruby
stub_request(:post, "https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/")
  .to_return(status: 200, body: { "orderNumberList" => ["1-2-3"],
                                  "PaginationResponseModel" => { "totalPages" => 1 } }.to_json)
```

Pin `request_gap: 0` and `retry_backoff: 0` in tests so the suite never sleeps.

## Development

```bash
bin/setup      # bundle install
rake test      # minitest
rubocop
```

## License

MIT. See [MIT-LICENSE](MIT-LICENSE).

This is an unofficial client and is not affiliated with or endorsed by Rakuten Group, Inc.
