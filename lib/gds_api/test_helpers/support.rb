module GdsApi
  module TestHelpers
    module Support
      SUPPORT_ENDPOINT = Plek.current.find('support')

      def stub_support_foi_request_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_ENDPOINT}/foi_requests")
        post_stub.with(:body => {"foi_request" => request_details}) unless request_details.nil?
        post_stub.to_return(:status => 201)
      end

      def stub_support_problem_report_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_ENDPOINT}/anonymous_feedback/problem_reports")
        post_stub.with(:body => { problem_report: request_details }) unless request_details.nil?
        post_stub.to_return(:status => 201)
      end

      def support_isnt_available
        stub_request(:post, /#{SUPPORT_ENDPOINT}\/.*/).to_return(:status => 503)
      end
    end
  end
end
