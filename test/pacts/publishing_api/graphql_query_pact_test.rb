require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#graphql_query pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  it "returns the response to the query" do
    query = <<~QUERY
      {
        edition(basePath: "/my-document") {
          ... on Edition {
            title
          }
        }
      }
    QUERY

    publishing_api
      .given("a published content item exists with base_path /my-example")
      .upon_receiving("a GraphQL request")
      .with(
        method: :post,
        path: "/graphql",
        body: { query: },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
        body: {
          "data": {
            "edition": {
              "title": "My document",
            },
          },
        },
      )

    api_client.graphql_query(query)
  end
end
