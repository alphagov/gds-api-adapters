require 'test_helper'
require 'gds_api/support_api'
require 'gds_api/test_helpers/support_api'

describe GdsApi::SupportApi do
  include GdsApi::TestHelpers::SupportApi

  before do
    @base_api_url = Plek.current.find("support-api")
    @api = GdsApi::SupportApi.new(@base_api_url)
  end

  it "can report a problem" do
    request_details = {certain: "details"}

    stub_post = stub_request(:post, "#{@base_api_url}/anonymous-feedback/problem-reports").
      with(:body => {"problem_report" => request_details}.to_json).
      to_return(:status => 201)

    @api.create_problem_report(request_details)

    assert_requested(stub_post)
  end

  it "can pass service feedback" do
    request_details = {"transaction-completed-values"=>"1", "details"=>"abc"}

    stub_post = stub_request(:post, "#{@base_api_url}/anonymous-feedback/service-feedback").
      with(:body => {"service_feedback" => request_details}.to_json).
      to_return(:status => 201)

    @api.create_service_feedback(request_details)

    assert_requested(stub_post)
  end

  it "can submit long-form anonymous feedback" do
    request_details = {certain: "details"}

    stub_post = stub_request(:post, "#{@base_api_url}/anonymous-feedback/long-form-contacts").
      with(:body => {"long_form_contact" => request_details}.to_json).
      to_return(:status => 201)

    @api.create_anonymous_long_form_contact(request_details)

    assert_requested(stub_post)
  end

  it "fetches problem report daily totals" do
    response_body = {"data" => ["results"]}

    stub_get = stub_request(:get, "#{@base_api_url}/anonymous-feedback/problem-reports/2014-07-12/totals").
      to_return(:status => 200, body: response_body.to_json)

    result = @api.problem_report_daily_totals_for(Date.new(2014, 7, 12))

    assert_requested(stub_get)
    assert_equal response_body, result.to_hash
  end

  it "throws an exception when the support app isn't available" do
    support_api_isnt_available

    assert_raises(GdsApi::HTTPServerError) { @api.create_service_feedback({}) }
  end

  describe "GET /anonymous-feedback" do
    it "fetches anonymous feedback" do
      stub_get = stub_anonymous_feedback(
        path_prefix: "/vat-rates",
        page: 55,
      )

      result = @api.anonymous_feedback(
        path_prefix: "/vat-rates",
        page: 55,
      )

      assert_requested(stub_get)
    end
  end

  describe "GET /anonymous-feedback/organisations/:organisation_slug" do
    it "fetches organisation summary" do
      slug = "hm-revenue-customs"

      stub_get = stub_anonymous_feedback_organisation_summary(slug)

      @api.organisation_summary(slug)

      assert_requested(stub_get)
    end

    it "accepts an ordering parameter" do
      slug = "hm-revenue-customs"
      ordering = "last_30_days"

      stub_get = stub_anonymous_feedback_organisation_summary(slug, ordering)

      @api.organisation_summary(slug, ordering: ordering)

      assert_requested(stub_get)
    end
  end

  describe "GET /anonymous-feedback/organisations" do
    it "fetches a list of organisations" do
      stub_get = stub_anonymous_feedback_organisations_list

      @api.organisations_list

      assert_requested(stub_get)
    end
  end
end
