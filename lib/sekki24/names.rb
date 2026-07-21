# frozen_string_literal: true

module Sekki24
  module Names
    Definition = Struct.new(
      :key,
      :name_ja,
      :reading,
      :name_en,
      :name_zh,
      :longitude,
      keyword_init: true
    )

    TERMS = [
      [:risshun, "立春", "りっしゅん", "Start of spring", "立春", 315],
      [:usui, "雨水", "うすい", "Rain water", "雨水", 330],
      [:keichitsu, "啓蟄", "けいちつ", "Awakening of insects", "惊蛰", 345],
      [:shunbun, "春分", "しゅんぶん", "Spring equinox", "春分", 0],
      [:seimei, "清明", "せいめい", "Pure brightness", "清明", 15],
      [:kokuu, "穀雨", "こくう", "Grain rain", "谷雨", 30],
      [:rikka, "立夏", "りっか", "Start of summer", "立夏", 45],
      [:shoman, "小満", "しょうまん", "Grain buds", "小满", 60],
      [:boshu, "芒種", "ぼうしゅ", "Grain in ear", "芒种", 75],
      [:geshi, "夏至", "げし", "Summer solstice", "夏至", 90],
      [:shosho, "小暑", "しょうしょ", "Minor heat", "小暑", 105],
      [:taisho, "大暑", "たいしょ", "Major heat", "大暑", 120],
      [:risshu, "立秋", "りっしゅう", "Start of autumn", "立秋", 135],
      [:shoshu, "処暑", "しょしょ", "End of heat", "处暑", 150],
      [:hakuro, "白露", "はくろ", "White dew", "白露", 165],
      [:shubun, "秋分", "しゅうぶん", "Autumn equinox", "秋分", 180],
      [:kanro, "寒露", "かんろ", "Cold dew", "寒露", 195],
      [:soko, "霜降", "そうこう", "Frost descent", "霜降", 210],
      [:ritto, "立冬", "りっとう", "Start of winter", "立冬", 225],
      [:shosetsu, "小雪", "しょうせつ", "Minor snow", "小雪", 240],
      [:taisetsu, "大雪", "たいせつ", "Major snow", "大雪", 255],
      [:toji, "冬至", "とうじ", "Winter solstice", "冬至", 270],
      [:shokan, "小寒", "しょうかん", "Minor cold", "小寒", 285],
      [:daikan, "大寒", "だいかん", "Major cold", "大寒", 300]
    ].map do |key, name_ja, reading, name_en, name_zh, longitude|
      Definition.new(
        key: key,
        name_ja: name_ja,
        reading: reading,
        name_en: name_en,
        name_zh: name_zh,
        longitude: longitude
      ).freeze
    end.freeze

    BY_KEY = TERMS.to_h { |term| [term.key, term] }.freeze
    BY_LONGITUDE = TERMS.to_h { |term| [term.longitude, term] }.freeze
    CALENDAR_ORDER = (TERMS.drop(22) + TERMS.take(22)).freeze

    module_function

    def fetch(key)
      BY_KEY.fetch(key.to_sym)
    rescue NoMethodError, KeyError
      raise ArgumentError, "unknown solar term: #{key.inspect}"
    end
  end
end
