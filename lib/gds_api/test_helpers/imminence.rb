require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module Imminence
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      IMMINENCE_API_ENDPOINT = Plek.find("imminence")

      def stub_imminence_has_places(latitude, longitude, details)
        query_hash = { "lat" => latitude, "lng" => longitude, "limit" => "5" }
        stub_imminence_places_request(details["slug"], query_hash, details["details"])
      end

      def stub_imminence_has_places_for_postcode(places, slug, postcode, limit)
        query_hash = { "postcode" => postcode, "limit" => limit }
        stub_imminence_places_request(slug, query_hash, places)
      end

      def stub_imminence_places_request(slug, query_hash, return_data, status_code = 200)
        stub_request(:get, "#{IMMINENCE_API_ENDPOINT}/places/#{slug}.json")
        .with(query: query_hash)
        .to_return(status: status_code, body: return_data.to_json, headers: {})
      end
    end
  end
end
