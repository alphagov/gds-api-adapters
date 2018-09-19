module GdsApi
  module TestHelpers
    module AssetManager
      ASSET_MANAGER_ENDPOINT = Plek.current.find('asset-manager')

      def asset_manager_has_an_asset(id, atts)
        response = atts.merge("_response_info" => { "status" => "ok" })

        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}")
          .to_return(body: response.to_json, status: 200)
      end

      def asset_manager_has_a_whitehall_asset(legacy_url_path, atts)
        response = atts.merge("_response_info" => { "status" => "ok" })

        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/whitehall_assets/#{legacy_url_path}")
          .to_return(body: response.to_json, status: 200)
      end

      def asset_manager_does_not_have_an_asset(id)
        response = {
          "_response_info" => { "status" => "not found" }
        }

        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}")
          .to_return(body: response.to_json, status: 404)
      end

      def asset_manager_does_not_have_a_whitehall_asset(legacy_url_path)
        response = {
          "_response_info" => { "status" => "not found" }
        }

        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/whitehall_assets/#{legacy_url_path}")
          .to_return(body: response.to_json, status: 404)
      end

      def asset_manager_receives_an_asset(response_url)
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(body: { file_url: response_url }.to_json, status: 200)
      end

      def asset_manager_upload_failure
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(status: 500)
      end

      def asset_manager_update_asset(asset_id, body = {})
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}")
          .to_return(body: body.to_json, status: 200)
      end

      def asset_manager_update_failure(asset_id)
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 500)
      end

      def asset_manager_delete_asset(asset_id, body = {})
        stub_request(:delete, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}")
          .to_return(body: body.to_json, status: 200)
      end

      def asset_manager_delete_asset_failure(asset_id)
        stub_request(:delete, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 500)
      end
    end
  end
end
