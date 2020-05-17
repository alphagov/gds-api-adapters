require "test_helper"
require "gds_api/support"
require "gds_api/test_helpers/support"

describe GdsApi::Support do
  include GdsApi::TestHelpers::Support

  before do
    @base_api_url = Plek.current.find("support")
    @api = GdsApi::Support.new(@base_api_url)
  end

  it "can create an FOI request" do
    request_details = { "foi_request" => { "requester" => { "name" => "A", "email" => "a@b.com" }, "details" => "abc" } }

    stub_post = stub_request(:post, "#{@base_api_url}/foi_requests")
      .with(body: { "foi_request" => request_details }.to_json)
      .to_return(status: 201)

    @api.create_foi_request(request_details)

    assert_requested(stub_post)
  end

  it "throws an exception when the support app isn't available while creating FOI requests" do
    stub_support_isnt_available

    assert_raises(GdsApi::HTTPServerError) { @api.create_foi_request({}) }
  end

  it "can create a named contact" do
    request_details = { certain: "details" }

    stub_post = stub_request(:post, "#{@base_api_url}/named_contacts")
      .with(body: { "named_contact" => request_details }.to_json)
      .to_return(status: 201)

    @api.create_named_contact(request_details)

    assert_requested(stub_post)
  end

  it "throws an exception when the support app isn't available while creating named contacts" do
    stub_support_isnt_available

    assert_raises(GdsApi::HTTPServerError) { @api.create_named_contact({}) }
  end

  it "gets the correct feedback URL" do
    assert_equal(
      "#{@base_api_url}/anonymous_feedback?path=foo",
      @api.feedback_url("foo"),
    )
  end
end
