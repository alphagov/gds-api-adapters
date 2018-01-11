# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gds_api/version'

Gem::Specification.new do |s|
  s.name         = "gds-api-adapters"
  s.version      = GdsApi::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["James Stewart"]
  s.email        = ["jystewart@gmail.com"]
  s.summary      = "Adapters to work with GDS APIs"
  s.homepage     = "http://github.com/alphagov/gds-api-adapters"
  s.description  = "A set of adapters providing easy access to the GDS GOV.UK APIs"

  s.files        = Dir.glob("lib/**/*") + Dir.glob("test/fixtures/**/*") + %w(README.md Rakefile)
  s.require_path = 'lib'
  s.add_dependency 'plek', '>= 1.9.0'
  s.add_dependency 'null_logger'
  s.add_dependency 'link_header'
  s.add_dependency 'lrucache', '~> 0.1.1'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'rack-cache'
  s.add_dependency 'addressable'

  s.add_development_dependency 'govuk-content-schema-test-helpers', '~> 1.5'
  s.add_development_dependency 'mocha', "~> 1.3.0"
  s.add_development_dependency "minitest", "~> 5.10.3"
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rack', '~> 2.0.3'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake', '~> 12.3.0'
  s.add_development_dependency 'yard', '~> 0.9.11'
  s.add_development_dependency 'simplecov', '~> 0.15.1'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'timecop', '~> 0.9.1'
  s.add_development_dependency 'webmock', '~> 3.1.1'
  # Versions of webrick > 1.3.1 only work with ruby >= 2.3.
  # We specify webrick to be 1.3.1 here because in our CI builds we are testing with ruby versions 2.1 and 2.2.
  s.add_development_dependency 'webrick', '1.3.1'

  s.add_development_dependency 'pact', '1.19.2'
  s.add_development_dependency 'pact-mock_service', '2.6.2'
  s.add_development_dependency 'pact-consumer-minitest', '1.0.1'
  s.add_development_dependency 'pact_broker-client', '1.13.1'
  s.add_development_dependency 'govuk-lint', '3.3.1'
end
