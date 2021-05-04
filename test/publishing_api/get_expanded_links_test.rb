require "test_helper"
require "gds_api/publishing_api"
require "json"

describe GdsApi::PublishingApi do
  include PactTest

  before do
    @api_client = GdsApi::PublishingApi.new(publishing_api_host)
    @content_id = "bed722e6-db68-43e5-9079-063f623335a7"
  end

  describe "#get_expanded_links" do
    it "responds with the links when there's a links entry with links" do
      publishing_api
        .given("organisation links exist for content_id #{@content_id}")
        .upon_receiving("a get-expanded-links request")
        .with(
          method: :get,
          path: "/v2/expanded-links/#{@content_id}",
        )
        .will_respond_with(
          status: 200,
          body: {
            expanded_links: {
              organisations: [
                { content_id: "20583132-1619-4c68-af24-77583172c070" },
              ],
            },
          },
        )

      @api_client.get_expanded_links(@content_id)
    end

    it "responds with the empty thing set if there's an empty link set" do
      publishing_api
        .given("empty links exist for content_id #{@content_id}")
        .upon_receiving("a get-expanded-links request")
        .with(
          method: :get,
          path: "/v2/expanded-links/#{@content_id}",
        )
        .will_respond_with(
          status: 200,
          body: {
            expanded_links: {
            },
          },
        )

      @api_client.get_expanded_links(@content_id)
    end

    it "responds with 404 if there's no link set entry" do
      publishing_api
        .given("no links exist for content_id #{@content_id}")
        .upon_receiving("a get-expanded-links request")
        .with(
          method: :get,
          path: "/v2/expanded-links/#{@content_id}",
        )
        .will_respond_with(
          status: 404,
        )

      assert_raises(GdsApi::HTTPNotFound) do
        @api_client.get_expanded_links(@content_id)
      end
    end
  end
end
