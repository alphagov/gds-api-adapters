require 'test_helper'
require 'gds_api/maslow'

describe GdsApi::Maslow do
  before do
    @api = GdsApi::Maslow.new("http://maslow.dev.gov.uk")
  end

  it "should provide a URL to need pages" do
    assert_equal "http://maslow.dev.gov.uk/needs/12345", @api.need_page_url(12345)
  end
end
