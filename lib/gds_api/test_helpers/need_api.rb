require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module NeedApi
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      NEED_API_ENDPOINT = Plek.current.find('needapi')

      def need_api_has_organisations(organisation_ids)
        url = NEED_API_ENDPOINT + "/organisations"
        orgs = organisation_ids.map do |k,v|
          { "id" => k,
            "name" => v
          }
        end
        stub_request(:get, url).to_return(status: 200, body: orgs.to_json, headers: {})
      end
    end
  end
end
