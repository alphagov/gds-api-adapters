require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#put_content pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "responds with 200 OK if the entry is valid" do
    content_item = content_item_for_content_id(content_id)

    publishing_api
      .given("no content exists")
      .upon_receiving("a request to create a content item without links")
      .with(
        method: :put,
        path: "/v2/content/#{content_id}",
        body: content_item,
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.put_content(content_id, content_item)
  end

  it "responds with 422 Unprocessable Entity if the path is reserved by a different app" do
    content_item = content_item_for_content_id(content_id, "base_path" => "/test-item", "publishing_app" => "whitehall")

    publishing_api
      .given("/test-item has been reserved by the Publisher application")
      .upon_receiving("a request from the Whitehall application to create a content item at /test-item")
      .with(
        method: :put,
        path: "/v2/content/#{content_id}",
        body: content_item,
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 422,
        error_code: Pact.like("base_path_already_in_use"),
        body: {
          "error" => {
            "code" => 422,
            "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
            "fields" => {
              "base_path" => Pact.each_like(
                {
                  "error" => Pact.term(generate: "/test-item is already reserved by publisher", matcher: /\S+/),
                  "code" => Pact.like("base_path_already_in_use"),
                },
                min: 1,
              ),
            },
          },
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    assert_raises(GdsApi::HTTPUnprocessableEntity) do
      api_client.put_content(content_id, content_item)
    end
  end

  it "responds with 422 Unprocessable Entity when given an invalid item" do
    content_item = content_item_for_content_id(content_id, "base_path" => "not a url path")

    publishing_api
      .given("no content exists")
      .upon_receiving("a request to create an invalid content-item")
      .with(
        method: :put,
        path: "/v2/content/#{content_id}",
        body: content_item,
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 422,
        body: [
          {
            schema: Pact.like({}),
            fragment: "#/base_path",
            message: Pact.like("The property '#/base_path' of type string did not match all of the required schemas in schema 91ab1054-cf15-5464-b83d-bf8f19abe4b0#"),
            failed_attribute: "AllOf",
          },
        ],
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    assert_raises(GdsApi::HTTPUnprocessableEntity) do
      api_client.put_content(content_id, content_item)
    end
  end

  describe "optimistic locking" do
    it "responds with 200 OK if the content item has not changed since it was requested" do
      content_item = content_item_for_content_id(
        content_id,
        "document_type" => "manual",
        "schema_name" => "manual",
        "locale" => "en",
        "details" => { "body" => [] },
        "previous_version" => "3",
      )

      publishing_api
        .given("the content item #{content_id} is at version 3")
        .upon_receiving("a request to update the content item at version 3")
        .with(
          method: :put,
          path: "/v2/content/#{content_id}",
          body: content_item,
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
        )

      api_client.put_content(content_id, content_item)
    end

    it "responds with 409 Conflict if the content item has changed in the meantime" do
      content_item = content_item_for_content_id(
        content_id,
        "document_type" => "manual",
        "schema_name" => "manual",
        "locale" => "en",
        "details" => { "body" => [] },
        "previous_version" => "2",
      )

      publishing_api
        .given("the content item #{content_id} is at version 3")
        .upon_receiving("a request to update the content item at version 2")
        .with(
          method: :put,
          path: "/v2/content/#{content_id}",
          body: content_item,
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 409,
          body: {
            "error" => {
              "code" => 409,
              "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
              "fields" => {
                "previous_version" => Pact.each_like("does not match", min: 1),
              },
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      assert_raises(GdsApi::HTTPConflict) do
        api_client.put_content(content_id, content_item)
      end
    end
  end

private

  def content_item_for_content_id(content_id, attrs = {})
    {
      "base_path" => "/robots.txt",
      "content_id" => content_id,
      "title" => "Instructions for crawler robots",
      "description" => "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
      "schema_name" => "special_route",
      "document_type" => "special_route",
      "public_updated_at" => "2015-07-30T13:58:11.000Z",
      "publishing_app" => "static",
      "rendering_app" => "static",
      "locale" => "en",
      "routes" => [
        {
          "path" => attrs["base_path"] || "/robots.txt",
          "type" => "exact",
        },
      ],
      "update_type" => "major",
      "details" => {},
    }.merge(attrs)
  end
end
