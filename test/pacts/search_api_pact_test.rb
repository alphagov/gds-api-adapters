require "test_helper"
require "gds_api/search"

describe "GdsApi::Search pact tests" do
  include PactTest

  let(:api_client) { GdsApi::Search.new(search_api_host) }

  describe "#search" do
    it "fetches a search response when search term is included" do
      search_api
        .given("there are search results for universal credit")
        .upon_receiving("a valid query for universal credit")
        .with(
          method: :get,
          query: "q=universal+credit",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              search_result,
              search_result,
            ],
            total: Pact.like(2),
            start: Pact.like(0),
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      api_client.search(q: "universal credit")
    end

    it "fetches a search response when no search term is included" do
      search_api
        .given("there are search results for universal credit")
        .upon_receiving("a valid query with no keyword")
        .with(
          method: :get,
          query: "count=2",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              search_result,
              search_result,
            ],
            total: Pact.like(2),
            start: Pact.like(0),
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      api_client.search(count: 2)
    end

    it "responds with 422 when ordering field is invalid" do
      search_api
        .given("there are search results for universal credit")
        .upon_receiving("a request to order results by invalid-order-field")
        .with(
          method: :get,
          query: "q=universal+credit&order=invalid-order-field",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 422,
          body: { "error" => "\"invalid-order-field\" is not a valid sort field" },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      assert_raises(GdsApi::HTTPUnprocessableEntity) do
        api_client.search(q: "universal credit", order: "invalid-order-field")
      end
    end
  end

  describe "#search_enum" do
    it "fetches a search response when no search term is included" do
      search_api
        .given("there are search results for universal credit")
        .upon_receiving("a request for the first batch of results")
        .with(
          method: :get,
          query: "start=0&count=2",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              search_result,
              search_result,
            ],
            total: Pact.like(2),
            start: Pact.like(0),
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
        )

      search_api
        .given("there are search results for universal credit")
        .upon_receiving("a request for the first batch of results")
        .with(
          method: :get,
          query: "start=2&count=2",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [],
            total: Pact.like(2),
            start: Pact.like(2),
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
        )

      api_client.search_enum({}, page_size: 2).to_a
    end
  end

private

  def search_result
    {
      "link" => Pact.like("/universal-credit"),
      "title" => Pact.like("Universal credit"),
      "index" => Pact.like("government_test"),
      "_id" => Pact.like("/universal-credit"),
      "elasticsearch_type" => Pact.like("edition"),
      "document_type" => Pact.like("edition"),
    }
  end
end
