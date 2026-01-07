require "test_helper"
require "gds_api/search"

describe "GdsApi::Search pact tests" do
  include PactTest

  let(:api_client) { GdsApi::Search.new(search_api_host) }

  describe "#search" do
    it "fetches a search response" do
      search_api
        .given("there are search results for universal credit")
        .upon_receiving("a query for universal credit")
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
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )

      api_client.search(q: "universal credit")
    end
  end

private

  def search_result
    {
      "link" => Pact.like("/universal-credit"),
      "title" => Pact.like("Universal credit"),
      "index" => Pact.like("govuk_test"),
      "_id" => Pact.like("/universal-credit"),
      "elasticsearch_type" => Pact.like("edition"),
      "document_type" => Pact.like("edition"),
    }
  end
end
