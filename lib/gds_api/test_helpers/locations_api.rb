module GdsApi
  module TestHelpers
    module LocationsApi
      LOCATIONS_API_ENDPOINT = Plek.current.find("locations-api")

      def stub_locations_api_has_location(postcode, locations)
        results = []
        locations.each do |l|
          results << {
            "latitude" => l["latitude"],
            "longitude" => l["longitude"],
            "postcode" => postcode,
            "local_custodian_code" => l["local_custodian_code"],
          }
        end

        response = {
          "average_latitude" => results.sum { |r| r["latitude"] } / results.size.to_f,
          "average_longitude" => results.sum { |r| r["longitude"] } / results.size.to_f,
          "results" => results,
        }

        stub_request(:get, "#{LOCATIONS_API_ENDPOINT}/locations?postcode=#{postcode}.json")
          .to_return(body: response.to_json, status: 200)
      end
    end
  end
end
