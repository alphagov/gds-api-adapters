require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_content pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "responds with 200 and the content item when the content item exists" do
    publishing_api
      .given("a content item exists with content_id: #{content_id}")
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
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_content(content_id)
  end

  it "responds with 200 and the content item when a content item exists in multiple locales" do
    publishing_api
      .given("a content item exists in multiple locales with content_id: #{content_id}")
      .upon_receiving("a request to return the content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
        query: "locale=fr",
      )
      .will_respond_with(
        status: 200,
        body: {
          "content_id" => content_id,
          "document_type" => Pact.like("special_route"),
          "schema_name" => Pact.like("special_route"),
          "publishing_app" => Pact.like("publisher"),
          "rendering_app" => Pact.like("frontend"),
          "locale" => "fr",
          "routes" => Pact.like([{}]),
          "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
          "details" => Pact.like({}),
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_content(content_id, locale: "fr")
  end

  it "responds with 200 and the superseded content item when requesting the superseded version, when a content item exists in with a superseded version" do
    publishing_api
      .given("a content item exists in with a superseded version with content_id: #{content_id}")
      .upon_receiving("a request to return the superseded content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
        query: "version=1",
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
          "publication_state" => "superseded",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_content(content_id, version: 1)
  end

  it "responds with 200 and the draft content item containing a warning, when a content item cannot be published because of a path conflict" do
    publishing_api
      .given("a draft content item exists with content_id #{content_id} with a blocking live item at the same path")
      .upon_receiving("a request to return the draft content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
      )
      .will_respond_with(
        status: 200,
        body: {
          "warnings" => Pact.like("content_item_blocking_publish" => "message"),
          "content_id" => content_id,
          "document_type" => Pact.like("special_route"),
          "schema_name" => Pact.like("special_route"),
          "publishing_app" => Pact.like("publisher"),
          "rendering_app" => Pact.like("frontend"),
          "locale" => Pact.like("en"),
          "routes" => Pact.like([{}]),
          "details" => Pact.like({}),
          "publication_state" => "draft",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_content(content_id, version: 2)
  end

  it "responds with 200 and the published content item when requesting the published version" do
    publishing_api
      .given("a content item exists in with a superseded version with content_id: #{content_id}")
      .upon_receiving("a request to return the published content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
        query: "version=2",
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
          "publication_state" => "published",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_content(content_id, version: 2)
  end

  it "responds with 200 and the published content item when requesting no specific version" do
    publishing_api
      .given("a content item exists in with a superseded version with content_id: #{content_id}")
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
          "publication_state" => "published",
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.get_content(content_id)
  end

  it "responds with 404 when requesting a non-existent item" do
    publishing_api
      .given("no content exists")
      .upon_receiving("a request for a non-existent content item")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}",
      )
      .will_respond_with(
        status: 404,
        body: {
          "error" => {
            "code" => 404,
            "message" => Pact.term(generate: "not found", matcher: /\S+/),
          },
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.get_content(content_id)
    end
  end
end
