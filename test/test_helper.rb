require "bundler"
Bundler.setup :default, :development, :test

require "simplecov"
require "simplecov-rcov"

SimpleCov.start do
  add_filter "/test/"
  add_group "Test Helpers", "lib/gds_api/test_helpers"
  formatter SimpleCov::Formatter::RcovFormatter
end

require "minitest/autorun"
require "minitest/around"
require "rack/utils"
require "rack/test"
require "mocha/minitest"
require "timecop"
require "gds-api-adapters"
require "govuk-content-schema-test-helpers"
require "climate_control"

class Minitest::Test
  def teardown
    Timecop.return
  end
end

require "pact/consumer/minitest"
module PactTest
  include Pact::Consumer::Minitest

  def before_setup
    # Pact does its own stubbing of network connections, so we want to
    # prevent WebMock interfering when pact is being used.
    ::WebMock.allow_net_connect!
    super
  end

  def after_teardown
    super
    ::WebMock.disable_net_connect!
  end
end

def load_fixture_file(filename)
  File.open(File.join(File.dirname(__FILE__), "fixtures", filename), encoding: "utf-8")
end

require "gds_api/test_helpers/json_client_helper"
require "test_helpers/pact_helper"

require "webmock/minitest"
WebMock.disable_net_connect!

GovukContentSchemaTestHelpers.configure do |config|
  config.schema_type = "publisher_v2"
  config.project_root = File.absolute_path(File.join(File.basename(__FILE__), ".."))
end

Mocha.configure do |c|
  c.reinstate_undocumented_behaviour_from_v1_9 = false
end
