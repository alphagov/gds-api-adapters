require 'test_helper'
require 'gds_api/publishing_api_v2'
require 'json'

describe GdsApi::PublishingApiV2 do
  include PactTest

  before do
    @api_client = GdsApi::PublishingApiV2.new(publishing_api_host)
    @content_id = "bed722e6-db68-43e5-9079-063f623335a7"
  end

  describe "#get_links" do
    describe "when there's a links entry with links" do
      before do
        publishing_api
          .given("organisation links exist for content_id #{@content_id}")
          .upon_receiving("a get-links request")
          .with(
            method: :get,
            path: "/v2/links/#{@content_id}",
          )
          .will_respond_with(
            status: 200,
            body: {
              links: {
                organisations: ["20583132-1619-4c68-af24-77583172c070"]
              }
            }
          )
      end

      it "responds with the links" do
        response = @api_client.get_links(@content_id)
        assert_equal 200, response.code
        assert_equal ["20583132-1619-4c68-af24-77583172c070"], response.links.organisations
      end
    end

    describe "when there's an empty links entry" do
      before do
        publishing_api
          .given("empty links exist for content_id #{@content_id}")
          .upon_receiving("a get-links request")
          .with(
            method: :get,
            path: "/v2/links/#{@content_id}",
          )
          .will_respond_with(
            status: 200,
            body: {
              links: {
              }
            }
          )
      end

      it "responds with the empty link set" do
        response = @api_client.get_links(@content_id)
        assert_equal 200, response.code
        assert_equal OpenStruct.new({}), response.links
      end
    end

    describe "when there's no links entry" do
      before do
        publishing_api
          .given("no links exist for content_id #{@content_id}")
          .upon_receiving("a get-links request")
          .with(
            method: :get,
            path: "/v2/links/#{@content_id}",
          )
          .will_respond_with(
            status: 404
          )
      end

      it "responds with 404" do
        response = @api_client.get_links(@content_id)
        assert_nil response
      end
    end
  end
end
