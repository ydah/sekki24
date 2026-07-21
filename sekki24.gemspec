# frozen_string_literal: true

require_relative "lib/sekki24/version"

Gem::Specification.new do |spec|
  spec.name = "sekki24"
  spec.version = Sekki24::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Calculate Japanese solar terms, observances, and lunisolar dates"
  spec.description = <<~DESCRIPTION
    Sekki24 calculates the 24 solar terms, 72 microseasons, supplementary
    seasonal observances, new moons, and Japanese lunisolar dates for years
    1900 through 2100 using pure Ruby and no runtime dependencies.
  DESCRIPTION
  spec.homepage = "https://rubygems.org/gems/sekki24"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
