require 'test_helper'
require 'gds_api/content_store'
require 'gds_api/test_helpers/content_store'

describe GdsApi::ContentStore do
  include GdsApi::TestHelpers::ContentStore

  before do
    @base_api_url = Plek.current.find("content-store")
    @api = GdsApi::ContentStore.new(@base_api_url)
  end

  describe "item" do
    it "should return the item" do
      base_path = "/test-from-content-store"
      content_store_has_item(base_path)
      response = @api.content_item(base_path)
      assert_equal base_path, response["base_path"]
    end

    it "should create the item" do
      base_path = "/test-to-content-store"
      stub_content_store_put_item(base_path)
      response = @api.put_content_item(base_path, item_for_base_path(base_path))
      assert_equal base_path, response["base_path"]
    end
  end
end
