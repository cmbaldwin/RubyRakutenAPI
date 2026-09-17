# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class ErrorsTest < TestCase
    def test_every_error_can_be_rescued_as_rakuten_rms_error
      [ ConfigurationError, ConnectionError, APIError, HTTPError,
        AuthenticationError, RateLimitError, ServerError ].each do |klass|
        assert_operator klass, :<, Error, "#{klass} should be rescuable as RakutenRms::Error"
      end
    end

    def test_http_error_subclasses_let_callers_branch_on_the_failure
      assert_operator AuthenticationError, :<, HTTPError
      assert_operator RateLimitError, :<, HTTPError
      assert_operator ServerError, :<, HTTPError
    end

    def test_api_error_joins_every_message_into_the_exception_message
      error = APIError.new([ Message.new(type: "ERROR", code: "E1", text: "一つ目"),
                             Message.new(type: "ERROR", code: "E2", text: "二つ目") ])

      assert_equal "E1: 一つ目; E2: 二つ目", error.message
      assert_equal %w[E1 E2], error.codes
    end

    def test_a_message_without_a_code_still_reads_cleanly
      error = APIError.new([ Message.new(type: "ERROR", code: nil, text: "原因不明") ])

      assert_equal "原因不明", error.message
    end

    # errorCode comes straight from the response, so it is whatever RMS sent.
    # Rendering an error must never raise a second one.
    def test_a_non_string_code_renders_instead_of_raising
      error = APIError.new([ Message.new(type: "ERROR", code: 503, text: nil) ])

      assert_equal "503", error.message
    end

    def test_message_knows_its_severity
      assert_predicate Message.new(type: "ERROR"), :error?
      assert_predicate Message.new(type: "WARNING"), :warning?
      refute_predicate Message.new(type: "INFO"), :error?
    end

    def test_http_error_defaults_to_a_message_naming_the_status
      assert_equal "RMS responded with HTTP 502", HTTPError.new(status: 502).message
    end
  end
end
