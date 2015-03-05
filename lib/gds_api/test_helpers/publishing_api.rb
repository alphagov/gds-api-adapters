require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'gds_api/test_helpers/intent_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module PublishingApi
      include ContentItemHelpers
      include IntentHelpers

      PUBLISHING_API_ENDPOINT = Plek.current.find('publishing-api')

      def stub_publishing_api_put_draft_item(base_path, body = content_item_for_base_path(base_path))
        stub_publishing_api_put_item(base_path, body, '/draft-content')
      end

      def stub_publishing_api_put_item(base_path, body = content_item_for_base_path(base_path), resource_path = '/content')
        url = PUBLISHING_API_ENDPOINT + resource_path + base_path
        stub_request(:put, url).with(body: body).to_return(status: 201, body: '{}', headers: {})
      end

      def stub_publishing_api_put_intent(base_path, body = intent_for_base_path(base_path))
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        body = body.to_json unless body.is_a?(String)
        stub_request(:put, url).with(body: body).to_return(status: 201, body: '{}', headers: {})
      end

      def stub_publishing_api_destroy_intent(base_path)
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        stub_request(:delete, url).to_return(status: 201, body: '{}')
      end

      def stub_default_publishing_api_put()
        stub_request(:put, %r{\A#{PUBLISHING_API_ENDPOINT}/content})
      end

      def stub_default_publishing_api_put_intent()
        stub_request(:put, %r{\A#{PUBLISHING_API_ENDPOINT}/publish-intent})
      end

      def assert_publishing_api_put_item(base_path, attributes = {}, times = 1)
        url = PUBLISHING_API_ENDPOINT + "/content" + base_path
        assert_publishing_api_put(url, attributes, times)
      end

      def assert_publishing_api_put_intent(base_path, attributes = {}, times = 1)
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        assert_publishing_api_put(url, attributes, times)
      end

      def assert_publishing_api_put(url, attributes = {}, times = 1)
        if attributes.empty?
          assert_requested(:put, url, times: times)
        else
          assert_requested(:put, url, times: times) do |req|
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
