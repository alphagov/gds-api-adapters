module GdsApi
  module TestHelpers
    module AssetManager

      ASSET_ENDPOINT = Plek.current.find('asset-manager')

      def asset_manager_has_an_asset(id, atts)
        response = atts.merge({
          "_response_info" => { "status" => "ok" }
        })

        stub_request(:get, "#{ASSET_ENDPOINT}/assets/#{id}")
          .to_return(:body => response.to_json, :status => 200)
      end

      def asset_manager_does_not_have_an_asset(id)
        response = {
          "_response_info" => { "status" => "not found" }
        }

        stub_request(:get, "#{ASSET_ENDPOINT}/assets/#{id}")
          .to_return(:body => response.to_json, :status => 404)
      end
    end
  end
end
