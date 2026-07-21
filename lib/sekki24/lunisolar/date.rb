# frozen_string_literal: true

module Sekki24
  module Lunisolar
    class Date
      attr_reader :year, :month, :day, :gregorian_date, :month_length

      def initialize(year:, month:, day:, leap:, gregorian_date:, month_length:)
        @year = year
        @month = month
        @day = day
        @leap = leap
        @gregorian_date = gregorian_date.freeze
        @month_length = month_length
        freeze
      end

      def leap?
        @leap
      end

      def month_name_ja
        prefix = leap? ? "閏" : ""
        "#{prefix}#{Month::MONTH_NAMES.fetch(month - 1)}"
      end

      def to_date
        gregorian_date
      end

      def ==(other)
        other.is_a?(Date) && year == other.year && month == other.month &&
          day == other.day && leap? == other.leap?
      end
      alias eql? ==

      def hash
        [self.class, year, month, day, leap?].hash
      end

      def to_h
        {
          year: year,
          month: month,
          day: day,
          leap: leap?,
          month_name_ja: month_name_ja,
          month_length: month_length,
          gregorian_date: gregorian_date
        }
      end

      def inspect
        "#<#{self.class} #{year}年#{month_name_ja}#{day}日 (#{gregorian_date.iso8601})>"
      end
    end
  end
end
