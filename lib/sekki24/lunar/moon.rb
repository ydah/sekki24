# frozen_string_literal: true

require_relative "periodic_terms"
require_relative "../nutation"

module Sekki24
  module Lunar
    module Moon
      J2000 = 2_451_545.0
      JULIAN_CENTURY = 36_525.0
      DEGREES_TO_RADIANS = Math::PI / 180.0

      module_function

      def longitude(jde)
        centuries = (Float(jde) - J2000) / JULIAN_CENTURY
        arguments = fundamental_arguments(centuries)
        correction = periodic_correction(arguments, centuries) + additive_correction(arguments, centuries)

        (arguments.fetch(:moon_longitude) + correction + Nutation.longitude(jde)) % 360.0
      end

      def fundamental_arguments(t)
        {
          moon_longitude: 218.3164477 + (481_267.88123421 * t) - (0.0015786 * t**2) +
            (t**3 / 538_841.0) - (t**4 / 65_194_000.0),
          elongation: 297.8501921 + (445_267.1114034 * t) - (0.0018819 * t**2) +
            (t**3 / 545_868.0) - (t**4 / 113_065_000.0),
          sun_anomaly: 357.5291092 + (35_999.0502909 * t) - (0.0001536 * t**2) +
            (t**3 / 24_490_000.0),
          moon_anomaly: 134.9633964 + (477_198.8675055 * t) + (0.0087414 * t**2) +
            (t**3 / 69_699.0) - (t**4 / 14_712_000.0),
          latitude_argument: 93.2720950 + (483_202.0175233 * t) - (0.0036539 * t**2) -
            (t**3 / 3_526_000.0) + (t**4 / 863_310_000.0)
        }
      end
      private_class_method :fundamental_arguments

      def periodic_correction(arguments, centuries)
        eccentricity = 1.0 - (0.002516 * centuries) - (0.0000074 * centuries**2)
        sum = PeriodicTerms::LONGITUDE.sum do |d, m, moon_m, f, coefficient|
          angle = (d * arguments.fetch(:elongation)) + (m * arguments.fetch(:sun_anomaly)) +
            (moon_m * arguments.fetch(:moon_anomaly)) + (f * arguments.fetch(:latitude_argument))
          coefficient * eccentricity**m.abs * sin_degrees(angle)
        end
        sum / 1_000_000.0
      end
      private_class_method :periodic_correction

      def additive_correction(arguments, centuries)
        a1 = 119.75 + (131.849 * centuries)
        a2 = 53.09 + (479_264.290 * centuries)
        correction = (3_958 * sin_degrees(a1)) +
          (1_962 * sin_degrees(arguments.fetch(:moon_longitude) - arguments.fetch(:latitude_argument))) +
          (318 * sin_degrees(a2))
        correction / 1_000_000.0
      end
      private_class_method :additive_correction

      def sin_degrees(angle)
        Math.sin(angle * DEGREES_TO_RADIANS)
      end
      private_class_method :sin_degrees
    end
  end
end
