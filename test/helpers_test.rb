require 'test_helper'
require 'gds_api/helpers'

describe GdsApi::Helpers do
  class TestDouble
    include GdsApi::Helpers
  end

  it "should define helpers for the various apis" do
    test_with_helpers = TestDouble.new

    refute_nil test_with_helpers.asset_manager_api
    refute_nil test_with_helpers.business_support_api
    refute_nil test_with_helpers.content_api
    refute_nil test_with_helpers.content_store
    refute_nil test_with_helpers.publisher_api
    refute_nil test_with_helpers.imminence_api
    refute_nil test_with_helpers.licence_application_api
    refute_nil test_with_helpers.need_api
    refute_nil test_with_helpers.panopticon_api
    refute_nil test_with_helpers.worldwide_api
    refute_nil test_with_helpers.email_alert_api
  end
end
