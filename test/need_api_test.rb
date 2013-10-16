require 'test_helper'
require 'gds_api/need_api'
require 'gds_api/test_helpers/need_api'

describe GdsApi::NeedApi do
  include GdsApi::TestHelpers::NeedApi

  before do
    @base_api_url = Plek.current.find("need-api")
    @api = GdsApi::NeedApi.new(@base_api_url)
  end

  describe "requesting needs" do
    it "should return a list of all needs" do
      req = need_api_has_needs([
        {
          "role" => "parent",
          "goal" => "apply for a primary school place",
          "benefit" => "my child can start school",
          "organisation_ids" => ["department-for-education"],
          "organisations" => [
            {
              "id" => "department-for-education",
              "name" => "Department for Education",
            }
          ],
          "justifications" => [
            "it's something only government does",
            "the government is legally obliged to provide it"
          ],
          "impact" => "Has serious consequences for the day-to-day lives of your users",
          "met_when" => [
            "The user applies for a school place"
          ]
        },
        {
          "role" => "user",
          "goal" => "find out about becoming a British citizen",
          "benefit" => "i can take the correct steps to apply for citizenship",
          "organisation_ids" => ["home-office"],
          "organisations" => [
            {
              "id" => "home-office",
              "name" => "Home Office",
            }
          ],
          "justifications" => [
            "it's something only government does",
            "the government is legally obliged to provide it"
          ],
          "impact" => "Has serious consequences for the day-to-day lives of your users",
          "met_when" => [
            "The user finds information about the citizenship test and the next steps"
          ]
        }
      ])

      needs = @api.needs

      assert_requested(req)
      assert_equal 2, needs.count

      assert_equal ["parent", "user"], needs.map(&:role)
      assert_equal ["apply for a primary school place", "find out about becoming a British citizen"], needs.map(&:goal)
      assert_equal ["my child can start school", "i can take the correct steps to apply for citizenship"], needs.map(&:benefit)

      assert_equal "department-for-education", needs.first.organisations.first.id
      assert_equal "Department for Education", needs.first.organisations.first.name
    end
  end

  describe "creating needs" do
    it "should post to the right endpoint" do
      request_stub = stub_request(:post, @base_api_url + "/needs").with(
        :body => '{"goal":"I wanna sammich!"}'
      )
      @api.create_need({"goal" => "I wanna sammich!"})
      assert_requested(request_stub)
    end
  end

  describe "viewing organisations" do
    it "should return a list of organisations" do
      request_stub = need_api_has_organisations(
        "committee-on-climate-change" => "Committee on Climate Change",
        "competition-commission" => "Competition Commission"
      )

      orgs = @api.organisations

      assert_requested(request_stub)
      assert_equal "Committee on Climate Change", orgs[0]["name"]
      assert_equal "Competition Commission", orgs[1]["name"]
      assert_equal 2, orgs.size
    end
  end
end
