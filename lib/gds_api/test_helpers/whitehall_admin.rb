module GdsApi
  module TestHelpers
    module WhitehallAdmin
      WHITEHALL_ADMIN_ENDPOINT = "#{Plek.current.find('whitehall-admin')}/government/admin".freeze

      def stub_whitehall_admin_export_data_has_content_ids(params, ids = nil)
        query_params = Rack::Utils.build_nested_query(params)

        stub_request(:get, "#{@base_api_url}/export-data?#{query_params}")
          .to_return(status: 200, body: ids.to_json)
      end
    end
  end
end
