# frozen_string_literal: true

module Sekki24
  module Solar
    module Fast
      J2000 = 2_451_545.0
      JULIAN_CENTURY = 36_525.0
      DEGREES_TO_RADIANS = Math::PI / 180.0

      module_function

      def longitude(jde)
        centuries = (Float(jde) - J2000) / JULIAN_CENTURY
        mean_longitude = 280.46646 + (36_000.76983 * centuries) + (0.0003032 * centuries**2)
        mean_anomaly = 357.52911 + (35_999.05029 * centuries) - (0.0001537 * centuries**2) +
          (centuries**3 / 24_490_000.0)
        center = equation_of_center(mean_anomaly, centuries)
        omega = 125.04 - (1934.136 * centuries)

        normalize(mean_longitude + center - 0.00569 - (0.00478 * sin_degrees(omega)))
      end

      def equation_of_center(mean_anomaly, centuries)
        ((1.914602 - (0.004817 * centuries) - (0.000014 * centuries**2)) * sin_degrees(mean_anomaly)) +
          ((0.019993 - (0.000101 * centuries)) * sin_degrees(2.0 * mean_anomaly)) +
          (0.000289 * sin_degrees(3.0 * mean_anomaly))
      end
      private_class_method :equation_of_center

      def sin_degrees(angle)
        Math.sin(angle * DEGREES_TO_RADIANS)
      end
      private_class_method :sin_degrees

      def normalize(angle)
        angle % 360.0
      end
      private_class_method :normalize
    end
  end
end
