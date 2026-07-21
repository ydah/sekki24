# frozen_string_literal: true

RSpec.describe "Sekki24 calculation core" do
  describe Sekki24::DeltaT do
    it "evaluates the published polynomial around 2000" do
      expect(described_class.seconds(2000.0)).to be_within(0.001).of(63.86)
    end

    it "supports the complete calculation boundary" do
      expect(described_class.seconds(1900.0)).to be_a(Float)
      expect(described_class.seconds(2100.0)).to be_a(Float)
    end
  end

  describe Sekki24::TimeScale do
    it "converts the J2000 epoch" do
      expect(described_class.utc_to_jd(Time.utc(2000, 1, 1, 12))).to eq(2_451_545.0)
      expect(described_class.jd_to_utc(2_451_545.0)).to eq(Time.utc(2000, 1, 1, 12))
    end

    it "round trips between UTC and terrestrial time" do
      utc = Time.utc(2026, 2, 4, 0, 2)
      expect(described_class.jde_to_utc(described_class.utc_to_jde(utc))).to be_within(0.001).of(utc)
    end

    it "handles fixed-offset and duck-typed timezones" do
      utc = Time.utc(2026, 2, 3, 20, 0)
      timezone = Object.new
      timezone.define_singleton_method(:utc_to_local) { |time| time.getlocal("+09:00") }

      expect(described_class.localize(utc, "+09:00").hour).to eq(5)
      expect(described_class.localize(utc, 32_400).hour).to eq(5)
      expect(described_class.localize(utc, timezone).hour).to eq(5)
    end
  end

  describe Sekki24::Solar::Fast do
    it "places the Sun near the expected longitude at the March equinox" do
      jde = Sekki24::TimeScale.utc_to_jde(Time.utc(2026, 3, 20, 14, 46))
      longitude = described_class.longitude(jde)
      error = ((longitude + 180.0) % 360.0) - 180.0

      expect(error.abs).to be < 0.02
    end
  end

  describe Sekki24::Finder do
    it "finds a solar term with fast precision" do
      time = described_class.find(year: 2026, longitude: 315, solar: Sekki24::Solar::Fast)

      expect(time).to be_within(20 * 60).of(Time.utc(2026, 2, 3, 20, 2))
    end
  end

  describe Sekki24::Term do
    it "is a frozen comparable value object" do
      definition = Sekki24::Names.fetch(:risshun)
      earlier = described_class.new(definition: definition, time: Time.utc(2026, 2, 3, 20, 2))
      later = described_class.new(definition: definition, time: Time.utc(2027, 2, 4, 1, 0))

      expect(earlier).to be_frozen
      expect(earlier.time).to be_frozen
      expect(earlier).to be < later
      expect(earlier.to_h).to include(key: :risshun, name_ja: "立春", longitude: 315)
      expect(earlier.to_date).to eq(Date.new(2026, 2, 3))
    end
  end
end

RSpec.describe Sekki24 do
  it "has a version number" do
    expect(Sekki24::VERSION).not_to be_nil
  end
end
