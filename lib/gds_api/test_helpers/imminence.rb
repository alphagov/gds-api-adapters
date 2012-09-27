require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Imminence
      IMMINENCE_API_HOST = "imminence.test.alphagov.co.uk"
      def imminence_has_places(latitude, longitude, details)
        response = JSON.dump(details['details'])

        ["http", "https"].each do |protocol|
          stub_request(:get, "#{protocol}://#{IMMINENCE_API_HOST}/places/#{details['slug']}.json").
          with(:query => {"lat" => latitude, "lng" => longitude, "limit" => "5"}).
          to_return(:status => 200, :body => response, :headers => {})
        end
      end

      def imminence_has_business_support_schemes(facets_hash, schemes)
        response = schemes.to_json(only: [:business_support_identifier, :title])
        stub_request(:get, "https://#{IMMINENCE_API_HOST}/business_support_schemes.json").
        with(query: facets_hash).
        to_return(status: 200, body: response, headers: {})
      end
    end
  end
end
