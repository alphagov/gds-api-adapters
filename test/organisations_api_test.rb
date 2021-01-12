require_relative "test_helper"
require "gds_api/organisations"
require "gds_api/test_helpers/organisations"

describe GdsApi::Organisations do
  include GdsApi::TestHelpers::Organisations
  include PactTest

  def base_api_url
    Plek.new.website_root
  end

  def api_client
    @api_client ||= GdsApi::Organisations.new(organisation_api_host)
  end

  def organisation(slug: "test-department")
    {
      "id" => Pact.like("www.gov.uk/api/organisations/#{slug}"),
      "title" => Pact.like("Test Department"),
      "updated_at" => Pact.like("2019-05-15T12:12:17.000+01:00"),
      "web_url" => Pact.like("www.gov.uk/government/organisations/#{slug}"),
      "details" => {
        "slug" => Pact.like(slug),
        "content_id" => Pact.like("b854f170-53c8-4098-bf77-e8ef42f93107"),
      },
      "analytics_identifier" => Pact.like("OT1276"),
      "child_organisations" => [],
      "superseded_organisations" => [],
    }
  end

  describe "fetching list of organisations" do
    before do
      organisation_api
        .given("there is a list of organisations")
        .upon_receiving("a request for the organisation list")
        .with(
          method: :get,
          path: "/api/organisations",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            results: [
              organisation,
              organisation,
            ],
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )
    end

    it "responds with 200 OK and a list of organisations" do
      response = api_client.organisations
      assert_equal 2, response["results"].count
      assert_equal 200, response.code
    end
  end

  describe "fetching a paginated list of organisations" do
    let(:api_client_endpoint) { "#{organisation_api_host}/api/organisations" }
    let(:page_one_links) { %(<#{api_client_endpoint}?page=2>; rel="next", <#{api_client_endpoint}?page=1>; rel="self") }
    let(:page_two_links) { %(<#{api_client_endpoint}?page=1>; rel="previous", <#{api_client_endpoint}?page=2>; rel="self") }

    let(:request) do
      {
        method: :get,
        path: "/api/organisations",
        headers: GdsApi::JsonClient.default_request_headers,
      }
    end
    let(:body) do
      {
        results: Pact.each_like({}, min: 20),
        page_size: 20,
        pages: 2,
      }
    end
    let(:response) do
      {
        status: 200,
        body: body,
      }
    end

    before do
      organisation_api
        .given("the organisation list is paginated, beginning at page 1")
        .upon_receiving("a request without a query param")
        .with(request.merge(query: ""))
        .will_respond_with(response.merge(headers: { "link" => page_one_links }))

      organisation_api
        .given("the organisation list is paginated, beginning at page 2")
        .upon_receiving("a request with page 2 params")
        .with(request.merge(query: "page=2"))
        .will_respond_with(response.merge(headers: { "link" => page_two_links }))
    end

    it "should handle pagination" do
      response = api_client.organisations

      assert_equal 20, response["results"].count
      assert_equal 40, response.with_subsequent_pages.count
    end
  end

  describe "fetching an organisation by slug" do
    let(:hmrc) { "hm-revenue-customs" }

    before do
      organisation_api
        .given("the organisation hmrc exists")
        .upon_receiving("a request for hm-revenue-customs")
        .with(
          method: :get,
          path: "/api/organisations/#{hmrc}",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: organisation(slug: hmrc),
        )
    end

    it "responds with 200 and the organisation" do
      response = api_client.organisation(hmrc)

      id = "www.gov.uk/api/organisations/#{hmrc}"
      assert_equal 200, response.code
      assert_equal id, response["id"]
    end
  end

  describe "an organisation doesn't exist for a given slug" do
    before do
      organisation_api
        .given("no organisation exists")
        .upon_receiving("a request for a non-existant organisation")
        .with(
          method: :get,
          path: "/api/organisations/department-for-making-life-better",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
          body: "404 error",
        )
    end

    it "returns a 404 error code" do
      error = assert_raises(GdsApi::HTTPNotFound) do
        api_client.organisation("department-for-making-life-better")
      end
      assert_equal 404, error.code
    end
  end
end
