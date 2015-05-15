require 'cgi'
require 'plek'

module GdsApi
  module TestHelpers
    module SupportApi
      SUPPORT_API_ENDPOINT = Plek.current.find('support-api')

      def stub_support_api_problem_report_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/problem-reports")
        post_stub.with(:body => { problem_report: request_details }) unless request_details.nil?
        post_stub.to_return(:status => 202)
      end

      def stub_support_api_service_feedback_creation(feedback_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/service-feedback")
        post_stub.with(:body => { service_feedback: feedback_details }) unless feedback_details.nil?
        post_stub.to_return(:status => 201)
      end

      def stub_support_long_form_anonymous_contact_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/long-form-contacts")
        post_stub.with(:body => { long_form_contact: request_details }) unless request_details.nil?
        post_stub.to_return(:status => 202)
      end

      def stub_problem_report_daily_totals_for(date, expected_results = nil)
        date_string = date.strftime("%Y-%m-%d")
        get_stub = stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback/problem-reports/#{date_string}/totals")
        response = { status: 200 }
        response[:body] = expected_results if expected_results
        get_stub.to_return(response)
      end

      def support_api_isnt_available
        stub_request(:post, /#{SUPPORT_API_ENDPOINT}\/.*/).to_return(:status => 503)
      end

      def stub_anonymous_feedback(params, response_body = {})
        stub_http_request(:get, "#{SUPPORT_API_ENDPOINT}/anonymous-feedback").
          with(query: params).
          to_return(status: 200, body: response_body.to_json)
      end
    end
  end
end
