# frozen_string_literal: true

module Sekki24
  module TimeScale
    UNIX_EPOCH_JD = 2_440_587.5
    SECONDS_PER_DAY = 86_400.0
    OFFSET_PATTERN = /\A([+-])(\d{2}):(\d{2})\z/

    module_function

    def utc_to_jd(time)
      utc_time = coerce_time(time).getutc
      (utc_time.to_r / SECONDS_PER_DAY) + UNIX_EPOCH_JD
    end

    def jd_to_utc(jd)
      Time.at((Float(jd) - UNIX_EPOCH_JD) * SECONDS_PER_DAY).utc
    end

    def utc_to_jde(time)
      utc_time = coerce_time(time).getutc
      utc_to_jd(utc_time) + (DeltaT.seconds(decimal_year(utc_time)) / SECONDS_PER_DAY)
    end

    def jde_to_utc(jde)
      utc = jd_to_utc(jde)
      2.times do
        utc = jd_to_utc(Float(jde) - (DeltaT.seconds(decimal_year(utc)) / SECONDS_PER_DAY))
      end
      utc
    end

    def decimal_year(time)
      utc_time = coerce_time(time).getutc
      year_start = Time.utc(utc_time.year, 1, 1)
      next_year = Time.utc(utc_time.year + 1, 1, 1)
      utc_time.year + ((utc_time - year_start) / (next_year - year_start))
    end

    def localize(time, timezone)
      utc_time = coerce_time(time).getutc
      offset = fixed_offset(timezone)
      return utc_time.getlocal(offset) unless offset.nil?

      local = timezone.utc_to_local(utc_time)
      return local if local.is_a?(Time)

      raise ArgumentError, "timezone utc_to_local must return a Time"
    end

    def timezone_key(timezone)
      offset = fixed_offset(timezone)
      return [:offset, offset].freeze unless offset.nil?

      identifier = timezone.identifier if timezone.respond_to?(:identifier)
      [:timezone, identifier || timezone.object_id].freeze
    end

    def fixed_offset(timezone)
      return validate_offset(timezone) if timezone.is_a?(Integer)
      return 0 if %w[UTC Z].include?(timezone)

      if timezone.is_a?(String)
        match = OFFSET_PATTERN.match(timezone)
        raise ArgumentError, 'timezone must use the format "+09:00"' unless match

        sign = match[1] == "+" ? 1 : -1
        hours = match[2].to_i
        minutes = match[3].to_i
        raise ArgumentError, "timezone offset is out of range" if hours > 23 || minutes > 59

        return validate_offset(sign * ((hours * 3600) + (minutes * 60)))
      end

      return nil if timezone.respond_to?(:utc_to_local)

      raise ArgumentError, "timezone must be an offset String, Integer, or timezone object"
    end

    def coerce_time(value)
      return value if value.is_a?(Time)

      raise TypeError, "expected Time, got #{value.class}"
    end
    private_class_method :coerce_time

    def validate_offset(offset)
      raise ArgumentError, "timezone offset is out of range" unless (-86_399..86_399).cover?(offset)

      offset
    end
    private_class_method :validate_offset
  end
end
