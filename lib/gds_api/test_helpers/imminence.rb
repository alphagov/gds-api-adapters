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

      def imminence_has_business_support_schemes(facets_hash, schemes)
        results = {
          "_response_info" => {"status" => "ok"},
          "description" => "Business Support Schemes!",
          "total" => schemes.size, "startIndex" => 1, "pageSize" => schemes.size, "currentPage" => 1, "pages" => 1,
          "results" => schemes
        }

        stub_request(:get, "#{IMMINENCE_API_ENDPOINT}/business_support_schemes.json").
          with(query: facets_hash).
          to_return(status: 200, body: results.to_json, headers: {})
      end

      # Stubs out all bussiness_support_schemes requests to return an ampty set of results.
      # Requests stubbed with the above method will take precedence over this.
      def stub_imminence_default_business_support_schemes
        empty_results = {
          "_response_info" => {"status" => "ok"},
          "description" => "Business Support Schemes!",
          "total" => 0, "startIndex" => 1, "pageSize" => 0, "currentPage" => 1, "pages" => 1,
          "results" => []
        }

        stub_request(:get, %r{\A#{IMMINENCE_API_ENDPOINT}/business_support_schemes\.json}).
          to_return(:body => empty_results.to_json)
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
