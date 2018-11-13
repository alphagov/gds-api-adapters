require_relative 'test_helper'
require 'gds_api/worldwide'
require 'gds_api/test_helpers/worldwide'

describe GdsApi::Worldwide do
  include GdsApi::TestHelpers::Worldwide

  before do
    @base_api_url = GdsApi::TestHelpers::Worldwide::WORLDWIDE_API_ENDPOINT
    @api = GdsApi::Worldwide.new(@base_api_url)
  end

  describe "fetching list of world locations" do
    it "should get the world locations" do
      country_slugs = %w(the-shire rivendel rohan lorien gondor arnor mordor)
      worldwide_api_has_locations(country_slugs)

      response = @api.world_locations
      assert_equal country_slugs, response.map { |r| r['details']['slug'] }
      assert_equal "Rohan", response['results'][2]['title']
    end

    it "should handle the pagination" do
      country_slugs = (1..50).map { |n| "country-#{n}" }
      worldwide_api_has_locations(country_slugs)

      response = @api.world_locations
      assert_equal(
        country_slugs,
        response.with_subsequent_pages.map { |r| r['details']['slug'] }
      )
    end

    it "should raise error if endpoint 404s" do
      stub_request(:get, "#{@base_api_url}/api/world-locations?page=1").to_return(status: 404)
      assert_raises GdsApi::HTTPNotFound do
        @api.world_locations
      end
    end
  end

  describe "fetching a world location" do
    it "should return the details" do
      worldwide_api_has_location('rohan')

      response = @api.world_location('rohan')
      assert_equal 'Rohan', response['title']
    end

    it "raises for a non-existent location" do
      worldwide_api_does_not_have_location('non-existent')

      assert_raises(GdsApi::HTTPNotFound) do
        @api.world_location('non-existent')
      end
    end
  end

  describe "fetching organisations for a location" do
    it "should return the organisation details" do
      details = JSON.parse(load_fixture_file("world_organisations_australia.json").read)
      worldwide_api_has_organisations_for_location('australia', details)

      response = @api.organisations_for_world_location('australia')
      assert response.is_a?(GdsApi::ListResponse)
      assert_equal(
        [
          "UK Trade & Investment Australia",
          "British High Commission Canberra"
        ],
        response.map { |item| item['title'] }
      )
    end

    it "should raise error on 404" do
      stub_request(:get, "#{@base_api_url}/api/world-locations/non-existent/organisations").to_return(status: 404)
      assert_raises GdsApi::HTTPNotFound do
        @api.organisations_for_world_location('non-existent')
      end
    end
  end
end
