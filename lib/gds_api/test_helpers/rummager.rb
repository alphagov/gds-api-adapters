require 'json'
require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Rummager
      RUMMAGER_ENDPOINT = Plek.current.find('rummager')

      def stub_any_rummager_post
        stub_request(:post, %r{#{RUMMAGER_ENDPOINT}/documents})
      end

      def stub_any_rummager_post_with_queueing_enabled
        stub_request(:post, %r{#{RUMMAGER_ENDPOINT}/documents}) \
          .to_return(status: [202, "Accepted"])
      end

      def assert_rummager_posted_item(attributes)
        url = RUMMAGER_ENDPOINT + "/documents"
        assert_requested(:post, url) do |req|
          data = JSON.parse(req.body)
          attributes.to_a.all? do |key, value|
            data[key.to_s] == value
          end
        end
      end

      # @deprecated Rummager.delete_docment is deprecated, so is this stub!  Use `stub_any_rummager_delete_content`
      def stub_any_rummager_delete
        warn "stub_any_rummager_delete is deprecated, instead use: stub_any_rummager_delete_content"
        stub_request(:delete, %r{#{RUMMAGER_ENDPOINT}/documents/.*})
      end

      def stub_any_rummager_delete_content
        stub_request(:delete, %r{#{RUMMAGER_ENDPOINT}/content.*})
      end

      # @deprecated Rummager.delete_docment is deprecated, so is this stub!  Use `assert_rummager_deleted_content`
      def assert_rummager_deleted_item(id)
        warn "assert_rummager_deleted_item stub is deprecated, instead use: assert_rummager_deleted_content"

        if id =~ %r{^/}
          raise ArgumentError, 'Rummager id must not start with a slash'
        end
        assert_requested(:delete, %r{#{RUMMAGER_ENDPOINT}/documents/#{id}})
      end

      def assert_rummager_deleted_content(base_path)
        assert_requested(:delete, %r{#{RUMMAGER_ENDPOINT}/content.*#{base_path}})
      end

      def rummager_has_services_and_info_data_for_organisation
        stub_request_for(search_results_found)
        run_example_query
      end

      def rummager_has_no_services_and_info_data_for_organisation
        stub_request_for(no_search_results_found)
        run_example_query
      end

      def rummager_has_specialist_sector_organisations(sub_sector)
        stub_request_for(sub_sector_organisations_results)
        run_example_query
      end

      def rummager_has_no_policies_for_any_type
        stub_request(:get, %r{/unified_search.json})
          .to_return(body: no_search_results_found)
      end

      def rummager_has_policies_for_every_type(options = {})
        if count = options[:count]
          stub_request(:get, %r{/unified_search.json.*count=#{count}.*})
            .to_return(body: first_n_results(new_policies_results, n: count))
        else
          stub_request(:get, %r{/unified_search.json})
            .to_return(body: new_policies_results)
        end
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
