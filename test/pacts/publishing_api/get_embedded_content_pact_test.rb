require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_content_by_embedded_document pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:reusable_content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }
  let(:content_id) { "d66d6552-2627-4451-9dbc-cadbbd2005a1" }
  let(:publishing_organisation_content_id) { "d1e7d343-9844-4246-a469-1fa4640e12ad" }
  let(:expected_body) do
    {
      "content_id" => reusable_content_id,
      "total" => 1,
      "results" => [
        {
          "title" => "foo",
          "base_path" => "/foo",
          "document_type" => "publication",
          "primary_publishing_organisation" => {
            "content_id" => publishing_organisation_content_id,
            "title" => "bar",
            "base_path" => "/bar",
          },
        },
      ],
    }
  end

  it "responds with 200 if the target content item exists" do
    publishing_api
      .given("a content item exists (content_id: #{content_id}) that embeds the reusable content (content_id: #{reusable_content_id})")
      .upon_receiving("a get_content_by_embedded_document request")
      .with(
        method: :get,
        path: "/v2/content/#{reusable_content_id}/embedded",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    response = api_client.get_content_by_embedded_document(reusable_content_id)

    assert_equal(expected_body, response.parsed_content)
  end

  it "responds with 404 if the content item does not exist" do
    missing_content_id = "missing-content-id"
    publishing_api
      .given("no content exists")
      .upon_receiving("a get_content_by_embedded_document request")
      .with(
        method: :get,
        path: "/v2/content/#{missing_content_id}/embedded",
      )
      .will_respond_with(
        status: 404,
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.get_content_by_embedded_document(missing_content_id)
    end
  end
end
