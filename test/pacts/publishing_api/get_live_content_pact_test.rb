require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_live_content pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "returns the published content item when the latest version of the content item is published" do
    publishing_api
      .given("a published content item exists with content_id: #{content_id}")
      .upon_receiving("a request to return the live content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
      )
      .will_respond_with(
        status: 200,
        body: {
          "content_id" => content_id,
          "document_type" => Pact.like("special_route"),
          "schema_name" => Pact.like("special_route"),
          "publishing_app" => Pact.like("publisher"),
          "rendering_app" => Pact.like("frontend"),
          "locale" => Pact.like("en"),
          "routes" => Pact.like([{}]),
          "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
          "details" => Pact.like({}),
          "state_history" => { "1" => "published" },
          "publication_state" => "published",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_live_content(content_id)
  end

  it "returns the live content item when there is a draft version of live content" do
    publishing_api
      .given("a published content item exists with a draft edition for content_id: #{content_id}")
      .upon_receiving("a request to return the live content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
        query: "locale=en&content_store=live",
      )
      .will_respond_with(
        status: 200,
        body: {
          "content_id" => content_id,
          "document_type" => Pact.like("special_route"),
          "schema_name" => Pact.like("special_route"),
          "publishing_app" => Pact.like("publisher"),
          "rendering_app" => Pact.like("frontend"),
          "locale" => Pact.like("en"),
          "routes" => Pact.like([{}]),
          "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
          "details" => Pact.like({}),
          "state_history" => { "1" => "published", "2" => "draft" },
          "publication_state" => "published",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_live_content(content_id)
  end

  it "returns the unpublished content item when the latest version of the content item is unpublished" do
    publishing_api
      .given("an unpublished content item exists with content_id: #{content_id}")
      .upon_receiving("a request to return the content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
      )
      .will_respond_with(
        status: 200,
        body: {
          "content_id" => content_id,
          "document_type" => Pact.like("special_route"),
          "schema_name" => Pact.like("special_route"),
          "publishing_app" => Pact.like("publisher"),
          "rendering_app" => Pact.like("frontend"),
          "locale" => Pact.like("en"),
          "routes" => Pact.like([{}]),
          "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
          "details" => Pact.like({}),
          "state_history" => { "1" => "unpublished" },
          "publication_state" => "unpublished",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_live_content(content_id)
  end
end
