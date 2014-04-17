require 'test_helper'
require 'gds_api/asset_manager'
require 'gds_api/test_helpers/asset_manager'
require 'json'

describe GdsApi::AssetManager do
  include GdsApi::TestHelpers::AssetManager

  let(:base_api_url) { Plek.current.find('asset-manager') }
  let(:api) { GdsApi::AssetManager.new(base_api_url) }

  let(:file_fixture) { load_fixture_file("hello.txt") }

  let(:asset_url) { [base_api_url, "assets", asset_id].join("/") }
  let(:asset_id) { "new-asset-id" }

  let(:asset_manager_response) {
    {
      asset: {
        id: asset_url,
      }
    }
  }

  it "creates an asset with a file" do
    req = stub_request(:post, "#{base_api_url}/assets").
      with(:body => %r{Content\-Disposition: form\-data; name="asset\[file\]"; filename="hello\.txt"\r\nContent\-Type: text/plain}).
      to_return(:body => JSON.dump(asset_manager_response), :status => 201)

    response = api.create_asset(:file => file_fixture)

    assert_equal asset_url, response.asset.id
    assert_requested(req)
  end

  it "returns nil when an asset does not exist" do
    asset_manager_does_not_have_an_asset("not-really-here")

    assert_nil api.asset("not-really-here")
  end

  describe "an asset exists" do
    before do
      asset_manager_has_an_asset(
        asset_id,
        "name" => "photo.jpg",
        "content_type" => "image/jpeg",
        "file_url" => "http://fooey.gov.uk/media/photo.jpg",
      )
    end

    let(:asset_id) { "test-id" }

    it "updates an asset with a file" do
      req = stub_request(:put, "http://asset-manager.dev.gov.uk/assets/test-id").
        to_return(:body => JSON.dump(asset_manager_response), :status => 200)

      response = api.update_asset(asset_id, :file => file_fixture)

      assert_equal "#{base_api_url}/assets/#{asset_id}", response.asset.id
      assert_requested(req)
    end

    it "retrieves an asset" do
      asset = api.asset(asset_id)

      assert_equal "photo.jpg", asset.name
      assert_equal "image/jpeg", asset.content_type
      assert_equal "http://fooey.gov.uk/media/photo.jpg", asset.file_url
    end
  end
end
