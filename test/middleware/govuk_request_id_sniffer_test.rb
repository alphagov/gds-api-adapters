require 'test_helper'
require 'gds_api/middleware/govuk_request_id_sniffer'

describe GdsApi::GovukRequestIdSniffer do
  include Rack::Test::Methods

  let(:inner_app) do
    lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['All good!']] }
  end

  let(:app) { GdsApi::GovukRequestIdSniffer.new(inner_app) }

  it "sniffs the govuk request id from request headers" do
    header "Govuk-Request-Id", "12345"
    get "/"
    assert_equal '12345', GdsApi::GovukRequestId.value
  end
end
