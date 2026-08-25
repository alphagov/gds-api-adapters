module GdsApi
  module TestHelpers
    module AssetManager
      ASSET_MANAGER_ENDPOINT = Plek.find("asset-manager")

      def stub_any_asset_manager_call
        stub_request(:any, %r{\A#{ASSET_MANAGER_ENDPOINT}}).to_return(status: 200)
      end

      def stub_asset_manager_isnt_available
        stub_request(:any, %r{\A#{ASSET_MANAGER_ENDPOINT}}).to_return(status: 503)
      end

      def stub_asset_manager_updates_any_asset(body = {})
        stub_request(:put, %r{\A#{ASSET_MANAGER_ENDPOINT}/assets})
          .to_return(body: body.to_json, status: 200)
      end

      def stub_asset_manager_deletes_any_asset(body = {})
        stub_request(:delete, %r{\A#{ASSET_MANAGER_ENDPOINT}/assets})
          .to_return(body: body.to_json, status: 200)
      end

      def stub_asset_manager_has_an_asset(id, atts, filename = "")
        response = atts.merge("_response_info" => { "status" => "ok" })

        stub_asset_manager_request_to_get_asset(id, response)
        stub_asset_manager_request_to_asset_media(id, filename)
      end

      def stub_asset_manager_request_to_get_asset(id, response)
        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}")
          .to_return(body: response.to_json, status: 200)
      end

      def stub_asset_manager_request_to_asset_media(id, filename)
        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/media/#{id}/#{filename}")
          .to_return(body: "Some file content", status: 200)
      end

      def stub_asset_manager_has_a_whitehall_media_asset(legacy_url_path, content)
        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/#{legacy_url_path}")
          .to_return(body: content, status: 200)
      end

      def stub_asset_manager_does_not_have_an_asset(id)
        response = {
          "_response_info" => { "status" => "not found" },
        }

        stub_request(:any, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}")
          .to_return(body: response.to_json, status: 404)
      end

      def stub_asset_manager_get_asset_forbidden(id)
        stub_request(:get, "#{ASSET_MANAGER_ENDPOINT}/assets/#{id}").to_return(status: 403)
      end

      # This can take a string of an exact url or a hash of options
      #
      # with a string:
      # `stub_asset_manager_create_asset("https://asset-manager/media/619ce797-b415-42e5-b2b1-2ffa0df52302/file.jpg")`
      #
      # with a hash:
      # `stub_asset_manager_create_asset(id: "20d04259-e3ae-4f71-8157-e6c843096e96", filename: "file.jpg")`
      # which would return a file url of "https://asset-manager/media/20d04259-e3ae-4f71-8157-e6c843096e96/file.jpg"
      #
      # with no argument
      #
      # `stub_asset_manager_create_asset`
      # which would return a file url of "https://asset-manager/media/0053adbf-0737-4923-9d8a-8180f2c723af/0d19136c4a94f07"
      def stub_asset_manager_create_asset(response_url = {}, response_body = {})
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return do
          if response_url.is_a?(String)
            file_url = response_url
          else
            options = {
              id: SecureRandom.uuid,
              filename: SecureRandom.hex(8),
            }.merge(response_url)

            file_url = "#{ASSET_MANAGER_ENDPOINT}/media/#{options[:id]}/#{options[:filename]}"
          end
          { body: response_body.merge(file_url:).to_json, status: 200 }
        end
      end

      def stub_asset_manager_receives_an_asset(response_url = {})
        warn <<~WARNING
          stub_asset_manager_receives_an_asset is deprecated and will be removed
          in a future version of gds-api-adapters. Replace calls to this method with
          stub_asset_manager_create_asset.
        WARNING

        stub_asset_manager_create_asset(response_url)
      end

      def stub_asset_manager_create_asset_too_large
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(status: 413)
      end

      def stub_asset_manager_create_asset_unprocessable(body = "")
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(body:, status: 422)
      end

      def stub_asset_manager_upload_failure
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets").to_return(status: 500)
      end

      def stub_asset_manager_update_asset(asset_id, body = {})
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}")
          .to_return(body: body.to_json, status: 200)
      end

      def stub_asset_manager_update_asset_forbidden(asset_id)
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 403)
      end

      def stub_asset_manager_update_asset_not_found(asset_id)
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 404)
      end

      def stub_asset_manager_update_asset_too_large(asset_id)
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 413)
      end

      def stub_asset_manager_update_asset_unprocessable(asset_id, body = "")
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(body:, status: 422)
      end

      def stub_asset_manager_update_asset_failure(asset_id)
        stub_request(:put, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 500)
      end

      def stub_asset_manager_delete_asset(asset_id, body = {})
        stub_request(:delete, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}")
          .to_return(body: body.to_json, status: 200)
      end

      def stub_asset_manager_delete_asset_forbidden(asset_id)
        stub_request(:delete, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}")
          .to_return(status: 403)
      end

      def stub_asset_manager_delete_asset_missing(asset_id)
        stub_request(:delete, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}")
          .to_return(status: 404)
      end

      def stub_asset_manager_delete_asset_failure(asset_id)
        stub_request(:delete, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}").to_return(status: 500)
      end

      def stub_asset_manager_restore_asset(asset_id, body = {})
        stub_request(:post, "#{ASSET_MANAGER_ENDPOINT}/assets/#{asset_id}/restore")
          .to_return(body: body.to_json, status: 200)
      end
    end
  end
end
