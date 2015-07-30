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

      def stub_default_publishing_api_put_draft()
        stub_request(:put, %r{\A#{PUBLISHING_API_ENDPOINT}/draft-content})
      end

      def stub_default_publishing_api_put_intent()
        stub_request(:put, %r{\A#{PUBLISHING_API_ENDPOINT}/publish-intent})
      end

      def assert_publishing_api_put_item(base_path, attributes_or_matcher = {}, times = 1)
        url = PUBLISHING_API_ENDPOINT + "/content" + base_path
        assert_publishing_api_put(url, attributes_or_matcher, times)
      end

      def assert_publishing_api_put_draft_item(base_path, attributes_or_matcher = {}, times = 1)
        url = PUBLISHING_API_ENDPOINT + "/draft-content" + base_path
        assert_publishing_api_put(url, attributes_or_matcher, times)
      end

      def assert_publishing_api_put_intent(base_path, attributes_or_matcher = {}, times = 1)
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        assert_publishing_api_put(url, attributes_or_matcher, times)
      end

      def assert_publishing_api_put(url, attributes_or_matcher = {}, times = 1)
        if attributes_or_matcher.is_a?(Hash)
          matcher = attributes_or_matcher.empty? ? nil : request_json_matching(attributes_or_matcher)
        else
          matcher = attributes_or_matcher
        end

        if matcher
          assert_requested(:put, url, times: times, &matcher)
        else
          assert_requested(:put, url, times: times)
        end
      end

      def request_json_matching(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          required_attributes.to_a.all? { |key, value| data[key.to_s] == value }
        end
      end

      def request_json_including(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          values_match_recursively(required_attributes, data)
        end
      end

      def publishing_api_isnt_available
        stub_request(:any, /#{PUBLISHING_API_ENDPOINT}\/.*/).to_return(:status => 503)
      end

    private
      def values_match_recursively(expected_value, actual_value)
        case expected_value
        when Hash
          return false unless actual_value.is_a?(Hash)
          expected_value.all? do |expected_sub_key, expected_sub_value|
            actual_value.has_key?(expected_sub_key.to_s) &&
              values_match_recursively(expected_sub_value, actual_value[expected_sub_key.to_s])
          end
        when Array
          return false unless actual_value.is_a?(Array)
          return false unless actual_value.size == expected_value.size
          expected_value.each.with_index.all? do |expected_sub_value, i|
            values_match_recursively(expected_sub_value, actual_value[i])
          end
        else
          expected_value == actual_value
        end
      end
    end
  end
end
