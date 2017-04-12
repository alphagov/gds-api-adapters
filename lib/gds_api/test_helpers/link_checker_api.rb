require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module LinkCheckerApi
      LINK_CHECKER_API_ENDPOINT = Plek.current.find("link-checker-api")

      def link_checker_api_link_report_hash(uri:, status: :ok, checked: nil, errors: {}, warnings: {})
        {
          uri: uri,
          status: status,
          checked: checked || Time.now.iso8601,
          errors: errors,
          warnings: warnings,
        }
      end

      def link_checker_api_batch_report_hash(id:, status: :completed, links: [], totals: {}, completed_at: nil)
        {
          id: id,
          status: status,
          links: links.map { |hash| link_checker_api_link_report_hash(**hash) },
          totals: totals,
          completed_at: completed_at || Time.now.iso8601,
        }
      end

      def link_checker_api_check(uri:, status: :ok, checked: nil, errors: {}, warnings: {})
        body = link_checker_api_link_report_hash(
          uri: uri, status: status, checked: checked, errors: errors, warnings: warnings
        ).to_json

        stub_request(:get, "#{LINK_CHECKER_API_ENDPOINT}/check")
          .with(query: { uri: uri })
          .to_return(body: body, status: 200, headers: { "Content-Type" => "application/json" })
      end

      def link_checker_api_get_batch(id:, status: :completed, links: [], totals: {}, completed_at: nil)
        body = link_checker_api_batch_report_hash(
          id: id, status: status, links: links, totals: totals, completed_at: completed_at
        ).to_json

        stub_request(:get, "#{LINK_CHECKER_API_ENDPOINT}/batch/#{id}")
          .to_return(body: body, status: 200, headers: { "Content-Type" => "application/json" })
      end

      def link_checker_api_create_batch(uris:, checked_within: nil, webhook_uri: nil, webhook_secret_token: nil, id: 0, status: :in_progress, links: nil, totals: {}, completed_at: nil)
        links = uris.map { |uri| { uri: uri } } if links.nil?

        response_body = link_checker_api_batch_report_hash(
          id: id,
          status: status,
          links: links,
          totals: totals,
          completed_at: completed_at
        ).to_json

        request_body = {
          uris: uris,
          checked_within: checked_within,
          webhook_uri: webhook_uri,
          webhook_secret_token: webhook_secret_token,
        }.delete_if { |_, v| v.nil? }.to_json

        stub_request(:post, "#{LINK_CHECKER_API_ENDPOINT}/batch")
          .with(body: request_body)
          .to_return(
            body: response_body,
            status: status == :in_progress ? 202 : 201,
            headers: { "Content-Type" => "application/json" }
          )
      end
    end
  end
end
