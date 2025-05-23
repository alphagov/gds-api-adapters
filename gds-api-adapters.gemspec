lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require "gds_api/version"
Gem::Specification.new do |s|
  s.name         = "gds-api-adapters"
  s.version      = GdsApi::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["GOV.UK Dev"]
  s.email        = ["govuk-dev@digital.cabinet-office.gov.uk"]
  s.summary      = "Adapters to work with GDS APIs"
  s.homepage     = "http://github.com/alphagov/gds-api-adapters"
  s.description  = "A set of adapters providing easy access to the GDS GOV.UK APIs"

  s.required_ruby_version = ">= 3.2"
  s.files        = Dir.glob("lib/**/*") + Dir.glob("test/fixtures/**/*") + %w[README.md Rakefile]
  s.require_path = "lib"
  s.add_dependency "addressable"
  s.add_dependency "link_header"
  s.add_dependency "null_logger"
  s.add_dependency "plek", ">= 1.9.0"
  s.add_dependency "rack", ">= 2.2.0"
  s.add_dependency "rest-client", "~> 2.0"

  s.add_development_dependency "byebug"
  s.add_development_dependency "climate_control", "~> 1.2"
  s.add_development_dependency "govuk_schemas", "~> 6.0"
  s.add_development_dependency "minitest", "~> 5.19"
  s.add_development_dependency "minitest-around", "~> 0.5"
  s.add_development_dependency "mocha", "~> 2.1"
  s.add_development_dependency "pact", "~> 1.62"
  s.add_development_dependency "pact_broker-client", "~> 1.65"
  s.add_development_dependency "pact-consumer-minitest", "~> 1.0"
  s.add_development_dependency "pact-mock_service", "~> 3.10"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rake"
  s.add_development_dependency "rubocop-govuk", "5.1.9"
  s.add_development_dependency "simplecov", "~> 0.21"
  s.add_development_dependency "timecop", "~> 0.9"
  s.add_development_dependency "webmock", "~> 3.17"
end
