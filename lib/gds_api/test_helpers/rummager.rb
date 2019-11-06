require "json"
require "gds_api/test_helpers/json_client_helper"
require "gds_api/test_helpers/search"

module GdsApi
  module TestHelpers
    module Rummager
      include GdsApi::TestHelpers::Search

      def self.included(_base)
        warn "GdsApi::TestHelpers::Rummager is deprecated.  Use GdsApi::TestHelpers::Search instead."
      end

      RUMMAGER_ENDPOINT = SEARCH_ENDPOINT

      def stub_any_rummager_post(*args)
        stub_any_search_post(*args)
      end

      def assert_rummager_posted_item(*args)
        assert_search_posted_item(*args)
      end

      def stub_any_rummager_search(*args)
        stub_any_search(*args)
      end

      def stub_any_rummager_search_to_return_no_results(*args)
        stub_any_search_to_return_no_results(*args)
      end

      def assert_rummager_search(*args)
        assert_search(*args)
      end

      def stub_any_rummager_delete(*args)
        stub_any_search_delete(*args)
      end

      def stub_any_rummager_delete_content(*args)
        stub_any_search_delete_content(*args)
      end

      def assert_rummager_deleted_item(*args)
        assert_search_deleted_item(*args)
      end

      def assert_rummager_deleted_content(*args)
        assert_search_deleted_content(*args)
      end

      def stub_rummager_has_services_and_info_data_for_organisation(*args)
        stub_search_has_services_and_info_data_for_organisation(*args)
      end

      def stub_rummager_has_no_services_and_info_data_for_organisation(*args)
        stub_search_has_no_services_and_info_data_for_organisation(*args)
      end

      def stub_rummager_has_specialist_sector_organisations(*args)
        stub_rummager_has_specialist_sector_organisations(*args)
      end

      def stub_rummager_has_no_policies_for_any_type(*args)
        stub_search_has_no_policies_for_any_type(*args)
      end

      def stub_rummager_has_policies_for_every_type(*args)
        stub_search_has_policies_for_every_type(*args)
      end

      def rummager_has_services_and_info_data_for_organisation(*args)
        stub_rummager_has_services_and_info_data_for_organisation(*args)
      end

      def rummager_has_no_services_and_info_data_for_organisation(*args)
        stub_rummager_has_no_services_and_info_data_for_organisation(*args)
      end

      def rummager_has_specialist_sector_organisations(*args)
        stub_rummager_has_specialist_sector_organisations(*args)
      end

      def rummager_has_no_policies_for_any_type(*args)
        stub_rummager_has_no_policies_for_any_type(*args)
      end

      def rummager_has_policies_for_every_type(*args)
        stub_rummager_has_policies_for_every_type(*args)
      end
    end
  end
end
