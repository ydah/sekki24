# frozen_string_literal: true

require_relative "vsop87_earth"
require_relative "../nutation"

module Sekki24
  module Solar
    module Precise
      J2000 = 2_451_545.0
      JULIAN_MILLENNIUM = 365_250.0
      JULIAN_CENTURY = 36_525.0
      RADIANS_TO_DEGREES = 180.0 / Math::PI
      ABERRATION_ARCSECONDS = 20.4898
      FK5_LONGITUDE_CORRECTION = -0.09033 / 3600.0

      module_function

      def longitude(jde)
        jde = Float(jde)
        millennia = (jde - J2000) / JULIAN_MILLENNIUM
        earth_longitude = evaluate(VSOP87Earth::LONGITUDE, millennia) * RADIANS_TO_DEGREES
        radius = evaluate(VSOP87Earth::RADIUS, millennia)
        geometric_longitude = earth_longitude + 180.0 + FK5_LONGITUDE_CORRECTION
        apparent_longitude = geometric_longitude + Nutation.longitude(jde) -
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

    end
  end
end
