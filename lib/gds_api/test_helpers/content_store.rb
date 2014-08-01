require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module ContentStore
      include ContentItemHelpers

      CONTENT_STORE_ENDPOINT = Plek.current.find('content-store')

      def content_store_has_item(base_path, body = content_item_for_base_path(base_path), expires_in = 900)
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        body = body.to_json unless body.is_a?(String)
        stub_request(:get, url).to_return(status: 200, body: body, headers: {cache_control: "public, max-age=#{expires_in}", date: Time.now.httpdate})
      end

      def content_store_does_not_have_item(base_path)
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        stub_request(:get, url).to_return(status: 404, headers: {})
      end

      def content_store_isnt_available
        stub_request(:any, /#{CONTENT_STORE_ENDPOINT}\/.*/).to_return(:status => 503)
      end
    end
  end
end
