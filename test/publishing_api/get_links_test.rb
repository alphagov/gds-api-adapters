require "test_helper"
require "gds_api/publishing_api"
require "json"

describe GdsApi::PublishingApi do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  describe "#get_links" do
    it "responds with links when there's a links entry with links" do
      publishing_api
        .given("organisation links exist for content_id #{content_id}")
        .upon_receiving("a get-links request")
        .with(
          method: :get,
          path: "/v2/links/#{content_id}",
        )
        .will_respond_with(
          status: 200,
          body: {
            links: {
              organisations: %w[20583132-1619-4c68-af24-77583172c070],
            },
          },
        )

      api_client.get_links(content_id)
    end

    it "responds with the empty link set when there's an empty links entry" do
      publishing_api
        .given("empty links exist for content_id #{content_id}")
        .upon_receiving("a get-links request")
        .with(
          method: :get,
          path: "/v2/links/#{content_id}",
        )
        .will_respond_with(
          status: 200,
          body: {
            links: {},
          },
        )

      api_client.get_links(content_id)
    end

    it "responds with 404 when there's no links entry" do
      publishing_api
        .given("no links exist for content_id #{content_id}")
        .upon_receiving("a get-links request")
        .with(
          method: :get,
          path: "/v2/links/#{content_id}",
        )
        .will_respond_with(
          status: 404,
        )

      assert_raises(GdsApi::HTTPNotFound) do
        api_client.get_links(content_id)
      end
    end
  end
end
