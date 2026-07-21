# Sekki24

[![CI](https://github.com/ydah/sekki24/actions/workflows/main.yml/badge.svg)](https://github.com/ydah/sekki24/actions/workflows/main.yml)

Japanese seasonal and lunisolar calendar calculations in Ruby for 1900–2100.

- 24 solar terms (二十四節気)
- 72 microseasons (七十二候)
- Supplementary observances (雑節)
- New moons and Japanese lunisolar dates (旧暦)

## Installation

Sekki24 requires Ruby 3.0 or later.

```bash
gem install sekki24
```

Or add it to a bundle:

```bash
bundle add sekki24
```

## Usage

### Solar terms

```ruby
require "sekki24"

# UTC is used unless tz: is supplied.
terms = Sekki24.year(2026, tz: "+09:00")
terms.length # => 24

risshun = Sekki24.term(2026, :risshun, tz: "+09:00")
risshun.name_ja   # => "立春"
risshun.reading   # => "りっしゅん"
risshun.name_en   # => "Start of spring"
risshun.name_zh   # => "立春"
risshun.longitude # => 315
risshun.time      # => 2026-02-04 05:02... +0900
risshun.to_date   # => #<Date: 2026-02-04 ...>

Sekki24.current(Time.now, tz: "+09:00")
Sekki24.next_term(Time.now, tz: "+09:00")
Sekki24.prev_term(Time.now, tz: "+09:00")
Sekki24.on(Date.new(2026, 2, 4), tz: "+09:00") # => 立春
```

### Microseasons and observances

```ruby
microseasons = Sekki24.kou_year(2026, tz: "+09:00")
microseasons.length # => 72

first = Sekki24.kou(2026, 1, tz: "+09:00")
first.name_ja # => "東風解凍"
first.reading # => "はるかぜこおりをとく"

observances = Sekki24.zassetsu_year(2026, tz: "+09:00")
observances.length # => 14
Sekki24.zassetsu(2026, :summer_doyo, tz: "+09:00")
Sekki24.zassetsu_on(Date.new(2026, 2, 3), tz: "+09:00")
```

The 14 observances include four doyo periods, Setsubun, both Higan periods,
Hachijuhachiya, Nyubai, Hangesho, Nihyakutoka, Nihyakuhatsuka, and both
Shanichi days. Doyo and Higan include their complete date ranges.

`kou_year` associates three microseasons with each solar term in the requested
year. The final microseason can begin just after the Gregorian year boundary.

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

## API

| Calendar | Methods on `Sekki24` |
| --- | --- |
| Solar terms | `year`, `term`, `current`, `next_term`, `prev_term`, `on` |
| Microseasons | `kou_year`, `kou`, `current_kou`, `next_kou`, `prev_kou` |
| Observances | `zassetsu_year`, `zassetsu`, `zassetsu_on`, `current_zassetsu` |
| New moons | `new_moons`, `new_moon_before`, `new_moon_after`, `moon_longitude` |
| Lunisolar calendar | `lunisolar`, `lunisolar_year`, `gregorian` |

`Term`, `Kou`, `Zassetsu`, `Lunisolar::Date`, and `Lunisolar::Month` are
immutable value objects with `#to_h`. `Term`, `Kou`, and `Zassetsu` also
implement `Comparable`.

## Timezones

`tz:` accepts:

- a UTC offset string such as `"+09:00"` or `"-08:00"`;
- an offset in seconds such as `32_400`; or
- an object responding to `utc_to_local(Time)`, such as a loaded
  `TZInfo::Timezone` instance.

Named-zone daylight-saving rules are used only when the caller supplies a
timezone object.

## Precision

```ruby
Sekki24.year(2026, precision: :precise) # default, within one minute
Sekki24.year(2026, precision: :fast)    # approximately within 20 minutes
```

`:precise` is validated against the National Astronomical Observatory of Japan
almanac. `precision:` applies to solar terms, microseasons, and supplementary
observances. New-moon and lunisolar APIs always use the precise lunar model.

Results are memoized. Use `Sekki24.clear_cache!` to clear all caches.

## Command line

The executable prints text by default and supports JSON output:

```bash
sekki24 2026 --tz +09:00
sekki24 2026 --tz +09:00 --format json
sekki24 2026 --tz +09:00 --calendar kou
sekki24 2026 --tz +09:00 --calendar zassetsu
sekki24 2026 --tz +09:00 --calendar new-moons
sekki24 2026 --tz +09:00 --calendar lunisolar
```

Run `sekki24 --help` for every option.

## Lunisolar calendar rules

Lunisolar months begin on the local civil date containing a new moon. When 13
months occur between winter-solstice months, the first month without a
principal solar term becomes a leap month.

For the ambiguous 2033 case, Sekki24 prioritizes the winter-solstice month and
uses the recommended leap eleventh month. The selected rule is available as
`Sekki24::Lunisolar::Calendar::LEAP_MONTH_RULE`.

Gregorian conversion is supported from 1900-01-01 through 2100-12-31. Lunar
year 1899 is accepted only because its final months overlap the start of that
range.

The historical Tenpo calendar was abolished in 1873. This API is a modern
astronomical reconstruction of its lunisolar rules, not an official Japanese
civil calendar.

## Accuracy and implementation

- UTC is converted to Terrestrial Time with the Espenak–Meeus ΔT polynomials.
- Solar longitude uses the IMCCE VSOP87D Earth series in precise mode and the
  Meeus Chapter 25 approximation in fast mode.
- Lunar longitude uses the principal Meeus periodic terms.
- Solar terms and new moons are solved numerically, with bisection fallbacks.

Coefficients are embedded in the gem; no ephemeris or calendar data is fetched
at runtime. Tests compare published solar terms, supplementary observances, and
every 2026 new moon against National Astronomical Observatory of Japan values.
They also cover all supported years, timezone boundaries, leap-month cases,
and Gregorian/lunisolar round trips.

## Development

```bash
bundle install
bundle exec rake
```

CI tests Ruby 3.0, 3.2, 3.3, 3.4, 4.0, and Ruby head. actionlint and zizmor
check the GitHub Actions workflows.

## License

Sekki24 is available under the [MIT License](LICENSE.txt).
