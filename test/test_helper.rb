# Ensure that in tests, we get a consistent domain back from Plek < 1.0.0
# Without this, content API tests re chunking of requests with long URLs would
# pass/fail in dev/CI.
ENV['RACK_ENV'] = "test"

require 'bundler'
Bundler.setup :default, :development, :test

require 'minitest/autorun'
require 'rack/utils'
require 'rack/test'
require 'simplecov'
require 'simplecov-rcov'
require 'mocha/mini_test'
require 'timecop'

SimpleCov.start do
  add_filter "/test/"
  add_group "Test Helpers", "lib/gds_api/test_helpers"
  formatter SimpleCov::Formatter::RcovFormatter
end

class MiniTest::Unit::TestCase
  def teardown
    Timecop.return
  end
end

require 'pact/consumer/minitest'
module PactTest
  include Pact::Consumer::Minitest

  def before_suite
    # Pact does its own stubbing of network connections, so we want to
    # prevent WebMock interfering when pact is being used.
    ::WebMock.allow_net_connect!
    super
  end

  def after_suite
    super
    ::WebMock.disable_net_connect!
  end
end

def load_fixture_file(filename)
  File.open( File.join( File.dirname(__FILE__), "fixtures", filename ), :encoding => 'utf-8' )
end

require 'webmock/minitest'
WebMock.disable_net_connect!

require 'gds_api/test_helpers/json_client_helper'
require 'test_helpers/pact_helper'

require 'govuk-content-schema-test-helpers'

GovukContentSchemaTestHelpers.configure do |config|
  config.schema_type = 'publisher'
  config.project_root = File.absolute_path(File.join(File.basename(__FILE__), '..'))
end
