require 'test_helper'
require 'gds_api/middleware/govuk_header_sniffer'

describe GdsApi::GovukHeaderSniffer do
  include Rack::Test::Methods

  let(:inner_app) do
    lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['All good!']] }
  end

  let(:app) { GdsApi::GovukHeaderSniffer.new(inner_app, 'HTTP_GOVUK_REQUEST_ID') }

  it "sniffs the govuk request id from request headers" do
    header "Govuk-Request-Id", "12345"
    get "/"
    assert_equal '12345', GdsApi::GovukHeaders.headers[:'govuk-request-id']
  end
end
