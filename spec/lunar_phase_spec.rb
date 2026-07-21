# frozen_string_literal: true

RSpec.describe "lunar longitude and new moons" do
  LUNAR_JST = "+09:00"

  before { Sekki24.clear_cache! }

  it "matches every 2026 NAOJ new moon within one minute" do
    published = %w[
      01-19T04:52 02-17T21:01 03-19T10:23 04-17T20:52
      05-17T05:01 06-15T11:54 07-14T18:44 08-13T02:37
      09-11T12:27 10-11T00:50 11-09T16:02 12-09T09:52
    ].map do |value|
      Time.new(2026, value[0, 2].to_i, value[3, 2].to_i, value[6, 2].to_i, value[9, 2].to_i, 0, LUNAR_JST)
    end

    calculated = Sekki24.new_moons(2026, tz: LUNAR_JST)

    expect(calculated.length).to eq(12)
    published.zip(calculated).each do |expected, actual|
      expect(actual).to be_within(60).of(expected)
    end
  end

  it "solves the apparent longitude conjunction" do
    time = Sekki24.new_moons(2026).first
    moon = Sekki24.moon_longitude(time)
    sun = Sekki24::Solar::Precise.longitude(Sekki24::TimeScale.utc_to_jde(time))
    difference = ((moon - sun + 180.0) % 360.0) - 180.0

    expect(difference.abs).to be < 1e-5
  end

  it "finds adjacent new moons around an instant" do
    instant = Time.utc(2026, 3, 1)
    previous = Sekki24.new_moon_before(instant)
    following = Sekki24.new_moon_after(instant)

    expect(previous).to be < instant
    expect(following).to be > instant
    expect(following - previous).to be_between(29 * 86_400, 30 * 86_400)
  end
end
