require "test_helper"
require "gds_api/performance_platform/data_out"
require "gds_api/test_helpers/performance_platform/data_out"

describe GdsApi::PerformancePlatform::DataOut do
  include GdsApi::TestHelpers::PerformancePlatform::DataOut

  before do
    @base_api_url = GdsApi::TestHelpers::PerformancePlatform::DataOut::PP_DATA_OUT_ENDPOINT
    @api = GdsApi::PerformancePlatform::DataOut.new(@base_api_url)
  end

  let(:transaction_slug) { "register-to-vote" }
  let(:statistics_slug) { "/european-health-insurance-card" }

  it "calls the service feedback endpoint for a particular slug" do
    request_details = { "some" => "data" }

    stub_post = stub_service_feedback(transaction_slug, request_details)

    @api.service_feedback(transaction_slug)

    assert_requested(stub_post)
  end

  it "calls the performance platform search_terms endpoint for a list of unique search results" do
    request_details = { "some" => "data" }

    stub_post = stub_search_terms(statistics_slug, request_details)

    @api.search_terms(statistics_slug)

    assert_requested(stub_post)
  end

  it "calls the performance platform searches endpoint for a list of search results" do
    request_details = { "some" => "data" }
    is_multipart = false

    stub_post = stub_searches(statistics_slug, is_multipart, request_details)

    @api.searches(statistics_slug, is_multipart)

    assert_requested(stub_post)
  end

  it "calls the performance platform page_views endpoint for a list of page statistics" do
    request_details = { "some" => "data" }
    is_multipart = false

    stub_post = stub_page_views(statistics_slug, is_multipart, request_details)

    @api.page_views(statistics_slug, is_multipart)

    assert_requested(stub_post)
  end

  it "calls the performance platform problem_reports endpoint for a list of page contacts" do
    request_details = { "some" => "data" }
    is_multipart = false

    stub_post = stub_problem_reports(statistics_slug, is_multipart, request_details)

    @api.problem_reports(statistics_slug, is_multipart)

    assert_requested(stub_post)
  end
end
