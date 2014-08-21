require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module CollectionsApi

      COLLECTIONS_API_ENDPOINT = Plek.current.find('collections-api')

      def collections_api_has_curated_lists_for(base_path)
        url = COLLECTIONS_API_ENDPOINT + "/curated-lists" + base_path

        stub_request(:get, url).to_return(
          status: 200,
          body: body.merge(base_path: base_path).to_json,
        )
      end

      def collections_api_has_no_curated_lists_for(base_path)
        url = COLLECTIONS_API_ENDPOINT + "/curated-lists" + base_path

        stub_request(:get, url).to_return(
          status: 404
        )
      end

      private

      def body
        {
          details: {
            groups: [
              # Curated content excluding untagged content
              {
                name: "Oil rigs",
                contents: [
                  "http://example.com/api/oil-rig-safety-requirements.json",
                  "http://example.com/api/oil-rig-staffing.json"
                ]
              },
              {
                name: "Piping",
                contents: [
                  "http://example.com/api/undersea-piping-restrictions.json"
                ]
              },
              # Uncurated content
              {
                name: "Other",
                contents: [
                  "http://example.com/api/north-sea-shipping-lanes.json"
                ]
              }
            ]
          }
        }
      end
    end
  end
end
