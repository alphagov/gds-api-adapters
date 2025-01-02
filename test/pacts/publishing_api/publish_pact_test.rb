require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#publish pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "responds with 200 if the publish command succeeds" do
    publishing_api
      .given("a draft content item exists with content_id: #{content_id}")
      .upon_receiving("a publish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/publish",
        body: {
          update_type: "major",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.publish(content_id, "major")
  end

  it "responds with 404 if the content item does not exist" do
    publishing_api
      .given("no content exists")
      .upon_receiving("a publish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/publish",
        body: {
          update_type: "major",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 404,
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.publish(content_id, "major")
    end
  end

  it "responds with 422 if the update information is invalid" do
    publishing_api
      .given("a draft content item exists with content_id: #{content_id}")
      .upon_receiving("an invalid publish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/publish",
        body: {
          "update_type" => "",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 422,
        body: {
          "error" => {
            "code" => 422,
            "message" => Pact.term(generate: "Unprocessable entity", matcher: /\S+/),
            "fields" => {
              "update_type" => Pact.each_like("is required", min: 1),
            },
          },
        },
      )

    assert_raises(GdsApi::HTTPUnprocessableEntity) do
      api_client.publish(content_id, "")
    end
  end

  it "responds with 200 if the content item is already published" do
    publishing_api
      .given("a published content item exists with content_id: #{content_id}")
      .upon_receiving("a publish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/publish",
        body: {
          update_type: "major",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.publish(content_id, "major")
  end

  it "responds with 200 if the update information contains a locale" do
    publishing_api
      .given("a draft content item exists with content_id: #{content_id} and locale: fr")
      .upon_receiving("a publish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/publish",
        body: {
          update_type: "major",
          locale: "fr",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.publish(content_id, "major", locale: "fr")
  end

  describe "optimistic locking" do
    it "responds with 200 OK if the content item has not changed since it was requested" do
      publishing_api
        .given("the content item #{content_id} is at version 3")
        .upon_receiving("a publish request for version 3")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            update_type: "minor",
            previous_version: 3,
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
        )

      api_client.publish(content_id, "minor", previous_version: 3)
    end

    it "responds with 409 Conflict if the content item has changed in the meantime" do
      publishing_api
        .given("the content item #{content_id} is at version 3")
        .upon_receiving("a publish request for version 2")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            update_type: "minor",
            previous_version: 2,
          },
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
        api_client.publish(content_id, "minor", previous_version: 2)
      end
    end
  end
end
