require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module NeedApi
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      NEED_API_ENDPOINT = Plek.current.find('needapi')

      def need_api_has_organisations(organisations)
        url = NEED_API_ENDPOINT + "/organisations"
        orgs = organisations.map do |o|
          { "id" => o,
            "name" => o.split('-').map(&:capitalize).join(' ')
          }
        end
        stub_request(:get, url).to_return(status: 200, body: orgs.to_json, headers: {})
      end
    end
  end
end
