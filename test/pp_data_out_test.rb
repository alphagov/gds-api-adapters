require 'test_helper'
require 'gds_api/performance_platform/data_out'
require 'gds_api/test_helpers/performance_platform/data_out'

describe GdsApi::PerformancePlatform::DataOut do
  include GdsApi::TestHelpers::PerformancePlatform::DataOut

  before do
    @base_api_url = GdsApi::TestHelpers::PerformancePlatform::DataOut::PP_DATA_OUT_ENDPOINT
    @api = GdsApi::PerformancePlatform::DataOut.new(@base_api_url)
  end

  let(:transaction_slug) { 'register-to-vote' }

  it "calls the service feedback endpoint for a particular slug" do
    request_details = { "some" => "data" }

    stub_post = stub_service_feedback(transaction_slug, request_details)

    @api.service_feedback(transaction_slug)

    assert_requested(stub_post)
  end
end
