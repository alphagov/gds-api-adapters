require "test_helper"
require "gds_api/imminence"
require "gds_api/test_helpers/imminence"

describe GdsApi::Imminence do
  include GdsApi::TestHelpers::Imminence
  include PactTest

  describe "#places" do
    let(:api_client) { GdsApi::Imminence.new(imminence_api_host) }

    it "responds with all responses for the given dataset" do
      imminence_api
        .given("a service exists called number-plate-supplier with places")
        .upon_receiving("the request to retrieve all places for the current dataset")
        .with(
          method: :get,
          path: "/places/number-plate-supplier.json",
          headers: GdsApi::JsonClient.default_request_headers,
          query: { lat: "-2.01", lng: "53.1", limit: "5" },
        )
        .will_respond_with(
          status: 200,
          body: Pact.each_like(
            {
              _id: { "$oid": "60867a0ee90e0703aed18e46" },
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
              snac: nil,
              source_address: "Yarrow Road Tower Park Poole  BH12 4QY",
              text_phone: nil,
              town: "Yarrow",
              url: nil,
            },
          ),
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.places("number-plate-supplier", "-2.01", "53.1", "5")
    end
  end

  describe "#areas" do
    let(:api_client) { GdsApi::Imminence.new(imminence_api_host) }

    it "responds with all responses for the given dataset" do
      imminence_api
        .given("a place exists with a postcode and areas")
        .upon_receiving("the request to retrieve the area for the given postcode")
        .with(
          method: :get,
          path: "/areas/WC2B%206SE.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            _response_info: {
              status: "ok",
              links: [],
            },
            total: 2,
            start_index: 1,
            page_size: 2,
            current_page: 1,
            pages: 1,
            results: [
              {
                name: "Westminster City Council",
                country_name: nil,
                type: "LBO",
                codes: {
                  gss: nil,
                },
              },
              {
                name: "London",
                country_name: nil,
                type: "EUR",
                codes: {
                  gss: nil,
                },
              },
            ],
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )
      api_client.areas_for_postcode("WC2B 6SE")
    end
  end
end
