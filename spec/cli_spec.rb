# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"

RSpec.describe "sekki24 executable" do
  def run_cli(*arguments)
    unbundled_environment = ENV.each_key
      .grep(/\A(?:BUNDLE|BUNDLER|RUBYOPT|RUBYLIB)/)
      .to_h { |key| [key, nil] }

    Open3.capture3(
      unbundled_environment,
      RbConfig.ruby,
      "-I#{File.expand_path("../lib", __dir__)}",
      File.expand_path("../exe/sekki24", __dir__),
      *arguments
    )
  end

  it "prints all terms as text" do
    stdout, stderr, status = run_cli("2026", "--tz", "+09:00")

    expect(status).to be_success
    expect(stderr).to be_empty
    expect(stdout.lines.length).to eq(24)
    expect(stdout).to include("2026-02-04T05:02", "立春 (risshun)", "315°")
  end

  it "emits machine-readable JSON" do
    stdout, stderr, status = run_cli("2026", "--tz", "+09:00", "--format", "json")
    records = JSON.parse(stdout)

    expect(status).to be_success
    expect(stderr).to be_empty
    expect(records.length).to eq(24)
    expect(records.fetch(2)).to include(
      "key" => "risshun",
      "name_ja" => "立春",
      "longitude" => 315,
      "date" => "2026-02-04"
    )
  end

  it "reports invalid input without a backtrace" do
    _stdout, stderr, status = run_cli("2200")

    expect(status).not_to be_success
    expect(stderr).to include("year must be between 1900 and 2100", "Usage: sekki24")
    expect(stderr).not_to include(".rb:")
  end
end
