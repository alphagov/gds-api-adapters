require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module ContentStore

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

      def content_item_for_base_path(base_path)
        {
          "title" => titleize_base_path(base_path),
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
