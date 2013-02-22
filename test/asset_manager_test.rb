require 'test_helper'
require 'gds_api/asset_manager'

describe GdsApi::AssetManager do

  before do
    @base_api_url = Plek.current.find("asset-manager")
    @api = GdsApi::AssetManager.new(@base_api_url)
  end

  it "can create an asset with a file" do
    stub_request(:post, "#{@base_api_url}/assets").
      with(:body => %r{Content\-Disposition: form\-data; name="asset\[file\]"; filename="hello\.txt"\r\nContent\-Type: text/plain}).
      to_return(:body => '{"asset":{"id":"http://asset-manager.dev.gov.uk/assets/51278b2b686c82076c000003"}}', :status => 201)

    file = load_fixture_file("hello.txt")
    response = @api.create_asset(file)

    assert_equal "http://asset-manager.dev.gov.uk/assets/51278b2b686c82076c000003", response.asset.id
  end
end
