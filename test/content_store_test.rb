require 'test_helper'
require 'gds_api/content_store'
require 'gds_api/test_helpers/content_store'

describe GdsApi::ContentStore do
  include GdsApi::TestHelpers::ContentStore

  before do
    @base_api_url = Plek.current.find("content-store")
    @api = GdsApi::ContentStore.new(@base_api_url)
  end

  describe "content_item" do
    it "should return the item" do
      base_path = "/test-from-content-store"
      content_store_has_item(base_path)
      response = @api.content_item(base_path)
      assert_equal base_path, response["base_path"]
    end

    it "should return nil if the item doesn't exist" do
      content_store_does_not_have_item("/non-existent")
      assert_nil @api.content_item("/non-existent")
    end
  end

  describe "content_item!" do
    it "should return the item" do
      base_path = "/test-from-content-store"
      content_store_has_item(base_path)
      response = @api.content_item!(base_path)
      assert_equal base_path, response["base_path"]
    end

    it "should raise if the item doesn't exist" do
      content_store_does_not_have_item("/non-existent")
      e = assert_raises GdsApi::ContentStore::ItemNotFound do
        @api.content_item!("/non-existent")
      end
      assert_equal 404, e.code
      assert_equal "url: #{@base_api_url}/content/non-existent", e.message.strip
    end
  end
end
