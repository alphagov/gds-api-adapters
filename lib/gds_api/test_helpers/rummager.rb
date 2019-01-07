require 'json'
require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Rummager
      RUMMAGER_ENDPOINT = Plek.current.find('rummager')

      def stub_any_rummager_post(index: nil)
        if index
          stub_request(:post, %r{#{RUMMAGER_ENDPOINT}/#{index}/documents})
            .to_return(status: [202, "Accepted"])
        else
          stub_request(:post, %r{#{RUMMAGER_ENDPOINT}/documents})
            .to_return(status: [202, "Accepted"])
        end
      end

      def assert_rummager_posted_item(attributes, index: nil, **options)
        if index
          url = RUMMAGER_ENDPOINT + "/#{index}/documents"
        else
          url = RUMMAGER_ENDPOINT + "/documents"
        end

        assert_requested(:post, url, **options) do |req|
          data = JSON.parse(req.body)
          attributes.to_a.all? do |key, value|
            data[key.to_s] == value
          end
        end
      end

      def stub_any_rummager_search
        stub_request(:get, %r{#{RUMMAGER_ENDPOINT}/search.json})
      end

      def stub_any_rummager_search_to_return_no_results
        stub_any_rummager_search.to_return(body: { results: [] }.to_json)
      end

      def assert_rummager_search(options)
        assert_requested :get, "#{RUMMAGER_ENDPOINT}/search.json", **options
      end

      def stub_any_rummager_delete(index: nil)
        if index
          stub_request(:delete, %r{#{RUMMAGER_ENDPOINT}/#{index}/documents/.*})
        else
          # use rummager's default index
          stub_request(:delete, %r{#{RUMMAGER_ENDPOINT}/documents/.*})
        end
      end

      def stub_any_rummager_delete_content
        stub_request(:delete, %r{#{RUMMAGER_ENDPOINT}/content.*})
      end

      def assert_rummager_deleted_item(id, index: nil, **options)
        if id =~ %r{^/}
          raise ArgumentError, 'Rummager id must not start with a slash'
        end
        if index
          assert_requested(
            :delete,
            %r{#{RUMMAGER_ENDPOINT}/#{index}/documents/#{id}},
            **options
          )
        else
          assert_requested(
            :delete,
            %r{#{RUMMAGER_ENDPOINT}/documents/#{id}},
            **options
          )
        end
      end

      def assert_rummager_deleted_content(base_path, **options)
        assert_requested(
          :delete,
          %r{#{RUMMAGER_ENDPOINT}/content.*#{base_path}},
          **options
        )
      end

      def rummager_has_services_and_info_data_for_organisation
        stub_request_for(search_results_found)
        run_example_query
      end

      def rummager_has_no_services_and_info_data_for_organisation
        stub_request_for(no_search_results_found)
        run_example_query
      end

      def rummager_has_specialist_sector_organisations(_sub_sector)
        stub_request_for(sub_sector_organisations_results)
        run_example_query
      end

      def rummager_has_no_policies_for_any_type
        stub_request(:get, %r{/search.json})
          .to_return(body: no_search_results_found)
      end

      def rummager_has_policies_for_every_type(options = {})
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

      def new_policies_results
        File.read(
          File.expand_path(
            "../../../../test/fixtures/new_policies_for_dwp.json",
            __FILE__
          )
        )
      end

      def old_policies_results
        File.read(
          File.expand_path(
            "../../../../test/fixtures/old_policies_for_dwp.json",
            __FILE__
          )
        )
      end

      def first_n_results(results, options)
        n = options[:n]
        results = JSON.parse(results)
        results["results"] = results["results"][0...n]

        results.to_json
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
