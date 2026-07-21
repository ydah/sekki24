# frozen_string_literal: true

module Sekki24
  module Nutation
    J2000 = 2_451_545.0
    JULIAN_CENTURY = 36_525.0
    DEGREES_TO_RADIANS = Math::PI / 180.0

    module_function

    # Four dominant IAU 1980 terms, returned in degrees.
    def longitude(jde)
      centuries = (Float(jde) - J2000) / JULIAN_CENTURY
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

    def sin_degrees(angle)
      Math.sin(angle * DEGREES_TO_RADIANS)
    end
    private_class_method :sin_degrees
  end
end
