# RMS docs harvest

Keep this gem honest against the real RMS WEB SERVICE reference, which lives
behind a merchant-portal login and has no public URL or sandbox.

## When to use

- RMS changed something (new error code, new field, new response version).
- The gem needs an endpoint it does not wrap yet.
- A live response disagrees with `docs/endpoints/` or the code.

## Prerequisites

- A Chrome profile already logged in to the RMS merchant portal
  (店舗様向け情報・サービス → WEB API). Drive it with Claude in Chrome, or
  `browser-harness` where installed.
- Portal credentials come from 1Password at session time. They are never
  written to this repo — not in code, docs, tests, screenshots, or filenames.
- Browsing the reference is read-only and safe. There is no sandbox, so never
  press anything that mutates: no 確定, 更新, 登録, 申請, or test-send buttons.

## Workflow

1. Pick one endpoint from the inventory below. Open its reference page in the
   portal (`merchant-portal/view/...`).
2. Capture, in your own words: request fields (names, types, required,
   limits), response envelope, error/message codes, rate or batching limits,
   and any version note (RMS deprecates old `getOrder` versions over time).
3. Refresh `docs/endpoints/<name>.md` to the canonical format: title line with
   the Japanese operation name, `Endpoint:` line, parameter table
   (Parameter | Japanese | Required | Type | Default | Description), code
   tables, then a short `## Notes` section for limits and version gotchas.
4. If the capture changes behavior: update `lib/`, `Codes` tables if codes
   were added, and add a regression test. Literal codes must keep working
   where symbols do, so a brand-new RMS code is never blocked.
5. Run `rake test` and `rubocop` before committing. Both are green on main;
   keep them green.

## Endpoint inventory

| Portal operation | Reference doc | Gem status |
| --- | --- | --- |
| 受注検索 searchOrder | `search-order.md` | wrapped (`Orders#search`) |
| 注文情報取得 getOrder | `get-order.md` | wrapped (`Orders#get`) |
| 受注者情報更新 updateOrderSender | `update-order-sender.md` | wrapped |
| 配送情報更新 updateOrderShipping | `update-order-shipping.md` | wrapped |
| ひとことメモ更新 updateOrderMemo | `update-order-memo.md` | wrapped |
| 備考更新 updateOrderRemarks | `update-order-remarks.md` | via `client.post`, docs only |
| サブステータス更新 updateOrderSubStatus | `update-order-sub-status.md` | via `client.post`, docs only |
| 配送情報更新 (async) | `update-order-shipping-async.md` | via `client.post`, docs only |
| 非同期結果取得 | `get-result-update-order-shipping-async.md` | via `client.query`, docs only |
| 商品検索 items/search | — (pass-through by design) | wrapped (`Items#search`) |

Promote a `client.post` endpoint to a wrapped method when a second caller
needs it — not before.

## Red lines

- Paraphrase the reference; never paste RMS doc text, screenshots, or
  response dumps containing real shop data into this repo.
- Example order numbers in docs/tests are synthetic (`123456-…`) by
  convention. Keep them that way.
- No credentials, session cookies, shop URLs, or customer data. Ever.
