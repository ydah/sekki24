# frozen_string_literal: true

module Sekki24
  class Zassetsu
    include Comparable

    ATTRIBUTES = %i[key name_ja reading category date end_date time longitude].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(key:, name_ja:, reading:, category:, date:, end_date: date, time: nil, longitude: nil)
      @key = key
      @name_ja = name_ja
      @reading = reading
      @category = category
      @date = date.freeze
      @end_date = end_date.freeze
      @time = time&.dup&.freeze
      @longitude = longitude
      freeze
    end

    def <=>(other)
      return unless other.respond_to?(:date)

      sort_key <=> other.sort_key
    end

    def include?(value)
      target = value.is_a?(Time) ? value.to_date : value
      (date..end_date).cover?(target)
    end

    def to_h
      ATTRIBUTES.to_h { |attribute| [attribute, public_send(attribute)] }
    end

    def inspect
      suffix = date == end_date ? date.iso8601 : "#{date.iso8601}..#{end_date.iso8601}"
      "#<#{self.class} #{name_ja} (#{key}) #{suffix}>"
    end

    protected

    def sort_key
      seconds = time ? (time.hour * 3600) + (time.min * 60) + time.sec : -1
      [date.jd, seconds]
    end
  end
end
