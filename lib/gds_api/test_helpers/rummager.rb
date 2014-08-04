require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Rummager
      def rummager_has_services_and_info_data_for_organisation
        stub_request_for search_results_found
        run_example_query
      end

      def rummager_has_no_services_and_info_data_for_organisation
        stub_request_for no_search_results_found
        run_example_query
      end

      def rummager_has_specialist_sector_organisations(sub_sector)
        stub_request_for sub_sector_organisations_results
        run_example_query
      end

    private
      def stub_request_for(result_set)
        stub_request(:get, /example.com\/unified_search/).to_return(body: result_set)
      end

      def run_example_query
        client.unified_search(example_query)
      end

      def search_results_found
        File.read(
          File.expand_path(
            "../../../../test/fixtures/services_and_info_fixture.json",
            __FILE__
          )
        )
      end

      def no_search_results_found
        File.read(
          File.expand_path(
            "../../../../test/fixtures/no_services_and_info_data_found_fixture.json",
            __FILE__
          )
        )
      end

      def sub_sector_organisations_results
        File.read(
          File.expand_path(
            "../../../../test/fixtures/sub_sector_organisations.json",
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
          facet_specialist_sectors: "1000,examples:4,example_scope:global,order:value.title"
        }
      end
    end
  end
end
