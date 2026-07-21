# frozen_string_literal: true

module Sekki24
  module Lunisolar
    module MonthBuilder
      PRINCIPAL_LONGITUDES = (0.step(330, 30).to_a).freeze

      RawMonth = Struct.new(
        :start_date,
        :end_date,
        :new_moon_time,
        :principal_longitudes,
        :number,
        :leap,
        :year,
        keyword_init: true
      )

      @cache_mutex = Mutex.new
      @principal_cache = {}

      class << self
        def build(years, timezone)
          terms = principal_terms(years, timezone)
          months = build_raw_months(years, timezone, terms)
          assign_month_numbers(months, terms)
          assign_lunar_years(months)
          months.filter_map { |raw| build_month(raw) }.freeze
        end

        def clear_cache!
          @cache_mutex.synchronize { @principal_cache.clear }
        end

        private

        def build_raw_months(years, timezone, principal_terms)
          moons = years.flat_map do |year|
            Lunar::PhaseFinder.new_moons_for_calendar(year, tz: timezone)
          end.uniq.sort
          moons.each_cons(2).map do |start_time, next_time|
            start_date = start_time.to_date
            end_date = next_time.to_date - 1
            terms = principal_terms.select { |term| (start_date..end_date).cover?(term.fetch(:date)) }
            RawMonth.new(
              start_date: start_date,
              end_date: end_date,
              new_moon_time: start_time,
              principal_longitudes: terms.map { |term| term.fetch(:longitude) }.freeze
            )
          end
        end

        def principal_terms(years, timezone)
          years.flat_map { |year| principal_terms_for_year(year, timezone) }
        end

        def principal_terms_for_year(year, timezone)
          cache_key = [year, TimeScale.timezone_key(timezone)].freeze
          cached = @cache_mutex.synchronize { @principal_cache[cache_key] }
          return cached if cached

          calculated = PRINCIPAL_LONGITUDES.map do |longitude|
            utc = Finder.find(year: year, longitude: longitude, solar: Solar::Precise)
            local = TimeScale.localize(utc, timezone)
            { longitude: longitude, date: local.to_date }.freeze
          end.freeze
          @cache_mutex.synchronize { @principal_cache[cache_key] ||= calculated }
        end

        def assign_month_numbers(months, principal_terms)
          solstice_dates = principal_terms.select { |term| term.fetch(:longitude) == 270 }.map { |term| term.fetch(:date) }
          anchors = solstice_dates.filter_map do |date|
            index = months.index { |month| (month.start_date..month.end_date).cover?(date) }
            [index, date] if index
          end

          anchors.each_cons(2) do |(left_index, _), (right_index, _)|
            assign_solstice_segment(months, left_index, right_index)
          end
        end

        def assign_solstice_segment(months, first_index, next_index)
          span = next_index - first_index
          unless [12, 13].include?(span)
            raise Error, "unexpected lunisolar month count between winter solstices: #{span}"
          end

          leap_index = find_leap_index(months, first_index, next_index, span)
          number = 11
          (first_index...next_index).each do |index|
            month = months.fetch(index)
            if index == leap_index
              month.leap = true
            else
              number = (number % 12) + 1 unless index == first_index
              month.leap = false
            end
            month.number = number
          end
        end

        def find_leap_index(months, first_index, next_index, span)
          return unless span == 13

          index = ((first_index + 1)...next_index).find do |candidate|
            months.fetch(candidate).principal_longitudes.empty?
          end
          raise Error, "could not identify leap month" unless index

          index
        end

        def assign_lunar_years(months)
          assigned = months.select(&:number)
          first_new_year = assigned.index { |month| month.number == 1 && !month.leap }
          raise Error, "could not identify lunisolar new year" unless first_new_year

          current_year = assigned.fetch(first_new_year).start_date.year
          assigned.take(first_new_year).each { |month| month.year = current_year }
          assigned.drop(first_new_year).each do |month|
            current_year = month.start_date.year if month.number == 1 && !month.leap
            month.year = current_year
          end
        end

        def build_month(raw)
          return unless raw.number && raw.year

          Month.new(
            year: raw.year,
            month: raw.number,
            leap: raw.leap,
            start_date: raw.start_date,
            end_date: raw.end_date,
            new_moon_time: raw.new_moon_time,
            principal_longitudes: raw.principal_longitudes
          )
        end
      end
    end
  end
end
