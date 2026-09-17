# frozen_string_literal: true

module RakutenRms
  # Credentials and connection settings for a {Client}.
  #
  # Each client keeps its own copy, so per-shop overrides never leak into the
  # process-wide defaults set by {RakutenRms.configure}.
  class Configuration
    BASE_URL = "https://api.rms.rakuten.co.jp/es/2.0"

    # RMS publishes a guideline of one request per second per shop.
    DEFAULT_REQUEST_GAP = 1.0

    # +getOrder+ response version. 7 added SKU support and is the oldest version
    # that returns +SkuModelList+; RMS deprecates old versions over time.
    DEFAULT_ORDER_VERSION = 7

    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_READ_TIMEOUT = 60

    # Retries apply only to failures that are safe and worth repeating:
    # 429, 5xx and transport errors.
    DEFAULT_MAX_RETRIES = 2
    DEFAULT_RETRY_BACKOFF = 1.0

    # @return [String] RMS service secret (RMS WEB SERVICE > API 利用設定)
    attr_accessor :service_secret
    # @return [String] RMS license key. Valid for 90 days, then must be reissued.
    attr_accessor :license_key
    # @return [String] API root, without a trailing slash
    attr_accessor :base_url
    # @return [Float] minimum seconds between requests; 0 disables throttling
    attr_accessor :request_gap
    # @return [Integer] default +version+ sent to +getOrder+
    attr_accessor :order_version
    attr_accessor :open_timeout, :read_timeout
    # @return [Integer] retry attempts for 429/5xx/transport failures
    attr_accessor :max_retries
    # @return [Float] seconds before the first retry; doubles each attempt
    attr_accessor :retry_backoff
    # @return [#debug, nil] receives method, path and status — never credentials
    attr_accessor :logger
    attr_accessor :user_agent

    def initialize
      @service_secret = ENV.fetch("RAKUTEN_SERVICE_SECRET", nil)
      @license_key = ENV.fetch("RAKUTEN_LICENSE_KEY", nil)
      @base_url = BASE_URL
      @request_gap = DEFAULT_REQUEST_GAP
      @order_version = DEFAULT_ORDER_VERSION
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @read_timeout = DEFAULT_READ_TIMEOUT
      @max_retries = DEFAULT_MAX_RETRIES
      @retry_backoff = DEFAULT_RETRY_BACKOFF
      @logger = nil
      @user_agent = "rakuten_rms/#{VERSION} (+https://github.com/cmbaldwin/RubyRakutenAPI)"
    end

    # @return [String] the +Authorization+ header value
    # @raise [ConfigurationError] when either credential is blank
    def authorization
      missing = { service_secret: service_secret, license_key: license_key }
                .select { |_, value| value.to_s.strip.empty? }.keys
      unless missing.empty?
        raise ConfigurationError,
              "missing RMS credentials: #{missing.join(' and ')}. Set them via " \
              "RakutenRms.configure, RakutenRms::Client.new(...), or the " \
              "RAKUTEN_SERVICE_SECRET / RAKUTEN_LICENSE_KEY environment variables."
      end

      # "ESA " + strict Base64 of "serviceSecret:licenseKey". pack("m0") is
      # Base64.strict_encode64 without the dependency, and unlike encode64 it
      # adds no wrapping newlines — which RMS rejects.
      credentials = [ "#{service_secret}:#{license_key}" ]
      "ESA #{credentials.pack('m0')}"
    end

    # Apply keyword overrides, rejecting unknown keys loudly rather than
    # silently ignoring a typo'd setting.
    def merge!(**overrides)
      overrides.each do |key, value|
        writer = :"#{key}="
        raise ConfigurationError, "unknown setting #{key.inspect}" unless respond_to?(writer)

        public_send(writer, value)
      end
      self
    end
  end
end
