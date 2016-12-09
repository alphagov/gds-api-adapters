require 'test_helper'
require 'gds_api/need_api'
require 'gds_api/test_helpers/need_api'

describe GdsApi::NeedApi do
  include GdsApi::TestHelpers::NeedApi

  before do
    @base_api_url = Plek.current.find("need-api")
    @api = GdsApi::NeedApi.new(@base_api_url)
  end

  describe "requesting needs by ID" do
    before do
      need_api_has_need_ids([
        {
          "id"   => "1",
          "role" => "parent",
          "goal" => "apply for a primary school place",
          "benefit" => "my child can start school",
        },
        {
          "id"   => "2",
          "role" => "user",
          "goal" => "find out about becoming a British citizen",
          "benefit" => "i can take the correct steps to apply for citizenship",
        },
        {
          "id"   => "3",
          "role" => "user",
          "goal" => "find out about unemployment benefits",
          "benefit" => "i have financial support whilst unemployed",
        }
      ])
    end

    it "returns a list of needs matching the IDs" do
      needs = @api.needs_by_id(1, 2, 3)

      assert_equal 3, needs.count
      assert_equal %w(1 2 3), needs.map { |need| need['id'] }
      assert_equal "apply for a primary school place", needs['results'][0]['goal']
      assert_equal "find out about becoming a British citizen", needs['results'][1]['goal']
      assert_equal "find out about unemployment benefits", needs['results'][2]['goal']
    end

    it "makes the same request regardless of the order of the IDs" do
      needs = @api.needs_by_id(2, 1, 3)

      assert_equal 3, needs.count
      assert_equal %w(1 2 3), needs.map { |need| need['id'] }
    end

    it "correctly sorts IDs requested as strings" do
      needs = @api.needs_by_id(%w(02 3 1))

      assert_equal 3, needs.count
      assert_equal %w(1 2 3), needs.map { |need| need['id'] }
    end
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

      assert_equal %w(parent user), needs.map { |need| need['role'] }
      assert_equal(
        [
          "apply for a primary school place",
          "find out about becoming a British citizen"
        ],
        needs.map { |need| need['goal'] }
      )
      assert_equal(
        [
          "my child can start school",
          "i can take the correct steps to apply for citizenship"
        ],
        needs.map { |need| need['benefit'] }
      )

      assert_equal(
        "department-for-education",
        needs.first['organisations'].first['id']
      )
      assert_equal(
        "Department for Education",
        needs.first['organisations'].first['name']
      )
    end
  end

  describe "creating needs" do
    it "should post to the right endpoint" do
      request_stub = stub_request(:post, @base_api_url + "/needs").with(
        body: '{"goal":"I wanna sammich!"}'
      )
      @api.create_need("goal" => "I wanna sammich!")
      assert_requested(request_stub)
    end
  end

  describe "filtering needs by organisation" do
    it "should return a subset of needs" do
      req = need_api_has_needs_for_organisation("ministry-of-justice", [
        {
          "role" => "parent",
          "goal" => "apply for a primary school place",
          "benefit" => "my child can start school",
          "organisation_ids" => ["ministry-of-justice"],
          "organisations" => [
            {
              "id" => "ministry-of-justice",
              "name" => "Ministry of Justice",
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
          "organisation_ids" => ["ministry-of-justice"],
          "organisations" => [
            {
              "id" => "ministry-of-justice",
              "name" => "Ministry of Justice",
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

      @api.needs(organisation_id: "ministry-of-justice")
      assert_requested(req)
    end
  end

  describe "viewing needs" do
    it "should return a need response" do
      need = {
        id: 100500,
        role: "parent",
        goal: "do things",
        benefit: "good things"
      }
      need_api_has_need(need)

      need_response = @api.need(100500)
      assert_equal "good things", need_response['benefit']
    end

    it "should raise for a missing need" do
      need_api_has_no_need(100600)

      assert_raises(GdsApi::HTTPNotFound) do
        @api.need(100600)
      end
    end
  end

  describe "viewing content_ids for needs" do
    it "should return the content_id for a need_id" do
      need = {
        id: 100700,
        content_id: "abcdef-12345",
        role: "need",
        goal: "needy",
        benefit: "needless"
      }
      need_api_has_content_id_for_need(need)

      need_response = @api.content_id(100700)
      assert_equal 'abcdef-12345', need_response.body
    end
  end

  describe "updating needs" do
    it "should send a PUT request" do
      updated_fields = {
        role: "parent",
        goal: "do things",
        benefit: "good things"
      }

      update_stub = stub_request(:put, @base_api_url + "/needs/100005")
                        .with(body: updated_fields.to_json)
                        .to_return(status: 204)
      @api.update_need(100005, updated_fields)
      assert_requested update_stub
    end

    it "should accept partial updates" do
      updated_fields = { role: "parent" }

      update_stub = stub_request(:put, @base_api_url + "/needs/100005")
                        .with(body: updated_fields.to_json)
                        .to_return(status: 204)
      @api.update_need(100005, updated_fields)
      assert_requested update_stub
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

    it "should return organisations with abbreviations if present" do
      request_stub = need_api_has_organisations(
        "committee-on-climate-change" => { "name" => "Committee on Climate Change",
                                          "abbreviation" => "CCC" },
        "competition-commission" => { "name" => "Competition Commission",
                                     "abbreviation" => "CC" }
      )
      orgs = @api.organisations

      assert_requested(request_stub)
      assert_equal "Committee on Climate Change", orgs[0]["name"]
      assert_equal "Competition Commission", orgs[1]["name"]
      assert_equal "CCC", orgs[0]["abbreviation"]
      assert_equal "CC", orgs[1]["abbreviation"]
      assert_equal 2, orgs.size
    end
  end

  describe "closing needs as duplicates" do
    it "should send a PUT request" do
      fields = {
        duplicate_of: 100001
      }

      duplicate_stub = stub_request(:put, @base_api_url + "/needs/100005/closed")
                         .with(body: fields.to_json)
                         .to_return(status: 204)
      @api.close(100005, fields)
      assert_requested duplicate_stub
    end
  end

  describe "reopening closed needs" do
    it "should send a DELETE request" do
      fields = {
        author: {
          name: "Winston Smith-Churchill",
          email: "winston@alphagov.co.uk"
        }
      }

      reopen_stub = stub_request(:delete, @base_api_url + "/needs/100001/closed")
                      .with(body: fields.to_json)
                      .to_return(status: 204)
      @api.reopen(100001, fields)
      assert_requested reopen_stub
    end
  end

  describe "creating notes" do
    it "should send a post request" do
      fields = {
        "text" => "test",
        "need_id" => "100001",
        "author" => {
          "name" => "Winston Smith-Churchill",
          "email" => "winston@alphagov.co.uk"
        }
      }
      request_stub = stub_create_note(fields)

      @api.create_note(fields)

      assert_requested(request_stub)
    end
  end
end
