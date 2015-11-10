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

    private
      def stub_publishing_api_put(content_id, body, resource_path)
        url = PUBLISHING_API_V2_ENDPOINT + resource_path + "/" + content_id
        stub_request(:put, url).with(body: body).to_return(status: 200, body: '{}', headers: {"Content-Type" => "application/json; charset=utf-8"})
      end
    end
  end
end
