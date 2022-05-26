require "test_helper"
require "gds_api/locations_api"
require "gds_api/test_helpers/locations_api"

describe GdsApi::LocationsApi do
  include GdsApi::TestHelpers::LocationsApi
  include PactTest

  describe "Locations API" do
    let(:base_api_url) { Plek.current.find("locations-api") }
    let(:api) { GdsApi::LocationsApi.new(base_api_url) }
    let(:locations) do
      [
        {
          "latitude" => 51.5010096,
          "longitude" => -0.1415870,
          "local_custodian_code" => 5900,
        },
        {
          "latitude" => 51.5010097,
          "longitude" => -0.1415871,
          "local_custodian_code" => 5901,
        },
      ]
    end

    it "should return the local custodian codes" do
      stub_locations_api_has_location("SW1A 1AA", locations)

      response = api.local_custodian_code_for_postcode("SW1A 1AA")
      assert_equal [5900, 5901], response
    end

    it "should return only unique local custodian codes " do
      stub_locations_api_has_location(
        "SW1A 1AA",
        [
          {
            "latitude" => 51.5010096,
            "longitude" => -0.1415870,
            "local_custodian_code" => 5900,
          },
          {
            "latitude" => 51.5010097,
            "longitude" => -0.1415871,
            "local_custodian_code" => 5901,
          },
          {
            "latitude" => 51.5010097,
            "longitude" => -0.1415871,
            "local_custodian_code" => 5901,
          },
        ],
      )

      response = api.local_custodian_code_for_postcode("SW1A 1AA")
      assert_equal [5900, 5901], response
    end

    it "should return empty list for postcode with no local custodian codes" do
      stub_locations_api_has_no_location("SW1A 1AA")

      response = api.local_custodian_code_for_postcode("SW1A 1AA")
      assert_equal response, []
    end

    it "should return the coordinates" do
      stub_locations_api_has_location("SW1A 1AA", locations)

      response = api.coordinates_for_postcode("SW1A 1AA")
      assert_equal response, { "latitude" => 51.50100965, "longitude" => -0.14158705 }
    end

    it "should return nil for postcode with no coordinates" do
      stub_locations_api_has_no_location("SW1A 1AA")

      response = api.coordinates_for_postcode("SW1A 1AA")
      assert_nil response
    end

    it "should return 400 for an invalid postcode" do
      stub_locations_api_does_not_have_a_bad_postcode("B4DP05TC0D3")

      assert_raises GdsApi::HTTPClientError do
        api.coordinates_for_postcode("B4DP05TC0D3")
      end
    end
  end

  describe "contract tests" do
    let(:api_client) { GdsApi::LocationsApi.new(locations_api_host) }

    describe "#local_custodian_code_for_postcode" do
      it "responds with a list of local custodian codes" do
        locations_api
          .given("a postcode")
          .upon_receiving("the request to get details about a postcode")
          .with(
            method: :get,
            path: "/v1/locations",
            headers: GdsApi::JsonClient.default_request_headers,
            query: { postcode: "SW1A1AA" },
          )
          .will_respond_with(
            status: 200,
            body: {
              "average_latitude" => 51.50100965,
              "average_longitude" => -0.14158705,
              "results" => [
                { "local_custodian_code" => 5900 },
                { "local_custodian_code" => 5901 },
              ],
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
        api_client.local_custodian_code_for_postcode("SW1A1AA")
      end
    end

    describe "#coordinates_for_postcode" do
      it "responds with average coordinates for postcode" do
        locations_api
          .given("a postcode")
          .upon_receiving("the request to get details about a postcode")
          .with(
            method: :get,
            path: "/v1/locations",
            headers: GdsApi::JsonClient.default_request_headers,
            query: { postcode: "SW1A1AA" },
          )
          .will_respond_with(
            status: 200,
            body: {
              "average_latitude" => 51.50100965,
              "average_longitude" => -0.14158705,
              "results" => [
                { "local_custodian_code" => 5900 },
                { "local_custodian_code" => 5901 },
              ],
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
        api_client.coordinates_for_postcode("SW1A1AA")
      end
    end
  end
end
