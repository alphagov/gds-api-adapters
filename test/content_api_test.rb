require 'test_helper'
require 'gds_api/content_api'
require 'gds_api/test_helpers/content_api'

describe GdsApi::ContentApi do
  include GdsApi::TestHelpers::ContentApi

  before do
    @base_api_url = "https://contentapi.test.alphagov.co.uk"
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

  describe "artefact" do
    it "should show the artefact" do
      content_api_has_an_artefact("devolution-uk")
      response = @api.artefact("devolution-uk")
      assert_equal "http://contentapi.test.gov.uk/devolution-uk.json", response["id"]
    end

    it "should work with unpublished editions" do
      content_api_has_unpublished_artefact("devolution-uk", 3)
      response = @api.artefact("devolution-uk", 3)
      assert_equal "http://contentapi.test.gov.uk/devolution-uk.json", response["id"]
    end
  end

  describe "tags" do
    it "should produce an artefact with the provided tag" do
      tag = "crime-and-justice"
      api_url = "#{@base_api_url}/with_tag.json?tag=#{tag}&include_children=1"
      json = {
        results: [{title: "Complain about a claims company"}]
      }.to_json
      stub_request(:get, api_url).to_return(:status => 200, :body => json)
      response = @api.with_tag("crime-and-justice")
      subsection = response["results"][0]
      assert_equal "Complain about a claims company", subsection["title"]
    end

    it "should return tag tree for a specific tag" do
      tag = "crime-and-justice"
      api_url = "#{@base_api_url}/tags/#{tag}.json"
      json = {
        title: "Crime and Justice"
      }
      stub_request(:get, api_url).to_return(:status => 200, :body => json.to_json)
      response = @api.tag(tag)
      title = response['title']
      assert_equal json[:title], title
    end
  end

  describe "licence" do
    it "should return an artefact with licence for a snac code" do
      response = content_api_has_an_artefact_with_snac_code("licence-example", '1234', {
        "title" => "Licence Example",
        "slug" => "licence-example",
        "details" => {
          "licence" => {
            "location_specific" => false,
            "availability" => [ "England", "Wales" ],
            "authorities" => [ ]
          }
        }
      })
      response = @api.artefact_with_snac_code('licence-example', '1234')

      assert_equal "Licence Example", response["title"]
      assert_equal [ "England", "Wales" ], response["details"]["licence"]["availability"]
    end

    it "should escape snac code when searching for licence" do
      stub_request(:get, "#{@base_api_url}/licence-example.json?snac=snacks%21").
        to_return(:status => 200,
                  :body => {"test" => "ing"}.to_json,
                  :headers => {})

      @api.artefact_with_snac_code("licence-example","snacks!")

      assert_requested :get, "#{@base_api_url}/licence-example.json?snac=snacks%21"
    end
  end

  describe "local authorities" do
    it "should return nil if no local authority found" do
      stub_request(:get, "#{@base_api_url}/local_authorities/does-not-exist.json").
        with(:headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
        to_return(:status => 404,
                  :body => {"_response_info" => {"status" => "ok"}}.to_json,
                  :headers => {})

      assert_nil @api.local_authority("does-not-exist")
    end

    it "should produce a LocalAuthority hash for an existing snac code" do
      body_response = {
        "name" => "Solihull Metropolitan Borough Council",
        "snac_code" => "00CT",
        "id" => "#{@base_api_url}/local_authorities/00CT.json",
        "_response_info" => {"status" => "ok"}
      }

      stub_request(:get, "#{@base_api_url}/local_authorities/00CT.json").
        with(:headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
        to_return(:status => 200,
                  :body => body_response.to_json,
                  :headers => {})

      response = @api.local_authority("00CT").to_hash

      assert_equal body_response, response
    end

    it "should return an empty result set if name not found" do
      body_response = {
        "_response_info" => {"status" => "ok"},
        "description" => "Local Authorities",
        "total" => 0,
        "results" => []
      }.to_json

      stub_request(:get, "#{@base_api_url}/local_authorities.json?name=Swansalona").
        with(:headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
        to_return(:status => 200,
                  :body => body_response,
                  :headers => {})

      response = @api.local_authorities_by_name("Swansalona")

      assert_equal 0, response["total"]
      assert_equal [], response["results"]
    end

    it "should return an empty result set if snac code not found" do
      body_response = {
        "_response_info" => {"status" => "ok"},
        "description" => "Local Authorities",
        "total" => 0,
        "results" => []
      }.to_json

      stub_request(:get, "#{@base_api_url}/local_authorities.json?snac_code=SNACKS").
        with(:headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
        to_return(:status => 200,
                  :body => body_response,
                  :headers => {})

      response = @api.local_authorities_by_snac_code("SNACKS")

      assert_equal 0, response["total"]
      assert_equal [], response["results"]
    end

    it "should have an array of results for a name search" do
      body_response = {
        "_response_info" => {"status" => "ok"},
        "description" => "Local Authorities",
        "total" => 2,
        "results" => [{
                        "name" => "Swansalona Council",
                        "snac_code" => "00VT",
                        "id" => "#{@base_api_url}/local_authorities/00VT.json"
                      },
                      {
                        "name" => "Swansea Council",
                        "snac_code" => "00CT",
                        "id" => "#{@base_api_url}/local_authorities/00VT.json"
                      }]
      }.to_json

      stub_request(:get, "#{@base_api_url}/local_authorities.json?name=Swans").
        with(:headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
        to_return(:status => 200,
                  :body => body_response,
                  :headers => {})

      response = @api.local_authorities_by_name("Swans")

      assert_equal 2, response["total"]
      assert_equal "Swansalona Council", response["results"][0]["name"]
    end

    it "should escape snac code when calling unique a local authority" do
      stub_request(:get, "#{@base_api_url}/local_authorities/escape%21.json").
        to_return(:status => 200,
                  :body => {"test" => "ing"}.to_json,
                  :headers => {})

      @api.local_authority("escape!")

      assert_requested :get, "#{@base_api_url}/local_authorities/escape%21.json"
    end

    it "should escape name when searching for local authorities" do
      stub_request(:get, "#{@base_api_url}/local_authorities.json?name=name%21").
        to_return(:status => 200,
                  :body => {"test" => "ing"}.to_json,
                  :headers => {})

      @api.local_authorities_by_name("name!")

      assert_requested :get, "#{@base_api_url}/local_authorities.json?name=name%21"
    end

    it "should escape snac code when searching for local authorities" do
      stub_request(:get, "#{@base_api_url}/local_authorities.json?snac_code=snacks%21").
        to_return(:status => 200,
                  :body => {"test" => "ing"}.to_json,
                  :headers => {})

      @api.local_authorities_by_snac_code("snacks!")

      assert_requested :get, "#{@base_api_url}/local_authorities.json?snac_code=snacks%21"
    end
  end
end
