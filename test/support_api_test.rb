require 'test_helper'
require 'gds_api/support'

describe GdsApi::Support do
  before do
    @base_api_url = Plek.current.find("support")
    @api = GdsApi::Support.new(@base_api_url)
  end

  it "can create an asset with a file" do
    request_details = {"foi_request"=>{"requester"=>{"name"=>"A", "email"=>"a@b.com"}, "details"=>"abc"}}

    stub_post = stub_request(:post, "#{@base_api_url}/foi_requests").
      with(:body => {"foi_request" => request_details}.to_json).
      to_return(:status => 201)

    @api.create_foi_request(request_details)

    assert_requested(stub_post)
  end
end
