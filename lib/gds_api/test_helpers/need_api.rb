require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module NeedApi
      include GdsApi::TestHelpers::CommonResponses

      NEED_API_ENDPOINT = Plek.current.find('need-api')

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

      def need_api_has_need_ids(needs)
        ids = needs.map { |need| (need["id"] || need[:id]).to_i }.sort.join(',')
        url = NEED_API_ENDPOINT + "/needs?ids=#{ids}"

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

      def need_api_has_content_id_for_need(need)
        need_id = need["id"] || need[:id]

        url = NEED_API_ENDPOINT + "/needs/#{need_id}/content_id"
        stub_request(:get, url).to_return(body: need[:content_id])
      end

      def need_api_has_raw_response_for_page(response, page = nil)
        url = NEED_API_ENDPOINT + "/needs"
        url << "?page=#{page}" unless page.nil?

        stub_request(:get, url).to_return(status: 200, body: response, headers: {})
      end

      def need_api_has_no_need(need_id)
        url = NEED_API_ENDPOINT + "/needs/#{need_id}"
        not_found_body = {
          "_response_info" => { "status" => "not_found" },
          "error" => "No need exists with this ID"
        }
        stub_request(:get, url).to_return(
          status: 404,
          body: not_found_body.to_json,
          headers: {}
        )
      end

      def stub_create_note(note_details = nil)
        post_stub = stub_request(:post, NEED_API_ENDPOINT + "/notes")
        post_stub.with(body: note_details.to_json) unless note_details.nil?
        post_stub.to_return(status: 201)
      end
    end
  end
end
