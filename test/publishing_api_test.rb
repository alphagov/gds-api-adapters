require "test_helper"
require "gds_api/publishing_api"
require "gds_api/test_helpers/publishing_api"

describe GdsApi::PublishingApi do
  include GdsApi::TestHelpers::PublishingApi

  let(:api_client) { GdsApi::PublishingApi.new(Plek.find("publishing-api")) }

  describe "content ID validation" do
    %i[get_content get_links get_linked_items discard_draft].each do |method|
      it "happens on #{method}" do
        assert_raises ArgumentError do
          api_client.send(method, nil)
        end
      end
    end

    it "happens on publish" do
      assert_raises ArgumentError do
        api_client.publish(nil, "major")
      end
    end

    it "happens on put_content" do
      assert_raises ArgumentError do
        api_client.put_content(nil, {})
      end
    end

    it "happens on patch_links" do
      assert_raises ArgumentError do
        api_client.patch_links(nil, links: {})
      end
    end
  end

  describe "#get_content_by_embedded_document" do
    it "sends a warning and calls #get_host_content_for_content_id" do
      content_id = SecureRandom.uuid
      args = { some: "args" }
      api_client.expects(:warn).with("GdsAPI::PublishingApi: #get_content_by_embedded_document deprecated (please use #get_host_content_for_content_id)")
      api_client.expects(:get_host_content_for_content_id).with(content_id, args)

      api_client.get_content_by_embedded_document(content_id, args)
    end
  end

  describe "#graphql_live_content_item" do
    it "indirectly returns the item" do
      base_path = "/test-from-content-store"
      stub_publishing_api_graphql_has_item(base_path)

      response = api_client.graphql_live_content_item_indirectly(base_path)

      assert_equal base_path, response["base_path"]
    end

    it "returns the item" do
      base_path = "/test-from-content-store"
      stub_publishing_api_graphql_has_item(base_path)

      response = api_client.graphql_live_content_item(base_path)

      assert_equal base_path, response["base_path"]
    end

    it "raises if the item doesn't exist" do
      stub_publishing_api_graphql_does_not_have_item("/non-existent")

      assert_raises(GdsApi::HTTPNotFound) do
        api_client.graphql_live_content_item("/non-existent")
      end
    end

    it "raises if the item is gone" do
      stub_publishing_api_graphql_has_gone_item("/it-is-gone")

      assert_raises(GdsApi::HTTPGone) do
        api_client.graphql_live_content_item("/it-is-gone")
      end
    end
  end
end
