require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module ContentStore
      include CommonResponses

      CONTENT_STORE_ENDPOINT = Plek.current.find('content-store')

      def content_store_has_item(base_path, body = item_for_base_path(base_path))
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def stub_content_store_put_item(base_path, body = item_for_base_path(base_path))
        url = CONTENT_STORE_ENDPOINT + "/content" + base_path
        stub_request(:put, url).with(body: body.to_json).to_return(status: 201, body: body.to_json, headers: {})
      end

      def stub_default_content_store_put()
        stub_request(:put, /.*content-store.*/)
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
    end
  end
end
