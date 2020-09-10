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

  s.required_ruby_version = ">= 2.4.0"
  s.files        = Dir.glob("lib/**/*") + Dir.glob("test/fixtures/**/*") + %w[README.md Rakefile]
  s.require_path = "lib"
  s.add_dependency "addressable"
  s.add_dependency "link_header"
  s.add_dependency "null_logger", "= 0.0.1"
  s.add_dependency "plek", ">= 1.9.0"
  s.add_dependency "rest-client", "~> 2.0"

  s.add_development_dependency "climate_control", "~> 0.2"
  s.add_development_dependency "govuk-content-schema-test-helpers", "~> 1.6"
  s.add_development_dependency "minitest", "~> 5.11"
  s.add_development_dependency "minitest-around", "~> 0.5"
  s.add_development_dependency "mocha", "~> 1.11"
  s.add_development_dependency "pact", "~> 1.20"
  s.add_development_dependency "pact_broker-client", "~> 1.14"
  s.add_development_dependency "pact-consumer-minitest", "~> 1.0"
  s.add_development_dependency "pact-mock_service", "~> 2.6"
  s.add_development_dependency "pry"
  s.add_development_dependency "rack", "~> 2.0"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rake", "~> 12.3"
  s.add_development_dependency "rubocop-govuk"
  s.add_development_dependency "simplecov", "~> 0.16"
  s.add_development_dependency "simplecov-rcov"
  s.add_development_dependency "timecop", "~> 0.9"
  s.add_development_dependency "webmock", "~> 3.5"
  s.add_development_dependency "webrick", "~> 1.4"
  s.add_development_dependency "yard", "~> 0.9"
end
