require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module LicenceApplication
      LICENCE_APPLICATION_ENDPOINT = "https://licenceapplication.test.alphagov.co.uk"

      def licence_exists(identifier, licence)
        licence = licence.to_json unless licence.is_a?(String)
        stub_request(:get, "#{LICENCE_APPLICATION_ENDPOINT}/api/licence/#{identifier}").
          with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
          to_return(status: 200,
            body: licence)
      end

      def licence_does_not_exist(identifier)
        stub_request(:get, "#{LICENCE_APPLICATION_ENDPOINT}/api/licence/#{identifier}").
          with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
          to_return(status: 404,
            body: "{\"error\": [\"Unrecognised Licence Id: #{identifier}\"]}")
      end
    end
  end
end
