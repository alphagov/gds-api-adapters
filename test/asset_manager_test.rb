require "test_helper"
require "gds_api/asset_manager"
require "gds_api/test_helpers/asset_manager"
require "json"

describe GdsApi::AssetManager do
  include GdsApi::TestHelpers::AssetManager

  let(:base_api_url) { Plek.find("asset-manager") }
  let(:api) { GdsApi::AssetManager.new(base_api_url) }

  let(:file_fixture) { load_fixture_file("hello.txt") }

  let(:asset_url) { [base_api_url, "assets", asset_id].join("/") }
  let(:asset_id) { "new-asset-id" }

  let(:stub_asset_manager_response) do
    {
      asset: {
        id: asset_url,
      },
    }
  end

  it "creates the asset with a file" do
    req = stub_request(:post, "#{base_api_url}/assets")
            .with { |request|
              request.body =~ %r{Content-Disposition: form-data; name="asset\[file\]"; filename="hello\.txt"\r\nContent-Type: text/plain}
            }.to_return(body: JSON.dump(stub_asset_manager_response), status: 201)

    response = api.create_asset(file: file_fixture)

    assert_equal asset_url, response["asset"]["id"]
    assert_requested(req)
  end

  it "returns not found when the asset does not exist" do
    stub_asset_manager_does_not_have_an_asset("not-really-here")

    assert_raises GdsApi::HTTPNotFound do
      api.asset("not-really-here")
    end

    assert_raises GdsApi::HTTPNotFound do
      api.delete_asset("not-really-here")
    end
  end

  describe "the asset exists" do
    before do
      stub_asset_manager_has_an_asset(
        asset_id,
        {
          "name" => "photo.jpg",
          "content_type" => "image/jpeg",
          "file_url" => "http://fooey.gov.uk/media/photo.jpg",
        },
        "photo.jpg",
      )
    end

    let(:asset_id) { "test-id" }

    it "updates the asset with a file" do
      req = stub_request(:put, "#{base_api_url}/assets/test-id")
              .to_return(body: JSON.dump(stub_asset_manager_response), status: 200)

      response = api.update_asset(asset_id, file: file_fixture)

      assert_equal "#{base_api_url}/assets/#{asset_id}", response["asset"]["id"]
      assert_requested(req)
    end

    it "retrieves the asset's metadata" do
      asset = api.asset(asset_id)

      assert_equal "photo.jpg", asset["name"]
      assert_equal "image/jpeg", asset["content_type"]
      assert_equal "http://fooey.gov.uk/media/photo.jpg", asset["file_url"]
    end

    it "retrieves the asset from media" do
      asset = api.media(asset_id, "photo.jpg")

      assert_equal "Some file content", asset.body
    end
  end

  describe "a Whitehall asset exists" do
    before do
      stub_asset_manager_has_a_whitehall_media_asset(
        "/government/uploads/photo.jpg",
        "Some file content",
      )
    end

    it "retrieves the asset" do
      asset = api.whitehall_media("/government/uploads/photo.jpg")

      assert_equal "Some file content", asset.body
    end
  end

  describe "a Whitehall asset with a legacy_url_path containing non-ascii characters exists" do
    before do
      stub_asset_manager_has_a_whitehall_media_asset(
        "/government/uploads/phot%C3%B8.jpg",
        "Some file content",
      )
    end

    it "retrieves the asset's metadata" do
      asset = api.whitehall_media("/government/uploads/photø.jpg")

      assert_equal "Some file content", asset.body
    end
  end

  it "deletes the asset for the given id" do
    req = stub_request(:delete, "#{base_api_url}/assets/#{asset_id}")
            .to_return(body: JSON.dump(stub_asset_manager_response), status: 200)

    response = api.delete_asset(asset_id)

    assert_equal "#{base_api_url}/assets/#{asset_id}", response["asset"]["id"]
    assert_requested(req)
  end

  it "restores the asset for the given id" do
    req = stub_request(:post, "#{base_api_url}/assets/#{asset_id}/restore")
            .to_return(body: JSON.dump(stub_asset_manager_response), status: 200)

    response = api.restore_asset(asset_id)

    assert_equal "#{base_api_url}/assets/#{asset_id}", response["asset"]["id"]
    assert_requested(req)
  end
end
