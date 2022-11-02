require "test_helper"
require "gds_api/locations_api"

describe "GdsApi::LocationsApi pact tests" do
  include PactTest

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
