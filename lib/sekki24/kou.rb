# frozen_string_literal: true

module Sekki24
  class Kou
    include Comparable

    ATTRIBUTES = %i[ordinal name_ja reading longitude term_key position time].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(definition:, time:)
      @ordinal = definition.ordinal
      @name_ja = definition.name_ja
      @reading = definition.reading
      @longitude = definition.longitude
      @term_key = definition.term_key
      @position = definition.position
      @time = time.dup.freeze
      freeze
    end

    def <=>(other)
      return unless other.respond_to?(:time)

      time <=> other.time
    end

    def ==(other)
      other.is_a?(Kou) && ordinal == other.ordinal && time == other.time
    end
    alias eql? ==

    def hash
      [self.class, ordinal, time].hash
    end

    def to_date
      time.to_date
    end

    def to_h
      ATTRIBUTES.to_h { |attribute| [attribute, public_send(attribute)] }
    end

    def inspect
      "#<#{self.class} 第#{ordinal}候 #{name_ja} #{time.iso8601} longitude=#{longitude}°>"
    end
  end
end
