# Changelog

## 0.1.0

Initial release, extracted from the Rakuten integration in
[funabiki-online](https://github.com/cmbaldwin/funabiki-online).

- ESA authentication, with a clear error naming the missing credential.
- RakutenPay Order API: `searchOrder` (auto-paginating), `getOrder`
  (auto-batched at 100), `updateOrderSender`, `updateOrderShipping`,
  `updateOrderMemo`. `client.post` / `client.query` reach anything else.
- Item API: `items.search`.
- The documented 1 request/second throttle, on a monotonic clock and safe
  across threads.
- Retries for reads only (429/5xx/dropped connections); writes never replay.
- Typed errors for both RMS failure envelopes — `MessageModelList` and the ESA
  gateway's `Results.errorCode`.
- JST datetime handling that converts zoned values and reads zoneless ones as
  Japan time.
- Symbolic codes for order status, date type, delivery class, shipping term and
  carriers; literal codes still accepted.
- No runtime dependencies.
