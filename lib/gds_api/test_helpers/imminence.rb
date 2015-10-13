require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Imminence
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      IMMINENCE_API_ENDPOINT = Plek.current.find('imminence')

      def imminence_has_places(latitude, longitude, details)
        response = JSON.dump(details['details'])

        stub_request(:get, "#{IMMINENCE_API_ENDPOINT}/places/#{details['slug']}.json").
        with(:query => {"lat" => latitude, "lng" => longitude, "limit" => "5"}).
        to_return(:status => 200, :body => response, :headers => {})
      end

      def imminence_has_areas_for_postcode(postcode, areas)
        results = {
          "_response_info" => {"status" => "ok"},
          "total" => areas.size, "startIndex" => 1, "pageSize" => areas.size,
          "currentPage" => 1, "pages" => 1, "results" => areas
        }

        stub_request(:get, %r{\A#{IMMINENCE_API_ENDPOINT}/areas/#{postcode}\.json}).
          to_return(:body => results.to_json)
      end
    end
  end
end
