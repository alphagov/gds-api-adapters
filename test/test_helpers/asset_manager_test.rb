require "test_helper"
require "gds_api/asset_manager"
require "gds_api/test_helpers/asset_manager"

describe GdsApi::TestHelpers::AssetManager do
  include GdsApi::TestHelpers::AssetManager

  let(:stub_asset_manager) do
    GdsApi::AssetManager.new(Plek.find("asset-manager"))
  end

  describe "#stub_asset_manager_create_asset" do
    describe "when passed a string" do
      it "returns the string as the file url" do
        url = "https://assets.example.com/path/to/asset"
        stub_asset_manager_create_asset(url)
        response = stub_asset_manager.create_asset({})

        assert_equal url, response["file_url"]
      end
    end

    describe "when passed no arguments" do
      it "returns a random, yet valid asset manager url" do
        stub_asset_manager_create_asset
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/[^/]*/[^/]*\Z}
        assert_match url_format, response["file_url"]
      end

      it "returns a different URL each call" do
        stub_asset_manager_create_asset
        response1 = stub_asset_manager.create_asset({})
        response2 = stub_asset_manager.create_asset({})

        refute_match response1["file_url"], response2["file_url"]
      end
    end

    describe "when passed a hash" do
      it "can specify the id of an asset" do
        stub_asset_manager_create_asset(id: "123")
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/123/[^/]*\Z}
        assert_match url_format, response["file_url"]
      end

      it "can specify the filename of an asset" do
        stub_asset_manager_create_asset(filename: "file.ext")
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/[^/]*/file.ext\Z}
        assert_match url_format, response["file_url"]
      end

      it "can specify both filename and id" do
        stub_asset_manager_create_asset(id: "123", filename: "file.ext")
        response = stub_asset_manager.create_asset({})

        url_format = %r{\Ahttp://asset-manager.dev.gov.uk/media/123/file.ext\Z}
        assert_match url_format, response["file_url"]
      end
    end
  end

  describe "#stub_asset_manager_receives_an_asset" do
    it "includes a deprecation warning" do
      expects(:warn).with(
        <<~WARNING,
          stub_asset_manager_receives_an_asset is deprecated and will be removed
          in a future version of gds-api-adapters. Replace calls to this method with
          stub_asset_manager_create_asset.
        WARNING
      )

      stub_asset_manager_receives_an_asset
    end

    it "delegates to the new method" do
      expects(:stub_asset_manager_create_asset).once

      stub_asset_manager_receives_an_asset
    end
  end

  describe "#stub_asset_manager_delete_asset" do
    it "returns an ok response and the provided body" do
      asset_id = "some-asset-id"
      body = { key: "value" }
      stub_asset_manager_delete_asset(asset_id, body)

      response = stub_asset_manager.delete_asset(asset_id)

      assert_equal 200, response.code
      assert_equal body[:key], response["key"]
    end
  end

  describe "#stub_asset_manager_delete_asset_missing" do
    it "raises a not found error" do
      asset_id = "some-asset-id"
      stub_asset_manager_delete_asset_missing(asset_id)

      assert_raises GdsApi::HTTPNotFound do
        stub_asset_manager.delete_asset(asset_id)
      end
    end
  end

  describe "#stub_asset_manager_delete_asset_failure" do
    it "raises an internal server error" do
      asset_id = "some-asset-id"
      stub_asset_manager_delete_asset_failure(asset_id)

      assert_raises GdsApi::HTTPInternalServerError do
        stub_asset_manager.delete_asset(asset_id)
      end
    end
  end

  describe "#stub_asset_manager_has_an_asset" do
    describe "when the asset endpoint is requested" do
      it "returns the given attributes" do
        asset_id = "some-asset-id"
        body = { key: "value" }
        stub_asset_manager_has_an_asset(asset_id, body)
        response = stub_asset_manager.asset(asset_id)

        assert_equal 200, response.code
        assert_equal body[:key], response["key"]
      end
    end

    describe "when the media endpoint is requested" do
      it "returns the file content" do
        asset_id = "some-asset-id"
        body = { key: "value" }
        filename = "file.pdf"
        stub_asset_manager_has_an_asset(asset_id, body, filename)
        response = stub_asset_manager.media(asset_id, filename)

        assert_equal 200, response.code
        assert_equal "Some file content", response
      end
    end
  end

  describe "#stub_asset_manager_request_to_get_asset" do
    describe "when the asset endpoint is requested" do
      it "returns the given attributes" do
        asset_id = "some-asset-id"
        body = { key: "value" }
        stub_asset_manager_request_to_get_asset(asset_id, body)
        response = stub_asset_manager.asset(asset_id)

        assert_equal 200, response.code
        assert_equal body[:key], response["key"]
      end
    end
  end

  describe "#stub_asset_manager_request_to_asset_media" do
    describe "when the media endpoint is requested" do
      it "returns the file content" do
        asset_id = "some-asset-id"
        filename = "file.pdf"
        stub_asset_manager_request_to_asset_media(asset_id, filename)
        response = stub_asset_manager.media(asset_id, filename)

        assert_equal 200, response.code
        assert_equal "Some file content", response
      end
    end
  end

  describe "#stub_asset_manager_create_asset_too_large" do
    describe "when the endpoint is requested" do
      it "raises GdsApi::HTTPPayloadTooLarge" do
        stub_asset_manager_create_asset_too_large

        assert_raises GdsApi::HTTPPayloadTooLarge do
          stub_asset_manager.create_asset({})
        end
      end
    end
  end

  describe "#stub_asset_manager_create_asset_unprocessable" do
    describe "when the endpoint is requested" do
      it "raises GdsApi::HTTPUnprocessableEntity" do
        stub_asset_manager_create_asset_unprocessable

        assert_raises GdsApi::HTTPUnprocessableEntity do
          stub_asset_manager.create_asset({})
        end
      end

      it "includes the body when provided" do
        stub_asset_manager_create_asset_unprocessable("Some output")

        error = assert_raises GdsApi::HTTPUnprocessableEntity do
          stub_asset_manager.create_asset({})
        end

        assert_includes error.message, "Some output"
      end
    end
  end
end
