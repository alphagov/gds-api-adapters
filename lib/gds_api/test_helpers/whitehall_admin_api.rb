module GdsApi
  module TestHelpers
    module WhitehallAdminApi
      WHITEHALL_ADMIN_API_ENDPOINT = "#{Plek.current.find("whitehall-admin")}/government/admin/api"

      def stub_all_whitehall_admin_api_requests
        stub_request(:any, %r|^#{WHITEHALL_ADMIN_API_ENDPOINT}|)
      end

      def assert_whitehall_received_reindex_request_for(slug)
        assert_requested(
          :post,
          "#{WHITEHALL_ADMIN_API_ENDPOINT}/reindex-specialist-sector-editions/#{slug}"
        )
      end
    end
  end
end
