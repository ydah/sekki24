# frozen_string_literal: true

require "date"
require "time"

module Sekki24
  class Term
    include Comparable

    ATTRIBUTES = %i[key name_ja reading name_en name_zh longitude time].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(definition:, time:)
      @key = definition.key
      @name_ja = definition.name_ja
      @reading = definition.reading
      @name_en = definition.name_en
      @name_zh = definition.name_zh
      @longitude = definition.longitude
      @time = time.dup.freeze
      freeze
    end

    def <=>(other)
      return unless other.respond_to?(:time)

      time <=> other.time
    end

    def ==(other)
      other.is_a?(Term) && key == other.key && time == other.time
    end
    alias eql? ==

    def hash
      [self.class, key, time].hash
    end

    def to_date
      time.to_date
    end

    def to_h
      ATTRIBUTES.to_h { |attribute| [attribute, public_send(attribute)] }
    end

    def inspect
      "#<#{self.class} #{name_ja} (#{key}) #{time.iso8601} longitude=#{longitude}°>"
    end
  end
end
