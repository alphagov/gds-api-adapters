require 'test_helper'
require 'gds_api/publishing_api'
require 'gds_api/test_helpers/publishing_api'

describe GdsApi::PublishingApi do
  include GdsApi::TestHelpers::PublishingApi
  include PactTest

  before do
    @base_api_url = Plek.current.find("publishing-api")
    @api_client = GdsApi::PublishingApi.new('http://localhost:3093')
  end

  describe "#put_content_item" do
    it "responds with 200 OK if the entry is valid" do
      base_path = "/test-content-item"
      content_item = content_item_for_publishing_api(base_path).merge("update_type" => "major")

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to create a content item")
        .with(
          method: :put,
          path: "/content#{base_path}",
          body: content_item,
          headers: {
            "Content-Type" => "application/json"
          },
        )
        .will_respond_with(
          status: 200,
          body: content_item,
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          },
        )

      response = @api_client.put_content_item(base_path, content_item)
      assert_equal 200, response.code
    end
  end

  describe "#put_draft_content_item" do
    it "responds with 200 OK if the entry is valid" do
      base_path = "/test-draft-content-item"
      content_item = content_item_for_publishing_api(base_path).merge("update_type" => "major")

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to create a draft content item")
        .with(
          method: :put,
          path: "/draft-content#{base_path}",
          body: content_item,
          headers: {
            "Content-Type" => "application/json"
          },
        )
        .will_respond_with(
          status: 200,
          body: content_item,
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          },
        )

      response = @api_client.put_draft_content_item(base_path, content_item)
      assert_equal 200, response.code
    end
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

      publish_intent = intent_for_publishing_api(base_path)

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

      publish_intent = intent_for_publishing_api(base_path)

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

  describe "#put_path" do
    it "returns 200 if the path was successfully reserved" do
      base_path = "/test-intent"
      payload = {
        publishing_app: "publisher"
      }

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to put a path")
        .with(
          method: :put,
          path: "/paths#{base_path}",
          body: payload,
          headers: {
            "Content-Type" => "application/json"
          },
        )
        .will_respond_with(
          status: 200,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          }
        )

      response = @api_client.put_path(base_path, payload)
      assert_equal 200, response.code
    end

    it "returns 422 if the request is invalid" do
      base_path = "/test-item"
      payload = {
        publishing_app: "whitehall"
      }

      publishing_api
        .given("/test-item has been reserved by the Publisher application")
        .upon_receiving("a request to change publishing app")
        .with(
          method: :put,
          path: "/paths#{base_path}",
          body: payload,
          headers: {
            "Content-Type" => "application/json"
          },

        )
        .will_respond_with(
          status: 422,
          body: {
            "error" => {
              "code" => 422,
              "message" => Pact.term(generate: "Unprocessable", matcher:/\S+/),
              "fields" => {
                "base_path" => Pact.each_like("has been reserved", :min => 1),
              },
            },
          },
        )

      error = assert_raises GdsApi::HTTPClientError do
        @api_client.put_path(base_path, payload)
      end
      assert_equal "Unprocessable", error.error_details["error"]["message"]
    end
  end
end
