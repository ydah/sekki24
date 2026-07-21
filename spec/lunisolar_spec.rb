# frozen_string_literal: true

RSpec.describe "Japanese lunisolar calendar" do
  LUNISOLAR_JST = "+09:00"

  before { Sekki24.clear_cache! }

  it "uses the local new-moon date as day one" do
    date = Sekki24.lunisolar(Date.new(2026, 2, 17), tz: LUNISOLAR_JST)

    expect(date.year).to eq(2026)
    expect(date.month).to eq(1)
    expect(date.day).to eq(1)
    expect(date).not_to be_leap
    expect(date.month_name_ja).to eq("正月")
    expect(date.to_date).to eq(Date.new(2026, 2, 17))
  end

  it "reproduces the NAOJ 2014 leap ninth-month example" do
    regular = Sekki24.lunisolar(Date.new(2014, 9, 24), tz: LUNISOLAR_JST)
    leap_month = Sekki24.lunisolar(Date.new(2014, 10, 24), tz: LUNISOLAR_JST)

    expect([regular.year, regular.month, regular.day, regular.leap?]).to eq([2014, 9, 1, false])
    expect([leap_month.year, leap_month.month, leap_month.day, leap_month.leap?]).to eq([2014, 9, 1, true])
  end

  it "uses the recommended leap eleventh month for the 2033 problem" do
    leap_month = Sekki24.lunisolar(Date.new(2033, 12, 22), tz: LUNISOLAR_JST)
    following = Sekki24.lunisolar(Date.new(2034, 1, 20), tz: LUNISOLAR_JST)

    expect(Sekki24::Lunisolar::Calendar::LEAP_MONTH_RULE).to eq(:winter_solstice_priority)
    expect([leap_month.year, leap_month.month, leap_month.day, leap_month.leap?]).to eq([2033, 11, 1, true])
    expect([following.year, following.month, following.day, following.leap?]).to eq([2033, 12, 1, false])
  end

  it "returns a complete immutable month model for a lunar year" do
    months = Sekki24.lunisolar_year(2014, tz: LUNISOLAR_JST)

    expect(months.length).to eq(13)
    expect(months).to be_frozen
    expect(months).to all(be_frozen)
    expect(months.map(&:length)).to all(be_between(29, 30))
    expect(months.count(&:leap?)).to eq(1)
    expect(months.find(&:leap?).month).to eq(9)
  end

  it "round trips Gregorian and lunisolar dates" do
    dates = [Date.new(1900, 1, 31), Date.new(2000, 2, 29), Date.new(2026, 7, 7), Date.new(2100, 12, 1)]

    dates.each do |gregorian_date|
      lunar = Sekki24.lunisolar(gregorian_date, tz: LUNISOLAR_JST)
      converted = Sekki24.gregorian(lunar.year, lunar.month, lunar.day, leap: lunar.leap?, tz: LUNISOLAR_JST)

      expect(converted).to eq(gregorian_date)
    end
  end

  it "validates impossible lunar dates" do
    expect { Sekki24.gregorian(2026, 13, 1, tz: LUNISOLAR_JST) }.to raise_error(ArgumentError)
    expect { Sekki24.gregorian(2026, 1, 31, tz: LUNISOLAR_JST) }.to raise_error(ArgumentError)
    expect { Sekki24.gregorian(2026, 1, 1, leap: true, tz: LUNISOLAR_JST) }.to raise_error(ArgumentError)
  end

  it "preserves month invariants across every supported lunar year" do
    (Sekki24::MIN_YEAR..Sekki24::MAX_YEAR).each do |year|
      months = Sekki24.lunisolar_year(year, tz: LUNISOLAR_JST)
      regular_months = months.reject(&:leap?)

      aggregate_failures("lunisolar year #{year}") do
        expect(months.length).to be_between(12, 13)
        expect(regular_months.map(&:month)).to eq((1..12).to_a)
        expect(months.count(&:leap?)).to eq(months.length - 12)
        expect(months.map(&:length)).to all(be_between(29, 30))
        expect(months.each_cons(2).all? { |left, right| left.end_date + 1 == right.start_date }).to be(true)
      end
    end
  end
end
