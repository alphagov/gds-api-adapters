require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'gds_api/test_helpers/intent_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module PublishingApiV2
      include ContentItemHelpers

      PUBLISHING_API_V2_ENDPOINT = Plek.current.find('publishing-api') + '/v2'

      def stub_publishing_api_put_content(content_id, body)
        stub_publishing_api_put(content_id, body, '/content')
      end

      def stub_publishing_api_put_links(content_id, body)
        stub_publishing_api_put(content_id, body, '/links')
      end

      def stub_publishing_api_publish(content_id, body)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/publish"
        stub_request(:post, url).with(body: body).to_return(status: 200, body: '{}', headers: {"Content-Type" => "application/json; charset=utf-8"})
      end

      def stub_publishing_api_put_content_links_and_publish(body, content_id = nil, publish_options = nil)
        content_id ||= body[:content_id]
        publish_options ||= { update_type: { update_type: body[:update_type], locale: body[:locale] } }
        stubs = []
        stubs << stub_publishing_api_put_content(content_id, body.except(:links))
        stubs << stub_publishing_api_put_links(content_id, body.slice(:links)) unless body.slice(:links).empty?
        stubs << stub_publishing_api_publish(content_id, publish_options)
        stubs
      end

      def stub_default_publishing_api_put
        stub_request(:put, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content})
      end

      def assert_publishing_api_put_item(content_id, attributes_or_matcher = {}, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + content_id
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
          required_attributes == data
        end
      end

      def publishing_api_has_fields_for_format(format, items, fields)
        body = items.map { |item|
          item.with_indifferent_access.slice(*fields)
        }

        query_params = fields.map { |f|
          "&fields%5B%5D=#{f}"
        }

        url = PUBLISHING_API_V2_ENDPOINT + "/content?content_format=#{format}#{query_params.join('')}"

        stub_request(:get, url).to_return(:status => 200, :body => body.to_json, :headers => {})
      end

      def publishing_api_has_item(item)
        item = item.with_indifferent_access
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + item[:content_id]
        stub_request(:get, url).to_return(status: 200, body: item.to_json, headers: {})
      end

    private
      def stub_publishing_api_put(content_id, body, resource_path)
        url = PUBLISHING_API_V2_ENDPOINT + resource_path + "/" + content_id
        stub_request(:put, url).with(body: body).to_return(status: 200, body: '{}', headers: {"Content-Type" => "application/json; charset=utf-8"})
      end
    end
  end
end
