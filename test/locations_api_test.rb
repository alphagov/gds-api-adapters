require "test_helper"
require "gds_api/locations_api"
require "gds_api/test_helpers/locations_api"

describe GdsApi::LocationsApi do
  include GdsApi::TestHelpers::LocationsApi

  before do
    @base_api_url = Plek.current.find("locations-api")
    @api = GdsApi::LocationsApi.new(@base_api_url)
    @locations = [
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

  describe "Locations API" do
    it "should return the local custodian codes" do
      stub_locations_api_has_location("SW1A 1AA", @locations)

      response = @api.local_custodian_code_for_postcode("SW1A 1AA")
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

      response = @api.local_custodian_code_for_postcode("SW1A 1AA")
      assert_equal [5900, 5901], response
    end

    it "should return empty list for postcode with no local custodian codes" do
      stub_locations_api_has_no_location("SW1A 1AA")

      response = @api.local_custodian_code_for_postcode("SW1A 1AA")
      assert_equal response, []
    end

    it "should return the coordinates" do
      stub_locations_api_has_location("SW1A 1AA", @locations)

      response = @api.coordinates_for_postcode("SW1A 1AA")
      assert_equal response, { "latitude" => 51.50100965, "longitude" => -0.14158705 }
    end

    it "should return nil for postcode with no coordinates" do
      stub_locations_api_has_no_location("SW1A 1AA")

      response = @api.coordinates_for_postcode("SW1A 1AA")
      assert_nil response
    end

    it "should return 400 for an invalid postcode" do
      stub_locations_api_does_not_have_a_bad_postcode("B4DP05TC0D3")

      assert_raises GdsApi::HTTPClientError do
        @api.coordinates_for_postcode("B4DP05TC0D3")
      end
    end
  end
end
