require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module ContentRegister
      CONTENT_REGISTER_ENDPOINT = Plek.find('content-register')

      def stub_content_register_put_entry(content_id, entry)
        response_body = entry.merge(content_id: content_id).to_json

        stub_request(:put, content_register_entry_url_for(content_id)).
          with(body: entry).
          to_return(status: 201, body: response_body)
      end

      def stub_content_register_entries(format, entries)
        stub_request(:get, content_register_entries_url(format)).
          to_return(body: entries.to_json, status: 200)
      end

      def content_register_isnt_available
        stub_request(:any, /#{CONTENT_REGISTER_ENDPOINT}\/.*/).
          to_return(status: 503)
      end

    private

      def content_register_entry_url_for(content_id)
        CONTENT_REGISTER_ENDPOINT + "/entry/" + content_id
      end

      def content_register_entries_url(format)
        CONTENT_REGISTER_ENDPOINT + "/entries?format=#{format}"
      end
    end
  end
end
