require 'test_helper'
require 'gds_api/content_store'
require 'gds_api/test_helpers/content_store'

describe GdsApi::ContentStore do
  include GdsApi::TestHelpers::ContentStore

  before do
    @base_api_url = Plek.current.find("content-store")
    @api = GdsApi::ContentStore.new(@base_api_url)
  end

  describe "#content_item" do
    it "returns the item" do
      base_path = "/test-from-content-store"
      content_store_has_item(base_path)

      response = @api.content_item(base_path)

      assert_equal base_path, response["base_path"]
    end

    it "returns nil if the item doesn't exist" do
      content_store_does_not_have_item("/non-existent")

      assert_nil @api.content_item("/non-existent")
    end
  end

  describe "#content_item!" do
    it "returns the item" do
      base_path = "/test-from-content-store"
      content_store_has_item(base_path)

      response = @api.content_item!(base_path)

      assert_equal base_path, response["base_path"]
    end

    it "raises if the item doesn't exist" do
      content_store_does_not_have_item("/non-existent")

      e = assert_raises GdsApi::ContentStore::ItemNotFound do
        @api.content_item!("/non-existent")
      end

      assert_equal 404, e.code
      assert_equal "URL: #{@base_api_url}/content/non-existent\nResponse body:\n\n\nRequest body:", e.message.strip
    end
  end

  describe "#incoming_links!" do
    it "returns the item" do
      base_path = "/test-from-content-store"
      content_store_has_incoming_links(base_path, [ { title: "Yolo" }])

      response = @api.incoming_links!(base_path)

      assert_equal [ { "title" => "Yolo" } ], response.to_hash
    end

    it "raises if the item doesn't exist" do
      content_store_does_not_have_item("/non-existent")

      e = assert_raises GdsApi::ContentStore::ItemNotFound do
        response = @api.incoming_links!("/non-existent")
      end

      assert_equal 404, e.code
    end
  end
end
