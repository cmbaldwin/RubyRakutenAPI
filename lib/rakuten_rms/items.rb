# frozen_string_literal: true

module RakutenRms
  # The Item API 2.0 (商品API).
  #
  #   client.items.search(hits: 100)["results"]
  class Items
    def initialize(client)
      @client = client
    end

    # +GET /items/search+ — the shop's items.
    #
    # Every documented query parameter is passed through, so this tracks the RMS
    # docs without the gem having to re-declare them:
    #
    #   client.items.search(hits: 100, offset: 1, isItemNumberSearch: true)
    #
    # @param params [Hash] query parameters; nil values are dropped
    # @return [Hash] the parsed response
    def search(**params) = @client.get("items/search", params)
  end
end
