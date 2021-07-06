require "test_helper"
require "gds_api/worldwide"
require "gds_api/test_helpers/worldwide"

describe GdsApi::Worldwide do
  include GdsApi::TestHelpers::Worldwide
  include PactTest

  before do
    @base_api_url = GdsApi::TestHelpers::Worldwide::WORLDWIDE_API_ENDPOINT
    @api = GdsApi::Worldwide.new(@base_api_url)
  end

  describe "fetching list of world locations" do
    it "should get the world locations" do
      country_slugs = %w[the-shire rivendel rohan lorien gondor arnor mordor]
      stub_worldwide_api_has_locations(country_slugs)

      response = @api.world_locations
      assert_equal(country_slugs, response.map { |r| r["details"]["slug"] })
      assert_equal "Rohan", response["results"][2]["title"]
    end

    it "should handle the pagination" do
      country_slugs = (1..50).map { |n| "country-#{n}" }
      stub_worldwide_api_has_locations(country_slugs)

      response = @api.world_locations
      assert_equal(
        country_slugs,
        response.with_subsequent_pages.map { |r| r["details"]["slug"] },
      )
    end

    it "should raise error if endpoint 404s" do
      stub_request(:get, "#{@base_api_url}/api/world-locations").to_return(status: 404)
      assert_raises GdsApi::HTTPNotFound do
        @api.world_locations
      end
    end
  end

  describe "fetching a world location" do
    it "should return the details" do
      stub_worldwide_api_has_location("rohan")

      response = @api.world_location("rohan")
      assert_equal "Rohan", response["title"]
    end

    it "raises for a non-existent location" do
      stub_worldwide_api_does_not_have_location("non-existent")

      assert_raises(GdsApi::HTTPNotFound) do
        @api.world_location("non-existent")
      end
    end
  end

  describe "fetching organisations for a location" do
    it "should return the organisation details" do
      details = JSON.parse(load_fixture_file("world_organisations_australia.json").read)
      stub_worldwide_api_has_organisations_for_location("australia", details)

      response = @api.organisations_for_world_location("australia")
      assert response.is_a?(GdsApi::ListResponse)
      assert_equal(
        [
          "UK Trade & Investment Australia",
          "British High Commission Canberra",
        ],
        response.map { |item| item["title"] },
      )
    end

    it "should raise error on 404" do
      stub_request(:get, "#{@base_api_url}/api/world-locations/non-existent/organisations").to_return(status: 404)
      assert_raises GdsApi::HTTPNotFound do
        @api.organisations_for_world_location("non-existent")
      end
    end
  end

  describe "#world_locations" do
    let(:api_client) { GdsApi::Worldwide.new(whitehall_api_host) }

    it "responds with 200 and all world locations" do
      whitehall_api
        .given("a world location exists")
        .upon_receiving("a request to return all world locations")
        .with(
          method: :get,
          path: "/api/world-locations",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              Pact.like(
                id: "https://www.gov.uk/api/world-locations/france",
                title: "France",
                format: "World location",
                updated_at: "2020-09-02T06:47:34.000+01:00",
                web_url: "https://www.gov.uk/world/france",
                analytics_identifier: "WL1",
                details: {
                  slug: "france",
                  iso2: nil,
                },
                organisations: {
                  id: "https://www.gov.uk/api/world-locations/france/organisations",
                  web_url: "https://www.gov.uk/world/france#organisations",
                },
                content_id: "5e9ecbce-7706-11e4-a3cb-005056011aef",
              ),
            ],
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.world_locations
    end

    it "responds with 200 and specific world location" do
      whitehall_api
        .given("a world location exists")
        .upon_receiving("a request to return a specific world location")
        .with(
          method: :get,
          path: "/api/world-locations/france",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            id: Pact.like("https://www.gov.uk/api/world-locations/france"),
            title: "France",
            format: "World location",
            updated_at: Pact.like("2020-09-02T06:47:34.000+01:00"),
            web_url: Pact.like("https://www.gov.uk/world/france"),
            analytics_identifier: Pact.like("WL1"),
            details: {
              slug: "france",
              iso2: nil,
            },
            organisations: Pact.like(
              id: "https://www.gov.uk/api/world-locations/france/organisations",
              web_url: "https://www.gov.uk/world/france#organisations",
            ),
            content_id: Pact.like("5e9ecbce-7706-11e4-a3cb-005056011aef"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.world_location("france")
    end

    it "responds with 200 and all world locations" do
      whitehall_api
        .given("a worldwide organisation exists")
        .upon_receiving("a request to return a countries worldwide organisations")
        .with(
          method: :get,
          path: "/api/world-locations/france/organisations",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              Pact.like(
                id: "https://www.gov.uk/api/worldwide-organisations/british-embassy-paris",
                title: "British Embassy Paris",
                format: "Worldwide Organisation",
                updated_at: "2014-05-13T10:15:06.000+01:00",
                web_url: "https://www.gov.uk/world/organisations/british-embassy-paris",
                details: {
                  slug: "british-embassy-paris",
                },
                analytics_identifier: "WO49",
                sponsors: [
                  {
                    title: "Foreign, Commonwealth & Development Office",
                    web_url: "https://www.gov.uk/government/organisations/foreign-commonwealth-development-office",
                    details: {
                      acronym: "FCDO",
                    },
                  },
                ],
              ),
            ],
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.organisations_for_world_location("france")
    end
  end
end
