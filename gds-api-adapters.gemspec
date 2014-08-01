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
  s.add_dependency 'plek'
  s.add_dependency 'null_logger'
  s.add_dependency 'link_header'
  s.add_dependency 'lrucache', '~> 0.1.1'
  s.add_dependency 'rest-client', '~> 1.6.3'  # At least 1.6.3 for redirect limits
  s.add_dependency 'rack-cache'
  s.add_dependency 'webmock', '~> 1.18'

  s.add_development_dependency 'rdoc', '3.12'
  s.add_development_dependency 'rake', '~> 0.9.2.2'
  s.add_development_dependency 'mocha', '~> 0.12.4'
  s.add_development_dependency "minitest", "~> 3.4.0"
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'simplecov', '~> 0.5.4'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'gem_publisher', '~> 1.1.1'
  s.add_development_dependency 'timecop', '~> 0.5.1'
end
