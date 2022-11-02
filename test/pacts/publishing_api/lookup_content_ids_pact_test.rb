require "test_helper"
require "gds_api/publishing_api"
require "json"

describe "GdsApi::PublishingApi#lookup_content_ids pact test" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  it "returns the content_id for a base_path" do
    reponse_hash = {
      "/foo" => "08f86d00-e95f-492f-af1d-470c5ba4752e",
      "/bar" => "ca6c58a6-fb9d-479d-b3e6-74908781cb18",
    }

    publishing_api
      .given("there are live content items with base_paths /foo and /bar")
      .upon_receiving("a request for multiple base_paths")
      .with(
        method: :post,
        path: "/lookup-by-base-path",
        body: {
          base_paths: ["/foo", "/bar"],
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: reponse_hash,
      )

    api_client.lookup_content_ids(base_paths: ["/foo", "/bar"])
  end
end
