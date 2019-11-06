require "test_helper"
require "gds_api/link_checker_api"
require "gds_api/test_helpers/link_checker_api"

describe GdsApi::LinkCheckerApi do
  include GdsApi::TestHelpers::LinkCheckerApi

  before do
    @base_api_url = Plek.find("link-checker-api")
    @api = GdsApi::LinkCheckerApi.new(@base_api_url)
  end

  describe "#check" do
    it "returns a useful response" do
      stub_link_checker_api_check(uri: "http://example.com", status: :broken)

      link_report = @api.check("http://example.com")

      assert_equal :broken, link_report.status
    end
  end

  describe "#create_batch" do
    it "returns a useful response" do
      stub_link_checker_api_create_batch(uris: ["http://example.com"])

      batch_report = @api.create_batch(["http://example.com"])

      assert_equal :in_progress, batch_report.status
      assert_equal "http://example.com", batch_report.links[0].uri
    end
  end

  describe "#get_batch" do
    it "returns a useful response" do
      stub_link_checker_api_get_batch(id: 10, links: [{ uri: "http://example.com" }])

      batch_report = @api.get_batch(10)

      assert_equal :completed, batch_report.status
      assert_equal "http://example.com", batch_report.links[0].uri
    end
  end

  describe "#upsert_resource_monitor" do
    it "returns a useful response" do
      stub_link_checker_api_upsert_resource_monitor(
        reference: "Test:10",
        app: "testing",
        links: ["http://example.com"],
      )

      resource_monitor = @api.upsert_resource_monitor(
        ["http://example.com"],
        "testing",
        "Test:10",
      )

      assert resource_monitor.has_key?("id")
    end
  end
end
