require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Rummager
      def rummager_has_services_and_info_data_for_organisation
        stub_request(:get, /example.com\/unified_search/).to_return(body: search_results)
        client.unified_search(example_query)
      end

      private

      def search_results
        File.read(
          File.expand_path(
            "../../../../test/fixtures/services_and_info_fixture.json",
            __FILE__
          )
        )
      end

      def client
        GdsApi::Rummager.new("http://example.com")
      end

      def example_query
        {
          filter_organisations: ["an-organisation-slug"],
          facet_specialist_sectors: "1000,examples:4,example_scope:global"
        }
      end
    end
  end
end
