# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class CodesTest < TestCase
    def test_resolve_maps_a_symbol_to_its_code
      assert_equal 100, Codes.resolve(Codes::ORDER_PROGRESS, :awaiting_confirmation)
      assert_equal 3, Codes.resolve(Codes::DELIVERY_CLASS, :frozen)
      assert_equal "1001", Codes.resolve(Codes::DELIVERY_COMPANY, :yamato)
    end

    def test_resolve_passes_a_literal_code_through
      assert_equal 500, Codes.resolve(Codes::ORDER_PROGRESS, 500)
      assert_equal 1416, Codes.resolve(Codes::SHIPPING_TERM, 1416), "custom h1h2 time ranges are not in the table"
    end

    def test_resolve_rejects_an_unknown_symbol_and_lists_the_alternatives
      error = assert_raises(ArgumentError) { Codes.resolve(Codes::DELIVERY_CLASS, :freezing) }

      assert_includes error.message, "freezing"
      assert_includes error.message, "frozen"
    end

    def test_resolve_all_handles_a_scalar_an_array_and_nothing
      assert_equal [ 100 ], Codes.resolve_all(Codes::ORDER_PROGRESS, :awaiting_confirmation)
      assert_equal [ 100, 500 ], Codes.resolve_all(Codes::ORDER_PROGRESS, %i[awaiting_confirmation shipped])
      assert_empty Codes.resolve_all(Codes::ORDER_PROGRESS, [])
      assert_empty Codes.resolve_all(Codes::ORDER_PROGRESS, nil)
    end

    def test_order_progress_matches_the_documented_codes
      assert_equal [ 100, 200, 300, 400, 500, 600, 700, 800, 900 ], Codes::ORDER_PROGRESS.values
    end

    def test_the_tables_are_frozen_so_callers_cannot_corrupt_them
      assert_predicate Codes::ORDER_PROGRESS, :frozen?
      assert_predicate Codes::DELIVERY_COMPANY, :frozen?
    end
  end
end
