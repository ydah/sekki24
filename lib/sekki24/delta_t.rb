# frozen_string_literal: true

module Sekki24
  module DeltaT
    module_function

    # Espenak & Meeus polynomials. The return value is TT - UT in seconds.
    def seconds(decimal_year)
      year = Float(decimal_year)

      case year
      when 1860...1900 then between_1860_and_1900(year - 1860.0)
      when 1900...1920 then between_1900_and_1920(year - 1900.0)
      when 1920...1941 then between_1920_and_1941(year - 1920.0)
      when 1941...1961 then between_1941_and_1961(year - 1950.0)
      when 1961...1986 then between_1961_and_1986(year - 1975.0)
      when 1986...2005 then between_1986_and_2005(year - 2000.0)
      when 2005...2050 then between_2005_and_2050(year - 2000.0)
      when 2050..2150 then between_2050_and_2150(year)
      else
        raise RangeError, "delta T is supported for years 1860..2150"
      end
    end

    def between_1860_and_1900(t)
      7.62 + (0.5737 * t) - (0.251754 * t**2) + (0.01680668 * t**3) -
        (0.0004473624 * t**4) + (t**5 / 233_174.0)
    end
    private_class_method :between_1860_and_1900

    def between_1900_and_1920(t)
      -2.79 + (1.494119 * t) - (0.0598939 * t**2) + (0.0061966 * t**3) - (0.000197 * t**4)
    end
    private_class_method :between_1900_and_1920

    def between_1920_and_1941(t)
      21.20 + (0.84493 * t) - (0.0761 * t**2) + (0.0020936 * t**3)
    end
    private_class_method :between_1920_and_1941

    def between_1941_and_1961(t)
      29.07 + (0.407 * t) - (t**2 / 233.0) + (t**3 / 2547.0)
    end
    private_class_method :between_1941_and_1961

    def between_1961_and_1986(t)
      45.45 + (1.067 * t) - (t**2 / 260.0) - (t**3 / 718.0)
    end
    private_class_method :between_1961_and_1986

    def between_1986_and_2005(t)
      63.86 + (0.3345 * t) - (0.060374 * t**2) + (0.0017275 * t**3) +
        (0.000651814 * t**4) + (0.00002373599 * t**5)
    end
    private_class_method :between_1986_and_2005

    def between_2005_and_2050(t)
      62.92 + (0.32217 * t) + (0.005589 * t**2)
    end
    private_class_method :between_2005_and_2050

    def between_2050_and_2150(year)
      -20.0 + (32.0 * ((year - 1820.0) / 100.0)**2) - (0.5628 * (2150.0 - year))
    end
    private_class_method :between_2050_and_2150
  end
end
