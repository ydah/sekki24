# frozen_string_literal: true

require_relative "month"
require_relative "date"
require_relative "month_builder"

module Sekki24
  module Lunisolar
    module Calendar
      LEAP_MONTH_RULE = :winter_solstice_priority
      @cache_mutex = Mutex.new
      @range_cache = {}
      @year_cache = {}

      class << self
        def convert(value, tz:)
          local_date = local_date(value, tz)
          validate_gregorian_year(local_date.year)
          month = generated_range(local_date.year, tz).find { |entry| entry.include?(local_date) }
          raise Error, "could not assign lunisolar month for #{local_date}" unless month

          Date.new(
            year: month.year,
            month: month.month,
            day: (local_date - month.start_date).to_i + 1,
            leap: month.leap?,
            gregorian_date: local_date,
            month_length: month.length
          )
        end

        def year(year, tz:)
          lunar_year = validate_lunar_year(year)
          cache_key = [lunar_year, TimeScale.timezone_key(tz)].freeze
          cached = @cache_mutex.synchronize { @year_cache[cache_key] }
          return cached if cached

          months = generated_range(lunar_year, tz).select { |month| month.year == lunar_year }.freeze
          unless [12, 13].include?(months.length)
            raise Error, "expected 12 or 13 lunisolar months for #{lunar_year}, got #{months.length}"
          end
          @cache_mutex.synchronize { @year_cache[cache_key] ||= months }
        end

        def to_gregorian(year, month, day, leap:, tz:)
          lunar_year = validate_lunar_year(year)
          month_number = Integer(month)
          day_number = Integer(day)
          raise ArgumentError, "leap must be true or false" unless [true, false].include?(leap)
          unless (1..12).cover?(month_number)
            raise ArgumentError, "lunar month must be between 1 and 12"
          end

          target = self.year(lunar_year, tz: tz).find do |entry|
            entry.month == month_number && entry.leap? == leap
          end
          raise ArgumentError, "lunisolar month does not exist" unless target
          unless (1..target.length).cover?(day_number)
            raise ArgumentError, "lunar day must be between 1 and #{target.length}"
          end

          target.start_date + day_number - 1
        rescue TypeError
          raise ArgumentError, "lunar month and day must be Integers"
        end

        def clear_cache!
          @cache_mutex.synchronize do
            @range_cache.clear
            @year_cache.clear
          end
          MonthBuilder.clear_cache!
        end

        private

        def generated_range(center_year, timezone)
          cache_key = [center_year, TimeScale.timezone_key(timezone)].freeze
          cached = @cache_mutex.synchronize { @range_cache[cache_key] }
          return cached if cached

          years = ((center_year - 2)..(center_year + 2)).to_a
          generated = MonthBuilder.build(years, timezone)
          @cache_mutex.synchronize { @range_cache[cache_key] ||= generated }
        end

        def local_date(value, timezone)
          return value if value.instance_of?(::Date)
          return TimeScale.localize(value, timezone).to_date if value.is_a?(Time)

          raise TypeError, "expected Date or Time, got #{value.class}"
        end

        def validate_gregorian_year(year)
          return year if (MIN_YEAR..MAX_YEAR).cover?(year)

          raise RangeError, "date must fall within years #{MIN_YEAR}..#{MAX_YEAR}"
        end

        def validate_lunar_year(year)
          value = Integer(year)
          return value if (MIN_YEAR..MAX_YEAR).cover?(value)

          raise RangeError, "lunisolar year must be between #{MIN_YEAR} and #{MAX_YEAR}"
        rescue ArgumentError, TypeError
          raise ArgumentError, "lunisolar year must be an Integer"
        end
      end
    end
  end

  class << self
    def lunisolar(value, tz: DEFAULT_TIMEZONE)
      Lunisolar::Calendar.convert(value, tz: tz)
    end

    def lunisolar_year(year, tz: DEFAULT_TIMEZONE)
      Lunisolar::Calendar.year(year, tz: tz)
    end

    def gregorian(lunar_year, month, day, leap: false, tz: DEFAULT_TIMEZONE)
      Lunisolar::Calendar.to_gregorian(lunar_year, month, day, leap: leap, tz: tz)
    end
  end
end
