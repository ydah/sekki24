# Sekki24

Sekki24 is a dependency-free Ruby gem for Japanese seasonal and lunisolar
calendars for years 1900–2100. It calculates the 24 solar terms (二十四節気), 72
microseasons (七十二候), supplementary observances (雑節), new moons, and Japanese
lunisolar dates (旧暦) without downloaded ephemerides or precomputed date tables.

## Installation

Add the gem to your bundle:

```bash
bundle add sekki24
```

Or install it directly:

```bash
gem install sekki24
```

## Usage

```ruby
require "sekki24"

# Results are UTC unless a timezone is supplied.
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

now = Time.now
Sekki24.current(now, tz: "+09:00")
Sekki24.next_term(now, tz: "+09:00")
Sekki24.prev_term(now, tz: "+09:00")

Sekki24.on(Date.new(2026, 2, 4), tz: "+09:00") # => 立春
Sekki24.on(Date.new(2026, 2, 5), tz: "+09:00") # => nil
```

`Sekki24::Term` is a frozen value object. It implements `Comparable`, `#to_h`,
`#to_date`, and a concise `#inspect`.

### The 72 microseasons

Each solar term is divided by apparent solar longitude into three 5° periods.

```ruby
microseasons = Sekki24.kou_year(2026, tz: "+09:00") # 72 entries
first = Sekki24.kou(2026, 1, tz: "+09:00")
first.name_ja # => "東風解凍"
first.reading # => "はるかぜこおりをとく"

Sekki24.current_kou(Time.now, tz: "+09:00")
Sekki24.next_kou(Time.now, tz: "+09:00")
Sekki24.prev_kou(Time.now, tz: "+09:00")
```

`kou_year` returns the three microseasons belonging to each of that year's 24
solar terms. The final microseason after the winter solstice can begin just
after the Gregorian year boundary.

### Supplementary observances

```ruby
observances = Sekki24.zassetsu_year(2026, tz: "+09:00")
Sekki24.zassetsu(2026, :summer_doyo, tz: "+09:00")
Sekki24.zassetsu_on(Date.new(2026, 2, 3), tz: "+09:00")
Sekki24.current_zassetsu(Date.new(2026, 3, 20), tz: "+09:00")
```

The result includes the four doyo periods, Setsubun, both Higan periods,
Hachijuhachiya, Nyubai, Hangesho, Nihyakutoka, both Shanichi days, and
Nihyakuhatsuka. Longitude-defined observances include their exact instant;
Higan and doyo include their start and end dates.

### New moons and the Japanese lunisolar calendar

```ruby
Sekki24.new_moons(2026, tz: "+09:00")
Sekki24.new_moon_before(Time.now)
Sekki24.new_moon_after(Time.now)

old_date = Sekki24.lunisolar(Date.new(2026, 2, 17), tz: "+09:00")
old_date.to_h
# => { year: 2026, month: 1, day: 1, leap: false, ... }

months = Sekki24.lunisolar_year(2026, tz: "+09:00")
Sekki24.gregorian(2026, 1, 1, tz: "+09:00") # => 2026-02-17
```

Lunisolar months start on the local civil date containing a new moon. Principal
solar terms are assigned by local civil date, and a month without one becomes a
leap month when 13 months occur between winter-solstice months. For the
ambiguous 2033 case, Sekki24 prioritizes the winter-solstice month and follows
the Japan Association for Calendars and Culture Promotion recommendation of a
leap eleventh month (`Lunisolar::Calendar::LEAP_MONTH_RULE`).

The historical Tenpo calendar was abolished in 1873, so this API is a modern
astronomical reconstruction of its lunisolar rules, not an official current
Japanese civil calendar.

Gregorian conversion is supported from 1900-01-01 through 2100-12-31. Lunar
year 1899 is accepted only because its final months overlap the beginning of
that Gregorian range.

### Timezones

`tz:` accepts:

- a UTC offset string such as `"+09:00"` or `"-08:00"`;
- an offset in seconds such as `32_400`; or
- an object responding to `utc_to_local(Time)`, including a loaded
  `TZInfo::Timezone` instance.

Timezone libraries are deliberately optional. Named-zone daylight-saving rules
are used only when the caller supplies such an object.

### Precision

The default `:precise` mode uses a truncated VSOP87D Earth series, dominant IAU
1980 nutation terms, and aberration correction. Its acceptance target is within
one minute of the National Astronomical Observatory of Japan almanac.

```ruby
Sekki24.year(2026, precision: :precise) # default
Sekki24.year(2026, precision: :fast)    # Meeus approximation, within ~20 minutes
```

Results are memoized by year, timezone, and precision. Long-lived applications
can discard all memoized values with `Sekki24.clear_cache!`.

The `precision:` option applies to solar terms, microseasons, and supplementary
observances. New-moon and lunisolar APIs always use the precise lunar model.

## Command line

The executable prints text by default and supports JSON output:

```bash
sekki24 2026 --tz +09:00
sekki24 2026 --tz +09:00 --precision precise --format json
sekki24 2026 --tz +09:00 --calendar kou --format json
sekki24 2026 --tz +09:00 --calendar zassetsu
sekki24 2026 --tz +09:00 --calendar new-moons
sekki24 2026 --tz +09:00 --calendar lunisolar
```

Run `sekki24 --help` for all options.

## Accuracy and algorithms

- UTC is converted to Terrestrial Time with the Espenak–Meeus ΔT
  polynomials. Future ΔT is necessarily an estimate.
- `:fast` follows the solar-position approximation in Jean Meeus,
  *Astronomical Algorithms*, Chapter 25.
- `:precise` embeds the principal terms from the official IMCCE VSOP87D Earth
  series by Bretagnon and Francou. No coefficient file is read at runtime.
- Solar-longitude crossings are solved with Newton iteration and a bisection
  fallback.
- Lunar longitude uses the principal periodic terms from Meeus, with
  eccentricity, additive perturbation, and nutation corrections. New moons are
  solved as apparent Sun–Moon longitude conjunctions.

Tests compare solar terms, supplementary terms, and all 2026 new moons against
published National Astronomical Observatory of Japan values. They check solar
and lunisolar calendar invariants for every supported year, the 2014 leap ninth
month, the recommended 2033 leap eleventh month, timezone handling, and
Gregorian/lunisolar round trips.

## Development

```bash
bundle install
bundle exec rake
```

The CI matrix covers Ruby 3.0, 3.2, and 3.4.

## License

Sekki24 is available under the [MIT License](LICENSE.txt).
