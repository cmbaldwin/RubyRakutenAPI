# frozen_string_literal: true

require "date"
require "time"

module RakutenRms
  # RMS timestamps are Japan Standard Time with an explicit +0900 offset and no
  # colon (+2017-10-14T00:00:00+0900+).
  #
  # Values carrying a zone are *converted* to JST, so a UTC +Time+ names the same
  # instant it always did. Values without one (a +Date+, or a string like
  # +"2026-01-14"+) are read as JST rather than as the server's local time —
  # otherwise a machine running in UTC would search the wrong day.
  module TimeFormat
    OFFSET = "+09:00"

    class << self
      # @param value [Time, DateTime, Date, String]
      # @return [String] e.g. +"2026-01-14T00:00:00+0900"+
      def datetime(value) = to_time(value).strftime("%Y-%m-%dT%H:%M:%S%z")

      # @param value [Time, DateTime, Date, String]
      # @return [String] the JST calendar day, e.g. +"2026-01-14"+
      def date(value)
        # A bare Date is already a calendar day; don't round-trip it through a
        # zone conversion that could only move it.
        return value.strftime("%Y-%m-%d") if value.instance_of?(Date)

        to_time(value).strftime("%Y-%m-%d")
      end

      # @param value [Time, DateTime, Date, String]
      # @return [Time] the same moment, expressed in JST
      # @raise [ArgumentError] for any other type, or an unparseable string
      def to_time(value)
        case value
        when String then parse(value)
        when DateTime then value.to_time.getlocal(OFFSET) # DateTime < Date, so test it first
        when Date then jst(value.year, value.month, value.day)
        when Time then value.getlocal(OFFSET)
        else raise ArgumentError, "expected a Time, DateTime, Date or String, got #{value.class}"
        end
      end

      private

      def parse(value)
        parts = Date._parse(value)
        raise ArgumentError, "could not parse #{value.inspect} as a date or time" unless parts[:year] && parts[:mon] && parts[:mday]
        return Time.parse(value).getlocal(OFFSET) if parts[:offset] || parts[:zone]

        jst(parts[:year], parts[:mon], parts[:mday], parts[:hour], parts[:min], parts[:sec])
      end

      def jst(year, month, day, hour = nil, minute = nil, second = nil)
        Time.new(year, month, day, hour || 0, minute || 0, second || 0, OFFSET)
      end
    end
  end
end
