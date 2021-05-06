require "test_helper"
require "gds_api/link_checker_api"
require "gds_api/test_helpers/link_checker_api"

describe GdsApi::LinkCheckerApi do
  include GdsApi::TestHelpers::LinkCheckerApi
  include PactTest

  describe "test helpers" do
    let(:base_url) { Plek.find("link-checker-api") }
    let(:api_client) { GdsApi::LinkCheckerApi.new(base_url) }

    describe "#check" do
      it "returns a useful response" do
        stub_link_checker_api_check(uri: "http://example.com", status: :broken)

        link_report = api_client.check("http://example.com")

        assert_equal :broken, link_report.status
      end
    end

    describe "#create_batch" do
      it "returns a useful response" do
        stub_link_checker_api_create_batch(uris: ["http://example.com"])

        batch_report = api_client.create_batch(["http://example.com"])

        assert_equal :in_progress, batch_report.status
        assert_equal "http://example.com", batch_report.links[0].uri
      end
    end

    describe "#get_batch" do
      it "returns a useful response" do
        stub_link_checker_api_get_batch(id: 10, links: [{ uri: "http://example.com" }])

        batch_report = api_client.get_batch(10)

        assert_equal :completed, batch_report.status
        assert_equal "http://example.com", batch_report.links[0].uri
      end
    end
  end

  describe "contract tests" do
    let(:api_client) { GdsApi::LinkCheckerApi.new(link_checker_api_host) }

    describe "#check" do
      it "responds with the details of the checked link" do
        link_checker_api
          .upon_receiving("the request to check a URI")
          .with(
            method: :get,
            path: "/check",
            headers: GdsApi::JsonClient.default_request_headers,
            query: { uri: "https://www.gov.uk" },
          )
          .will_respond_with(
            status: 200,
            body: {
              uri: "https://www.gov.uk",
              status: "pending",
              checked: nil,
              errors: [],
              warnings: [],
              problem_summary: nil,
              suggested_fix: nil,
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.check("https://www.gov.uk")
      end
    end

    describe "#create_batch" do
      it "responds with details of the created batch" do
        link_checker_api
          .upon_receiving("the request to create a batch")
          .with(
            method: :post,
            path: "/batch",
            headers: GdsApi::JsonClient.default_request_with_json_body_headers,
            body: { uris: ["https://www.gov.uk"] },
          )
          .will_respond_with(
            status: 202,
            body: {
              id: Pact.like(1),
              status: "in_progress",
              links: [
                {
                  uri: "https://www.gov.uk",
                  status: "pending",
                },
              ],
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.create_batch(["https://www.gov.uk"])
      end
    end

    describe "#get_batch" do
      it "responds with the details of the batch" do
        link_checker_api
          .given("a batch exists with id 99 and uris https://www.gov.uk")
          .upon_receiving("the request to get a batch")
          .with(
            method: :get,
            path: "/batch/99",
            headers: GdsApi::JsonClient.default_request_headers,
          )
          .will_respond_with(
            status: 200,
            body: {
              id: 99,
              status: "in_progress",
              links: [
                {
                  uri: "https://www.gov.uk",
                  status: "pending",
                },
              ],
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.get_batch(99)
      end
    end
  end
end
