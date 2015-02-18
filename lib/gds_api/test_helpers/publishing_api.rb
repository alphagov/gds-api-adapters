require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/intent_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module PublishingApi
      include IntentHelpers

      PUBLISHING_API_ENDPOINT = Plek.current.find('publishing-api')

      def stub_publishing_api_put_item(base_path, body = content_item_for_base_path_in_a_publish_request(base_path))
        raise ArgumentError, "Strings are no longer supported for response bodies" if body.is_a?(String)

        url = PUBLISHING_API_ENDPOINT + "/content" + base_path
        response_body = body.dup
        response_body["base_path"] = base_path
        stub_request(:put, url).with(body: body).to_return(status: 201, body: response_body.to_json, headers: {})
      end

      def stub_publishing_api_put_intent(base_path, body = intent_for_base_path(base_path))
        raise ArgumentError, "Strings are no longer supported for response bodies" if body.is_a?(String)

        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        response_body = body.dup
        response_body["base_path"] = base_path
        stub_request(:put, url).with(body: body).to_return(status: 201, body: response_body.to_json, headers: {})
      end

      def stub_publishing_api_destroy_intent(base_path)
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        response_body = {base_path: base_path}.to_json
        stub_request(:delete, url).to_return(status: 201, body: response_body)
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

      def content_item_for_base_path_in_a_publish_request(base_path)
        {
          "title" => titleize_base_path(base_path),
          "description" => "Description for #{base_path}",
          "format" => "guide",
          "need_ids" => ["100001"],
          "public_updated_at" => "2014-05-06T12:01:00+00:00",
          "details" => {
            "body" => "Some content for #{base_path}",
          }
        }
      end

      def titleize_base_path(base_path, options = {})
        if options[:title_case]
          base_path.gsub("-", " ").gsub(/\b./) {|m| m.upcase }
        else
          base_path.gsub(%r{[-/]}, " ").strip.capitalize
        end
      end
    end
  end
end
