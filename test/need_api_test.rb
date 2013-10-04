require 'test_helper'
require 'gds_api/need_api'

describe GdsApi::NeedApi do

  before do
    @base_api_url = Plek.current.find("needapi")
    @api = GdsApi::NeedApi.new(@base_api_url)
  end

  describe "creating needs" do
    it "should post to the right endpoint" do
      stub_request(:post, @base_api_url + "/needs").with(
        :body => '{"goal":"I wanna sammich!"}'
      )
      @api.create_need({"goal" => "I wanna sammich!"})
    end
  end
end
