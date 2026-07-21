# frozen_string_literal: true

require_relative "sekki24/version"

module Sekki24
  class Error < StandardError; end
end

require_relative "sekki24/names"
require_relative "sekki24/term"
require_relative "sekki24/delta_t"
require_relative "sekki24/time_scale"
require_relative "sekki24/solar"
require_relative "sekki24/finder"

module Sekki24
  MIN_YEAR = 1900
  MAX_YEAR = 2100
  DEFAULT_TIMEZONE = "+00:00"
  DEFAULT_PRECISION = :precise

  @cache_mutex = Mutex.new
  @year_cache = {}
  @candidate_cache = {}

  class << self
    def year(year, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      calendar_year = validate_year(year)
      mode, solar = resolve_precision(precision)
      cache_key = [calendar_year, TimeScale.timezone_key(tz), mode].freeze
      cached = @cache_mutex.synchronize { @year_cache[cache_key] }
      return cached if cached

      calculated = calculate_year(calendar_year, tz, mode, solar)
      @cache_mutex.synchronize { @year_cache[cache_key] ||= calculated }
    end

    def term(year, key, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      definition = Names.fetch(key)
      self.year(year, tz: tz, precision: precision).find { |entry| entry.key == definition.key }
    end

    def current(time = Time.now, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      instant = ensure_time(time)
      navigation_terms(instant, tz, precision).select { |entry| entry.time <= instant }.max ||
        raise(RangeError, "no current solar term in the supported range")
    end

    def next_term(time = Time.now, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      instant = ensure_time(time)
      navigation_terms(instant, tz, precision).select { |entry| entry.time > instant }.min ||
        raise(RangeError, "no next solar term in the supported range")
    end

    def prev_term(time = Time.now, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      instant = ensure_time(time)
      navigation_terms(instant, tz, precision).select { |entry| entry.time < instant }.max ||
        raise(RangeError, "no previous solar term in the supported range")
    end

    def on(date, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      unless date.is_a?(Date)
        raise TypeError, "expected Date, got #{date.class}"
      end

      year(date.year, tz: tz, precision: precision).find { |entry| entry.to_date == date }
    end

    def clear_cache!
      @cache_mutex.synchronize do
        @year_cache.clear
        @candidate_cache.clear
      end
      SeventyTwoKou.clear_cache! if defined?(SeventyTwoKou)
      nil
    end

    private

    def calculate_year(calendar_year, timezone, mode, solar)
      candidates = ((calendar_year - 1)..(calendar_year + 1)).flat_map do |utc_year|
        candidate_times(utc_year, mode, solar)
      end
      terms = candidates.filter_map do |definition, utc_time|
        local_time = TimeScale.localize(utc_time, timezone)
        next unless local_time.year == calendar_year

        Term.new(definition: definition, time: local_time)
      end.sort.freeze

      return terms if terms.length == 24

      raise Error, "expected 24 solar terms for #{calendar_year}, got #{terms.length}"
    end

    def candidate_times(year, mode, solar)
      cache_key = [year, mode].freeze
      cached = @cache_mutex.synchronize { @candidate_cache[cache_key] }
      return cached if cached

      calculated = Names::CALENDAR_ORDER.map do |definition|
        utc_time = Finder.find(year: year, longitude: definition.longitude, solar: solar).freeze
        [definition, utc_time].freeze
      end.freeze
      @cache_mutex.synchronize { @candidate_cache[cache_key] ||= calculated }
    end

    def navigation_terms(time, timezone, precision)
      local_year = TimeScale.localize(time, timezone).year
      years = ((local_year - 1)..(local_year + 1)).select { |value| (MIN_YEAR..MAX_YEAR).cover?(value) }
      raise RangeError, "time must fall within years #{MIN_YEAR}..#{MAX_YEAR}" if years.empty?

      years.flat_map { |value| year(value, tz: timezone, precision: precision) }
    end

    def validate_year(year)
      value = Integer(year)
      return value if (MIN_YEAR..MAX_YEAR).cover?(value)

      raise RangeError, "year must be between #{MIN_YEAR} and #{MAX_YEAR}"
    rescue ArgumentError, TypeError
      raise ArgumentError, "year must be an Integer between #{MIN_YEAR} and #{MAX_YEAR}"
    end

    def resolve_precision(precision)
      mode = precision.to_sym
      [mode, Solar.model(mode)]
    rescue NoMethodError
      raise ArgumentError, "precision must be :fast or :precise"
    end

    def ensure_time(time)
      return time if time.is_a?(Time)

      raise TypeError, "expected Time, got #{time.class}"
    end
  end
end

require_relative "sekki24/seventy_two_kou"
