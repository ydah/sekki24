# Sekki24

Sekki24 is a dependency-free Ruby gem that calculates the exact instants of the
24 East Asian solar terms (二十四節気) for years 1900–2100. It computes apparent
solar longitude at runtime, so it does not rely on downloaded ephemeris files or
precomputed date tables.

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

## Command line

The executable prints text by default and supports JSON output:

```bash
sekki24 2026 --tz +09:00
sekki24 2026 --tz +09:00 --precision precise --format json
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

Tests compare 2010, 2020, and 2026 results against published National
Astronomical Observatory of Japan values. They also check calendar invariants
for every supported year and representative timezone offsets.

## Development

```bash
bundle install
bundle exec rake
```

The CI matrix covers Ruby 3.0, 3.2, and 3.4.

## License

Sekki24 is available under the [MIT License](LICENSE.txt).
