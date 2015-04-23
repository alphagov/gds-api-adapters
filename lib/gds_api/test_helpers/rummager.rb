require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Rummager
      def stub_any_rummager_post
        stub_request(:post, %r{#{Plek.new.find('search')}/documents})
      end

      def stub_any_rummager_post_with_queueing_enabled
        stub_request(:post, %r{#{Plek.new.find('search')}/documents}) \
          .to_return(status: [202, "Accepted"])
      end

      def assert_rummager_posted_item(attributes)
        url = Plek.new.find('search') + "/documents"
        assert_requested(:post, url) do |req|
          data = JSON.parse(req.body)
          attributes.to_a.all? do |key, value|
            data[key.to_s] == value
          end
        end
      end

      def stub_any_rummager_delete
        stub_request(:delete, %r{#{Plek.new.find('search')}/documents/.*})
      end

      def assert_rummager_deleted_item(id)
        if id =~ %r{^/}
          raise ArgumentError, 'Rummager id must not start with a slash'
        end
        stub_request(:delete, %r{#{Plek.new.find('search')}/documents/#{id}})
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

      def rummager_has_no_policies_for_any_organisation
        stub_request(:get, %r{/unified_search.json})
          .to_return(body: no_search_results_found)
      end

      def rummager_has_four_new_policies_for_every_organisation
        stub_request(:get, %r{/unified_search.json})
          .to_return(body: four_new_policies_results)
      end

      def rummager_has_four_old_policies_for_every_organisation
        stub_request(:get, %r{/unified_search.json})
          .to_return(body: four_old_policies_results)
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

      def four_new_policies_results
        File.read(
          File.expand_path(
            "../../../../test/fixtures/4_new_policies_for_dwp.json",
            __FILE__
          )
        )
      end

      def four_old_policies_results
        File.read(
          File.expand_path(
            "../../../../test/fixtures/4_old_policies_for_dwp.json",
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
