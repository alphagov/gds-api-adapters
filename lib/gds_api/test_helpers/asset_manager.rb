module GdsApi
  module TestHelpers
    module AssetManager
      ASSET_MANAGER_ENDPOINT = Plek.current.find('asset-manager')

      def asset_manager_has_an_asset(id, atts)
        response = atts.merge("_response_info" => { "status" => "ok" })

        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}")
          .to_return(body: response.to_json, status: 200)
      end

      def asset_manager_does_not_have_an_asset(id)
        response = {
          "_response_info" => { "status" => "not found" }
        }

        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}")
          .to_return(body: response.to_json, status: 404)
      end

      def asset_manager_receives_an_asset(response_url)
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(body: { file_url: response_url }.to_json, status: 200)
      end

      def asset_manager_upload_failure
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(status: 500)
      end
    end
  end
end
