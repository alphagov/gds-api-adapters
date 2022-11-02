require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_links_by_content_id pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  it "returns the links for some content_ids" do
    content_id_with_links = "bed722e6-db68-43e5-9079-063f623335a7"
    content_id_no_links = "f40a63ce-ac0c-4102-84d1-f1835cb7daac"

    response_hash = {
      content_id_with_links => {
        "links" => {
          "taxons" => %w[20583132-1619-4c68-af24-77583172c070],
        },
        "version" => 2,
      },
      content_id_no_links => {
        "links" => {},
        "version" => 0,
      },
    }

    publishing_api
      .given("taxon links exist for content_id bed722e6-db68-43e5-9079-063f623335a7")
      .upon_receiving("a bulk_links request")
      .with(
        method: :post,
        path: "/v2/links/by-content-id",
        body: {
          content_ids: [content_id_with_links, content_id_no_links],
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: response_hash,
      )

    api_client.get_links_for_content_ids([content_id_with_links, content_id_no_links])
  end
end
