# frozen_string_literal: true

require_relative "sekki24/version"

module Sekki24
  class Error < StandardError; end
end

require_relative "sekki24/names"
require_relative "sekki24/term"
require_relative "sekki24/delta_t"
require_relative "sekki24/time_scale"
require_relative "sekki24/solar/fast"
require_relative "sekki24/finder"
