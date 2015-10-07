require 'test_helper'
require 'gds_api/publishing_api_v2'
require 'json'

describe GdsApi::PublishingApiV2 do
  include PactTest

  def content_item_for_content_id(content_id, attrs = {})
    robots_json = GovukContentSchemaTestHelpers::Examples.new.get('special_route', 'robots.txt')
    robots = JSON.parse(robots_json)
    robots = robots.merge(attrs.merge("content_id" => content_id))

    unless attrs.has_key?("routes")
      robots["routes"] = [
        { "path" => robots["base_path"], "type" => "exact" },
      ]
    end
    robots
  end

  before do
    @base_api_url = Plek.current.find("publishing-api")
    @api_client = GdsApi::PublishingApiV2.new('http://localhost:3093')

    @content_id = "bed722e6-db68-43e5-9079-063f623335a7"
  end

  describe "#put_content" do
    it "responds with 200 OK if the entry is valid" do
      content_item = content_item_for_content_id(@content_id)

      publishing_api
        .given("both content stores and the url-arbiter are empty")
        .upon_receiving("a request to create a content item without links")
        .with(
          method: :put,
          path: "/v2/content/#{@content_id}",
          body: content_item,
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
        )

      response = @api_client.put_content(@content_id, content_item)
      assert_equal 200, response.code
    end

    it "responds with 409 Conflict if the path is reserved by a different app" do
      content_item = content_item_for_content_id(@content_id, "base_path" => "/test-item", "publishing_app" => "whitehall")

      publishing_api
        .given("/test-item has been reserved in url-arbiter by the Publisher application")
        .upon_receiving("a request from the Whitehall application to create a content item at /test-item")
        .with(
          method: :put,
          path: "/v2/content/#{@content_id}",
          body: content_item,
          headers: {
            "Content-Type" => "application/json",
          }
        )
        .will_respond_with(
          status: 409,
          body: {
            "error" => {
              "code" => 409,
              "message" => Pact.term(generate: "Conflict", matcher:/\S+/),
              "fields" => {
                "base_path" => Pact.each_like("is already in use by the 'publisher' app", :min => 1),
              },
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          }
        )

      error = assert_raises GdsApi::HTTPConflict do
        @api_client.put_content(@content_id, content_item)
      end
      assert_equal "Conflict", error.error_details["error"]["message"]
    end

    it "responds with 422 Unprocessable Entity with an invalid item" do
      content_item = content_item_for_content_id(@content_id, "base_path" => "not a url path")

      publishing_api
        .given("both content stores and the url-arbiter are empty")
        .upon_receiving("a request to create an invalid content-item")
        .with(
          method: :put,
          path: "/v2/content/#{@content_id}",
          body: content_item,
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 422,
          body: {
            "error" => {
              "code" => 422,
              "message" => Pact.term(generate: "Unprocessable entity", matcher:/\S+/),
              "fields" => {
                "base_path" => Pact.each_like("is invalid", :min => 1),
              },
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          }
        )

      error = assert_raises GdsApi::HTTPClientError do
        @api_client.put_content(@content_id, content_item)
      end
      assert_equal 422, error.code
      assert_equal "Unprocessable entity", error.error_details["error"]["message"]
    end
  end

  describe "#get_content" do
    it "responds with 200 and the content item when it exists" do
      content_item = content_item_for_content_id(@content_id)
      publishing_api
        .given("a content item exists with content_id: #{@content_id}")
        .upon_receiving("a request to return the content item")
        .with(
          method: :get,
          path: "/v2/content/#{@content_id}",
        )
        .will_respond_with(
          status: 200,
          body: content_item,
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      response = @api_client.get_content(@content_id)
      assert_equal 200, response.code
      assert_equal content_item["format"], response["format"]
    end

    it "responds with 404 for a non-existent item" do
      publishing_api
        .given("both content stores and the url-arbiter are empty")
        .upon_receiving("a request for a non-existent content item")
        .with(
          method: :get,
          path: "/v2/content/#{@content_id}",
        )
        .will_respond_with(
          status: 404,
          body: {
            "error" => {
              "code" => 404,
              "message" => Pact.term(generate: "not found", matcher:/\S+/)
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      assert_nil @api_client.get_content(@content_id)
    end
  end
end
