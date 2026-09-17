# frozen_string_literal: true

module RakutenRms
  # The RakutenPay Order API (RakutenPayOrderAPI).
  #
  # Order payloads are returned exactly as RMS sends them — camelCase keys,
  # +PackageModelList+ and friends intact — so the official RMS field reference
  # is the field reference for this gem, and nothing is lost in translation.
  #
  #   orders = client.orders
  #   numbers = orders.search(start_date: Date.today - 7, end_date: Date.today,
  #                           status: :awaiting_confirmation)
  #   orders.get(numbers).each { |order| puts order["orderNumber"] }
  class Orders
    # +getOrder+ accepts at most 100 order numbers per request.
    MAX_ORDER_NUMBERS_PER_REQUEST = 100
    # +searchOrder+ accepts at most 1,000 results per page.
    MAX_RECORDS_PER_PAGE = 1000
    # +searchOrder+ rejects a start/end span wider than 63 days.
    MAX_SEARCH_SPAN_DAYS = 63
    # +searchOrder+ cannot reach past the 15,000th result; anything beyond that
    # is silently unreachable, so {#search} warns rather than losing it quietly.
    MAX_SEARCH_RESULTS = 15_000

    # Distinguishes "caller omitted this field" (leave it alone) from
    # "caller passed nil" (send null, which clears the field at RMS).
    UNSET = Object.new.freeze
    private_constant :UNSET

    def initialize(client)
      @client = client
    end

    # +searchOrder+ — every matching order number, following pagination.
    #
    # @param start_date [Time, Date, String] inclusive start of the window (JST)
    # @param end_date [Time, Date, String] inclusive end of the window (JST)
    # @param status [Symbol, Integer, Array] {Codes::ORDER_PROGRESS} names or
    #   codes; empty means every status
    # @param date_type [Symbol, Integer] which timestamp to filter on,
    #   see {Codes::DATE_TYPE}
    # @param page_size [Integer] results per page, up to {MAX_RECORDS_PER_PAGE}
    # @param filters [Hash] any other documented +searchOrder+ parameter, passed
    #   through verbatim, e.g. +shippingDateBlankFlag: 1+
    # @return [Array<String>] order numbers
    # @raise [ArgumentError] if the window is inverted or wider than
    #   {MAX_SEARCH_SPAN_DAYS}
    # @raise [APIError] if RMS rejects the search
    def search(start_date:, end_date:, status: [], date_type: :ordered,
               page_size: MAX_RECORDS_PER_PAGE, **filters)
      window = search_window(start_date, end_date)
      page_options = { status: status, date_type: date_type, page_size: page_size, **filters }

      first = search_page(**window, page: 1, **page_options)
      warn_if_truncated(first)

      numbers = Array(first["orderNumberList"])
      total_pages = first.dig("PaginationResponseModel", "totalPages").to_i
      (2..total_pages).each do |page|
        later = search_page(**window, page: page, **page_options)
        numbers.concat(Array(later["orderNumberList"]))
      end
      numbers
    end

    # +searchOrder+ — a single page, returned raw so callers can read
    # +PaginationResponseModel+ and drive their own paging.
    #
    # @return [Hash] the parsed +searchOrder+ response
    def search_page(start_date:, end_date:, status: [], date_type: :ordered,
                    page_size: MAX_RECORDS_PER_PAGE, page: 1, sort_direction: 1, **filters)
      payload = {
        "dateType" => Codes.resolve(Codes::DATE_TYPE, date_type),
        "startDatetime" => TimeFormat.datetime(start_date),
        "endDatetime" => TimeFormat.datetime(end_date),
        "orderProgressList" => Codes.resolve_all(Codes::ORDER_PROGRESS, status),
        "PaginationRequestModel" => {
          "requestRecordsAmount" => [ page_size, MAX_RECORDS_PER_PAGE ].min,
          "requestPage" => page,
          "SortModelList" => [ { "sortColumn" => 1, "sortDirection" => sort_direction } ]
        }
      }
      @client.query("order/searchOrder/", payload.merge(stringify(filters)))
    end

    # +getOrder+ — full order details, transparently split into requests of
    # {MAX_ORDER_NUMBERS_PER_REQUEST}.
    #
    # @param order_numbers [Array<String>, String] one or many order numbers
    # @param version [Integer] response version; defaults to
    #   {Configuration#order_version}
    # @return [Array<Hash>] +OrderModel+ hashes, in RMS's order
    # @raise [APIError] if RMS reports an error for any batch
    def get(order_numbers, version: nil)
      numbers = Array(order_numbers).compact.uniq
      return [] if numbers.empty?

      version ||= @client.config.order_version
      numbers.each_slice(MAX_ORDER_NUMBERS_PER_REQUEST).flat_map do |batch|
        response = @client.query("order/getOrder/",
                                 { "orderNumberList" => batch, "version" => version })
        Array(response["OrderModelList"])
      end
    end

    # +updateOrderSender+ — recipient, item and payment changes before shipping.
    # Only valid while the order is in status 100, 200 or 300.
    #
    # @param order_number [String]
    # @param packages [Array<Hash>] +PackageModelList+ entries
    # @param attrs [Hash] further documented fields, e.g. +CouponModelList:+
    # @return [Hash] the parsed response
    def update_sender(order_number:, packages:, **attrs)
      post_update("updateOrderSender",
                  { "orderNumber" => order_number, "PackageModelList" => packages }, attrs)
    end

    # +updateOrderShipping+ — shipping date, carrier and tracking number.
    #
    # @param order_number [String]
    # @param baskets [Array<Hash>] +BasketidModelList+ entries
    # @return [Hash] the parsed response
    def update_shipping(order_number:, baskets:, **attrs)
      post_update("updateOrderShipping",
                  { "orderNumber" => order_number, "BasketidModelList" => baskets }, attrs)
    end

    # +updateOrderMemo+ — memo, sub-status, delivery class and requested
    # delivery date/time.
    #
    # Omitted fields are left untouched at RMS; passing an explicit +nil+ sends
    # null, which clears the field.
    #
    # @param order_number [String]
    # @param memo [String, nil] 1,000 characters max
    # @param sub_status_id [Integer, nil] shop-defined sub-status
    # @param delivery_class [Symbol, Integer, nil] see {Codes::DELIVERY_CLASS}
    # @param delivery_date [Date, String, nil] requested delivery date
    # @param shipping_term [Symbol, Integer, nil] see {Codes::SHIPPING_TERM}
    # @param attrs [Hash] further documented fields, e.g. +operator:+
    # @return [Hash] the parsed response
    def update_memo(order_number:, memo: UNSET, sub_status_id: UNSET, delivery_class: UNSET,
                    delivery_date: UNSET, shipping_term: UNSET, **attrs)
      payload = {
        "orderNumber" => order_number,
        "memo" => memo,
        "subStatusId" => sub_status_id,
        "deliveryClass" => map_unless_nil(delivery_class) { Codes.resolve(Codes::DELIVERY_CLASS, _1) },
        "deliveryDate" => map_unless_nil(delivery_date) { TimeFormat.date(_1) },
        "shippingTerm" => map_unless_nil(shipping_term) { Codes.resolve(Codes::SHIPPING_TERM, _1) }
      }
      post_update("updateOrderMemo", payload.reject { |_, value| UNSET.equal?(value) }, attrs)
    end

    private

    def post_update(endpoint, payload, attrs)
      @client.post("order/#{endpoint}/", payload.merge(stringify(attrs)))
    end

    # Leaves UNSET and nil alone; converts anything else through the block.
    def map_unless_nil(value)
      return value if UNSET.equal?(value) || value.nil?

      yield value
    end

    # Callers use snake_case keywords for the fields the gem names explicitly and
    # RMS's own camelCase for the long tail, which passes straight through.
    def stringify(attrs)
      attrs.each_with_object({}) { |(key, value), out| out[key.to_s] = value }
    end

    def search_window(start_date, end_date)
      start_time = TimeFormat.to_time(start_date)
      end_time = TimeFormat.to_time(end_date)
      span = (end_time - start_time) / 86_400.0

      raise ArgumentError, "end_date (#{end_time}) is before start_date (#{start_time})" if span.negative?

      if span > MAX_SEARCH_SPAN_DAYS
        raise ArgumentError,
              "searchOrder allows at most #{MAX_SEARCH_SPAN_DAYS} days between start_date and " \
              "end_date, got #{span.round(1)}; split the window and search each part"
      end

      { start_date: start_time, end_date: end_time }
    end

    # Beyond 15,000 results RMS simply stops paginating, so the caller would
    # otherwise get a short list with no indication anything was dropped.
    def warn_if_truncated(response)
      total = response.dig("PaginationResponseModel", "totalRecordsAmount").to_i
      return if total <= MAX_SEARCH_RESULTS

      @client.config.logger&.warn do
        "RakutenRms: searchOrder matched #{total} orders but RMS only returns the first " \
        "#{MAX_SEARCH_RESULTS}; narrow the date window to see the rest"
      end
    end
  end
end
