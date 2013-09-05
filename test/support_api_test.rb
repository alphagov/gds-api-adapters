require 'test_helper'
require 'gds_api/support'
require 'gds_api/test_helpers/support'

describe GdsApi::Support do
  include GdsApi::TestHelpers::Support

  before do
    @base_api_url = Plek.current.find("support")
    @api = GdsApi::Support.new(@base_api_url)
  end

  it "can create an FOI request" do
    request_details = {"foi_request"=>{"requester"=>{"name"=>"A", "email"=>"a@b.com"}, "details"=>"abc"}}

    stub_post = stub_request(:post, "#{@base_api_url}/foi_requests").
      with(:body => {"foi_request" => request_details}.to_json).
      to_return(:status => 201)

    @api.create_foi_request(request_details)

    assert_requested(stub_post)
  end

  it "can add a custom header onto the FOI request to the support app" do
    stub_request(:post, "#{@base_api_url}/foi_requests")

    @api.create_foi_request({}, headers: { "X-Varnish" => "12345"})

    assert_requested(:post, %r{/foi_requests}) do |request|
      request.headers["X-Varnish"] == "12345"
    end
  end

  it "throws an exception when the support app isn't available" do
    support_isnt_available

    assert_raises(GdsApi::HTTPErrorResponse) { @api.create_foi_request({}) }
  end

  it "can report a problem" do
    request_details = {certain: "details"}

    stub_post = stub_request(:post, "#{@base_api_url}/problem_reports").
      with(:body => {"problem_report" => request_details}.to_json).
      to_return(:status => 201)

    @api.create_problem_report(request_details)

    assert_requested(stub_post)
  end

  it "can add a custom header onto the problem_report request to the support app" do
    stub_request(:post, "#{@base_api_url}/problem_reports")

    @api.create_problem_report({}, headers: { "X-Varnish" => "12345"})

    assert_requested(:post, %r{/problem_reports}) do |request|
      request.headers["X-Varnish"] == "12345"
    end
  end

  it "throws an exception when the support app isn't available" do
    support_isnt_available

    assert_raises(GdsApi::HTTPErrorResponse) { @api.create_problem_report({}) }
  end
end
