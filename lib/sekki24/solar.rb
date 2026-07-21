# frozen_string_literal: true

require_relative "solar/fast"
require_relative "solar/precise"

module Sekki24
  module Solar
    MODELS = {
      fast: Fast,
      precise: Precise
    }.freeze

    module_function

    def model(precision)
      MODELS.fetch(precision.to_sym)
    rescue NoMethodError, KeyError
      raise ArgumentError, "precision must be :fast or :precise"
    end
  end
end
