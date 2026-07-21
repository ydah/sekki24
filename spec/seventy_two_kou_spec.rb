# frozen_string_literal: true

RSpec.describe "the 72 seasonal microseasons" do
  before { Sekki24.clear_cache! }

  it "defines the complete traditional Japanese sequence" do
    expect(Sekki24::KouNames::TERMS.length).to eq(72)
    expect(Sekki24::KouNames.fetch(1).name_ja).to eq("東風解凍")
    expect(Sekki24::KouNames.fetch(30).name_ja).to eq("半夏生")
    expect(Sekki24::KouNames.fetch(72).name_ja).to eq("鶏始乳")
  end

  it "calculates three five-degree crossings for each term in the year" do
    entries = Sekki24.kou_year(2026, tz: "+09:00")
    intervals = entries.each_cons(2).map { |left, right| right.time - left.time }

    expect(entries.length).to eq(72)
    expect(entries.map(&:longitude)).to eq((285.step(355, 5).to_a + 0.step(280, 5).to_a))
    expect(entries.map(&:time)).to eq(entries.map(&:time).sort)
    expect(entries.first.time.year).to eq(2026)
    expect(entries.last.time.year).to be_between(2026, 2027)
    expect(intervals).to all(be_between(4 * 86_400, 6 * 86_400))
  end

  it "shares each solar-term instant with its initial microseason" do
    terms = Sekki24.year(2026, tz: "+09:00")
    initial_microseasons = Sekki24.kou_year(2026, tz: "+09:00").select { |entry| entry.position == :initial }

    terms.zip(initial_microseasons).each do |term, microseason|
      expect(microseason.term_key).to eq(term.key)
      expect(microseason.time).to be_within(0.001).of(term.time)
    end
  end

  it "supports lookup and navigation" do
    entry = Sekki24.kou(2026, 1, tz: "+09:00")
    instant = entry.time + 86_400

    expect(entry).to be_frozen
    expect(entry.name_ja).to eq("東風解凍")
    expect(entry.reading).to eq("はるかぜこおりをとく")
    expect(Sekki24.current_kou(instant, tz: "+09:00")).to eq(entry)
    expect(Sekki24.next_kou(instant, tz: "+09:00").ordinal).to eq(2)
    expect(Sekki24.prev_kou(instant, tz: "+09:00")).to eq(entry)
  end

  it "validates the ordinal" do
    expect { Sekki24.kou(2026, 0) }.to raise_error(ArgumentError)
    expect { Sekki24.kou(2026, 73) }.to raise_error(ArgumentError)
  end
end
