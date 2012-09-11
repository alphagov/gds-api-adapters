require 'test_helper'
require 'gds_api/content_api'
require 'gds_api/test_helpers/content_api'

describe GdsApi::ContentApi do
  include GdsApi::TestHelpers::ContentApi

  before do
    @api = GdsApi::ContentApi.new('test')
  end

  describe "sections" do
    it "should show a list of sections" do
      content_api_has_root_sections(["crime"])
      response = @api.sections
      first_section = response["results"][0]
      assert_equal "http://contentapi.test.gov.uk/tags/crime.json", first_section["id"]
    end
  end

  describe "tags" do
    it "should produce an artefact with the provided tag" do
      tag = "crime-and-justice"
      api_url = "https://contentapi.test.alphagov.co.uk/with_tag.json?tag=#{tag}&include_children=1"
      json = {
        results: [{title: "Complain about a claims company"}]
      }.to_json
      stub_request(:get, api_url).to_return(:status => 200, :body => json)
      response = @api.with_tag("crime-and-justice")
      subsection = response["results"][0]
      assert_equal "Complain about a claims company", subsection["title"]
    end
  end
end
