# frozen_string_literal: true

RSpec.describe Sekki24 do
  before { described_class.clear_cache! }

  describe ".year" do
    it "returns the 24 terms in chronological order using precise UTC defaults" do
      terms = described_class.year(2026)

      expect(terms.length).to eq(24)
      expect(terms.map(&:key)).to eq(Sekki24::Names::CALENDAR_ORDER.map(&:key))
      expect(terms).to eq(terms.sort)
      expect(terms).to be_frozen
      expect(terms.first.time.utc_offset).to eq(0)
      expect(terms.first.time).to be_within(60).of(Time.utc(2026, 1, 5, 8, 23))
    end

    it "memoizes by year, timezone, and precision" do
      first = described_class.year(2026, tz: "+09:00", precision: :fast)
      second = described_class.year(2026, tz: 32_400, precision: :fast)
      precise = described_class.year(2026, tz: "+09:00", precision: :precise)

      expect(second).to equal(first)
      expect(precise).not_to equal(first)

      described_class.clear_cache!
      expect(described_class.year(2026, tz: "+09:00", precision: :fast)).not_to equal(first)
    end

    it "applies timezone objects at each instant" do
      timezone = Object.new
      timezone.define_singleton_method(:identifier) { "Test/Tokyo" }
      timezone.define_singleton_method(:utc_to_local) { |time| time.getlocal("+09:00") }

      expect(described_class.year(2026, tz: timezone).first.time.utc_offset).to eq(32_400)
    end

    it "validates its public options" do
      expect { described_class.year(1899) }.to raise_error(RangeError)
      expect { described_class.year(2101) }.to raise_error(RangeError)
      expect { described_class.year(2026, precision: :unknown) }.to raise_error(ArgumentError)
      expect { described_class.year(2026, tz: "JST") }.to raise_error(ArgumentError)
    end
  end

  describe ".term" do
    it "looks up a term by key" do
      term = described_class.term(2026, :risshun, tz: "+09:00")

      expect(term.name_ja).to eq("立春")
      expect(term.reading).to eq("りっしゅん")
      expect(term.name_en).to eq("Start of spring")
      expect(term.name_zh).to eq("立春")
      expect(term.longitude).to eq(315)
      expect(term.time).to be_within(60).of(Time.new(2026, 2, 4, 5, 2, 0, "+09:00"))
    end

    it "rejects an unknown key" do
      expect { described_class.term(2026, :unknown) }.to raise_error(ArgumentError)
    end
  end

  describe "navigation" do
    let(:time) { Time.new(2026, 7, 10, 12, 0, 0, "+09:00") }

    it "finds the current, next, and previous terms" do
      expect(described_class.current(time, tz: "+09:00").key).to eq(:shosho)
      expect(described_class.next_term(time, tz: "+09:00").key).to eq(:taisho)
      expect(described_class.prev_term(time, tz: "+09:00").key).to eq(:shosho)
    end

    it "treats a term instant as the beginning of its period" do
      risshun = described_class.term(2026, :risshun)

      expect(described_class.current(risshun.time).key).to eq(:risshun)
      expect(described_class.next_term(risshun.time).key).to eq(:usui)
      expect(described_class.prev_term(risshun.time).key).to eq(:daikan)
    end
  end

  describe ".on" do
    it "returns a term only when the local date is a solar-term date" do
      expect(described_class.on(Date.new(2026, 2, 4), tz: "+09:00").key).to eq(:risshun)
      expect(described_class.on(Date.new(2026, 2, 5), tz: "+09:00")).to be_nil
    end

    it "reflects date changes between timezones" do
      expect(described_class.on(Date.new(2026, 2, 19), tz: "+09:00").key).to eq(:usui)
      expect(described_class.on(Date.new(2026, 2, 18), tz: "-08:00").key).to eq(:usui)
    end
  end
end
