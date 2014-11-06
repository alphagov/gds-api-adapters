require 'test_helper'
require 'gds_api/collections_api'
require 'gds_api/test_helpers/collections_api'

describe GdsApi::CollectionsApi do
  include GdsApi::TestHelpers::CollectionsApi

  before do
    @base_api_url = Plek.current.find("collections-api")
    @api = GdsApi::CollectionsApi.new(@base_api_url)
  end

  describe "topic" do
    it "should return the curated lists for a given base path" do
      base_path = "/test/base-path"
      collections_api_has_content_for(base_path)
      response = @api.topic(base_path)
      assert_equal base_path, response["base_path"]
    end
  end
end
