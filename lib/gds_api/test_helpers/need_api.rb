require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module NeedApi
      include GdsApi::TestHelpers::CommonResponses

      NEED_API_ENDPOINT = Plek.current.find('need-api')

      def need_api_has_organisations(organisations)
        url = NEED_API_ENDPOINT + "/organisations"

        body = response_base.merge(
          "organisations" => organisations.map {|id, name|
            {
              "id" => id,
              "name" => name
            }
          }
        )
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end
    end
  end
end
