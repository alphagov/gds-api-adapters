require "test_helper"
require "gds_api/calendars"
require "gds_api/test_helpers/calendars"

describe GdsApi::Calendars do
  include GdsApi::TestHelpers::Calendars
  include PactTest

  def base_api_url
    Plek.new.website_root
  end

  def api_client
    @api_client ||= GdsApi::Calendars.new(bank_holidays_api_host)
  end

  def event
    {
      "title" => Pact.like("New Year's Day"),
      "date" => Pact.like("2016-01-01"),
      "notes" => Pact.like("Substitute day"),
      "bunting" => Pact.like(true),
    }
  end

  describe "fetching all bank holidays" do
    before do
      bank_holidays_api
        .given("there is a list of all bank holidays")
        .upon_receiving("the request for the list of all bank holidays")
        .with(
          method: :get,
          path: "/bank-holidays.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            "england-and-wales": {
              division: "england-and-wales",
              events: Pact.each_like(event),
            },
            "scotland": {
              division: "scotland",
              events: Pact.each_like(event),
            },
            "northern-ireland": {
              division: "northern-ireland",
              events: Pact.each_like(event),
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )
    end

    it "responds with 200 OK and a list of bank holidays for each nation" do
      response = api_client.bank_holidays
      assert response["england-and-wales"]["events"].count.positive?
      assert response["scotland"]["events"].count.positive?
      assert response["northern-ireland"]["events"].count.positive?
      assert_equal 200, response.code
    end
  end

  describe "fetching only Scottish bank holidays" do
    before do
      bank_holidays_api
        .given("there is a list of all bank holidays")
        .upon_receiving("the request for the list of Scottish bank holidays")
        .with(
          method: :get,
          path: "/bank-holidays/scotland.json",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            division: "scotland",
            events: Pact.each_like(event),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )
    end

    it "responds with 200 OK and a list of bank holidays" do
      response = api_client.bank_holidays("scotland")
      assert response["events"].count.positive?
      assert_equal 200, response.code
    end
  end
end
