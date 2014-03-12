require 'test_helper'
require 'gds_api/external_link_tracker'

describe GdsApi::ExternalLinkTracker do

  before do
    @base_api_url = "http://link-tracker-api.example.com"
    @api = GdsApi::ExternalLinkTracker.new(@base_api_url)
  end

  describe "managing links" do
    it "should allow creating an external link" do
      req = WebMock.stub_request(:put, "#{@base_api_url}/url?url=http%3A%2F%2Ffoo.example.com%2F").
        to_return(:status => 201,
                  :headers => {"Content-type" => "application/json"})

      response = @api.add_external_link("http://foo.example.com/")
      assert_equal 201, response.code

      assert_requested(req)
    end

    it "should raise an error if creating an external link fails" do
      req = WebMock.stub_request(:put, "#{@base_api_url}/url?url=invalid").
        to_return(:status => 400, :headers => {"Content-type" => "application/json"})

      e = nil
      begin
        @api.add_external_link("invalid")
      rescue GdsApi::HTTPErrorResponse => ex
        e = ex
      end

      refute_nil e
      assert_equal 400, e.code

      assert_requested(req)
    end
  end
end
