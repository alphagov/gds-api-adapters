require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module Imminence
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      IMMINENCE_API_ENDPOINT = Plek.find("imminence")

      def stub_imminence_has_places(latitude, longitude, details)
        query_hash = { "lat" => latitude, "lng" => longitude, "limit" => "5" }
        response_data = {
          status: "ok",
          content: "places",
          places: details["details"],
        }
        stub_imminence_places_request(details["slug"], query_hash, response_data)
      end

      def stub_imminence_has_multiple_authorities_for_postcode(addresses, slug, postcode, limit)
        query_hash = { "postcode" => postcode, "limit" => limit }
        response_data = {
          status: "address-information-required",
          content: "addresses",
          addresses:,
        }
        stub_imminence_places_request(slug, query_hash, response_data)
      end

      def stub_imminence_has_places_for_postcode(places, slug, postcode, limit, local_authority_slug)
        query_hash = { "postcode" => postcode, "limit" => limit }
        query_hash.merge!(local_authority_slug:) if local_authority_slug
        response_data = {
          status: "ok",
          content: "places",
          places:,
        }
        stub_imminence_places_request(slug, query_hash, response_data)
      end

      def stub_imminence_places_request(slug, query_hash, return_data, status_code = 200)
        stub_request(:get, "#{IMMINENCE_API_ENDPOINT}/places/#{slug}.json")
        .with(query: query_hash)
        .to_return(status: status_code, body: return_data.to_json, headers: {})
      end
    end
  end
end
