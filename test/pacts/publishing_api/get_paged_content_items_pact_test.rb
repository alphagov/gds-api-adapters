require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_paged_content_items pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  it "returns two content items" do
    publishing_api
      .given("there are four content items with document_type 'taxon'")
      .upon_receiving("get the first page request")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=taxon&fields%5B%5D=title&fields%5B%5D=base_path&page=1&per_page=2",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 4,
          pages: 2,
          current_page: 1,
          links: [{ href: "http://example.org/v2/content?document_type=taxon&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=2",
                    rel: "next" },
                  { href: "http://example.org/v2/content?document_type=taxon&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=1",
                    rel: "self" }],
          results: [
            { title: "title_1", base_path: "/path_1" },
            { title: "title_2", base_path: "/path_2" },
          ],
        },
      )
    publishing_api
      .given("there are four content items with document_type 'taxon'")
      .upon_receiving("get the second page request")
      .with(
        method: :get,
        path: "/v2/content",
        query: "document_type=taxon&fields%5B%5D=title&fields%5B%5D=base_path&page=2&per_page=2",
      )
      .will_respond_with(
        status: 200,
        body: {
          total: 4,
          pages: 2,
          current_page: 2,
          links: [{ href: "http://example.org/v2/content?document_type=taxon&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=1",
                    rel: "previous" },
                  { href: "http://example.org/v2/content?document_type=taxon&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=2",
                    rel: "self" }],
          results: [
            { title: "title_3", base_path: "/path_3" },
            { title: "title_4", base_path: "/path_4" },
          ],
        },
      )
    assert_equal(
      api_client.get_content_items_enum(document_type: "taxon", fields: %i[title base_path], per_page: 2).to_a,
      [
        { "title" => "title_1", "base_path" => "/path_1" },
        { "title" => "title_2", "base_path" => "/path_2" },
        { "title" => "title_3", "base_path" => "/path_3" },
        { "title" => "title_4", "base_path" => "/path_4" },
      ],
    )
  end
end
