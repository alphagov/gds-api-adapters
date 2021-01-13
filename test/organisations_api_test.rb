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
end
