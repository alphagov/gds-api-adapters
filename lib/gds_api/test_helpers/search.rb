require "json"
require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module Search
      SEARCH_ENDPOINT = Plek.find("search-api")

      def stub_any_search
        stub_request(:get, %r{#{SEARCH_ENDPOINT}/search.json})
      end

      def stub_any_search_to_return_no_results
        stub_any_search.to_return(body: { results: [] }.to_json)
      end

      def assert_search(options)
        assert_requested :get, "#{SEARCH_ENDPOINT}/search.json", **options
      end

      def stub_search_has_services_and_info_data_for_organisation
        stub_request_for(search_results_found)
        run_example_query
      end

      def stub_search_has_no_services_and_info_data_for_organisation
        stub_request_for(no_search_results_found)
        run_example_query
      end

      def stub_search_has_specialist_sector_organisations(_sub_sector)
        stub_request_for(sub_sector_organisations_results)
        run_example_query
      end

      def stub_search_has_no_policies_for_any_type
        stub_request(:get, %r{/search.json})
          .to_return(body: no_search_results_found)
      end

      def stub_search_has_policies_for_every_type(options = {})
        if options[:count]
          stub_request(:get, %r{/search.json.*count=#{options[:count]}.*})
            .to_return(body: first_n_results(new_policies_results, n: options[:count]))
        else
          stub_request(:get, %r{/search.json})
            .to_return(body: new_policies_results)
        end
      end

    private

      def stub_request_for(result_set)
        stub_request(:get, /example.com\/search/).to_return(body: result_set)
      end

      def run_example_query
        client.search(example_query)
      end

      def search_results_found
        File.read(
          File.expand_path(
            "../../../test/fixtures/services_and_info_fixture.json",
            __dir__,
          ),
        )
      end

      def no_search_results_found
        File.read(
          File.expand_path(
            "../../../test/fixtures/no_services_and_info_data_found_fixture.json",
            __dir__,
          ),
        )
      end

      def sub_sector_organisations_results
        File.read(
          File.expand_path(
            "../../../test/fixtures/sub_sector_organisations.json",
            __dir__,
          ),
        )
      end

      def new_policies_results
        File.read(
          File.expand_path(
            "../../../test/fixtures/new_policies_for_dwp.json",
            __dir__,
          ),
        )
      end

      def first_n_results(results, options)
        n = options[:n]
        results = JSON.parse(results)
        results["results"] = results["results"][0...n]

        results.to_json
      end

      def client
        GdsApi::Search.new("http://example.com")
      end

      def example_query
        {
          filter_organisations: %w[an-organisation-slug],
          facet_specialist_sectors: "1000,examples:4,example_scope:global,order:value.title",
        }
      end
    end
  end
end
