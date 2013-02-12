require 'test_helper'
require 'gds_api/mapit'
require 'gds_api/test_helpers/mapit'

describe GdsApi::Mapit do
  include GdsApi::TestHelpers::Mapit

  before do
    @base_api_url = Plek.current.find("mapit")
    @api = GdsApi::Mapit.new(@base_api_url)
  end

  describe "postcodes" do
    it "should return the coordinates" do
      mapit_has_a_postcode("SW1A 1AA", [ 51.5010096, -0.1415870 ])

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal 51.5010096, response.lat
      assert_equal -0.1415870, response.lon
    end

    it "should return the postcode" do
      mapit_has_a_postcode("SW1A 1AA", [ 51.5010096, -0.1415870 ])

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal "SW1A 1AA", response.postcode
    end

    it "should return areas" do
      mapit_has_a_postcode_and_areas("SW1A 1AA", [ 51.5010096, -0.1415870 ], [
        { 'name' => 'Lancashire County Council', 'type' => 'CTY', 'ons' => '30', 'gss' => 'E10000017' },
        { 'name' => 'South Ribble Borough Council', 'type' => 'DIS', 'ons' => '30UN', 'gss' => 'E07000126' }
      ])

      response = @api.location_for_postcode("SW1A 1AA")
      assert_equal 2, response.areas.length

      assert_equal "Lancashire County Council", response.areas.first.name
      assert_equal "South Ribble Borough Council", response.areas.last.name

      assert_equal "CTY", response.areas.first.type
      assert_equal "DIS", response.areas.last.type

      assert_equal "30", response.areas.first.codes['ons']
      assert_equal "30UN", response.areas.last.codes['ons']
    end

    it "should return nil if a postcode doesn't exist" do
      mapit_does_not_have_a_postcode("SW1A 1AA")

      assert_nil @api.location_for_postcode("SW1A 1AA")
    end

    it "should return nil for an invalid postcode" do
      mapit_does_not_have_a_bad_postcode("B4DP05TC0D3")

      assert_nil @api.location_for_postcode("B4DP05TC0D3")
    end
  end
end
