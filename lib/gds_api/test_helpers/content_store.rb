require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module ContentStore
      include ContentItemHelpers

      CONTENT_STORE_ENDPOINT = Plek.current.find('content-store')

      # Stubs a content item in the content store.
      # The following options can be passed in:
      #
      #   :max_age  will set the max-age of the Cache-Control header in the response. Defaults to 900
      #   :private  if true, the Cache-Control header will include the "private" directive. By default it
      #             will include "public"
      def content_store_has_item(base_path, body = content_item_for_base_path(base_path), options = {})
        max_age = options.fetch(:max_age, 900)
        visibility = options[:private] ? "private" : "public"
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        body = body.to_json unless body.is_a?(String)

        stub_request(:get, url).to_return(
          status: 200,
          body: body,
          headers: {
            cache_control: "#{visibility}, max-age=#{max_age}",
            date: Time.now.httpdate
          }
        )
      end

      def content_store_does_not_have_item(base_path)
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        stub_request(:get, url).to_return(status: 404, headers: {})

        url = CONTENT_STORE_ENDPOINT + "/incoming-links" + base_path
        stub_request(:get, url).to_return(status: 404, headers: {})
      end

      def content_store_isnt_available
        stub_request(:any, /#{CONTENT_STORE_ENDPOINT}\/.*/).to_return(:status => 503)
      end

      def content_item_for_base_path(base_path)
        super.merge({ "base_path" => base_path })
      end

      def content_store_has_incoming_links(base_path, links)
        url = CONTENT_STORE_ENDPOINT + "/incoming-links" + base_path
        body = links.to_json

        stub_request(:get, url).to_return(body: body)
      end
    end
  end
end
