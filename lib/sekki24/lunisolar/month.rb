# frozen_string_literal: true

module Sekki24
  module Lunisolar
    class Month
      MONTH_NAMES = %w[正月 二月 三月 四月 五月 六月 七月 八月 九月 十月 十一月 十二月].freeze

      attr_reader :year, :month, :start_date, :end_date, :new_moon_time, :principal_longitudes

      def initialize(year:, month:, leap:, start_date:, end_date:, new_moon_time:, principal_longitudes:)
        @year = year
        @month = month
        @leap = leap
        @start_date = start_date.freeze
        @end_date = end_date.freeze
        @new_moon_time = new_moon_time.dup.freeze
        @principal_longitudes = principal_longitudes.dup.freeze
        freeze
      end

      def leap?
        @leap
      end

      def length
        (end_date - start_date).to_i + 1
      end

      def name_ja
        prefix = leap? ? "閏" : ""
        "#{prefix}#{MONTH_NAMES.fetch(month - 1)}"
      end

      def include?(date)
        (start_date..end_date).cover?(date)
      end

      def ==(other)
        other.is_a?(Month) && year == other.year && month == other.month &&
          leap? == other.leap? && start_date == other.start_date
      end
      alias eql? ==

      def hash
        [self.class, year, month, leap?, start_date].hash
      end

      def to_h
        {
          year: year,
          month: month,
          leap: leap?,
          name_ja: name_ja,
          start_date: start_date,
          end_date: end_date,
          length: length,
          new_moon_time: new_moon_time,
          principal_longitudes: principal_longitudes
        }
      end

      def inspect
        "#<#{self.class} #{year}年#{name_ja} #{start_date.iso8601}..#{end_date.iso8601}>"
      end
    end
  end
end
