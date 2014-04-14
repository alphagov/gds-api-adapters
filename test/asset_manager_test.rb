require 'test_helper'
require 'gds_api/asset_manager'
require 'gds_api/test_helpers/asset_manager'

describe GdsApi::AssetManager do
  include GdsApi::TestHelpers::AssetManager

  before do
    @base_api_url = Plek.current.find("asset-manager")
    @api = GdsApi::AssetManager.new(@base_api_url)
  end

  it "creates an asset with a file" do
    stub_request(:post, "#{@base_api_url}/assets").
      with(:body => %r{Content\-Disposition: form\-data; name="asset\[file\]"; filename="hello\.txt"\r\nContent\-Type: text/plain}).
      to_return(:body => '{"asset":{"id":"http://asset-manager.dev.gov.uk/assets/51278b2b686c82076c000003"}}', :status => 201)

    file = load_fixture_file("hello.txt")
    response = @api.create_asset(:file => file)

    assert_equal "http://asset-manager.dev.gov.uk/assets/51278b2b686c82076c000003", response.asset.id
  end

  it "retrieves an asset" do
    asset_manager_has_an_asset("test-id", { "name" => "photo.jpg", "content_type" => "image/jpeg", "file_url" => "http://fooey.gov.uk/media/photo.jpg" })

    asset = @api.asset("test-id")

    assert_equal "photo.jpg", asset.name
    assert_equal "image/jpeg", asset.content_type
    assert_equal "http://fooey.gov.uk/media/photo.jpg", asset.file_url
  end

  it "returns nil when an asset does not exist" do
    asset_manager_does_not_have_an_asset("not-really-here")

    assert_nil @api.asset("not-really-here")
  end
end
