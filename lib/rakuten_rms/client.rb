# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module RakutenRms
  # Entry point for the RMS WEB SERVICE API.
  #
  #   client = RakutenRms::Client.new(service_secret: "...", license_key: "...")
  #   client.orders.search(start_date: Date.today - 7, end_date: Date.today)
  #
  # One client owns one throttle, so give long-running processes a single shared
  # instance rather than constructing one per call. Instances are thread-safe.
  class Client
    # Transport failures worth retrying. +EOFError+ and +Errno::ECONNRESET+ show
    # up when RMS drops a keep-alive connection mid-flight.
    RETRIABLE_TRANSPORT = [
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, EOFError,
      IOError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    ].freeze
    private_constant :RETRIABLE_TRANSPORT

    # @return [Configuration] this client's own settings
    attr_reader :config

    # @param config [Configuration, nil] base settings; defaults to a copy of
    #   {RakutenRms.configuration}
    # @param overrides [Hash] per-client settings, e.g. +license_key:+
    def initialize(config = nil, **overrides)
      @config = (config || RakutenRms.configuration).dup.merge!(**overrides)
      @throttle_lock = Mutex.new
      @last_request_at = nil
    end

    # @return [Orders] the RakutenPay Order API
    def orders = @orders ||= Orders.new(self)

    # @return [Items] the Item API
    def items = @items ||= Items.new(self)

    # POST a JSON payload to an endpoint that *changes* something. Use this
    # directly for endpoints the gem does not wrap.
    #
    #   client.post("order/confirmOrder/", orderNumberList: ["123-456-789"])
    #
    # Never retried: RMS may have applied the change before the connection
    # failed, and replaying an +updateOrderSender+ would add its wrapping models
    # and prices a second time. Reads use {#query} instead.
    #
    # @param path [String] path below the API root
    # @param payload [Hash] request body, serialised as JSON
    # @return [Hash] the parsed response body
    def post(path, payload = {}) = json_post(path, payload, retriable: false)

    # POST a JSON payload to an endpoint that only *reads*, such as
    # +searchOrder+ or +getOrder+. Identical to {#post} except that a 429, 5xx
    # or dropped connection is retried.
    #
    # @param (see #post)
    # @return (see #post)
    def query(path, payload = {}) = json_post(path, payload, retriable: true)

    # GET with an optional query string.
    #
    # @param path [String] path below the API root
    # @param query [Hash] query parameters; nil values are dropped
    # @return [Hash] the parsed response body
    def get(path, query = {})
      compacted = query.compact
      suffix = compacted.empty? ? "" : "?#{URI.encode_www_form(compacted)}"
      request(Net::HTTP::Get, "#{path}#{suffix}", retriable: true)
    end

    private

    def json_post(path, payload, retriable:)
      request(Net::HTTP::Post, path, retriable: retriable) do |req|
        req["Content-Type"] = "application/json; charset=utf-8"
        req.body = JSON.generate(payload)
      end
    end

    def request(verb, path, retriable:)
      uri = build_uri(path)
      attempt = 0

      begin
        throttle
        response = perform(verb, uri) { |req| yield req if block_given? }
        config.logger&.debug { "RakutenRms #{verb::METHOD} #{uri.path} -> #{response.code}" }
        parse(check_status(response))
      rescue RateLimitError, ServerError, ConnectionError => e
        raise e unless retriable && attempt < config.max_retries

        attempt += 1
        sleep(config.retry_backoff * (2**(attempt - 1)))
        retry
      end
    end

    def build_uri(path)
      URI.parse("#{config.base_url.chomp('/')}/#{path.to_s.delete_prefix('/')}")
    end

    def perform(verb, uri)
      req = verb.new(uri)
      req["Authorization"] = config.authorization
      req["User-Agent"] = config.user_agent if config.user_agent
      yield req

      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: uri.scheme == "https",
                      open_timeout: config.open_timeout,
                      read_timeout: config.read_timeout) { |http| http.request(req) }
    rescue *RETRIABLE_TRANSPORT => e
      raise ConnectionError, "#{e.class}: #{e.message}"
    end

    # Pace request *starts* at least +request_gap+ apart, using a monotonic clock
    # so a wall-clock adjustment cannot stall or skip the gap.
    def throttle
      gap = config.request_gap.to_f
      return if gap <= 0

      @throttle_lock.synchronize do
        if @last_request_at
          remaining = gap - (clock_now - @last_request_at)
          sleep(remaining) if remaining.positive?
        end
        @last_request_at = clock_now
      end
    end

    def clock_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    def check_status(response)
      status = response.code.to_i
      return response if status.between?(200, 299)

      error_class =
        case status
        when 401, 403 then AuthenticationError
        when 429 then RateLimitError
        when 500..599 then ServerError
        else HTTPError
        end
      raise error_class.new(status: status, body: response.body)
    end

    def parse(response)
      body = response.body.to_s
      return {} if body.strip.empty?

      parsed = JSON.parse(body)
      raise_api_errors(parsed) if parsed.is_a?(Hash)
      parsed
    rescue JSON::ParserError => e
      raise Error, "could not parse RMS response as JSON (#{e.message}): #{body[0, 200]}"
    end

    # RMS reports failure two ways on a 200: an ESA gateway envelope, or ERROR
    # entries inside +MessageModelList+.
    def raise_api_errors(body)
      gateway = body["Results"]
      if gateway.is_a?(Hash) && gateway.key?("errorCode")
        raise APIError.new(
          [ Message.new(type: "ERROR", code: gateway["errorCode"], text: gateway["errorMessage"]) ],
          body: body
        )
      end

      errors = messages(body).select(&:error?)
      raise APIError.new(errors, body: body) unless errors.empty?
    end

    def messages(body)
      Array(body["MessageModelList"]).filter_map do |entry|
        next unless entry.is_a?(Hash)

        Message.new(type: entry["messageType"], code: entry["messageCode"], text: entry["message"])
      end
    end
  end
end
