require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_linkables pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:linkables) do
    [
      {
        "title" => "Content Item A",
        "internal_name" => "an internal name",
        "content_id" => "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa",
        "publication_state" => "draft",
        "base_path" => "/a-base-path",
      },
      {
        "title" => "Content Item B",
        "internal_name" => "Content Item B",
        "content_id" => "bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb",
        "publication_state" => "published",
        "base_path" => "/another-base-path",
      },
    ]
  end

  it "returns the content items of a given document_type" do
    publishing_api
      .given("there is content with document_type 'taxon'")
      .upon_receiving("a get linkables request")
      .with(
        method: :get,
        path: "/v2/linkables",
        query: "document_type=taxon",
      )
      .will_respond_with(
        status: 200,
        body: linkables,
      )

    api_client.get_linkables(document_type: "taxon")
  end
end
