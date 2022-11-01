require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_editions pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "responds correctly when there are editions available to paginate over" do
    publishing_api
      .given("there are live content items with base_paths /foo and /bar")
      .upon_receiving("a get editions request")
      .with(
        method: :get,
        path: "/v2/editions",
        query: "fields%5B%5D=content_id",
      )
      .will_respond_with(
        status: 200,
        body: {
          results: [
            { content_id: "08f86d00-e95f-492f-af1d-470c5ba4752e" },
            { content_id: "ca6c58a6-fb9d-479d-b3e6-74908781cb18" },
          ],
          links: [
            { href: "http://example.org/v2/editions?fields%5B%5D=content_id", rel: "self" },
          ],
        },
      )

    api_client.get_editions(fields: %w[content_id])
  end
end
