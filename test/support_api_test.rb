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

  describe "problem report by org" do
    it "fetches problem reports by org for a given month (JSON)" do
      stub_get = stub_request(:get, "#{@base_api_url}/anonymous-feedback/problem-reports/2012-02.json?organisation_slug=moj").
        to_return(:status => 200, body: ['some', 'response'].to_json)

      response = @api.problem_reports_for(month: Date.new(2012,02,01), organisation_slug: "moj")

      assert_equal(["some", "response"], response.to_a)
    end

    it "fetches problem reports by org for a given day (JSON)" do
      stub_get = stub_request(:get, "#{@base_api_url}/anonymous-feedback/problem-reports/2012-02-02.json?organisation_slug=moj").
        to_return(:status => 200, body: ['some', 'response'].to_json)

      response = @api.problem_reports_for(day: Date.new(2012,02,02), organisation_slug: "moj")

      assert_equal(["some", "response"], response.to_a)
    end

    it "fetches problem reports by org for a given month (CSV)" do
      stub_get = stub_request(:get, "#{@base_api_url}/anonymous-feedback/problem-reports/2012-02.csv?organisation_slug=moj").
        to_return(:status => 200, body: 'csv response')

      response = @api.problem_reports_for(month: Date.new(2012,02,01), organisation_slug: "moj", format: 'csv')

      assert_equal("csv response", response.to_s)
    end
  end

  it "throws an exception when the support app isn't available" do
    support_api_isnt_available

    assert_raises(GdsApi::HTTPServerError) { @api.create_service_feedback({}) }
  end
end
