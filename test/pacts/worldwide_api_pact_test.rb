require "test_helper"
require "gds_api/worldwide"

describe "GdsApi::Worldwide pact tests" do
  include PactTest

  let(:api_client) { GdsApi::Worldwide.new(whitehall_api_host) }

  describe "#world_locations" do
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
  end

  describe "#world_location" do
    describe "#organisations_for_world_location" do
      it "responds with 200 and all worldwide organisations" do
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
end
