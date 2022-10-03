require "test_helper"
require "gds_api/asset_manager"
require "gds_api/test_helpers/asset_manager"

describe GdsApi::TestHelpers::AssetManager do
  include GdsApi::TestHelpers::AssetManager

  let(:stub_asset_manager) do
    GdsApi::AssetManager.new(Plek.find("asset-manager"))
  end

  describe "#stub_asset_manager_receives_an_asset" do
    describe "when passed a string" do
      it "returns the string as the file url" do
        url = "https://assets.example.com/path/to/asset"
        stub_asset_manager_receives_an_asset(url)
        response = stub_asset_manager.create_asset({})

        assert_equal url, response["file_url"]
      end
    end

    describe "when passed no arguments" do
      it "returns a random, yet valid asset manager url" do
        stub_asset_manager_receives_an_asset
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/[^/]*/[^/]*\Z}
        assert_match url_format, response["file_url"]
      end

      it "returns a different URL each call" do
        stub_asset_manager_receives_an_asset
        response1 = stub_asset_manager.create_asset({})
        response2 = stub_asset_manager.create_asset({})

        refute_match response1["file_url"], response2["file_url"]
      end
    end

    describe "when passed a hash" do
      it "can specify the id of an asset" do
        stub_asset_manager_receives_an_asset(id: "123")
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/123/[^/]*\Z}
        assert_match url_format, response["file_url"]
      end

      it "can specify the filename of an asset" do
        stub_asset_manager_receives_an_asset(filename: "file.ext")
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/[^/]*/file.ext\Z}
        assert_match url_format, response["file_url"]
      end

      it "can specify both filename and id" do
        stub_asset_manager_receives_an_asset(id: "123", filename: "file.ext")
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/123/file.ext\Z}
        assert_match url_format, response["file_url"]
      end
    end
  end
end
