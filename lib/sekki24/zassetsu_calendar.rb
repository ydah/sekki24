# frozen_string_literal: true

require_relative "zassetsu"

module Sekki24
  module ZassetsuCalendar
    NAMES = {
      winter_doyo: ["冬土用", "ふゆどよう"],
      setsubun: ["節分", "せつぶん"],
      spring_higan: ["春彼岸", "はるひがん"],
      spring_shanichi: ["春社日", "はるしゃにち"],
      spring_doyo: ["春土用", "はるどよう"],
      hachijuhachiya: ["八十八夜", "はちじゅうはちや"],
      nyubai: ["入梅", "にゅうばい"],
      hangesho: ["半夏生", "はんげしょう"],
      summer_doyo: ["夏土用", "なつどよう"],
      nihyakutoka: ["二百十日", "にひゃくとおか"],
      nihyakuhatsuka: ["二百二十日", "にひゃくはつか"],
      autumn_higan: ["秋彼岸", "あきひがん"],
      autumn_shanichi: ["秋社日", "あきしゃにち"],
      autumn_doyo: ["秋土用", "あきどよう"]
    }.transform_values(&:freeze).freeze

    SOLAR_EVENTS = {
      winter_doyo: 297,
      spring_doyo: 27,
      nyubai: 80,
      hangesho: 100,
      summer_doyo: 117,
      autumn_doyo: 207
    }.freeze

    @cache_mutex = Mutex.new
    @year_cache = {}

    class << self
      def year(year, tz:, precision:)
        calendar_year = validate_year(year)
        mode = normalize_precision(precision)
        solar = Solar.model(mode)
        cache_key = [calendar_year, TimeScale.timezone_key(tz), mode].freeze
        cached = @cache_mutex.synchronize { @year_cache[cache_key] }
        return cached if cached

        calculated = calculate_year(calendar_year, tz, mode, solar).sort.freeze
        @cache_mutex.synchronize { @year_cache[cache_key] ||= calculated }
      end

      def fetch(year, key, tz:, precision:)
        normalized = key.to_sym
        raise ArgumentError, "unknown zassetsu: #{key.inspect}" unless NAMES.key?(normalized)

        self.year(year, tz: tz, precision: precision).find { |entry| entry.key == normalized }
      rescue NoMethodError
        raise ArgumentError, "unknown zassetsu: #{key.inspect}"
      end

      def on(date, tz:, precision:)
        raise TypeError, "expected Date, got #{date.class}" unless date.is_a?(Date)

        year(date.year, tz: tz, precision: precision).select { |entry| entry.date == date }.freeze
      end

      def active(date, tz:, precision:)
        raise TypeError, "expected Date or Time, got #{date.class}" unless date.is_a?(Date) || date.is_a?(Time)

        local_date = date.is_a?(Time) ? TimeScale.localize(date, tz).to_date : date
        year(local_date.year, tz: tz, precision: precision).select { |entry| entry.include?(local_date) }.freeze
      end

      def clear_cache!
        @cache_mutex.synchronize { @year_cache.clear }
      end

      private

      def calculate_year(year, timezone, mode, solar)
        terms = Sekki24.year(year, tz: timezone, precision: mode)
        by_key = terms.to_h { |term| [term.key, term] }
        solar_events = calculate_solar_events(year, timezone, solar, by_key)

        solar_events + date_observances(by_key) + shanichi_observances(by_key)
      end

      def calculate_solar_events(year, timezone, solar, terms)
        SOLAR_EVENTS.map do |key, longitude|
          utc_time = Finder.find(year: year, longitude: longitude, solar: solar)
          local_time = TimeScale.localize(utc_time, timezone)
          end_date = doyo_end_date(key, terms) || local_time.to_date
          build(key, category: :solar_longitude, date: local_time.to_date, end_date: end_date,
                     time: local_time, longitude: longitude)
        end
      end

      def date_observances(terms)
        risshun = terms.fetch(:risshun).to_date
        spring_equinox = terms.fetch(:shunbun).to_date
        autumn_equinox = terms.fetch(:shubun).to_date

        [
          build(:setsubun, category: :calendar_day, date: risshun - 1),
          build(:spring_higan, category: :period, date: spring_equinox - 3, end_date: spring_equinox + 3),
          build(:hachijuhachiya, category: :counted_day, date: risshun + 87),
          build(:nihyakutoka, category: :counted_day, date: risshun + 209),
          build(:nihyakuhatsuka, category: :counted_day, date: risshun + 219),
          build(:autumn_higan, category: :period, date: autumn_equinox - 3, end_date: autumn_equinox + 3)
        ]
      end

      def shanichi_observances(terms)
        [
          [:spring_shanichi, terms.fetch(:shunbun)],
          [:autumn_shanichi, terms.fetch(:shubun)]
        ].map do |key, equinox|
          build(key, category: :sexagenary_day, date: closest_tsuchinoe_day(equinox))
        end
      end

      def closest_tsuchinoe_day(equinox)
        center = equinox.to_date
        candidates = (-5..5).map { |offset| center + offset }.select { |date| ((date.jd + 49) % 10) == 4 }
        return candidates.first if candidates.length == 1

        equinox.time.hour < 12 ? candidates.min : candidates.max
      end

      def doyo_end_date(key, terms)
        season_start = {
          winter_doyo: :risshun,
          spring_doyo: :rikka,
          summer_doyo: :risshu,
          autumn_doyo: :ritto
        }[key]
        terms.fetch(season_start).to_date - 1 if season_start
      end

      def build(key, **attributes)
        name_ja, reading = NAMES.fetch(key)
        Zassetsu.new(key: key, name_ja: name_ja, reading: reading, **attributes)
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
    def zassetsu_year(year, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      ZassetsuCalendar.year(year, tz: tz, precision: precision)
    end

    def zassetsu(year, key, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      ZassetsuCalendar.fetch(year, key, tz: tz, precision: precision)
    end

    def zassetsu_on(date, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      ZassetsuCalendar.on(date, tz: tz, precision: precision)
    end

    def current_zassetsu(date = Date.today, tz: DEFAULT_TIMEZONE, precision: DEFAULT_PRECISION)
      ZassetsuCalendar.active(date, tz: tz, precision: precision)
    end
  end
end
