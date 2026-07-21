# frozen_string_literal: true

RSpec.describe "supplementary seasonal observances" do
  ZASSETSU_JST = "+09:00"

  before { Sekki24.clear_cache! }

  it "calculates the complete modern and traditional observance set" do
    entries = Sekki24.zassetsu_year(2026, tz: ZASSETSU_JST)

    expect(entries.map(&:key)).to contain_exactly(*Sekki24::ZassetsuCalendar::NAMES.keys)
    expect(entries).to eq(entries.sort)
    expect(entries).to all(be_frozen)
  end

  it "matches the 2026 NAOJ solar-longitude observances within one minute" do
    published = {
      winter_doyo: Time.new(2026, 1, 17, 12, 3, 0, ZASSETSU_JST),
      spring_doyo: Time.new(2026, 4, 17, 9, 1, 0, ZASSETSU_JST),
      nyubai: Time.new(2026, 6, 11, 6, 14, 0, ZASSETSU_JST),
      hangesho: Time.new(2026, 7, 2, 5, 4, 0, ZASSETSU_JST),
      summer_doyo: Time.new(2026, 7, 20, 0, 48, 0, ZASSETSU_JST),
      autumn_doyo: Time.new(2026, 10, 20, 18, 13, 0, ZASSETSU_JST)
    }

    published.each do |key, expected|
      entry = Sekki24.zassetsu(2026, key, tz: ZASSETSU_JST)
      expect(entry.time).to be_within(60).of(expected)
    end
  end

  it "matches published calendar-day observances" do
    expected_dates = {
      setsubun: Date.new(2026, 2, 3),
      spring_higan: Date.new(2026, 3, 17),
      hachijuhachiya: Date.new(2026, 5, 2),
      nihyakutoka: Date.new(2026, 9, 1),
      autumn_higan: Date.new(2026, 9, 20)
    }

    expected_dates.each do |key, expected|
      expect(Sekki24.zassetsu(2026, key, tz: ZASSETSU_JST).date).to eq(expected)
    end
    expect(Sekki24.zassetsu(2026, :nihyakuhatsuka, tz: ZASSETSU_JST).date).to eq(Date.new(2026, 9, 11))
  end

  it "represents doyo and higan as periods" do
    spring_higan = Sekki24.zassetsu(2026, :spring_higan, tz: ZASSETSU_JST)
    summer_doyo = Sekki24.zassetsu(2026, :summer_doyo, tz: ZASSETSU_JST)

    expect(spring_higan.end_date).to eq(Date.new(2026, 3, 23))
    expect(summer_doyo.end_date).to eq(Date.new(2026, 8, 6))
    expect(Sekki24.current_zassetsu(Date.new(2026, 3, 20), tz: ZASSETSU_JST)).to include(spring_higan)
  end

  it "calculates the nearest tsuchinoe day for shanichi" do
    spring = Sekki24.zassetsu(2026, :spring_shanichi, tz: ZASSETSU_JST)
    autumn = Sekki24.zassetsu(2026, :autumn_shanichi, tz: ZASSETSU_JST)

    expect((spring.date.jd + 49) % 10).to eq(4)
    expect((autumn.date.jd + 49) % 10).to eq(4)
    expect((spring.date - Sekki24.term(2026, :shunbun, tz: ZASSETSU_JST).to_date).abs).to be <= 5
    expect((autumn.date - Sekki24.term(2026, :shubun, tz: ZASSETSU_JST).to_date).abs).to be <= 5
  end

  it "finds observances beginning on a date" do
    expect(Sekki24.zassetsu_on(Date.new(2026, 2, 3), tz: ZASSETSU_JST).map(&:key)).to eq([:setsubun])
    expect(Sekki24.zassetsu_on(Date.new(2026, 2, 4), tz: ZASSETSU_JST)).to be_empty
  end
end
