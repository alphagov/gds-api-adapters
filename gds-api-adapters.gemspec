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

  s.files        = Dir.glob("lib/**/*") + %w(README.md Rakefile)
  s.test_files   = Dir['test/**/*']
  s.require_path = 'lib'
  s.add_dependency 'plek', '>= 1.9.0'
  s.add_dependency 'null_logger'
  s.add_dependency 'link_header'
  s.add_dependency 'lrucache', '~> 0.1.1'
  s.add_dependency 'rest-client', '~> 1.8.0'
  s.add_dependency 'rack-cache'

  s.add_development_dependency 'gem_publisher', '~> 1.5.0'
  s.add_development_dependency 'mocha', "> 1.0.0"
  s.add_development_dependency "minitest", "> 5.0.0"
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rack', '~> 1.6.4'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake', '~> 0.9.2.2'
  s.add_development_dependency 'yard', '0.8.7.6'
  s.add_development_dependency 'simplecov', '~> 0.5.4'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'timecop', '~> 0.5.1'

  # Webmock 1.24.3 complains that "WebMock does not support matching body for multipart/form-data requests"
  # This is currently breaks existing tests. Revisit this when new version of
  # webmock is released.
  s.add_development_dependency 'webmock', '1.24.2'

  s.add_development_dependency 'pact', '1.9.0'
  s.add_development_dependency 'pact-mock_service', '0.8.1'
  s.add_development_dependency 'pact-consumer-minitest', '1.0.1'
  s.add_development_dependency 'pact_broker-client', '1.0.0'
end
