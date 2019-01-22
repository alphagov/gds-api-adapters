module GdsApi
  module TestHelpers
    module Support
      SUPPORT_ENDPOINT = Plek.current.find('support')

      def stub_support_foi_request_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_ENDPOINT}/foi_requests")
        post_stub.with(body: { "foi_request" => request_details }) unless request_details.nil?
        post_stub.to_return(status: 201)
      end

      def stub_support_named_contact_creation(request_details = nil)
        post_stub = stub_http_request(:post, "#{SUPPORT_ENDPOINT}/named_contacts")
        post_stub.with(body: { named_contact: request_details }) unless request_details.nil?
        post_stub.to_return(status: 201)
      end

      def stub_support_isnt_available
        stub_request(:post, /#{SUPPORT_ENDPOINT}\/.*/).to_return(status: 503)
      end

      # Aliases for DEPRECATED methods
      alias_method :support_isnt_available, :stub_support_isnt_available
    end
  end
end
