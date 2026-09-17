# frozen_string_literal: true

module RakutenRms
  # One entry from an RMS +MessageModelList+, or a synthesised entry for the
  # ESA gateway error envelope (+{"Results" => {"errorCode" => ...}}+).
  Message = Struct.new(:type, :code, :text, keyword_init: true) do
    def error? = type == "ERROR"
    def warning? = type == "WARNING"

    # Tolerates a non-string code: failing to render an error is the worst
    # possible place to raise a second one.
    def to_s = [ code, text ].map(&:to_s).reject(&:empty?).join(": ")
  end

  # Base class for everything this gem raises. Rescue it to catch any RMS failure.
  class Error < StandardError; end

  # Credentials are missing or unusable before a request is even attempted.
  class ConfigurationError < Error; end

  # The request never produced an HTTP response (DNS, TLS, timeout, reset).
  class ConnectionError < Error; end

  # A non-2xx HTTP response.
  class HTTPError < Error
    attr_reader :status, :body

    def initialize(message = nil, status:, body: nil)
      @status = status
      @body = body
      super(message || "RMS responded with HTTP #{status}")
    end
  end

  # HTTP 401/403. Most often an expired license key — RMS license keys are only
  # valid for 90 days and must be reissued in RMS WEB SERVICE.
  class AuthenticationError < HTTPError; end

  # HTTP 429, or RMS shedding load during a traffic spike.
  class RateLimitError < HTTPError; end

  # HTTP 5xx.
  class ServerError < HTTPError; end

  # RMS answered 200 but the payload reports failure — either an +ERROR+ entry in
  # +MessageModelList+ or the ESA gateway's +Results.errorCode+ envelope.
  class APIError < Error
    # @return [Array<Message>] the ERROR entries that caused this
    attr_reader :messages
    # @return [Hash] the full parsed response body
    attr_reader :body

    def initialize(messages, body: nil)
      @messages = messages
      @body = body
      super(messages.map(&:to_s).join("; "))
    end

    # @return [Array<String>] the RMS message codes, e.g. +["ORDER_EXT_API_..."]+
    def codes = messages.map(&:code)
  end
end
