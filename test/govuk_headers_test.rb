require_relative "test_helper"
require "gds_api/govuk_headers"

describe GdsApi::GovukHeaders do
  before :each do
    Thread.current[:headers] = nil if Thread.current[:headers]
  end

  it "supports read/write of headers" do
    GdsApi::GovukHeaders.set_header("GDS-Request-Id", "123-456")
    GdsApi::GovukHeaders.set_header("Content-Type", "application/pdf")

    assert_equal({
      "GDS-Request-Id" => "123-456",
      "Content-Type" => "application/pdf",
    }, GdsApi::GovukHeaders.headers)
  end

  it "supports clearing of headers" do
    GdsApi::GovukHeaders.set_header("GDS-Request-Id", "123-456")

    GdsApi::GovukHeaders.clear_headers

    assert_equal({}, GdsApi::GovukHeaders.headers)
  end
end
