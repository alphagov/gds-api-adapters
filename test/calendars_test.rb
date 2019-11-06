require_relative "test_helper"
require "gds_api/calendars"
require "gds_api/test_helpers/calendars"

describe GdsApi::Calendars do
  include GdsApi::TestHelpers::Calendars

  before do
    @host = Plek.new.website_root
    @api = GdsApi::Calendars.new(@host)
  end

  describe "#bank_holidays" do
    it "fetches all bank holidays when called with no argument" do
      holidays_request = stub_request(:get, "#{@host}/bank-holidays.json").to_return(status: 200, body: "{}")

      @api.bank_holidays

      assert_requested(holidays_request)
    end

    it "fetches just the requested bank holidays when called with an argument" do
      all_holidays_request = stub_request(:get, "#{@host}/bank-holidays.json")
      scotland_holidays_request = stub_request(:get, "#{@host}/bank-holidays/scotland.json").to_return(status: 200, body: "{}")

      @api.bank_holidays(:scotland)

      assert_not_requested(all_holidays_request)
      assert_requested(scotland_holidays_request)
    end

    it "normalises the argument from underscores to dashes" do
      underscored_england_and_wales_holidays_request = stub_request(:get, "#{@host}/bank-holidays/england_and_wales.json").to_return(status: 200, body: "{}")
      dashed_england_and_wales_holidays_request = stub_request(:get, "#{@host}/bank-holidays/england-and-wales.json").to_return(status: 200, body: "{}")

      @api.bank_holidays(:england_and_wales)

      assert_not_requested(underscored_england_and_wales_holidays_request)
      assert_requested(dashed_england_and_wales_holidays_request)
    end

    it "should raise error if argument is for an area we don't have holidays for" do
      stub_request(:get, "#{@host}/bank-holidays/lyonesse.json").to_return(status: 404)
      assert_raises GdsApi::HTTPNotFound do
        @api.bank_holidays(:lyonesse)
      end
    end

    it "fetches the bank holidays requested for all divisions" do
      stub_calendars_has_a_bank_holiday_on(Date.parse("2012-12-12"))
      holidays = @api.bank_holidays

      assert_equal "2012-12-12", holidays["england-and-wales"]["events"][0]["date"]
      assert_equal "2012-12-12", holidays["scotland"]["events"][0]["date"]
      assert_equal "2012-12-12", holidays["northern-ireland"]["events"][0]["date"]
    end

    it "fetches the bank holidays requested for just one divisions" do
      stub_calendars_has_a_bank_holiday_on(Date.parse("2012-12-12"), in_division: "scotland")
      holidays = @api.bank_holidays(:scotland)

      assert_equal "2012-12-12", holidays["events"][0]["date"]
      assert_equal "scotland", holidays["division"]
    end
  end
end
