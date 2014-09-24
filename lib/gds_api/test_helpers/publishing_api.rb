require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module PublishingApi
      include ContentItemHelpers

      PUBLISHING_API_ENDPOINT = Plek.current.find('publishing-api')

      def stub_publishing_api_put_item(base_path, body = content_item_for_base_path(base_path))
        url = PUBLISHING_API_ENDPOINT + "/content" + base_path
        body = body.to_json unless body.is_a?(String)
        stub = stub_request(:put, url)
        if body
          body.to_json unless body.is_a?(String)
          stub.with(body: body)
        end
        stub.to_return(status: 201, body: body, headers: {})
      end

      def stub_default_publishing_api_put()
        stub_request(:put, %r{\A#{PUBLISHING_API_ENDPOINT}/content})
      end

      def assert_publishing_api_put_item(base_path, attributes = {})
        url = PUBLISHING_API_ENDPOINT + "/content" + base_path
        if attributes.empty?
          assert_requested(:put, url)
        else
          assert_requested(:put, url) do |req|
            data = JSON.parse(req.body)
            attributes.to_a.all? do |key, value|
              data[key.to_s] == value
            end
          end
        end
      end

      def publishing_api_isnt_available
        stub_request(:any, /#{PUBLISHING_API_ENDPOINT}\/.*/).to_return(:status => 503)
      end
    end
  end
end
