require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#discard_draft pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "responds with 200 when the content item exists" do
    publishing_api
      .given("a content item exists with content_id: #{content_id}")
      .upon_receiving("a request to discard draft content")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/discard-draft",
        body: {},
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.discard_draft(content_id)
  end

  it "responds with 200 when the content item exists and is French" do
    publishing_api
      .given("a French content item exists with content_id: #{content_id}")
      .upon_receiving("a request to discard French draft content")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/discard-draft",
        body: {
          locale: "fr",
        },
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 200,
      )

    api_client.discard_draft(content_id, locale: "fr")
  end

  it "responds with a 404 when there is no content with that content_id" do
    publishing_api
      .given("no content exists")
      .upon_receiving("a request to discard draft content")
      .with(
        method: :post,
        path: "/v2/content/#{content_id}/discard-draft",
        body: {},
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
      )
      .will_respond_with(
        status: 404,
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.discard_draft(content_id)
    end
  end
end
