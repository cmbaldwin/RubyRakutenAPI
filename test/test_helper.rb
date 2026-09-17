# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require "json"
require_relative "../lib/rakuten_rms"

module RakutenRms
  # Shared setup for the gem's tests.
  #
  # Every test builds its client through {#build_client}, which pins the request
  # gap to 0 and retry backoff to 0 so the suite never actually sleeps. Tests
  # that care about throttling or retries opt back in explicitly.
  class TestCase < Minitest::Test
    BASE = Configuration::BASE_URL

    def setup
      RakutenRms.reset_configuration!
      WebMock.reset!
    end

    def teardown
      RakutenRms.reset_configuration!
    end

    def build_client(**overrides)
      Client.new(service_secret: "secret", license_key: "licence",
                 request_gap: 0, retry_backoff: 0, **overrides)
    end

    # The Authorization header produced by the credentials {#build_client} uses.
    def expected_authorization = "ESA #{[ 'secret:licence' ].pack('m0')}"

    def stub_rms(path, method: :post, status: 200, body: {}, headers: {})
      stub_request(method, "#{BASE}/#{path}")
        .to_return(status: status,
                   body: body.is_a?(String) ? body : JSON.generate(body),
                   headers: { "Content-Type" => "application/json" }.merge(headers))
    end

    # The JSON body of the nth recorded request, parsed.
    def recorded_body(request)
      JSON.parse(request.body)
    end

    def info_messages(code = "INFO_101", message = "ok")
      [ { "messageType" => "INFO", "messageCode" => code, "message" => message } ]
    end

    def error_messages(code = "ERROR_009", message = "だめです")
      [ { "messageType" => "ERROR", "messageCode" => code, "message" => message } ]
    end

    def search_response(numbers, total_pages: 1, total: nil)
      {
        "orderNumberList" => numbers,
        "MessageModelList" => info_messages,
        "PaginationResponseModel" => {
          "totalRecordsAmount" => total || numbers.length,
          "totalPages" => total_pages,
          "requestPage" => 1
        }
      }
    end
  end
end
