# frozen_string_literal: true

require_relative "kou_names"
require_relative "kou"

module Sekki24
  module SeventyTwoKou
    @cache_mutex = Mutex.new
    @year_cache = {}
    @candidate_cache = {}

    class << self
      def year(year, tz:, precision:)
        calendar_year = validate_year(year)
        mode = normalize_precision(precision)
        solar = Solar.model(mode)
        cache_key = [calendar_year, TimeScale.timezone_key(tz), mode].freeze
        cached = @cache_mutex.synchronize { @year_cache[cache_key] }
        return cached if cached

        calculated = calculate_year(calendar_year, tz, mode, solar)
        @cache_mutex.synchronize { @year_cache[cache_key] ||= calculated }
      end

      def fetch(year, ordinal, tz:, precision:)
        definition = KouNames.fetch(ordinal)
        self.year(year, tz: tz, precision: precision).find { |entry| entry.ordinal == definition.ordinal }
      end

      def current(time, tz:, precision:)
        navigation_terms(time, tz, precision).select { |entry| entry.time <= time }.max ||
          raise(RangeError, "no current kou in the supported range")
      end

      def next_kou(time, tz:, precision:)
        navigation_terms(time, tz, precision).select { |entry| entry.time > time }.min ||
          raise(RangeError, "no next kou in the supported range")
      end

      def previous(time, tz:, precision:)
        navigation_terms(time, tz, precision).select { |entry| entry.time < time }.max ||
          raise(RangeError, "no previous kou in the supported range")
      end

      def clear_cache!
        @cache_mutex.synchronize do
          @year_cache.clear
          @candidate_cache.clear
        end
      end

      private

      def calculate_year(calendar_year, timezone, mode, solar)
        entries = candidate_times(calendar_year, mode, solar).map do |definition, utc_time|
          local_time = TimeScale.localize(utc_time, timezone)
          Kou.new(definition: definition, time: local_time)
        end.sort.freeze
        return entries if entries.length == 72

        raise Error, "expected 72 kou for #{calendar_year}, got #{entries.length}"
      end

      def candidate_times(year, mode, solar)
        cache_key = [year, mode].freeze
        cached = @cache_mutex.synchronize { @candidate_cache[cache_key] }
        return cached if cached

        calculated = Names::CALENDAR_ORDER.flat_map do |term_definition|
          term_time = Finder.find(year: year, longitude: term_definition.longitude, solar: solar).freeze
          KouNames::TERMS.select { |definition| definition.term_key == term_definition.key }.map do |definition|
            time = if definition.position == :initial
                     term_time
                   else
                     Finder.find_after(time: term_time, longitude: definition.longitude, solar: solar).freeze
                   end
            [definition, time].freeze
          end
        end.freeze
        @cache_mutex.synchronize { @candidate_cache[cache_key] ||= calculated }
      end

      def navigation_terms(time, timezone, precision)
        raise TypeError, "expected Time, got #{time.class}" unless time.is_a?(Time)

        local_year = TimeScale.localize(time, timezone).year
        years = ((local_year - 1)..(local_year + 1)).select { |value| (MIN_YEAR..MAX_YEAR).cover?(value) }
        years.flat_map { |value| year(value, tz: timezone, precision: precision) }
      end

      def validate_year(year)
        value = Integer(year)
        return value if (MIN_YEAR..MAX_YEAR).cover?(value)

        raise RangeError, "year must be between #{MIN_YEAR} and #{MAX_YEAR}"
      rescue ArgumentError, TypeError
        raise ArgumentError, "year must be an Integer between #{MIN_YEAR} and #{MAX_YEAR}"
      end

      def normalize_precision(precision)
        precision.to_sym
      rescue NoMethodError
        raise ArgumentError, "precision must be :fast or :precise"
      end
    end
  end

  class << self
    def kou_year(year, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      SeventyTwoKou.year(year, tz: tz, precision: precision)
    end

    def kou(year, ordinal, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      SeventyTwoKou.fetch(year, ordinal, tz: tz, precision: precision)
    end

    def current_kou(time = Time.now, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      SeventyTwoKou.current(time, tz: tz, precision: precision)
    end

    def next_kou(time = Time.now, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      SeventyTwoKou.next_kou(time, tz: tz, precision: precision)
    end

    def prev_kou(time = Time.now, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      SeventyTwoKou.previous(time, tz: tz, precision: precision)
    end
  end
end
