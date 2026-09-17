# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class OrdersTest < TestCase
    def setup
      super
      @client = build_client
      @orders = @client.orders
    end

    # --- searchOrder -------------------------------------------------------

    def test_search_sends_the_documented_payload
      stub_rms("order/searchOrder/", body: search_response([ "1-2-3" ]))

      @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 8))

      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        recorded_body(request) == {
          "dateType" => 1,
          "startDatetime" => "2026-01-01T00:00:00+0900",
          "endDatetime" => "2026-01-08T00:00:00+0900",
          "orderProgressList" => [],
          "PaginationRequestModel" => {
            "requestRecordsAmount" => 1000,
            "requestPage" => 1,
            "SortModelList" => [ { "sortColumn" => 1, "sortDirection" => 1 } ]
          }
        }
      end
    end

    def test_search_resolves_symbolic_status_and_date_type
      stub_rms("order/searchOrder/", body: search_response([]))

      @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 2),
                     status: %i[awaiting_confirmation shipped], date_type: :shipped)

      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        body = recorded_body(request)
        body["orderProgressList"] == [ 100, 500 ] && body["dateType"] == 4
      end
    end

    def test_search_accepts_a_bare_symbol_or_integer_status
      stub_rms("order/searchOrder/", body: search_response([]))

      @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 2), status: 300)

      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        recorded_body(request)["orderProgressList"] == [ 300 ]
      end
    end

    def test_search_rejects_an_unknown_status_name
      error = assert_raises(ArgumentError) do
        @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 2), status: :shippped)
      end

      assert_includes error.message, "shippped"
      assert_includes error.message, "shipped", "the message should list the valid names"
    end

    def test_search_passes_undocumented_filters_through_verbatim
      stub_rms("order/searchOrder/", body: search_response([]))

      @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 2),
                     shippingDateBlankFlag: 1, asurakuFlag: 1)

      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        body = recorded_body(request)
        body["shippingDateBlankFlag"] == 1 && body["asurakuFlag"] == 1
      end
    end

    def test_search_follows_every_page
      pages = [
        search_response(%w[a b], total_pages: 3, total: 6),
        search_response(%w[c d], total_pages: 3, total: 6),
        search_response(%w[e f], total_pages: 3, total: 6)
      ]
      stub_request(:post, "#{BASE}/order/searchOrder/").to_return(pages.map { |page| json(page) })

      result = @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 8))

      assert_equal %w[a b c d e f], result
      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 3)
    end

    def test_search_asks_for_each_page_in_turn
      stub_request(:post, "#{BASE}/order/searchOrder/")
        .to_return([ json(search_response(%w[a], total_pages: 2)), json(search_response(%w[b], total_pages: 2)) ])

      @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 8))

      requested_pages = []
      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 2) do |request|
        requested_pages << recorded_body(request).dig("PaginationRequestModel", "requestPage")
      end

      assert_equal [ 1, 2 ], requested_pages
    end

    def test_search_returns_an_empty_array_when_rms_finds_nothing
      stub_rms("order/searchOrder/", body: {
        "orderNumberList" => [],
        "MessageModelList" => info_messages("INFO_102", "検索結果０件"),
        "PaginationResponseModel" => { "totalRecordsAmount" => nil, "totalPages" => nil, "requestPage" => nil }
      })

      assert_empty @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 2))
    end

    def test_search_rejects_a_window_wider_than_rms_allows
      error = assert_raises(ArgumentError) do
        @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 4, 1))
      end

      assert_includes error.message, "63 days"
      assert_not_requested(:post, "#{BASE}/order/searchOrder/")
    end

    def test_search_accepts_a_window_of_exactly_the_limit
      stub_rms("order/searchOrder/", body: search_response([]))

      @orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 3, 5))

      assert_requested(:post, "#{BASE}/order/searchOrder/")
    end

    def test_search_rejects_an_inverted_window
      error = assert_raises(ArgumentError) do
        @orders.search(start_date: Date.new(2026, 1, 8), end_date: Date.new(2026, 1, 1))
      end

      assert_includes error.message, "before"
    end

    def test_search_warns_when_rms_truncates_the_result_set
      stub_rms("order/searchOrder/", body: search_response(%w[a], total_pages: 1, total: 20_000))
      logger = ClientTest::CollectingLogger.new

      build_client(logger: logger).orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 8))

      assert_equal 1, logger.warns.size
      assert_includes logger.warns.first, "20000"
      assert_includes logger.warns.first, "15000"
    end

    def test_search_does_not_warn_below_the_limit
      stub_rms("order/searchOrder/", body: search_response(%w[a], total: 10))
      logger = ClientTest::CollectingLogger.new

      build_client(logger: logger).orders.search(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 8))

      assert_empty logger.warns
    end

    def test_search_page_returns_the_raw_response_for_manual_paging
      stub_rms("order/searchOrder/", body: search_response(%w[a], total_pages: 4, total: 3500))

      page = @orders.search_page(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 8),
                                 page: 2, page_size: 50)

      assert_equal 4, page.dig("PaginationResponseModel", "totalPages")
      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        pagination = recorded_body(request)["PaginationRequestModel"]
        pagination["requestPage"] == 2 && pagination["requestRecordsAmount"] == 50
      end
    end

    def test_search_page_caps_page_size_at_the_rms_maximum
      stub_rms("order/searchOrder/", body: search_response([]))

      @orders.search_page(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 2), page_size: 9999)

      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        recorded_body(request).dig("PaginationRequestModel", "requestRecordsAmount") == 1000
      end
    end

    # --- getOrder ----------------------------------------------------------

    def test_get_returns_the_order_model_list
      stub_rms("order/getOrder/", body: {
        "MessageModelList" => info_messages,
        "OrderModelList" => [ { "orderNumber" => "1-2-3" } ]
      })

      assert_equal [ { "orderNumber" => "1-2-3" } ], @orders.get([ "1-2-3" ])
    end

    def test_get_sends_the_configured_order_version
      stub_rms("order/getOrder/", body: { "OrderModelList" => [] })

      @orders.get([ "1-2-3" ])

      assert_requested(:post, "#{BASE}/order/getOrder/") do |request|
        recorded_body(request) == { "orderNumberList" => [ "1-2-3" ], "version" => 7 }
      end
    end

    def test_get_version_can_be_overridden_per_call
      stub_rms("order/getOrder/", body: { "OrderModelList" => [] })

      @orders.get([ "1-2-3" ], version: 9)

      assert_requested(:post, "#{BASE}/order/getOrder/") do |request|
        recorded_body(request)["version"] == 9
      end
    end

    def test_get_splits_requests_at_the_hundred_order_limit
      numbers = (1..250).map { |n| "order-#{n}" }
      stub_rms("order/getOrder/", body: { "OrderModelList" => [] })

      @orders.get(numbers)

      batch_sizes = []
      assert_requested(:post, "#{BASE}/order/getOrder/", times: 3) do |request|
        batch_sizes << recorded_body(request)["orderNumberList"].length
      end

      assert_equal [ 100, 100, 50 ], batch_sizes
    end

    def test_get_concatenates_every_batch
      stub_request(:post, "#{BASE}/order/getOrder/")
        .to_return([ json({ "OrderModelList" => [ { "orderNumber" => "a" } ] }),
                     json({ "OrderModelList" => [ { "orderNumber" => "b" } ] }) ])

      result = @orders.get((1..150).map { |n| "order-#{n}" })

      assert_equal %w[a b], result.map { |order| order["orderNumber"] }
    end

    def test_get_accepts_a_single_order_number
      stub_rms("order/getOrder/", body: { "OrderModelList" => [ { "orderNumber" => "1-2-3" } ] })

      assert_equal 1, @orders.get("1-2-3").length
    end

    def test_get_deduplicates_and_drops_nils
      stub_rms("order/getOrder/", body: { "OrderModelList" => [] })

      @orders.get([ "a", "a", nil, "b" ])

      assert_requested(:post, "#{BASE}/order/getOrder/") do |request|
        recorded_body(request)["orderNumberList"] == %w[a b]
      end
    end

    def test_get_makes_no_request_for_an_empty_list
      assert_empty @orders.get([])

      assert_not_requested(:post, "#{BASE}/order/getOrder/")
    end

    def test_get_raises_when_rms_reports_an_error_for_a_batch
      stub_rms("order/getOrder/", body: { "MessageModelList" => error_messages("GET_ERROR_1", "存在しない注文番号") })

      error = assert_raises(APIError) { @orders.get([ "missing" ]) }

      assert_equal [ "GET_ERROR_1" ], error.codes
    end

    # --- updateOrderSender -------------------------------------------------

    def test_update_sender_sends_the_package_model_list
      stub_rms("order/updateOrderSender/", body: { "MessageModelList" => info_messages })
      packages = [ { "basketId" => 1, "SenderModel" => { "familyName" => "船曳" } } ]

      @orders.update_sender(order_number: "1-2-3", packages: packages)

      assert_requested(:post, "#{BASE}/order/updateOrderSender/") do |request|
        recorded_body(request) == { "orderNumber" => "1-2-3", "PackageModelList" => packages }
      end
    end

    def test_update_sender_merges_extra_documented_fields
      stub_rms("order/updateOrderSender/", body: { "MessageModelList" => info_messages })

      @orders.update_sender(order_number: "1-2-3", packages: [], CouponModelList: [ { "couponCode" => "X" } ])

      assert_requested(:post, "#{BASE}/order/updateOrderSender/") do |request|
        recorded_body(request)["CouponModelList"] == [ { "couponCode" => "X" } ]
      end
    end

    # --- updateOrderShipping -----------------------------------------------

    def test_update_shipping_sends_the_basket_model_list
      stub_rms("order/updateOrderShipping/", body: { "MessageModelList" => info_messages })
      baskets = [ { "basketId" => 9, "ShippingModelList" => [ { "shippingDate" => "2026-01-20" } ] } ]

      @orders.update_shipping(order_number: "1-2-3", baskets: baskets)

      assert_requested(:post, "#{BASE}/order/updateOrderShipping/") do |request|
        recorded_body(request) == { "orderNumber" => "1-2-3", "BasketidModelList" => baskets }
      end
    end

    def test_update_shipping_raises_on_an_rms_error
      stub_rms("order/updateOrderShipping/", body: { "MessageModelList" => error_messages("SHIP_1", "発送日が不正") })

      assert_raises(APIError) { @orders.update_shipping(order_number: "1-2-3", baskets: []) }
    end

    # --- updateOrderMemo ---------------------------------------------------

    def test_update_memo_resolves_symbolic_codes_and_formats_the_date
      stub_rms("order/updateOrderMemo/", body: { "MessageModelList" => info_messages })

      @orders.update_memo(order_number: "1-2-3", memo: "冷凍 2D", sub_status_id: 15_822,
                          delivery_class: :frozen, delivery_date: Date.new(2026, 1, 20),
                          shipping_term: :morning)

      assert_requested(:post, "#{BASE}/order/updateOrderMemo/") do |request|
        recorded_body(request) == {
          "orderNumber" => "1-2-3",
          "memo" => "冷凍 2D",
          "subStatusId" => 15_822,
          "deliveryClass" => 3,
          "deliveryDate" => "2026-01-20",
          "shippingTerm" => 1
        }
      end
    end

    def test_update_memo_omits_fields_the_caller_left_out
      stub_rms("order/updateOrderMemo/", body: { "MessageModelList" => info_messages })

      @orders.update_memo(order_number: "1-2-3", memo: "だけ")

      assert_requested(:post, "#{BASE}/order/updateOrderMemo/") do |request|
        recorded_body(request) == { "orderNumber" => "1-2-3", "memo" => "だけ" }
      end
    end

    # An explicit nil is how a caller clears the requested delivery date for a
    # prepaid order that must not ship yet.
    def test_update_memo_sends_an_explicit_nil_to_clear_a_field
      stub_rms("order/updateOrderMemo/", body: { "MessageModelList" => info_messages })

      @orders.update_memo(order_number: "1-2-3", delivery_date: nil)

      assert_requested(:post, "#{BASE}/order/updateOrderMemo/") do |request|
        body = recorded_body(request)
        body.key?("deliveryDate") && body["deliveryDate"].nil?
      end
    end

    def test_update_memo_accepts_literal_codes_as_well_as_symbols
      stub_rms("order/updateOrderMemo/", body: { "MessageModelList" => info_messages })

      @orders.update_memo(order_number: "1-2-3", delivery_class: 2, shipping_term: 1416)

      assert_requested(:post, "#{BASE}/order/updateOrderMemo/") do |request|
        body = recorded_body(request)
        body["deliveryClass"] == 2 && body["shippingTerm"] == 1416
      end
    end

    def test_update_memo_merges_extra_documented_fields
      stub_rms("order/updateOrderMemo/", body: { "MessageModelList" => info_messages })

      @orders.update_memo(order_number: "1-2-3", operator: "船曳")

      assert_requested(:post, "#{BASE}/order/updateOrderMemo/") do |request|
        recorded_body(request)["operator"] == "船曳"
      end
    end

    private

    def json(body)
      { status: 200, body: JSON.generate(body), headers: { "Content-Type" => "application/json" } }
    end
  end
end
