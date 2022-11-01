require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_paged_editions pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  describe "there are multiple pages of editions" do
    let(:content_id_1) { "bd50a6d9-f03d-4ccf-94aa-ad79579990a9" }
    let(:content_id_2) { "989033fe-252a-4e69-976d-5c0059bca949" }
    let(:content_id_3) { "271d4270-9186-4d60-b2ca-1d7dae7e0f73" }
    let(:content_id_4) { "638af19c-27fc-4cc9-a914-4cca49028688" }

    let(:first_page) do
      {
        request: {
          method: :get,
          path: "/v2/editions",
          query: "fields%5B%5D=content_id&per_page=2",
          headers: GdsApi::JsonClient.default_request_headers,
        },
        response: {
          status: 200,
          body: {
            results: [
              { content_id: content_id_1 },
              { content_id: content_id_2 },
            ],
            links: [
              { href: "http://example.org#{second_page[:request][:path]}?#{second_page[:request][:query]}", rel: "next" },
              { href: "http://example.org/v2/editions?fields%5B%5D=content_id&per_page=2", rel: "self" },
            ],
          },
        },
      }
    end

    let(:second_page) do
      {
        request: {
          method: :get,
          path: "/v2/editions",
          query: "fields%5B%5D=content_id&per_page=2&after=2017-02-01T00%3A00%3A00.000000Z%2C2",
          headers: GdsApi::JsonClient.default_request_headers,
        },
        response: {
          status: 200,
          body: {
            results: [
              { content_id: content_id_3 },
              { content_id: content_id_4 },
            ],
            links: [
              { href: "http://example.org/v2/editions?fields%5B%5D=content_id&per_page=2&after=2017-02-01T00%3A00%3A00.000000Z%2C2", rel: "self" },
              { href: "http://example.org/v2/editions?fields%5B%5D=content_id&per_page=2&before=2017-03-01T00%3A00%3A00.000000Z%2C3", rel: "previous" },
            ],
          },
        },
      }
    end

    before do
      publishing_api
        .given("there are 4 live content items with fixed updated timestamps")
        .upon_receiving("a get editions request for 2 per page")
        .with(first_page[:request])
        .will_respond_with(first_page[:response])

      publishing_api
        .given("there are 4 live content items with fixed updated timestamps")
        .upon_receiving("a next page editions request")
        .with(second_page[:request])
        .will_respond_with(second_page[:response])
    end

    it "receives two pages of results" do
      first_page_url = "#{publishing_api_host}#{first_page[:request][:path]}?#{first_page[:request][:query]}"
      second_page_path = "#{second_page[:request][:path]}?#{second_page[:request][:query]}"

      # Manually override JsonClient#get_json, because the Pact tests mean we return an invalid pagination
      # URL, which we have to replace with our mocked publishing_api_host
      api_client
        .expects(:get_json)
        .with(first_page_url)
        .returns(GdsApi::JsonClient.new.get_json(first_page_url, first_page[:request][:headers]))

      api_client
        .expects(:get_json)
        .with("http://example.org#{second_page_path}")
        .returns(GdsApi::JsonClient.new.get_json("#{publishing_api_host}#{second_page_path}", second_page[:request][:headers]))

      response = api_client.get_paged_editions(fields: %w[content_id], per_page: 2).to_a

      assert_equal 2, response.count
      first_page_content_ids = response[0]["results"].map { |content_item| content_item["content_id"] }
      second_page_content_ids = response[1]["results"].map { |content_item| content_item["content_id"] }

      assert_equal [content_id_1, content_id_2], first_page_content_ids
      assert_equal [content_id_3, content_id_4], second_page_content_ids
    end
  end
end
