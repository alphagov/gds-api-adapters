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
  s.description  = "A set of adapters providing easy access to the GDS gov.uk APIs"
 
  s.files        = Dir.glob("lib/**/*") + %w(README.md Rakefile)
  s.test_files   = Dir['test/**/*']
  s.require_path = 'lib'
  s.add_dependency 'plek'
  
  s.add_development_dependency 'rake', '~> 0.9.2.2'
  s.add_development_dependency 'webmock', '~> 1.7'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'simplecov', '0.4.2'
end
