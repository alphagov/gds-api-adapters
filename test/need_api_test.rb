require 'test_helper'
require 'gds_api/need_api'
require 'gds_api/test_helpers/need_api'

describe GdsApi::NeedApi do
  include GdsApi::TestHelpers::NeedApi

  before do
    @base_api_url = Plek.current.find("need-api")
    @api = GdsApi::NeedApi.new(@base_api_url)
  end

  describe "creating needs" do
    it "should post to the right endpoint" do
      request_stub = stub_request(:post, @base_api_url + "/needs").with(
        :body => '{"goal":"I wanna sammich!"}'
      )
      @api.create_need({"goal" => "I wanna sammich!"})
      assert_requested(request_stub)
    end
  end

  describe "viewing organisations" do
    it "should return a list of organisations" do
      request_stub = need_api_has_organisations(
        "committee-on-climate-change" => "Committee on Climate Change",
        "competition-commission" => "Competition Commission"
      )

      orgs = @api.organisations

      assert_requested(request_stub)
      assert_equal "Committee on Climate Change", orgs[0]["name"]
      assert_equal "Competition Commission", orgs[1]["name"]
      assert_equal 2, orgs.size
    end
  end
end
