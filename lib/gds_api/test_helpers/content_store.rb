require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'
require 'json'

module GdsApi
  module TestHelpers
    module ContentStore
      include CommonResponses

      CONTENT_STORE_ENDPOINT = Plek.current.find('content-store')

      def content_store_has_item(base_path, body = item_for_base_path(base_path), expires_in = 900)
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        body = body.to_json unless body.is_a?(String)
        stub_request(:get, url).to_return(status: 200, body: body, headers: {cache_control: "public, max-age=#{expires_in}", date: Time.now.httpdate})
      end

      def content_store_does_not_have_item(base_path)
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        stub_request(:get, url).to_return(status: 404, headers: {})
      end

      def stub_content_store_put_item(base_path, body = item_for_base_path(base_path))
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        body = body.to_json unless body.is_a?(String)
        stub_request(:put, url).with(body: body).to_return(status: 201, body: body, headers: {})
      end

      def stub_default_content_store_put()
        stub_request(:put, %r{\A#{CONTENT_STORE_ENDPOINT}/content})
      end

      def item_for_base_path(base_path)
        {
          "title" => titleize_slug(base_path),
          "description" => "Description for #{base_path}",
          "format" => "guide",
          "need_ids" => ["100001"],
          "public_updated_at" => "2014-05-06T12:01:00+00:00",
          "base_path" => base_path,
          "details" => {
            "body" => "Some content for #{base_path}",
          }
        }
      end

      def assert_content_store_put_item(base_path, attributes = {})
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
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

      def content_store_isnt_available
        stub_request(:any, /#{CONTENT_STORE_ENDPOINT}\/.*/).to_return(:status => 503)
      end
    end
  end
end
