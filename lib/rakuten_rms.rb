# frozen_string_literal: true

require_relative "rakuten_rms/version"
require_relative "rakuten_rms/errors"
require_relative "rakuten_rms/codes"
require_relative "rakuten_rms/time_format"
require_relative "rakuten_rms/configuration"
require_relative "rakuten_rms/orders"
require_relative "rakuten_rms/items"
require_relative "rakuten_rms/client"

# A client for Rakuten's RMS WEB SERVICE API (RakutenPay Order API and Item API).
#
#   RakutenRms.configure do |config|
#     config.service_secret = ENV["RAKUTEN_SERVICE_SECRET"]
#     config.license_key    = ENV["RAKUTEN_LICENSE_KEY"]
#   end
#
#   client = RakutenRms::Client.new
#   client.orders.get(client.orders.search(start_date: Date.today - 1, end_date: Date.today))
module RakutenRms
  class << self
    # Process-wide defaults. Every {Client} starts from a copy of this, so a
    # client's own overrides never mutate it.
    #
    # @return [Configuration]
    def configuration = @configuration ||= Configuration.new

    # @yieldparam config [Configuration]
    # @return [Configuration]
    def configure
      yield configuration
      configuration
    end

    # Discard the process-wide defaults. Useful between tests.
    #
    # @return [Configuration] the fresh defaults
    def reset_configuration! = @configuration = Configuration.new
  end
end
