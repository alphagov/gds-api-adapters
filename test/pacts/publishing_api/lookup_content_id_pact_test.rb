require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#lookup_content_id pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  it "returns the content_id for a base_path" do
    publishing_api
      .given("there are live content items with base_paths /foo and /bar")
      .upon_receiving("a /lookup-by-base-path-request")
      .with(
        method: :post,
        path: "/lookup-by-base-path",
        body: {
          base_paths: ["/foo"],
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: {
          "/foo" => "08f86d00-e95f-492f-af1d-470c5ba4752e",
        },
      )

    content_id = api_client.lookup_content_id(base_path: "/foo")

    assert_equal "08f86d00-e95f-492f-af1d-470c5ba4752e", content_id
  end

  it "returns the content_id of a draft document for a base_path" do
    publishing_api
      .given("there is a draft content item with base_path /foo")
      .upon_receiving("a /lookup-by-base-path-request")
      .with(
        method: :post,
        path: "/lookup-by-base-path",
        body: {
          base_paths: ["/foo"],
          with_drafts: true,
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: {
          "/foo" => "cbb460a7-60de-4a74-b5be-0b27c6d6af9b",
        },
      )

    api_client.lookup_content_id(base_path: "/foo", with_drafts: true)
  end
end
