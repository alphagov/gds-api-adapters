require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module LicenceApplication
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      LICENCE_APPLICATION_ENDPOINT = Plek.current.find("licensify")

      def stub_licence_exists(identifier, licence)
        licence = licence.to_json unless licence.is_a?(String)
        stub_request(:get, "#{LICENCE_APPLICATION_ENDPOINT}/api/licence/#{identifier}").
          with(headers: GdsApi::JsonClient.default_request_headers).
          to_return(status: 200,
            body: licence)
      end

      def stub_licence_does_not_exist(identifier)
        stub_request(:get, "#{LICENCE_APPLICATION_ENDPOINT}/api/licence/#{identifier}").
          with(headers: GdsApi::JsonClient.default_request_headers).
          to_return(status: 404,
            body: "{\"error\": [\"Unrecognised Licence Id: #{identifier}\"]}")
      end

      def stub_licence_times_out(identifier)
        stub_request(:get, "#{LICENCE_APPLICATION_ENDPOINT}/api/licence/#{identifier}").to_timeout
      end

      def stub_licence_returns_error(identifier)
        stub_request(:get, "#{LICENCE_APPLICATION_ENDPOINT}/api/licence/#{identifier}").to_return(status: 500)
      end

      # Aliases for DEPRECATED methods
      alias_method :licence_exists, :stub_licence_exists
      alias_method :licence_does_not_exist, :stub_licence_does_not_exist
      alias_method :licence_times_out, :stub_licence_times_out
      alias_method :licence_returns_error, :stub_licence_returns_error
    end
  end
end
