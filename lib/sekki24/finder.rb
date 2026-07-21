# frozen_string_literal: true

module Sekki24
  module Finder
    MEAN_SOLAR_MOTION = 0.9856
    DERIVATIVE_HALF_WINDOW = 1.0 / 24.0
    ANGULAR_TOLERANCE = 1e-6
    NEWTON_ATTEMPTS = 5
    MAX_NEWTON_STEP = 5.0
    BISECTION_ATTEMPTS = 80

    class ConvergenceError < Sekki24::Error; end

    module_function

    def find(year:, longitude:, solar:)
      start = TimeScale.utc_to_jde(Time.utc(Integer(year), 1, 1))
      start_longitude = solar.longitude(start)
      estimate = start + (positive_difference(longitude, start_longitude) / MEAN_SOLAR_MOTION)
      root = newton(estimate, longitude, solar)
      TimeScale.jde_to_utc(root)
    end

    def newton(estimate, target, solar)
      jde = estimate

      NEWTON_ATTEMPTS.times do
        error = signed_difference(solar.longitude(jde), target)
        return jde if error.abs < ANGULAR_TOLERANCE

        derivative = numerical_derivative(jde, solar)
        break unless derivative.finite? && derivative.positive?

        step = error / derivative
        break if step.abs > MAX_NEWTON_STEP

        jde -= step
      end

      bisect(estimate, target, solar)
    end
    private_class_method :newton

    def numerical_derivative(jde, solar)
      before = solar.longitude(jde - DERIVATIVE_HALF_WINDOW)
      after = solar.longitude(jde + DERIVATIVE_HALF_WINDOW)
      signed_difference(after, before) / (2.0 * DERIVATIVE_HALF_WINDOW)
    end
    private_class_method :numerical_derivative

    def bisect(estimate, target, solar)
      radius = 2.0
      lower, upper, lower_error, upper_error = bracket(estimate, target, solar, radius)

      while lower_error * upper_error > 0.0 && radius < 32.0
        radius *= 2.0
        lower, upper, lower_error, upper_error = bracket(estimate, target, solar, radius)
      end

      if lower_error * upper_error > 0.0
        raise ConvergenceError, "could not bracket solar longitude #{target}°"
      end

      BISECTION_ATTEMPTS.times do
        midpoint = (lower + upper) / 2.0
        midpoint_error = signed_difference(solar.longitude(midpoint), target)
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
    private_class_method :bisect

    def bracket(estimate, target, solar, radius)
      lower = estimate - radius
      upper = estimate + radius
      [
        lower,
        upper,
        signed_difference(solar.longitude(lower), target),
        signed_difference(solar.longitude(upper), target)
      ]
    end
    private_class_method :bracket

    def positive_difference(target, actual)
      (Float(target) - actual) % 360.0
    end
    private_class_method :positive_difference

    def signed_difference(left, right)
      ((left - right + 180.0) % 360.0) - 180.0
    end
    private_class_method :signed_difference
  end
end
