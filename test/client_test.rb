# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class ClientTest < TestCase
    def test_post_sends_esa_auth_and_the_json_content_type_rms_requires
      stub_rms("order/searchOrder/", body: { "ok" => true })

      build_client.post("order/searchOrder/", { dateType: 1 })

      assert_requested(:post, "#{BASE}/order/searchOrder/") do |request|
        request.headers["Authorization"] == expected_authorization &&
          request.headers["Content-Type"] == "application/json; charset=utf-8" &&
          recorded_body(request) == { "dateType" => 1 }
      end
    end

    def test_post_identifies_the_gem_in_the_user_agent
      stub_rms("order/getOrder/")

      build_client.post("order/getOrder/")

      assert_requested(:post, "#{BASE}/order/getOrder/") do |request|
        request.headers["User-Agent"].to_s.start_with?("rakuten_rms/#{VERSION}")
      end
    end

    def test_get_appends_the_query_and_drops_nils
      stub_request(:get, "#{BASE}/items/search?hits=10")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      build_client.get("items/search", hits: 10, offset: nil)

      assert_requested(:get, "#{BASE}/items/search?hits=10")
    end

    def test_paths_resolve_the_same_with_or_without_a_leading_slash
      stub_rms("order/getOrder/")

      client = build_client
      client.post("/order/getOrder/")
      client.post("order/getOrder/")

      assert_requested(:post, "#{BASE}/order/getOrder/", times: 2)
    end

    def test_missing_credentials_raise_before_any_request_is_made
      assert_raises(ConfigurationError) do
        Client.new(service_secret: nil, license_key: nil).post("order/getOrder/")
      end

      assert_not_requested(:post, "#{BASE}/order/getOrder/")
    end

    # --- response parsing -------------------------------------------------

    def test_successful_body_is_returned_parsed
      stub_rms("order/getOrder/", body: { "OrderModelList" => [ { "orderNumber" => "1-2-3" } ] })

      result = build_client.post("order/getOrder/")

      assert_equal [ { "orderNumber" => "1-2-3" } ], result["OrderModelList"]
    end

    def test_empty_body_becomes_an_empty_hash
      stub_rms("order/updateOrderMemo/", body: "")

      assert_empty build_client.post("order/updateOrderMemo/")
    end

    def test_unparseable_body_raises_with_a_usable_excerpt
      stub_rms("order/getOrder/", body: "<html>maintenance</html>")

      error = assert_raises(Error) { build_client.post("order/getOrder/") }

      assert_includes error.message, "maintenance"
    end

    # --- HTTP status mapping ----------------------------------------------

    def test_401_raises_authentication_error
      stub_rms("order/getOrder/", status: 401, body: "")

      error = assert_raises(AuthenticationError) { build_client.post("order/getOrder/") }

      assert_equal 401, error.status
    end

    def test_403_raises_authentication_error
      stub_rms("order/getOrder/", status: 403, body: "")

      assert_raises(AuthenticationError) { build_client.post("order/getOrder/") }
    end

    def test_400_raises_a_plain_http_error_carrying_the_body
      stub_rms("order/getOrder/", status: 400, body: "bad request")

      error = assert_raises(HTTPError) { build_client.post("order/getOrder/") }

      refute_kind_of AuthenticationError, error
      assert_equal 400, error.status
      assert_equal "bad request", error.body
    end

    def test_503_raises_server_error_after_exhausting_retries
      stub_rms("order/searchOrder/", status: 503, body: "")

      assert_raises(ServerError) { build_client.query("order/searchOrder/") }
    end

    # --- RMS payload-level errors -----------------------------------------

    def test_error_entries_in_message_model_list_raise_api_error
      stub_rms("order/searchOrder/", body: { "MessageModelList" => error_messages, "orderNumberList" => nil })

      error = assert_raises(APIError) { build_client.post("order/searchOrder/") }

      assert_equal [ "ERROR_009" ], error.codes
      assert_includes error.message, "だめです"
      assert_equal({ "messageType" => "ERROR", "messageCode" => "ERROR_009", "message" => "だめです" },
                   error.body["MessageModelList"].first)
    end

    def test_info_and_warning_entries_do_not_raise
      messages = info_messages + [ { "messageType" => "WARNING", "messageCode" => "W1", "message" => "注意" } ]
      stub_rms("order/searchOrder/", body: { "MessageModelList" => messages })

      assert build_client.post("order/searchOrder/")
    end

    def test_mixed_messages_raise_with_only_the_errors
      messages = info_messages + error_messages("E2", "二つ目")
      stub_rms("order/searchOrder/", body: { "MessageModelList" => messages })

      error = assert_raises(APIError) { build_client.post("order/searchOrder/") }

      assert_equal [ "E2" ], error.codes
    end

    # The ESA gateway answers 200 with its own envelope for auth and routing
    # failures, which never reaches MessageModelList.
    def test_gateway_error_envelope_raises_api_error
      stub_rms("order/searchOrder/", body: {
        "Results" => { "errorCode" => "wrong_parameter", "errorMessage" => "invalid licenseKey" }
      })

      error = assert_raises(APIError) { build_client.post("order/searchOrder/") }

      assert_equal [ "wrong_parameter" ], error.codes
      assert_includes error.message, "invalid licenseKey"
    end

    def test_a_results_key_without_an_error_code_is_not_an_error
      stub_rms("items/search", method: :get, body: { "results" => [], "Results" => { "numFound" => 0 } })

      assert build_client.get("items/search")
    end

    # --- retries -----------------------------------------------------------

    def test_a_retriable_request_recovers_from_a_transient_500
      stub_request(:post, "#{BASE}/order/searchOrder/")
        .to_return({ status: 500, body: "" },
                   { status: 200, body: JSON.generate(search_response([ "1-2-3" ])),
                     headers: { "Content-Type" => "application/json" } })

      result = build_client.query("order/searchOrder/")

      assert_equal [ "1-2-3" ], result["orderNumberList"]
      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 2)
    end

    def test_a_retriable_request_recovers_from_a_429
      stub_request(:post, "#{BASE}/order/searchOrder/")
        .to_return({ status: 429, body: "" },
                   { status: 200, body: "{}", headers: { "Content-Type" => "application/json" } })

      build_client.query("order/searchOrder/")

      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 2)
    end

    def test_a_retriable_request_recovers_from_a_dropped_connection
      stub_request(:post, "#{BASE}/order/getOrder/")
        .to_raise(Errno::ECONNRESET).then
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      build_client.query("order/getOrder/")

      assert_requested(:post, "#{BASE}/order/getOrder/", times: 2)
    end

    # Replaying updateOrderSender would add its wrapping models and prices twice,
    # so a write must fail rather than guess whether RMS applied it.
    def test_a_write_is_never_retried
      stub_rms("order/updateOrderSender/", status: 500, body: "")

      assert_raises(ServerError) { build_client.post("order/updateOrderSender/") }

      assert_requested(:post, "#{BASE}/order/updateOrderSender/", times: 1)
    end

    def test_retries_stop_at_max_retries
      stub_rms("order/searchOrder/", status: 500, body: "")

      assert_raises(ServerError) do
        build_client(max_retries: 3).query("order/searchOrder/")
      end

      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 4)
    end

    def test_retries_can_be_disabled
      stub_rms("order/searchOrder/", status: 500, body: "")

      assert_raises(ServerError) do
        build_client(max_retries: 0).query("order/searchOrder/")
      end

      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 1)
    end

    def test_a_401_is_not_retried_because_a_dead_licence_key_stays_dead
      stub_rms("order/searchOrder/", status: 401, body: "")

      assert_raises(AuthenticationError) { build_client.query("order/searchOrder/") }

      assert_requested(:post, "#{BASE}/order/searchOrder/", times: 1)
    end

    # --- throttling --------------------------------------------------------

    def test_requests_are_spaced_by_the_request_gap
      stub_rms("order/getOrder/")
      client = build_client(request_gap: 1.0)
      recorder = SleepRecorder.new(client, ticks: [ 100.0, 100.2, 100.2 ])

      client.post("order/getOrder/")
      client.post("order/getOrder/")

      assert_equal 1, recorder.slept.size
      assert_in_delta 0.8, recorder.slept.first, 0.001
    end

    def test_the_first_request_is_not_delayed
      stub_rms("order/getOrder/")
      client = build_client(request_gap: 1.0)
      recorder = SleepRecorder.new(client, ticks: [ 100.0 ])

      client.post("order/getOrder/")

      assert_empty recorder.slept
    end

    def test_no_sleep_when_the_gap_has_already_elapsed
      stub_rms("order/getOrder/")
      client = build_client(request_gap: 1.0)
      recorder = SleepRecorder.new(client, ticks: [ 100.0, 105.0, 105.0 ])

      client.post("order/getOrder/")
      client.post("order/getOrder/")

      assert_empty recorder.slept
    end

    def test_a_zero_gap_disables_throttling
      stub_rms("order/getOrder/")
      client = build_client(request_gap: 0)
      recorder = SleepRecorder.new(client, ticks: [])

      3.times { client.post("order/getOrder/") }

      assert_empty recorder.slept
    end

    def test_throttling_serialises_concurrent_threads
      stub_rms("order/getOrder/")
      client = build_client(request_gap: 0.05)

      threads = 4.times.map { Thread.new { client.post("order/getOrder/") } }
      threads.each(&:join)

      assert_requested(:post, "#{BASE}/order/getOrder/", times: 4)
    end

    # --- logging -----------------------------------------------------------

    def test_the_logger_records_the_call_without_leaking_credentials
      stub_rms("order/getOrder/")
      logger = CollectingLogger.new

      build_client(logger: logger).post("order/getOrder/", { orderNumberList: [ "1-2-3" ] })

      assert_equal 1, logger.debugs.size
      assert_includes logger.debugs.first, "order/getOrder/"
      assert_includes logger.debugs.first, "200"
      refute_includes logger.debugs.first, "licence"
      refute_includes logger.debugs.first, "ESA"
    end

    # Replaces the client's clock and sleep so throttling can be asserted
    # without the suite actually waiting.
    class SleepRecorder
      attr_reader :slept

      def initialize(client, ticks:)
        @slept = []
        slept = @slept
        client.define_singleton_method(:sleep) { |seconds| slept << seconds }
        client.define_singleton_method(:clock_now) { ticks.shift }
      end
    end

    class CollectingLogger
      attr_reader :debugs, :warns

      def initialize
        @debugs = []
        @warns = []
      end

      def debug(message = nil, &block) = @debugs << (block ? block.call : message)
      def warn(message = nil, &block) = @warns << (block ? block.call : message)
    end
  end
end
