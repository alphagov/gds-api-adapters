module GdsApi
  module TestHelpers
    module Support
      SUPPORT_ENDPOINT = Plek.current.find('support')

      def support_expects_foi_request_creation(request_details = nil)
        body_expectation = {"foi_request" => request_details}.to_json

        post_stub = stub_request(:post, "#{SUPPORT_ENDPOINT}/foi_requests")
        post_stub.with(:body => {"foi_request" => request_details}.to_json) unless request_details.nil?
        post_stub.to_return(:status => 201)
      end

      def support_isnt_available
        stub_request(:post, /#{SUPPORT_ENDPOINT}\/.*/).to_return(:status => 503)
      end
    end
  end
end
