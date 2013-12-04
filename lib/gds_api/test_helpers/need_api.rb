require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module NeedApi
      include GdsApi::TestHelpers::CommonResponses

      NEED_API_ENDPOINT = Plek.current.find('need-api')

      def need_api_has_organisations(organisations)
        url = NEED_API_ENDPOINT + "/organisations"

        body = response_base.merge(
          "organisations" => organisations.map {|id, attrs|
            if attrs.is_a? String
              { "id" => id }.merge("name" => attrs)
            else
              { "id" => id }.merge(attrs)
            end
          }
        )
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def need_api_has_needs_for_organisation(organisation, needs)
        url = NEED_API_ENDPOINT + "/needs?organisation_id=#{organisation}"

        body = response_base.merge(
          "results" => needs
        )
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def need_api_has_needs_for_search(search_term, needs)
        url = NEED_API_ENDPOINT + "/needs?q=#{search_term}"

        body = response_base.merge(
          "results" => needs
        )
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def need_api_has_needs(needs)
        url = NEED_API_ENDPOINT + "/needs"

        body = response_base.merge(
          "results" => needs
        )
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def need_api_has_need(need)
        need_id = need["id"] || need[:id]
        raise ArgumentError, "Test need is missing an ID" unless need_id

        url = NEED_API_ENDPOINT + "/needs/#{need_id}"
        stub_request(:get, url).to_return(status: 200, body: need.to_json, headers: {})
      end

      def need_api_has_raw_response_for_page(response, page = nil)
        url = NEED_API_ENDPOINT + "/needs"
        url << "?page=#{page}" unless page.nil?

        stub_request(:get, url).to_return(status: 200, body: response, headers: {})
      end

      def need_api_has_no_need(need_id)
        url = NEED_API_ENDPOINT + "/needs/#{need_id}"
        not_found_body = {
          "_response_info" => {"status" => "not_found"},
          "error" => "No need exists with this ID"
        }
        stub_request(:get, url).to_return(
          status: 404,
          body: not_found_body.to_json,
          headers: {}
        )
      end
    end
  end
end
