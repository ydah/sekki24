# frozen_string_literal: true

require_relative "moon"

module Sekki24
  module Lunar
    module PhaseFinder
      MEAN_NEW_MOON_EPOCH = 2_451_550.09765
      SYNODIC_MONTH = 29.530588853
      DERIVATIVE_HALF_WINDOW = 1.0 / 24.0
      ANGULAR_TOLERANCE = 1e-7
      NEWTON_ATTEMPTS = 8

      @cache_mutex = Mutex.new
      @root_cache = {}
      @year_cache = {}

      class << self
        def new_moons(year, tz:)
          calendar_year = validate_year(year)
          cache_key = [calendar_year, TimeScale.timezone_key(tz)].freeze
          cached = @cache_mutex.synchronize { @year_cache[cache_key] }
          return cached if cached

          roots = roots_near_year(calendar_year).filter_map do |time|
            local = TimeScale.localize(time, tz)
            local.freeze if local.year == calendar_year
          end.freeze
          @cache_mutex.synchronize { @year_cache[cache_key] ||= roots }
        end

        def new_moon_before(time)
          raise TypeError, "expected Time, got #{time.class}" unless time.is_a?(Time)

          jde = TimeScale.utc_to_jde(time)
          lunation = ((jde - MEAN_NEW_MOON_EPOCH) / SYNODIC_MONTH).floor
          root = root_for(lunation)
          root > time ? root_for(lunation - 1) : root
        end

        def new_moon_after(time)
          raise TypeError, "expected Time, got #{time.class}" unless time.is_a?(Time)

          jde = TimeScale.utc_to_jde(time)
          lunation = ((jde - MEAN_NEW_MOON_EPOCH) / SYNODIC_MONTH).ceil
          root = root_for(lunation)
          root <= time ? root_for(lunation + 1) : root
        end

        def clear_cache!
          @cache_mutex.synchronize do
            @root_cache.clear
            @year_cache.clear
          end
        end

        private

        def roots_near_year(year)
          start_jde = TimeScale.utc_to_jde(Time.utc(year, 1, 1))
          end_jde = TimeScale.utc_to_jde(Time.utc(year + 1, 1, 1))
          first = ((start_jde - MEAN_NEW_MOON_EPOCH) / SYNODIC_MONTH).floor - 2
          last = ((end_jde - MEAN_NEW_MOON_EPOCH) / SYNODIC_MONTH).ceil + 2
          (first..last).map { |lunation| root_for(lunation) }
        end

        def root_for(lunation)
          cached = @cache_mutex.synchronize { @root_cache[lunation] }
          return cached if cached

          estimate = MEAN_NEW_MOON_EPOCH + (SYNODIC_MONTH * lunation)
          utc = TimeScale.jde_to_utc(solve(estimate)).freeze
          @cache_mutex.synchronize { @root_cache[lunation] ||= utc }
        end

        def solve(estimate)
          jde = estimate
          NEWTON_ATTEMPTS.times do
            error = phase_error(jde)
            return jde if error.abs < ANGULAR_TOLERANCE

            derivative = numerical_derivative(jde)
            break unless derivative.finite? && derivative.positive?

            step = error / derivative
            break if step.abs > 2.0

            jde -= step
          end
          bisect(estimate - 2.0, estimate + 2.0)
        end

        def numerical_derivative(jde)
          before = phase_error(jde - DERIVATIVE_HALF_WINDOW)
          after = phase_error(jde + DERIVATIVE_HALF_WINDOW)
          signed_difference(after, before) / (2.0 * DERIVATIVE_HALF_WINDOW)
        end

        def bisect(lower, upper)
          lower_error = phase_error(lower)
          80.times do
            midpoint = (lower + upper) / 2.0
            midpoint_error = phase_error(midpoint)
            return midpoint if midpoint_error.abs < ANGULAR_TOLERANCE

            if lower_error * midpoint_error <= 0.0
              upper = midpoint
            else
              lower = midpoint
              lower_error = midpoint_error
            end
          end
          (lower + upper) / 2.0
        end

        def phase_error(jde)
          signed_difference(Moon.longitude(jde), Solar::Precise.longitude(jde))
        end

        def signed_difference(left, right)
          ((left - right + 180.0) % 360.0) - 180.0
        end

        def validate_year(year)
          value = Integer(year)
          return value if (MIN_YEAR..MAX_YEAR).cover?(value)

          raise RangeError, "year must be between #{MIN_YEAR} and #{MAX_YEAR}"
        rescue ArgumentError, TypeError
          raise ArgumentError, "year must be an Integer between #{MIN_YEAR} and #{MAX_YEAR}"
        end
      end
    end
  end

  class << self
    def new_moons(year, tz: DEFAULT_TIMEZONE)
      Lunar::PhaseFinder.new_moons(year, tz: tz)
    end

    def new_moon_before(time = Time.now)
      Lunar::PhaseFinder.new_moon_before(time)
    end

    def new_moon_after(time = Time.now)
      Lunar::PhaseFinder.new_moon_after(time)
    end

    def moon_longitude(time)
      Lunar::Moon.longitude(TimeScale.utc_to_jde(time))
    end
  end
end
