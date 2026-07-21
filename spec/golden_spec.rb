# frozen_string_literal: true

RSpec.describe "NAOJ solar-term times" do
  JST = "+09:00"

  # National Astronomical Observatory of Japan, Calendar and Ephemeris Office.
  # Published values are rounded to the nearest minute in Japan Standard Time.
  PUBLISHED_TIMES = {
    2010 => %w[
      01-05T20:09 01-20T13:28 02-04T07:48 02-19T03:36
      03-06T01:46 03-21T02:32 04-05T06:30 04-20T13:30
      05-05T23:44 05-21T12:34 06-06T03:49 06-21T20:28
      07-07T14:02 07-23T07:21 08-07T23:49 08-23T14:27
      09-08T02:45 09-23T12:09 10-08T18:26 10-23T21:35
      11-07T21:42 11-22T19:15 12-07T14:38 12-22T08:38
    ],
    2020 => %w[
      01-06T06:30 01-20T23:55 02-04T18:03 02-19T13:57
      03-05T11:57 03-20T12:50 04-04T16:38 04-19T23:45
      05-05T09:51 05-20T22:49 06-05T13:58 06-21T06:44
      07-07T00:14 07-22T17:37 08-07T10:06 08-23T00:45
      09-07T13:08 09-22T22:31 10-08T04:55 10-23T08:00
      11-07T08:14 11-22T05:40 12-07T01:09 12-21T19:02
    ],
    2026 => %w[
      01-05T17:23 01-20T10:45 02-04T05:02 02-19T00:52
      03-05T22:59 03-20T23:46 04-05T03:40 04-20T10:39
      05-05T20:49 05-21T09:37 06-06T00:48 06-21T17:25
      07-07T10:57 07-23T04:13 08-07T20:43 08-23T11:19
      09-07T23:41 09-23T09:05 10-08T15:29 10-23T18:38
      11-07T18:52 11-22T16:23 12-07T11:53 12-22T05:50
    ]
  }.freeze

  def published_time(year, value)
    Time.new(year, value[0, 2].to_i, value[3, 2].to_i, value[6, 2].to_i, value[9, 2].to_i, 0, JST)
  end

  PUBLISHED_TIMES.each do |year, values|
    it "matches the #{year} almanac within one minute in precise mode" do
      actual = Sekki24::Names::CALENDAR_ORDER.map do |definition|
        utc = Sekki24::Finder.find(year: year, longitude: definition.longitude, solar: Sekki24::Solar::Precise)
        Sekki24::TimeScale.localize(utc, JST)
      end

      values.zip(actual).each do |published, calculated|
        expect(calculated).to be_within(60).of(published_time(year, published))
      end
    end
  end

  it "keeps fast mode within twenty minutes of the published values" do
    actual = Sekki24::Names::CALENDAR_ORDER.map do |definition|
      utc = Sekki24::Finder.find(year: 2026, longitude: definition.longitude, solar: Sekki24::Solar::Fast)
      Sekki24::TimeScale.localize(utc, JST)
    end

    PUBLISHED_TIMES.fetch(2026).zip(actual).each do |published, calculated|
      expect(calculated).to be_within(20 * 60).of(published_time(2026, published))
    end
  end
end
