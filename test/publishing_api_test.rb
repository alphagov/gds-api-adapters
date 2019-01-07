require 'test_helper'
require 'gds_api/publishing_api'
require 'gds_api/test_helpers/publishing_api'

describe GdsApi::PublishingApi do
  include GdsApi::TestHelpers::PublishingApi
  include PactTest

  before do
    @base_api_url = Plek.current.find("publishing-api")
    @api_client = GdsApi::PublishingApi.new(publishing_api_host)
  end

  describe "#put_intent" do
    it "responds with 200 OK if publish intent is valid" do
      base_path = "/test-intent"
      publish_intent = intent_for_publishing_api(base_path)

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to create a publish intent")
        .with(
          method: :put,
          path: "/publish-intent#{base_path}",
          body: publish_intent,
          headers: {
            "Content-Type" => "application/json"
          },
        )
        .will_respond_with(
          status: 200,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          },
        )

      response = @api_client.put_intent(base_path, publish_intent)
      assert_equal 200, response.code
    end
  end

  describe "#delete_intent" do
    it "returns 200 OK if intent existed and was deleted" do
      base_path = "/test-intent"

      publishing_api
        .given("a publish intent exists at /test-intent")
        .upon_receiving("a request to delete a publish intent")
        .with(
          method: :delete,
          path: "/publish-intent#{base_path}",
        )
        .will_respond_with(
          status: 200,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          }
        )

      response = @api_client.destroy_intent(base_path)
      assert_equal 200, response.code
    end

    it "returns 404 Not found if the intent does not exist" do
      base_path = "/test-intent"

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to delete a publish intent")
        .with(
          method: :delete,
          path: "/publish-intent#{base_path}",
        )
        .will_respond_with(
          status: 404,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          }
        )

      response = @api_client.destroy_intent(base_path)
      assert_equal 404, response.code
    end
  end
end
