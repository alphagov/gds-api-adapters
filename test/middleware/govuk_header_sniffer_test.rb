require 'test_helper'
require 'gds_api/middleware/govuk_header_sniffer'

describe GdsApi::GovukHeaderSniffer do
  include Rack::Test::Methods

  let(:inner_app) do
    lambda { |_env| [200, { 'Content-Type' => 'text/plain' }, ['All good!']] }
  end

  let(:app) { GdsApi::GovukHeaderSniffer.new(inner_app, 'HTTP_GOVUK_REQUEST_ID') }

  it "sniffs custom request headers and stores them for later use" do
    header "Govuk-Request-Id", "12345"
    get "/"
    assert_equal '12345', GdsApi::GovukHeaders.headers[:govuk_request_id]
  end
end
