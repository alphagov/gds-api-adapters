require "test_helper"
require "gds_api/asset_manager"
require "gds_api/test_helpers/asset_manager"
require "asset_manager/asset_manager_pact_helper"
require "json"

describe GdsApi::AssetManager do
  include PactTest
  include AssetManagerPactHelper

  let(:api_client) { GdsApi::AssetManager.new(asset_manager_api_host) }
  let(:content_id) { "4dca570c2975bc0d6d437491" }
  let(:filename) { "hello.txt" }
  let(:file_fixture) { load_fixture_file(filename) }

  describe "Non-Whitehall assets" do
    let(:url_for_existing_asset) { "http://static.dev.gov.uk/media/#{content_id}/asset.png" }
    let(:existing_asset_response_body) { existing_asset_body(file_url: url_for_existing_asset) }

    describe "#create_asset" do
      it "creates a new asset" do
        asset_manager
          .upon_receiving("a create asset request")
          .with(
            method: :post,
            path: "/assets",
            body: a_multipart_request_body,
            headers: AssetManagerPactHelper::MULTIPART_HEADERS,
          )
          .will_respond_with(
            status: 201,
            body: created_asset_body(id: an_asset_id_string, file_url: a_file_url_string),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.create_asset(file: file_fixture)
      end
    end

    describe "#asset" do
      it "returns an asset when it exists" do
        asset_manager
          .given("an asset exists with identifier #{content_id}")
          .upon_receiving("a get asset request")
          .with(
            method: :get,
            path: "/assets/#{content_id}",
          )
          .will_respond_with(
            status: 200,
            body: existing_asset_response_body,
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.asset(content_id)
      end

      it "returns a 404 when it does not exist" do
        asset_manager
          .upon_receiving("a get asset request")
          .with(
            method: :get,
            path: "/assets/#{content_id}",
          )
          .will_respond_with(
            status: 404,
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        assert_raises(GdsApi::HTTPNotFound) do
          api_client.asset(content_id)
        end
      end
    end

    describe "#update_asset" do
      it "updates an asset" do
        asset_manager
          .given("an asset exists with identifier #{content_id}")
          .upon_receiving("an update asset request")
          .with(
            method: :put,
            path: "/assets/#{content_id}",
            body: a_multipart_request_body,
            headers: AssetManagerPactHelper::MULTIPART_HEADERS,
          )
          .will_respond_with(
            status: 200,
            body: created_asset_body(
              id: "http://example.org/assets/#{content_id}",
              file_url: "http://static.dev.gov.uk/media/#{content_id}/#{filename}",
            ),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.update_asset(content_id, file: file_fixture)
      end

      it "returns not found when attempting to update a soft deleted asset" do
        asset_manager
          .given("a soft deleted asset exists with identifier #{content_id}")
          .upon_receiving("an update asset request")
          .with(
            method: :put,
            path: "/assets/#{content_id}",
            body: a_multipart_request_body,
            headers: AssetManagerPactHelper::MULTIPART_HEADERS,
          )
          .will_respond_with(
            status: 404,
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        assert_raises(GdsApi::HTTPNotFound) do
          api_client.update_asset(content_id, file: file_fixture)
        end
      end
    end

    describe "#delete_asset" do
      it "deletes an asset" do
        asset_manager
          .given("an asset exists with identifier #{content_id}")
          .upon_receiving("a delete asset request")
          .with(
            method: :delete,
            path: "/assets/#{content_id}",
          )
          .will_respond_with(
            status: 200,
            body: existing_asset_response_body.merge({ "deleted" => true }),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.delete_asset(content_id)
      end
    end

    describe "#restore_asset" do
      it "restores a soft deleted asset" do
        asset_manager
          .given("a soft deleted asset exists with identifier #{content_id}")
          .upon_receiving("a restore asset request")
          .with(
            method: :post,
            path: "/assets/#{content_id}/restore",
          )
          .will_respond_with(
            status: 200,
            body: existing_asset_response_body.merge({ "state" => "unscanned" }),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.restore_asset(content_id)
      end
    end
  end

  describe "Whitehall assets" do
    let(:legacy_url_path) { "/government/uploads/some-edition/#{filename}" }
    let(:url_for_asset) { "http://static.dev.gov.uk#{legacy_url_path}" }
    let(:existing_asset_response_body) { existing_asset_body(file_url: url_for_asset) }

    describe "#create whitehall asset" do
      it "creates a whitehall asset" do
        asset_manager
          .upon_receiving("a create whitehall asset request")
          .with(
            method: :post,
            path: "/whitehall_assets",
            body: a_whitehall_multipart_request_body,
            headers: AssetManagerPactHelper::MULTIPART_HEADERS,
          ).will_respond_with(
            status: 201,
            body: created_asset_body(
              id: an_asset_id_string,
              file_url: url_for_asset,
            ),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.create_whitehall_asset(file: file_fixture, legacy_url_path: legacy_url_path)
      end
    end

    describe "#get whitehall asset" do
      it "gets a whitehall asset" do
        asset_manager
          .given("a whitehall asset exists with legacy url path #{legacy_url_path} and id #{content_id}")
          .upon_receiving("a get whitehall asset request")
          .with(
            method: :get,
            path: "/whitehall_assets/#{legacy_url_path}",
          ).will_respond_with(
            status: 200,
            body: existing_asset_response_body,
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.whitehall_asset(legacy_url_path)
      end
    end

    describe "#update_asset" do
      it "updates a whitehall asset" do
        asset_manager
          .given("a whitehall asset exists with legacy url path #{legacy_url_path} and id #{content_id}")
          .upon_receiving("an update asset request")
          .with(
            method: :put,
            path: "/assets/#{content_id}",
            body: a_multipart_request_body,
            headers: AssetManagerPactHelper::MULTIPART_HEADERS,
          )
          .will_respond_with(
            status: 200,
            body: created_asset_body(
              id: "http://example.org/assets/#{content_id}",
              file_url: "http://static.dev.gov.uk#{legacy_url_path}",
            ),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.update_asset(content_id, file: file_fixture)
      end
    end

    describe "#delete_asset" do
      it "deletes a whitehall asset" do
        asset_manager
          .given("a whitehall asset exists with legacy url path #{legacy_url_path} and id #{content_id}")
          .upon_receiving("a delete asset request")
          .with(
            method: :delete,
            path: "/assets/#{content_id}",
          )
          .will_respond_with(
            status: 200,
            body: existing_asset_response_body.merge({ "deleted" => true }),
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.delete_asset(content_id)
      end
    end

    describe "#restore_asset" do
      it "restores a soft deleted whitehall asset" do
        asset_manager
          .given("a soft deleted whitehall asset exists with legacy url path #{legacy_url_path} and id #{content_id}")
          .upon_receiving("a restore asset request")
          .with(
            method: :post,
            path: "/assets/#{content_id}/restore",
          )
          .will_respond_with(
            status: 200,
            body: existing_asset_response_body,
            headers: AssetManagerPactHelper::JSON_CONTENT_TYPE,
          )

        api_client.restore_asset(content_id)
      end
    end
  end

private

  def existing_asset_body(file_url:)
    {
      "id" => "http://example.org/assets/4dca570c2975bc0d6d437491",
      "name" => "asset.png",
      "content_type" => "image/png",
      "size" => 57_705,
      "state" => "uploaded",
      "file_url" => file_url,
      "draft" => false,
      "deleted" => false,
    }
  end

  def created_asset_body(id:, file_url:)
    {
      "id" => id,
      "file_url" => file_url,
      "name" => "hello.txt",
      "content_type" => "text/plain; charset=utf-8",
      "size" => 14,
      "state" => "unscanned",
      "draft" => false,
      "deleted" => false,
    }
  end
end
