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

    it "should be able to fetch unpublished editions when authenticated" do
      api = GdsApi::ContentApi.new('test', { bearer_token: 'MY_BEARER_TOKEN' })
      content_api_has_unpublished_artefact("devolution-uk", 3)
      response = api.artefact("devolution-uk", 3)
      assert_equal "http://contentapi.test.gov.uk/devolution-uk.json", response["id"]
    end

    it "should raise an exception if no bearer token is used when fetching unpublished editions" do
      content_api_has_unpublished_artefact("devolution-uk", 3)
      assert_raises GdsApi::NoBearerToken do
        @api.artefact("devolution-uk", 3)
      end
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

  describe "business support schemes" do
    it "should query content_api for business_support_schemes" do
      stub_request(:get, %r{\A#{@base_api_url}/business_support_schemes.json}).
        to_return(:status => 200, :body => {"foo" => "bar"}.to_json)

      response = @api.business_support_schemes(['foo', 'bar'])

      assert_equal({"foo" => "bar"}, response.to_hash)
      assert_requested :get, "#{@base_api_url}/business_support_schemes.json?identifiers=foo,bar", :times => 1
    end

    it "should CGI escape identifiers" do
      stub_request(:get, %r{\A#{@base_api_url}/business_support_schemes.json}).
        to_return(:status => 200, :body => {"foo" => "bar"}.to_json)

      response = @api.business_support_schemes(['foo bar', 'baz&bing'])

      assert_equal({"foo" => "bar"}, response.to_hash)
      assert_requested :get, "#{@base_api_url}/business_support_schemes.json?identifiers=foo%20bar,baz%26bing", :times => 1
    end

    it "should not modify the given array" do
      stub_request(:get, %r{\A#{@base_api_url}/business_support_schemes.json}).
        to_return(:status => 200, :body => {"foo" => "bar"}.to_json)

      ids = %w(foo bar baz)
      @api.business_support_schemes(ids)

      assert_equal %w(foo bar baz), ids
    end

    it "should raise an error if content_api returns 404" do
      stub_request(:get, %r{\A#{@base_api_url}/business_support_schemes.json}).
        to_return(:status => 404, :body => "Not Found")

      assert_raises GdsApi::HTTPNotFound do
        @api.business_support_schemes(['foo', 'bar'])
      end
    end

    it "should raise an error if content_api returns a 50x error" do
      stub_request(:get, %r{\A#{@base_api_url}/business_support_schemes.json}).
        to_return(:status => 503, :body => "Gateway timeout")

      assert_raises GdsApi::HTTPErrorResponse do
        @api.business_support_schemes(['foo', 'bar'])
      end
    end

    describe "handling requests that would have a URI in excess of 2000 chars" do
      before :each do
        stub_request(:get, %r{\A#{@base_api_url}/business_support_schemes\.json}).
          to_return(:status => 200, :body => api_response_for_results([{"foo" => "bar"}]).to_json)
      end

      it "should do the request in batches" do
        ids = (1..300).map {|n| sprintf "%09d", n } # each id is 9 chars long

        response = @api.business_support_schemes(ids)

        assert_requested :get, %r{\A#{@base_api_url}/business_support_schemes\.json}, :times => 2

        first_batch = ids[0..190]
        assert_requested :get, "#{@base_api_url}/business_support_schemes.json?identifiers=#{first_batch.join(',')}"
        second_batch = ids[191..299]
        assert_requested :get, "#{@base_api_url}/business_support_schemes.json?identifiers=#{second_batch.join(',')}"
      end

      it "should merge the responses into a single GdsApi::Response" do
        ids = (1..300).map {|n| sprintf "%09d", n } # each id is 9 chars long
        first_batch = ids[0..190]
        stub_request(:get, "#{@base_api_url}/business_support_schemes.json").
          with(:query => {"identifiers" => first_batch.join(',')}).
          to_return(:status => 200, :body => api_response_for_results(first_batch).to_json) # We're stubbing response that just return the requested ids
        second_batch = ids[191..299]
        stub_request(:get, "#{@base_api_url}/business_support_schemes.json").
          with(:query => {"identifiers" => second_batch.join(',')}).
          to_return(:status => 200, :body => api_response_for_results(second_batch).to_json)

        response = @api.business_support_schemes(ids)

        # Assert both Hash an OpenStruct access to ensure nothing's been memoized part-way through merging stuff
        assert_equal 300, response["total"]
        assert_equal ids, response["results"]

        assert_equal 300, response.total
        assert_equal ids, response.results
      end
    end

    it "should do the request in batches if the request path would otherwise exceed 2000 chars" do

    end

    describe "test helpers" do
      it "should have representative test helpers" do
        setup_content_api_business_support_schemes_stubs

        s1 = artefact_for_slug('scheme-1')
        s1["details"].merge!("business_support_identifier" => "s1")
        content_api_has_business_support_scheme(s1)
        s2 = artefact_for_slug('scheme-2')
        s2["details"].merge!("business_support_identifier" => "s2")
        content_api_has_business_support_scheme(s2)
        s3 = artefact_for_slug('scheme-3')
        s3["details"].merge!("business_support_identifier" => "s3")
        content_api_has_business_support_scheme(s3)

        response = @api.business_support_schemes(['s1', 's3']).to_hash

        assert_equal 2, response["total"]
        assert_equal [s1, s3], response["results"]
      end
    end
  end

  def api_response_for_results(results)
    {
      "_response_info" => {
        "status" => "ok",
      },
      "total" => results.size,
      "results" => results,
    }
  end
end
