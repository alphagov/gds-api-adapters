require "test_helper"
require "gds_api/support"

describe GdsApi::Support do
  before do
    @base_api_url = Plek.find("support")
    @api = GdsApi::Support.new(@base_api_url)
  end

  it "gets the correct feedback URL" do
    assert_equal(
      "#{@base_api_url}/anonymous_feedback?path=foo",
      @api.feedback_url("foo"),
    )
  end
end
