require "test_helper"
require "gds_api/places_manager"

describe "GdsApi::PlacesManager pact tests" do
  include PactTest

  describe "#places" do
    let(:api_client) { GdsApi::PlacesManager.new(places_manager_api_host) }

    it "responds with all responses for the given dataset" do
      places_manager_api
        .given("a service exists called number-plate-supplier with places")
        .upon_receiving("the request to retrieve relevant places for the current dataset for a lat/lon")
        .with(
          method: :get,
          path: "/places/number-plate-supplier.json",
          headers: GdsApi::JsonClient.default_request_headers,
          query: { lat: "-2.01", lng: "53.1", limit: "5" },
        )
        .will_respond_with(
          status: 200,
          body: {
            status: "ok",
            contents: "places",
            places: Pact.each_like(
              {
                access_notes: nil,
                address1: "Yarrow Road Tower Park",
                address2: nil,
                data_set_version: 473,
                email: nil,
                fax: nil,
                general_notes: nil,
                geocode_error: nil,
                location: { longitude: -1.9552618901330387, latitude: 50.742754933617285 },
                name: "Breeze Motor Co Ltd",
                override_lat: nil,
                override_lng: nil,
                phone: "01202 713000",
                postcode: "BH12 4QY",
                service_slug: "number-plate-supplier",
                gss: nil,
                source_address: "Yarrow Road Tower Park Poole  BH12 4QY",
                text_phone: nil,
                town: "Yarrow",
                url: nil,
              },
            ),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.places("number-plate-supplier", "-2.01", "53.1", "5")
    end

    it "responds with a choice of addresses for disambiguation of split postcodes" do
      places_manager_api
        .given("a service exists called register office exists with places, and CH25 9BJ is a split postcode")
        .upon_receiving("the request to retrieve relevant places for the current dataset for CH25 9BJ")
        .with(
          method: :get,
          path: "/places/register-office.json",
          headers: GdsApi::JsonClient.default_request_headers,
          query: { postcode: "CH25 9BJ", limit: "5" },
        )
        .will_respond_with(
          status: 200,
          body: {
            status: "address-information-required",
            contents: "addresses",
            addresses: Pact.each_like(
              {
                address: "HOUSE 1",
                local_authority_slug: "achester",
              },
            ),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.places_for_postcode("register-office", "CH25 9BJ")
    end
  end
end
