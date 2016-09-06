require 'test_helper'
require 'gds_api/publishing_api_v2'
require 'json'

describe GdsApi::PublishingApiV2 do
  include PactTest

  before do
    @api_client = GdsApi::PublishingApiV2.new(publishing_api_host)
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
                { content_id: "20583132-1619-4c68-af24-77583172c070" }
              ]
            }
          }
        )

      response = @api_client.get_expanded_links(@content_id)

      expected_body = {
        "expanded_links" => {
          "organisations" => [
            { "content_id" => "20583132-1619-4c68-af24-77583172c070" }
          ]
        }
      }
      assert_equal 200, response.code
      assert_equal expected_body, response.to_h
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
            }
          }
        )

      response = @api_client.get_expanded_links(@content_id)

      assert_equal 200, response.code
      assert_equal({}, response.to_h['expanded_links'])
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
          status: 404
        )

      response = @api_client.get_expanded_links(@content_id)

      assert_nil response
    end
  end
end
