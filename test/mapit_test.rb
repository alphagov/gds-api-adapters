require "test_helper"
require "gds_api/mapit"
require "gds_api/test_helpers/mapit"

describe GdsApi::Mapit do
  include GdsApi::TestHelpers::Mapit

  before do
    @base_api_url = Plek.current.find("mapit")
    @api = GdsApi::Mapit.new(@base_api_url)
  end

  describe "postcodes" do
    it "should return the coordinates" do
      stub_mapit_has_a_postcode("SW1A 1AA", [51.5010096, -0.1415870])

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal 51.5010096, response.lat
      assert_equal(-0.1415870, response.lon)
    end

    it "should return the postcode" do
      stub_mapit_has_a_postcode("SW1A 1AA", [51.5010096, -0.1415870])

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal "SW1A 1AA", response.postcode
    end

    it "should return areas" do
      stub_mapit_has_a_postcode_and_areas(
        "SW1A 1AA",
        [51.5010096, -0.1415870],
        [
          { "name" => "Lancashire County Council", "type" => "CTY", "ons" => "30", "gss" => "E10000017" },
          { "name" => "South Ribble Borough Council", "type" => "DIS", "ons" => "30UN", "gss" => "E07000126" },
        ],
      )

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal 2, response.areas.length

      assert_equal "Lancashire County Council", response.areas.first.name
      assert_equal "South Ribble Borough Council", response.areas.last.name

      assert_equal "CTY", response.areas.first.type
      assert_equal "DIS", response.areas.last.type

      assert_equal "30", response.areas.first.codes["ons"]
      assert_equal "30UN", response.areas.last.codes["ons"]
    end

    it "should return the country name" do
      stub_mapit_has_a_postcode_and_country_name("SW1A 1AA", [51.5010096, -0.1415870], "England")

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal "England", response.country_name
    end

    it "should allow the country name to be nil" do
      stub_mapit_has_a_postcode_and_country_name("SW1A 1AA", [51.5010096, -0.1415870], nil)

      response = @api.location_for_postcode("SW1A 1AA")
      assert_nil response.country_name
    end

    it "should allow the country name to be an empty string" do
      stub_mapit_has_a_postcode_and_country_name("SW1A 1AA", [51.5010096, -0.1415870], "")

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal "", response.country_name
    end

    it "should raise if a postcode doesn't exist" do
      stub_mapit_does_not_have_a_postcode("SW1A 1AA")

      assert_raises(GdsApi::HTTPNotFound) do
        @api.location_for_postcode("SW1A 1AA")
      end
    end

    it "should return 400 for an invalid postcode" do
      stub_mapit_does_not_have_a_bad_postcode("B4DP05TC0D3")

      assert_raises GdsApi::HTTPClientError do
        @api.location_for_postcode("B4DP05TC0D3")
      end
    end
  end

  describe "areas_for_type" do
    before do
      stub_mapit_has_areas(
        "EUR",
        "123" => { "name" => "Eastern", "id" => "123", "country_name" => "England" },
        "234" => { "name" => "North West", "id" => "234", "country_name" => "England" },
        "345" => { "name" => "Scotland", "id" => "345", "country_name" => "Scotland" },
      )
      stub_mapit_does_not_have_areas("FOO")
    end
    it "should return areas of a type" do
      areas = @api.areas_for_type("EUR").to_hash

      assert_equal 3, areas.size
      assert_equal "Eastern", areas["123"]["name"]
      assert_equal "England", areas["123"]["country_name"]
      assert_equal "North West", areas["234"]["name"]
      assert_equal "England", areas["234"]["country_name"]
      assert_equal "Scotland", areas["345"]["name"]
      assert_equal "Scotland", areas["345"]["country_name"]
    end
    it "should return and empty result for an unknown area type" do
      response = @api.areas_for_type("FOO")

      assert_empty response.parsed_content
    end
  end

  describe "area_for_code" do
    before do
      south_ribble_area = {
        name: "South Ribble Borough Council",
        codes: {
          ons: "30UN",
          gss: "E07000126",
          unit_id: "4834",
        },
        type: "DIS",
      }
      stub_mapit_has_area_for_code("ons", "30UN", south_ribble_area)
      stub_mapit_does_not_have_area_for_code("govuk_slug", "neverland")
    end

    it "should return area for a code type" do
      area = @api.area_for_code("ons", "30UN")

      assert_equal "South Ribble Borough Council", area["name"]
    end

    it "should return 404 for a missing area of a certain code type" do
      assert_raises(GdsApi::HTTPNotFound) do
        @api.area_for_code("govuk_slug", "neverland")
      end
    end
  end
end
