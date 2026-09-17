# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class TimeFormatTest < TestCase
    # --- datetime ----------------------------------------------------------

    def test_a_date_becomes_midnight_jst
      assert_equal "2026-01-14T00:00:00+0900", TimeFormat.datetime(Date.new(2026, 1, 14))
    end

    # The whole point of converting rather than relabelling: a UTC instant must
    # keep naming the same moment, which in JST is nine hours later.
    def test_a_utc_time_is_converted_not_relabelled
      utc = Time.utc(2026, 1, 13, 15, 30, 0)

      assert_equal "2026-01-14T00:30:00+0900", TimeFormat.datetime(utc)
    end

    def test_a_time_already_in_jst_is_unchanged
      jst = Time.new(2026, 1, 14, 9, 0, 0, "+09:00")

      assert_equal "2026-01-14T09:00:00+0900", TimeFormat.datetime(jst)
    end

    def test_a_time_in_another_zone_is_converted
      new_york = Time.new(2026, 1, 13, 10, 0, 0, "-05:00")

      assert_equal "2026-01-14T00:00:00+0900", TimeFormat.datetime(new_york)
    end

    def test_a_datetime_is_converted
      assert_equal "2026-01-14T09:00:00+0900",
                   TimeFormat.datetime(DateTime.new(2026, 1, 14, 0, 0, 0, "+00:00"))
    end

    # Without an offset in the string there is nothing to convert from, and
    # reading it as the server's local time would silently search the wrong day
    # on a machine set to UTC.
    def test_a_zoneless_string_is_read_as_jst
      assert_equal "2026-01-14T00:00:00+0900", TimeFormat.datetime("2026-01-14")
      assert_equal "2026-01-14T08:30:00+0900", TimeFormat.datetime("2026-01-14 08:30:00")
    end

    def test_a_string_with_an_offset_is_converted_from_it
      assert_equal "2026-01-14T09:00:00+0900", TimeFormat.datetime("2026-01-14T00:00:00Z")
      assert_equal "2026-01-14T09:00:00+0900", TimeFormat.datetime("2026-01-13T19:00:00-05:00")
    end

    def test_an_rms_formatted_string_round_trips_unchanged
      assert_equal "2026-01-14T00:00:00+0900", TimeFormat.datetime("2026-01-14T00:00:00+0900")
    end

    def test_the_offset_is_written_without_a_colon_as_rms_expects
      assert_match(/\+0900\z/, TimeFormat.datetime(Date.new(2026, 1, 14)))
    end

    # --- date --------------------------------------------------------------

    def test_date_of_a_date_is_that_calendar_day
      assert_equal "2026-01-14", TimeFormat.date(Date.new(2026, 1, 14))
    end

    def test_date_of_a_utc_time_is_the_jst_calendar_day
      # 23:00 UTC is already the next day in Tokyo.
      assert_equal "2026-01-15", TimeFormat.date(Time.utc(2026, 1, 14, 23, 0, 0))
    end

    def test_date_of_a_string_keeps_the_day
      assert_equal "2026-01-14", TimeFormat.date("2026-01-14")
    end

    # --- to_time -----------------------------------------------------------

    def test_to_time_returns_a_jst_time
      result = TimeFormat.to_time(Date.new(2026, 1, 14))

      assert_kind_of Time, result
      assert_equal 9 * 3600, result.utc_offset
    end

    def test_unsupported_types_are_rejected
      error = assert_raises(ArgumentError) { TimeFormat.to_time(1_768_000_000) }

      assert_includes error.message, "Integer"
    end

    def test_an_unparseable_string_is_rejected
      assert_raises(ArgumentError) { TimeFormat.to_time("last tuesday-ish") }
    end
  end
end
