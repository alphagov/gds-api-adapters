require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_host_content_for_content_id pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:reusable_content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }
  let(:content_id) { "d66d6552-2627-4451-9dbc-cadbbd2005a1" }
  let(:publishing_organisation_content_id) { "d1e7d343-9844-4246-a469-1fa4640e12ad" }
  let(:result) do
    {
      "title" => "foo",
      "base_path" => "/foo",
      "document_type" => "publication",
      "publishing_app" => "publisher",
      "primary_publishing_organisation" => {
        "content_id" => publishing_organisation_content_id,
        "title" => "bar",
        "base_path" => "/bar",
      },
    }
  end
  let(:expected_body) do
    {
      "content_id" => reusable_content_id,
      "total" => 1,
      "results" => [result],
    }
  end

  it "responds with 200 if the target content item exists" do
    publishing_api
      .given("a content item exists (content_id: #{content_id}) that embeds the reusable content (content_id: #{reusable_content_id})")
      .upon_receiving("a get_host_content_for_content_id request")
      .with(
        method: :get,
        path: "/v2/content/#{reusable_content_id}/host-content",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    response = api_client.get_host_content_for_content_id(reusable_content_id)

    assert_equal(expected_body, response.parsed_content)
  end

  describe "there are multiple pages" do
    let(:publishing_api_with_multiple_content_items) do
      publishing_api.given("multiple content items exist that embed the reusable content (content_id: #{reusable_content_id})")
    end

    let(:result) do
      {
        "title" => "foo",
        "base_path" => "/foo",
        "document_type" => "publication",
        "publishing_app" => "publisher",
        "primary_publishing_organisation" => {
          "content_id" => nil,
          "title" => nil,
          "base_path" => nil,
        },
      }
    end

    it "returns the first page of results" do
      publishing_api_with_multiple_content_items
        .upon_receiving("a get_host_content_for_content_id request for multiple pages")
        .with(
          method: :get,
          path: "/v2/content/#{reusable_content_id}/host-content",
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => reusable_content_id,
            "total" => 12,
            "total_pages" => 2,
            "results" => Pact.each_like(result, min: 10),
          },
        )

      api_client.get_host_content_for_content_id(reusable_content_id)
    end

    it "supports a page argument" do
      publishing_api_with_multiple_content_items
        .upon_receiving("a get_host_content_for_content_id request for multiple pages with a page argument")
        .with(
          method: :get,
          path: "/v2/content/#{reusable_content_id}/host-content",
          query: "page=2",
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => reusable_content_id,
            "total" => 12,
            "total_pages" => 2,
            "results" => Pact.each_like(result, min: 2),
          },
        )

      api_client.get_host_content_for_content_id(reusable_content_id, { page: 2 })
    end

    it "supports a per page argument" do
      publishing_api_with_multiple_content_items
        .upon_receiving("a get_host_content_for_content_id request for multiple pages with a per_page argument")
        .with(
          method: :get,
          path: "/v2/content/#{reusable_content_id}/host-content",
          query: "per_page=1",
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => reusable_content_id,
            "total" => 12,
            "total_pages" => 12,
            "results" => Pact.each_like(result, min: 1),
          },
        )

      api_client.get_host_content_for_content_id(reusable_content_id, { per_page: 1 })
    end

    it "supports sorting" do
      publishing_api_with_multiple_content_items
        .upon_receiving("a get_host_content_for_content_id request for multiple pages with sorting")
        .with(
          method: :get,
          path: "/v2/content/#{reusable_content_id}/host-content",
          query: "order=-last_edited_at",
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => reusable_content_id,
            "total" => 12,
            "total_pages" => 2,
            "results" => Pact.each_like(result, min: 10),
          },
        )

      api_client.get_host_content_for_content_id(reusable_content_id, { order: "-last_edited_at" })
    end
  end

  it "responds with 404 if the content item does not exist" do
    missing_content_id = "missing-content-id"
    publishing_api
      .given("no content exists")
      .upon_receiving("a get_host_content_for_content_id request")
      .with(
        method: :get,
        path: "/v2/content/#{missing_content_id}/host-content",
      )
      .will_respond_with(
        status: 404,
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.get_host_content_for_content_id(missing_content_id)
    end
  end
end
