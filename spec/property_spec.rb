# frozen_string_literal: true

RSpec.describe "solar-term properties" do
  before { Sekki24.clear_cache! }
  after { Sekki24.clear_cache! }

  it "preserves the calendar invariants for every supported year" do
    (Sekki24::MIN_YEAR..Sekki24::MAX_YEAR).each do |year|
      terms = Sekki24.year(year, precision: :precise)
      intervals = terms.each_cons(2).map { |left, right| right.time - left.time }

      aggregate_failures("year #{year}") do
        expect(terms.length).to eq(24)
        expect(terms.map(&:longitude)).to eq((285.step(345, 15).to_a + 0.step(270, 15).to_a))
        expect(terms.map(&:time)).to eq(terms.map(&:time).sort)
        expect(terms.map { |term| term.time.year }.uniq).to eq([year])
        expect(intervals).to all(be_between(14 * 86_400, 16 * 86_400))
      end
    end
  end

  it "returns 24 local-year terms across representative offsets and modes" do
    ["-12:00", "+00:00", "+09:00", "+14:00"].product(%i[fast precise]).each do |timezone, precision|
      terms = Sekki24.year(2026, tz: timezone, precision: precision)

      expect(terms.length).to eq(24)
      expect(terms.map { |term| term.time.year }.uniq).to eq([2026])
    end
  end
end
