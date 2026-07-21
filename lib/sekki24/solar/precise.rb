# frozen_string_literal: true

require_relative "vsop87_earth"

module Sekki24
  module Solar
    module Precise
      J2000 = 2_451_545.0
      JULIAN_MILLENNIUM = 365_250.0
      JULIAN_CENTURY = 36_525.0
      RADIANS_TO_DEGREES = 180.0 / Math::PI
      DEGREES_TO_RADIANS = Math::PI / 180.0
      ABERRATION_ARCSECONDS = 20.4898
      FK5_LONGITUDE_CORRECTION = -0.09033 / 3600.0

      module_function

      def longitude(jde)
        jde = Float(jde)
        millennia = (jde - J2000) / JULIAN_MILLENNIUM
        earth_longitude = evaluate(VSOP87Earth::LONGITUDE, millennia) * RADIANS_TO_DEGREES
        radius = evaluate(VSOP87Earth::RADIUS, millennia)
        geometric_longitude = earth_longitude + 180.0 + FK5_LONGITUDE_CORRECTION
        apparent_longitude = geometric_longitude + nutation_longitude(jde) -
          (ABERRATION_ARCSECONDS / (3600.0 * radius))

        apparent_longitude % 360.0
      end

      def evaluate(series, time)
        power = 1.0
        series.sum do |terms|
          value = terms.sum do |amplitude, phase, frequency|
            amplitude * Math.cos(phase + (frequency * time))
          end
          result = value * power
          power *= time
          result
        end
      end
      private_class_method :evaluate

      # The four dominant IAU 1980 nutation terms are sufficient to keep
      # solar-term times within the one-minute public accuracy contract.
      def nutation_longitude(jde)
        centuries = (jde - J2000) / JULIAN_CENTURY
        sun_mean_longitude = 280.4665 + (36_000.7698 * centuries)
        moon_mean_longitude = 218.3165 + (481_267.8813 * centuries)
        ascending_node = 125.04452 - (1934.136261 * centuries) +
          (0.0020708 * centuries**2) + (centuries**3 / 450_000.0)

        arcseconds = (-17.20 * sin_degrees(ascending_node)) -
          (1.32 * sin_degrees(2.0 * sun_mean_longitude)) -
          (0.23 * sin_degrees(2.0 * moon_mean_longitude)) +
          (0.21 * sin_degrees(2.0 * ascending_node))
        arcseconds / 3600.0
      end
      private_class_method :nutation_longitude

      def sin_degrees(angle)
        Math.sin(angle * DEGREES_TO_RADIANS)
      end
      private_class_method :sin_degrees
    end
  end
end
