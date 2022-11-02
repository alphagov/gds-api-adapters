require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_linked_items pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "404s if the content item does not exist" do
    publishing_api
      .given("no content exists")
      .upon_receiving("a request to return the items linked to it")
      .with(
        method: :get,
        path: "/v2/linked/#{content_id}",
        query: "fields%5B%5D=content_id&fields%5B%5D=base_path&link_type=topic",
      )
      .will_respond_with(
        status: 404,
        body: {
          "error" => {
            "code" => 404,
            "message" => Pact.term(generate: "not found", matcher: /\S+/),
          },
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.get_linked_items(
        content_id,
        link_type: "topic",
        fields: %w[content_id base_path],
      )
    end
  end

  describe "there are two documents that link to the wanted document" do
    let(:linked_content_id) { "6cb2cf8c-670f-4de3-97d5-6ad9114581c7" }

    let(:linking_content_item1) do
      {
        "content_id" => "e2961462-bc37-48e9-bb98-c981ef1a2d59",
        "base_path" => "/item-b",
      }
    end

    let(:linking_content_item2) do
      {
        "content_id" => "08dfd5c3-d935-4e81-88fd-cfe65b78893d",
        "base_path" => "/item-a",
      }
    end

    before do
      publishing_api
        .given("there are two documents with a 'topic' link to another document")
        .upon_receiving("a get linked request")
        .with(
          method: :get,
          path: "/v2/linked/#{linked_content_id}",
          query: "fields%5B%5D=content_id&fields%5B%5D=base_path&link_type=topic",
        )
        .will_respond_with(
          status: 200,
          body: [
            {
              content_id: linking_content_item1["content_id"],
              base_path: linking_content_item1["base_path"],
            },
            {
              content_id: linking_content_item2["content_id"],
              base_path: linking_content_item2["base_path"],
            },
          ],
        )
    end

    it "returns the requested fields of linking items" do
      response = api_client.get_linked_items(
        linked_content_id,
        link_type: "topic",
        fields: %w[content_id base_path],
      )
      assert_equal 200, response.code

      expected_documents = [linking_content_item2, linking_content_item1]

      expected_documents.each do |document|
        assert_includes response.to_a, document
      end
    end
  end
end
