# Sekki24

[![CI](https://github.com/ydah/sekki24/actions/workflows/main.yml/badge.svg)](https://github.com/ydah/sekki24/actions/workflows/main.yml)

Japanese seasonal and lunisolar calendar calculations in Ruby. Sekki24 covers
the 24 solar terms (二十四節気), 72 microseasons (七十二候), supplementary
observances (雑節), new moons, and Japanese lunisolar dates (旧暦) for
1900–2100.

Calculations run locally from astronomical algorithms and embedded
coefficients. No downloaded ephemerides or precomputed calendar tables are
required.

## Features

- Exact instants for the 24 solar terms, with Japanese, reading, English, and
  Chinese names
- The complete traditional Japanese sequence of 72 microseasons
- Four doyo periods, Setsubun, Higan, Shanichi, and other supplementary
  observances
- New-moon calculation and Gregorian/lunisolar date conversion
- Explicit timezone handling and precise or fast solar calculation modes
- Immutable calendar value objects and JSON-ready hashes

## Installation

Requires Ruby 3.0 or later.

```bash
gem install sekki24
```

With Bundler:

```bash
bundle add sekki24
```

## Quick start

```ruby
require "sekki24"

# Results are UTC unless a timezone is supplied.
terms = Sekki24.year(2026, tz: "+09:00")
terms.length # => 24

risshun = Sekki24.term(2026, :risshun, tz: "+09:00")
risshun.name_ja   # => "立春"
risshun.reading   # => "りっしゅん"
risshun.name_en   # => "Start of spring"
risshun.longitude # => 315
risshun.time      # => 2026-02-04 05:02... +0900
risshun.to_date   # => #<Date: 2026-02-04 ...>

Sekki24.current(Time.now, tz: "+09:00")
Sekki24.next_term(Time.now, tz: "+09:00")
Sekki24.prev_term(Time.now, tz: "+09:00")
Sekki24.on(Date.new(2026, 2, 4), tz: "+09:00") # => 立春
```

## API overview

| Calendar | Main APIs |
| --- | --- |
| 24 solar terms | `year`, `term`, `current`, `next_term`, `prev_term`, `on` |
| 72 microseasons | `kou_year`, `kou`, `current_kou`, `next_kou`, `prev_kou` |
| Supplementary observances | `zassetsu_year`, `zassetsu`, `zassetsu_on`, `current_zassetsu` |
| New moons | `new_moons`, `new_moon_before`, `new_moon_after`, `moon_longitude` |
| Lunisolar calendar | `lunisolar`, `lunisolar_year`, `gregorian` |

All methods are available directly on `Sekki24`. `Term`, `Kou`, `Zassetsu`,
`Lunisolar::Date`, and `Lunisolar::Month` are immutable and expose `#to_h`.
Solar terms, microseasons, and supplementary observances also implement
`Comparable`.

### Seasonal calendars

```ruby
microseasons = Sekki24.kou_year(2026, tz: "+09:00")
microseasons.length # => 72

first = Sekki24.kou(2026, 1, tz: "+09:00")
first.name_ja # => "東風解凍"
first.reading # => "はるかぜこおりをとく"

observances = Sekki24.zassetsu_year(2026, tz: "+09:00")
Sekki24.zassetsu(2026, :summer_doyo, tz: "+09:00")
Sekki24.zassetsu_on(Date.new(2026, 2, 3), tz: "+09:00")
Sekki24.current_zassetsu(Date.new(2026, 3, 20), tz: "+09:00")
```

`kou_year` returns three microseasons for each of the year's 24 solar terms.
The last one can begin just after the Gregorian year boundary.

Supplementary observances include the four doyo periods, Setsubun, both Higan
periods, Hachijuhachiya, Nyubai, Hangesho, Nihyakutoka, Nihyakuhatsuka, and both
Shanichi days. Doyo and Higan results include their complete date ranges.

### New moons and lunisolar dates

```ruby
Sekki24.new_moons(2026, tz: "+09:00")
Sekki24.new_moon_before(Time.now)
Sekki24.new_moon_after(Time.now)

old_date = Sekki24.lunisolar(Date.new(2026, 2, 17), tz: "+09:00")
old_date.year          # => 2026
old_date.month_name_ja # => "正月"
old_date.day           # => 1
old_date.leap?         # => false

Sekki24.lunisolar_year(2026, tz: "+09:00")
Sekki24.gregorian(2026, 1, 1, tz: "+09:00") # => 2026-02-17
```

Lunisolar months begin on the local civil date containing a new moon. When 13
months occur between winter-solstice months, the first month without a
principal solar term becomes a leap month. For the ambiguous 2033 case,
Sekki24 prioritizes the winter-solstice month and uses the recommended leap
eleventh month (`Sekki24::Lunisolar::Calendar::LEAP_MONTH_RULE`).

Gregorian conversion is supported from 1900-01-01 through 2100-12-31. Lunar
year 1899 is accepted only because its final months overlap the start of that
range.

The historical Tenpo calendar was abolished in 1873. This API is a modern
astronomical reconstruction of its lunisolar rules, not an official Japanese
civil calendar.

## Timezones and precision

`tz:` accepts:

- a UTC offset string such as `"+09:00"` or `"-08:00"`;
- an offset in seconds such as `32_400`; or
- an object responding to `utc_to_local(Time)`, such as a loaded
  `TZInfo::Timezone` instance.

Named-zone daylight-saving rules are used only when the caller supplies a
timezone object.

The default `:precise` mode targets agreement within one minute of the National
Astronomical Observatory of Japan almanac. `:fast` trades accuracy for a
lighter calculation:

```ruby
Sekki24.year(2026, precision: :precise) # default
Sekki24.year(2026, precision: :fast)    # approximately within 20 minutes
```

`precision:` applies to solar terms, microseasons, and supplementary
observances. New-moon and lunisolar APIs always use the precise lunar model.
Results are memoized; call `Sekki24.clear_cache!` to clear all caches.

## Command line

The executable prints text by default and can emit JSON:

```bash
sekki24 2026 --tz +09:00
sekki24 2026 --tz +09:00 --precision precise --format json
sekki24 2026 --tz +09:00 --calendar kou --format json
sekki24 2026 --tz +09:00 --calendar zassetsu
sekki24 2026 --tz +09:00 --calendar new-moons
sekki24 2026 --tz +09:00 --calendar lunisolar
```

Run `sekki24 --help` for every option.

## Accuracy and implementation

- UTC is converted to Terrestrial Time with the Espenak–Meeus ΔT
  polynomials. Future ΔT is necessarily an estimate.
- Fast solar longitude follows Jean Meeus, *Astronomical Algorithms*, Chapter
  25.
- Precise solar longitude uses the principal terms from the IMCCE VSOP87D
  Earth series, dominant IAU 1980 nutation terms, and aberration correction.
- Solar-longitude crossings use Newton iteration with a bisection fallback.
- Lunar longitude uses the principal Meeus periodic terms. New moons are
  solved as apparent Sun–Moon longitude conjunctions.

Tests compare solar terms, supplementary observances, and every 2026 new moon
against published National Astronomical Observatory of Japan values. They also
cover all supported years, timezone boundaries, the 2014 leap ninth month, the
2033 leap eleventh month, and Gregorian/lunisolar round trips.

Sekki24 has no runtime gem dependencies.

## Development

```bash
bundle install
bundle exec rake
```

CI tests Ruby 3.0, 3.2, 3.3, 3.4, 4.0, and Ruby head. It also checks GitHub
Actions workflows with actionlint and zizmor.

## License

Sekki24 is available under the [MIT License](LICENSE.txt).
