require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#unpublish pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "responds with 200 if the unpublish command succeeds" do
    publishing_api
      .given("a published content item exists with content_id: #{content_id}")
      .upon_receiving("an unpublish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/unpublish",
        body: {
          type: "gone",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.unpublish(content_id, type: "gone")
  end

  it "responds with 404 if the content item does not exist" do
    publishing_api
      .given("no content exists")
      .upon_receiving("an unpublish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/unpublish",
        body: {
          type: "gone",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 404,
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.unpublish(content_id, type: "gone")
    end
  end

  it "responds with 422 if the type is incorrect" do
    publishing_api
      .given("a published content item exists with content_id: #{content_id}")
      .upon_receiving("an invalid unpublish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/unpublish",
        body: {
          type: "not-a-valid-type",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 422,
        body: {
          "error" => {
            "code" => 422,
            "message" => Pact.term(generate: "not-a-valid-type is not a valid unpublishing type", matcher: /\S+/),
            "fields" => {},
          },
        },
      )

    assert_raises(GdsApi::HTTPUnprocessableEntity) do
      api_client.unpublish(content_id, type: "not-a-valid-type")
    end
  end

  it "responds with 200 and updates the unpublishing if the content item is already unpublished" do
    publishing_api
      .given("an unpublished content item exists with content_id: #{content_id}")
      .upon_receiving("an unpublish request")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/unpublish",
        body: {
          type: "gone",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.unpublish(content_id, type: "gone")
  end

  describe "optimistic locking" do
    it "responds with 200 OK if the content item has not changed since it was requested" do
      publishing_api
        .given("the published content item #{content_id} is at version 3")
        .upon_receiving("an unpublish request for version 3")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/unpublish",
          body: {
            type: "gone",
            previous_version: 3,
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
        )

      api_client.unpublish(content_id, type: "gone", previous_version: 3)
    end

    it "responds with 409 Conflict if the content item has changed in the meantime" do
      publishing_api
        .given("the published content item #{content_id} is at version 3")
        .upon_receiving("an unpublish request for version 2")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/unpublish",
          body: {
            type: "gone",
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
        api_client.unpublish(content_id, type: "gone", previous_version: 2)
      end
    end
  end
end
