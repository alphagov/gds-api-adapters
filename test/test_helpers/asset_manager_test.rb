require 'test_helper'
require 'gds_api/asset_manager'
require 'gds_api/test_helpers/asset_manager'

describe GdsApi::TestHelpers::AssetManager do
  include GdsApi::TestHelpers::AssetManager

  let(:asset_manager) do
    GdsApi::AssetManager.new(Plek.current.find("asset-manager"))
  end

  describe "#asset_manager_receives_an_asset" do
    describe "when passed a string" do
      it "returns the string as the file url" do
        url = "https://assets.example.com/path/to/asset"
        asset_manager_receives_an_asset(url)
        response = asset_manager.create_asset({})

        assert_equal url, response["file_url"]
      end
    end

    describe "when passed no arguments" do
      it "returns a random, yet valid asset manager url" do
        asset_manager_receives_an_asset
        response = asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/[^/]*/[^/]*\Z}
        assert_match url_format, response["file_url"]
      end
    end

    describe "when passed a hash" do
      it "can specify the id of an asset" do
        asset_manager_receives_an_asset(id: "123")
        response = asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/123/[^/]*\Z}
        assert_match url_format, response["file_url"]
      end

      it "can specify the filename of an asset" do
        asset_manager_receives_an_asset(filename: "file.ext")
        response = asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/[^/]*/file.ext\Z}
        assert_match url_format, response["file_url"]
      end

      it "can specify both filename and id" do
        asset_manager_receives_an_asset(id: "123", filename: "file.ext")
        response = asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/123/file.ext\Z}
        assert_match url_format, response["file_url"]
      end
    end
  end
end
