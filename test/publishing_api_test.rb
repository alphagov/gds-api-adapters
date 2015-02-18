require 'test_helper'
require 'gds_api/publishing_api'
require 'gds_api/test_helpers/publishing_api'

describe GdsApi::PublishingApi do
  include GdsApi::TestHelpers::PublishingApi

  before do
    @base_api_url = Plek.current.find("publishing-api")
    @api = GdsApi::PublishingApi.new(@base_api_url)
  end

  describe "item" do
    it "should create the item" do
      base_path = "/test-to-publishing-api"
      stub_publishing_api_put_item(base_path)
      response = @api.put_content_item(base_path, content_item_for_base_path_in_a_publish_request(base_path))
      assert_equal base_path, response["base_path"]
    end
  end

  describe "intent" do
    it "should create the intent" do
      base_path = "/test-intent"
      stub_publishing_api_put_intent(base_path)
      response = @api.put_intent(base_path, intent_for_base_path(base_path))
      assert_equal base_path, response["base_path"]
    end

    it "should delete an intent" do
      base_path = "/test-intent"
      stub_publishing_api_destroy_intent(base_path)
      response = @api.destroy_intent(base_path)
      assert_equal base_path, response["base_path"]
    end
  end
end
