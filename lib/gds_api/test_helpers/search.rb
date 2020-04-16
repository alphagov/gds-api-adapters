require "json"
require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module Search
      SEARCH_ENDPOINT = Plek.current.find("search")

      def stub_any_search_post(index: nil)
        if index
          stub_request(:post, %r{#{SEARCH_ENDPOINT}/#{index}/documents})
            .to_return(status: [202, "Accepted"])
        else
          stub_request(:post, %r{#{SEARCH_ENDPOINT}/documents})
            .to_return(status: [202, "Accepted"])
        end
      end

      def assert_search_posted_item(attributes, index: nil, **options)
        url = if index
          SEARCH_ENDPOINT + "/#{index}/documents"
        else
          SEARCH_ENDPOINT + "/documents"
        end

        assert_requested(:post, url, **options) do |req|
          data = JSON.parse(req.body)
          attributes.to_a.all? do |key, value|
            data[key.to_s] == value
          end
        end
      end

      def stub_any_search
        stub_request(:get, %r{#{SEARCH_ENDPOINT}/search.json})
      end

      def stub_any_search_to_return_no_results
        stub_any_search.to_return(body: { results: [] }.to_json)
      end

      def assert_search(options)
        assert_requested :get, "#{SEARCH_ENDPOINT}/search.json", **options
      end

      def stub_any_search_delete(index: nil)
        if index
          stub_request(:delete, %r{#{SEARCH_ENDPOINT}/#{index}/documents/.*})
        else
          # use search-api's default index
          stub_request(:delete, %r{#{SEARCH_ENDPOINT}/documents/.*})
        end
      end

      def stub_any_search_delete_content
        stub_request(:delete, %r{#{SEARCH_ENDPOINT}/content.*})
      end

      def assert_search_deleted_item(id, index: nil, **options)
        if id =~ %r{^/}
          raise ArgumentError, "Search id must not start with a slash"
        end

        if index
          assert_requested(
            :delete,
            %r{#{SEARCH_ENDPOINT}/#{index}/documents/#{id}},
            **options,
          )
        else
          assert_requested(
            :delete,
            %r{#{SEARCH_ENDPOINT}/documents/#{id}},
            **options,
          )
        end
      end

      def assert_search_deleted_content(base_path, **options)
        assert_requested(
          :delete,
          %r{#{SEARCH_ENDPOINT}/content.*#{base_path}},
          **options,
        )
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

      def old_policies_results
        File.read(
          File.expand_path(
            "../../../test/fixtures/old_policies_for_dwp.json",
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
