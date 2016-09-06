require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module ContentStore
      include ContentItemHelpers

      # Stubs a content item in the content store.
      # The following options can be passed in:
      #
      #   :max_age  will set the max-age of the Cache-Control header in the response. Defaults to 900
      #   :private  if true, the Cache-Control header will include the "private" directive. By default it
      #             will include "public"
      #   :draft    will point to the draft content store if set to true

      def content_store_endpoint(draft=false)
        draft ? Plek.current.find('draft-content-store') : Plek.current.find('content-store')
      end

      def content_store_has_item(base_path, body = content_item_for_base_path(base_path), options = {})
        max_age = options.fetch(:max_age, 900)
        visibility = options[:private] ? "private" : "public"
        url = content_store_endpoint(options[:draft]) + "/content" + base_path
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

      def content_store_does_not_have_item(base_path, options = {})
        url = content_store_endpoint(options[:draft]) + "/content" + base_path
        stub_request(:get, url).to_return(status: 404, headers: {})

        url = content_store_endpoint(options[:draft]) + "/incoming-links" + base_path
        stub_request(:get, url).to_return(status: 404, headers: {})
      end

      # Content store has gone item
      #
      # Stubs a content item in the content store to respond with 410 HTTP Status Code and response body with 'format' set to 'gone'.
      #
      # @param base_path [String]
      # @param body [Hash]
      # @param options [Hash]
      # @option options [String] draft Will point to the draft content store if set to true
      #
      # @example
      #
      #   content_store.content_store_has_gone_item('/sample-slug')
      #
      #   # Will return HTTP Status Code 410 and the following response body:
      #   {
      #     "title" => nil,
      #     "description" => nil,
      #     "format" => "gone",
      #     "schema_name" => "gone",
      #     "public_updated_at" => nil,
      #     "base_path" => "/sample-slug",
      #     "withdrawn_notice" => {},
      #     "details" => {}
      #   }
      def content_store_has_gone_item(base_path, body = gone_content_item_for_base_path(base_path), options = {})
        url = content_store_endpoint(options[:draft]) + "/content" + base_path
        body = body.to_json unless body.is_a?(String)

        stub_request(:get, url).to_return(
          status: 410,
          body: body,
          headers: {}
        )
      end

      def content_store_isnt_available
        stub_request(:any, /#{content_store_endpoint}\/.*/).to_return(:status => 503)
      end

      def content_item_for_base_path(base_path)
        super.merge({ "base_path" => base_path })
      end

      def content_store_has_incoming_links(base_path, links)
        url = content_store_endpoint + "/incoming-links" + base_path
        body = links.to_json

        stub_request(:get, url).to_return(body: body)
      end
    end
  end
end
