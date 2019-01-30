require 'cgi'
require 'plek'

module GdsApi
  module TestHelpers
    module SupportApi
      SUPPORT_API_ENDPOINT = Plek.current.find('support-api')

      def stub_support_api_problem_report_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/problem-reports")
        post_stub.with(body: { problem_report: request_details }) unless request_details.nil?
        post_stub.to_return(status: 202)
      end

      def stub_support_api_service_feedback_creation(feedback_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/service-feedback")
        post_stub.with(body: { service_feedback: feedback_details }) unless feedback_details.nil?
        post_stub.to_return(status: 201)
      end

      def stub_support_api_long_form_anonymous_contact_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/long-form-contacts")
        post_stub.with(body: { long_form_contact: request_details }) unless request_details.nil?
        post_stub.to_return(status: 202)
      end

      def stub_support_api_feedback_export_request_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/export-requests")
        post_stub.with(body: { export_request: request_details }) unless request_details.nil?
        post_stub.to_return(status: 202)
      end

      def stub_support_api_feedback_by_day(date, page, per_page, response_body = { results: [] })
        date_string = date.strftime("%Y-%m-%d")
        get_stub = stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/feedback-by-day/#{date_string}?page=#{page}&per_page=#{per_page}")
        get_stub.to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_global_export_request_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/global-export-requests")
        post_stub.with(body: { global_export_request: request_details }) unless request_details.nil?
        post_stub.to_return(status: 202)
      end

      def stub_support_api_create_page_improvement(params)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/page-improvements")
        post_stub.with(body: params)
        post_stub.to_return(status: 201)
      end

      def stub_support_api_create_content_improvement_feedback(params)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/content_improvement")
        post_stub.with(body: params)
        post_stub.to_return(status: 201)
      end

      def stub_support_api_problem_report_daily_totals_for(date, expected_results = nil)
        date_string = date.strftime("%Y-%m-%d")
        get_stub = stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/problem-reports/#{date_string}/totals")
        response = { status: 200 }
        response[:body] = expected_results if expected_results
        get_stub.to_return(response)
      end

      def stub_support_api_problem_reports(params, response_body = {})
        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/problem-reports").
          with(query: params).
          to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_mark_reviewed_for_spam(request_details = nil, response_body = {})
        post_stub = stub_http_request(:put, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/problem-reports/mark-reviewed-for-spam")
        post_stub.with(body: { reviewed_problem_report_ids: request_details }) unless request_details.nil?
        post_stub.to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_isnt_available
        stub_request(:post, /#{SUPPORT_API_ENDPOINT}\/.*/).to_return(status: 503)
      end

      def stub_support_api_anonymous_feedback(params, response_body = {})
        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback").
          with(query: params).
          to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_anonymous_feedback_organisation_summary(slug, ordering = nil, response_body = {})
        uri = "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/organisations/#{slug}"
        uri << "?ordering=#{ordering}" if ordering
        stub_http_request(:get, uri).
          to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_organisations_list(response_body = nil)
        response_body ||= [
          {
            slug: "cabinet-office",
            web_url: "https://www.gov.uk/government/organisations/cabinet-office",
            title: "Cabinet Office",
            acronym: "CO",
            govuk_status: "live"
          },
          {
            slug: "gds",
            web_url: "https://www.gov.uk/government/organisations/gds",
            title: "Government Digital Service",
            acronym: "GDS",
            govuk_status: "live"
          }
        ]

        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/organisations").
          to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_organisation(slug = "cabinet-office", response_body = nil)
        response_body ||= {
          slug: slug,
          web_url: "https://www.gov.uk/government/organisations/#{slug}",
          title: "Cabinet Office",
          acronym: "CO",
          govuk_status: "live"
        }

        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/organisations/#{slug}").
          to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_document_type_list(response_body = nil)
        response_body ||= %w(case_study detailed_guide smart_answer)

        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/document-types").
            to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_anonymous_feedback_doc_type_summary(document_type, ordering = nil, response_body = nil)
        uri = "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/document-types/#{document_type}"
        uri << "?ordering=#{ordering}" if ordering
        stub_http_request(:get, uri).
            to_return(status: 200, body: response_body.to_json)
      end

      def stub_support_api_feedback_export_request(id, response_body = nil)
        response_body ||= {
          filename: "feedex_0000-00-00_2015-01-01.csv",
          ready: true
        }

        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/export-requests/#{id}").
          to_return(status: 200, body: response_body.to_json)
      end

      def stub_any_support_api_call
        stub_request(:any, %r{\A#{SUPPORT_API_ENDPOINT}})
      end

      # Aliases for DEPRECATED methods
      alias_method :support_api_isnt_available, :stub_support_api_isnt_available
    end
  end
end
