# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class ItemsTest < TestCase
    def test_search_without_parameters_hits_the_bare_endpoint
      stub_request(:get, "#{BASE}/items/search")
        .to_return(status: 200, body: JSON.generate({ "numFound" => 0, "results" => [] }),
                   headers: { "Content-Type" => "application/json" })

      assert_empty build_client.items.search["results"]
    end

    def test_search_passes_parameters_through_as_a_query_string
      stub_request(:get, "#{BASE}/items/search?hits=100&offset=1")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      build_client.items.search(hits: 100, offset: 1)

      assert_requested(:get, "#{BASE}/items/search?hits=100&offset=1")
    end

    def test_search_raises_on_an_rms_error
      stub_request(:get, "#{BASE}/items/search")
        .to_return(status: 200,
                   body: JSON.generate({ "MessageModelList" => error_messages("ITEM_1", "権限がありません") }),
                   headers: { "Content-Type" => "application/json" })

      assert_raises(APIError) { build_client.items.search }
    end
  end
end
