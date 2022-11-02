require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_content_items pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "returns the content items of a certain document_type" do
    publishing_api
      .given("there is content with document_type 'topic'")
      .upon_receiving("a get entries request")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 2,
          pages: 1,
          current_page: 1,
          links: [{
            href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&page=1",
            rel: "self",
          }],
          results: [
            { title: "Content Item A", base_path: "/a-base-path" },
            { title: "Content Item B", base_path: "/another-base-path" },
          ],
        },
      )

    api_client.get_content_items(
      document_type: "topic",
      fields: %i[title base_path],
    )
  end

  it "returns the content items in english locale by default" do
    publishing_api
      .given("a content item exists in multiple locales with content_id: #{content_id}")
      .upon_receiving("a get entries request")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 1,
          pages: 1,
          current_page: 1,
          links: [{
            href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&page=1",
            rel: "self",
          }],
          results: [
            { content_id: content_id, locale: "en" },
          ],
        },
      )

    api_client.get_content_items(
      document_type: "topic",
      fields: %i[content_id locale],
    )
  end

  it "returns the content items in a specific locale" do
    publishing_api
      .given("a content item exists in multiple locales with content_id: #{content_id}")
      .upon_receiving("a get entries request with a specific locale")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=fr",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 1,
          pages: 1,
          current_page: 1,
          links: [{
            href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=fr&page=1",
            rel: "self",
          }],
          results: [
            { content_id: content_id, locale: "fr" },
          ],
        },
      )

    api_client.get_content_items(
      document_type: "topic",
      fields: %i[content_id locale],
      locale: "fr",
    )
  end

  it "returns the content items in all the available locales" do
    publishing_api
      .given("a content item exists in multiple locales with content_id: #{content_id}")
      .upon_receiving("a get entries request with an 'all' locale")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=all",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 3,
          pages: 1,
          current_page: 1,
          links: [{
            href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=all&page=1",
            rel: "self",
          }],
          results: [
            { content_id: content_id, locale: "en" },
            { content_id: content_id, locale: "fr" },
            { content_id: content_id, locale: "ar" },
          ],
        },
      )

    api_client.get_content_items(
      document_type: "topic",
      fields: %i[content_id locale],
      locale: "all",
    )
  end

  it "returns details hashes" do
    publishing_api
      .given("a content item exists with content_id: #{content_id} and it has details")
      .upon_receiving("a get entries request with details field")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=details",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 1,
          pages: 1,
          current_page: 1,
          links: [{
            href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=details&page=1",
            rel: "self",
          }],
          results: [
            { content_id: content_id, details: { foo: :bar } },
          ],
        },
      )

    api_client.get_content_items(
      document_type: "topic",
      fields: %i[content_id details],
    )
  end

  it "returns the items matching a query" do
    publishing_api
      .given("there is content with document_type 'topic'")
      .upon_receiving("a get entries request with search_in and q parameters")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=topic&fields%5B%5D=content_id&q=an+internal+name&search_in%5B%5D=details.internal_name",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 1,
          pages: 1,
          current_page: 1,
          links: [{
            href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&q=an+internal+name&search_in%5B%5D=details.internal_name&page=1",
            rel: "self",
          }],
          results: [
            { content_id: "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa" },
          ],
        },
      )

    api_client.get_content_items(
      document_type: "topic",
      fields: [:content_id],
      q: "an internal name",
      search_in: ["details.internal_name"],
    )
  end
end
