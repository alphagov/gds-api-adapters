require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Imminence
      def imminence_has_places(latitude, longitude, details)
        response = JSON.dump(details['details'])

        ["http", "https"].each { |protocol|
          stub_request(:get, "#{protocol}://imminence.test.alphagov.co.uk/places/#{details['slug']}.json").
          with(:query => {"lat" => latitude, "lng" => longitude, "limit" => "5"}).
          to_return(:status => 200, :body => response, :headers => {})
        }
      end
    end
  end
end
