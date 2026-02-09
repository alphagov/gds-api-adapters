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
    it "returns two pages of results - the last page is not full" do
      search_api
        .given("there are four search results for universal credit")
        .upon_receiving("get the first page request for up to 3 documents")
        .with(
          method: :get,
          query: "start=0&count=3",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              search_result_1,
              search_result_2,
              search_result_3,
            ],
            total: 4,
            start: 0,
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      search_api
        .given("there are four search results for universal credit")
        .upon_receiving("get the second page request for up to 3 documents")
        .with(
          method: :get,
          query: "start=3&count=3",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              search_result_4,
            ],
            total: 4,
            start: 3,
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      assert_equal(
        api_client.search_enum({}, page_size: 3).to_a,
        [
          search_result_1,
          search_result_2,
          search_result_3,
          search_result_4,
        ],
      )
    end

    it "returns two pages of results - the last page is full" do
      search_api
        .given("there are four search results for universal credit")
        .upon_receiving("get the first page request for up to 2 documents")
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
              search_result_1,
              search_result_2,
            ],
            total: 4,
            start: 0,
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      search_api
        .given("there are four search results for universal credit")
        .upon_receiving("get the second page request for up to 2 documents")
        .with(
          method: :get,
          query: "start=2&count=2",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              search_result_3,
              search_result_4,
            ],
            total: 4,
            start: 2,
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      search_api
        .given("there are four search results for universal credit")
        .upon_receiving("get the third page request for up to 2 documents")
        .with(
          method: :get,
          query: "start=4&count=2",
          path: "/search.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [],
            total: 4,
            start: 4,
            aggregates: Pact.like({}),
            suggested_queries: Pact.like([]),
            suggested_autocomplete: Pact.like([]),
            es_cluster: Pact.like("A"),
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      assert_equal(
        api_client.search_enum({}, page_size: 2).to_a,
        [
          search_result_1,
          search_result_2,
          search_result_3,
          search_result_4,
        ],
      )
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

  def search_result_1
    {
      "link" => "/universal-credit-1",
      "title" => "Universal credit 1",
      "index" => "government_test",
      "_id" => "/universal-credit-1",
      "elasticsearch_type" => "edition",
      "document_type" => "edition",
    }
  end

  def search_result_2
    {
      "link" => "/universal-credit-2",
      "title" => "Universal credit 2",
      "index" => "government_test",
      "_id" => "/universal-credit-2",
      "elasticsearch_type" => "edition",
      "document_type" => "edition",
    }
  end

  def search_result_3
    {
      "link" => "/universal-credit-3",
      "title" => "Universal credit 3",
      "index" => "government_test",
      "_id" => "/universal-credit-3",
      "elasticsearch_type" => "edition",
      "document_type" => "edition",
    }
  end

  def search_result_4
    {
      "link" => "/universal-credit-4",
      "title" => "Universal credit 4",
      "index" => "government_test",
      "_id" => "/universal-credit-4",
      "elasticsearch_type" => "edition",
      "document_type" => "edition",
    }
  end
end
