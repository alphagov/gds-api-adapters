require 'test_helper'
require 'gds_api/content_api'
require 'gds_api/test_helpers/content_api'

describe GdsApi::ContentApi do
  include GdsApi::TestHelpers::ContentApi

  before do
    @base_api_url = Plek.current.find("contentapi")
    @api = GdsApi::ContentApi.new(@base_api_url)
  end

  describe "when asked for relative web URLs" do
    before do
      @api = GdsApi::ContentApi.new(
        @base_api_url,
        web_urls_relative_to: "http://www.test.gov.uk"
      )
    end

    it "should use relative URLs for an artefact" do
      artefact_response = artefact_for_slug_in_a_section("bank-holidays", "cheese")

      # Rewrite the web_url fields to have a common prefix
      # The helper's default is to point the web_url for an artefact at the
      # frontend app, and the web_url for a tag's content to www: to test the
      # rewriting properly, they need to be the same
      artefact_response["web_url"] = "http://www.test.gov.uk/bank-holidays"
      section_tag_content = artefact_response["tags"][0]["content_with_tag"]
      section_tag_content["web_url"] = "http://www.test.gov.uk/browse/cheese"

      content_api_has_an_artefact("bank-holidays", artefact_response)
      artefact = @api.artefact("bank-holidays")

      assert_equal "Bank holidays", artefact.title
      assert_equal "/bank-holidays", artefact.web_url

      assert_equal "/browse/cheese", artefact.tags[0].content_with_tag.web_url
    end

    it "should use relative URLs for tag listings" do
      content_api_has_root_sections %w(housing benefits tax)
      tags = @api.root_sections

      assert_equal 3, tags.count
      tags.each do |tag|
        web_url = tag.content_with_tag.web_url
        assert web_url.start_with?("/browse/"), web_url
      end
    end

    describe "with caching enabled" do
      before do
        @original_cache = GdsApi::JsonClient.cache
        GdsApi::JsonClient.cache = LRUCache.new(max_size: 10, ttl: 10)
      end

      it "should not pollute the cache with relative URLs" do
        artefact_response = artefact_for_slug("bank-holidays")
        artefact_response["web_url"] = "http://www.test.gov.uk/bank-holidays"
        content_api_has_an_artefact("bank-holidays", artefact_response)

        assert_equal "/bank-holidays", @api.artefact("bank-holidays").web_url

        clean_api = GdsApi::ContentApi.new(@base_api_url)
        clean_artefact = clean_api.artefact("bank-holidays")

        assert_equal "http://www.test.gov.uk/bank-holidays", clean_artefact.web_url
      end

      after do
        GdsApi::JsonClient.cache = @original_cache
      end
    end
  end

  describe "sections" do
    it "should show a list of sections" do
      content_api_has_root_sections(["crime"])
      response = @api.sections

      # Old-style dictionary access
      first_section = response["results"][0]
      assert_equal "#{@base_api_url}/tags/sections/crime.json", first_section["id"]

      # Also check attribute access
      first_section = response.first
      assert_equal "#{@base_api_url}/tags/sections/crime.json", first_section.id
    end

    def section_page_url(page_parameter)
      if page_parameter
        "#{GdsApi::TestHelpers::ContentApi::CONTENT_API_ENDPOINT}/tags.json?type=section&page=#{page_parameter}"
      else
        "#{GdsApi::TestHelpers::ContentApi::CONTENT_API_ENDPOINT}/tags.json?type=section"
      end
    end

    def stub_section_page(page_parameter, options)
      total_pages = options.fetch :of

      url = section_page_url(page_parameter)

      page_number = page_parameter || 1
      # e.g. page 2 -> 11..20
      range_start = (page_number - 1) * 10 + 1
      range_end = page_number * 10
      tags = (range_start..range_end).map { |number|
        tag_for_slug("section-#{number}", "section")
      }
      body = plural_response_base.merge(
        "results" => tags
      )

      links = []
      if page_number > 1
        links << "<#{section_page_url(page_number - 1)}>; rel=\"previous\""
      end
      if page_number < total_pages
        links << "<#{section_page_url(page_number + 1)}>; rel=\"next\""
      end

      stub_request(:get, url).to_return(
        status: 200,
        body: body.to_json,
        headers: {"Link" => links.join(",")}
      )
    end

    it "should allow iteration across pages" do
      [nil, 2].each do |page_parameter|
        stub_section_page(page_parameter, of: 2)
      end

      sections = @api.sections
      assert_equal 20, sections.with_subsequent_pages.count
      assert_equal "Section 20", sections.with_subsequent_pages.to_a.last.title
    end

    it "should iterate across three or more pages" do
      [nil, 2, 3].each do |page_parameter|
        stub_section_page(page_parameter, of: 3)
      end

      sections = @api.sections
      assert_equal 30, sections.with_subsequent_pages.count
      assert_equal "Section 30", sections.with_subsequent_pages.to_a.last.title
    end

    it "should not load a page multiple times" do
      [nil, 2].each do |page_parameter|
        stub_section_page(page_parameter, of: 2)
      end

      sections = @api.sections

      3.times do
        # Loop through all the items, just to make sure we load all the pages
        sections.with_subsequent_pages.each do end
      end

      assert_requested :get, section_page_url(2), times: 1
    end

    it "should display a single page of sections" do
      stub_section_page(nil, of: 1)
      sections = @api.sections
      assert_equal 10, sections.with_subsequent_pages.count
    end
  end

  describe "artefact" do
    it "should show the artefact" do
      content_api_has_an_artefact("devolution-uk")
      response = @api.artefact("devolution-uk")
      assert_equal "#{@base_api_url}/devolution-uk.json", response["id"]
    end

    it "should be able to fetch unpublished editions when authenticated" do
      api = GdsApi::ContentApi.new(@base_api_url, { bearer_token: 'MY_BEARER_TOKEN' })
      content_api_has_unpublished_artefact("devolution-uk", 3)
      response = api.artefact("devolution-uk", edition: 3)
      assert_equal "#{@base_api_url}/devolution-uk.json", response["id"]
    end

    it "should raise an exception if no bearer token is used when fetching unpublished editions" do
      content_api_has_unpublished_artefact("devolution-uk", 3)
      assert_raises GdsApi::NoBearerToken do
        @api.artefact("devolution-uk", edition: 3)
      end
    end

    it "should raise a 410 if an artefact has been archived" do
      content_api_has_an_archived_artefact("atlantis")
      assert_raises GdsApi::HTTPGone do
        @api.artefact!("atlantis")
      end
    end

    it "should be able to fetch artefacts with a '/' in the slug" do
      content_api_has_an_artefact("foreign-travel-advice/aruba")
      response = @api.artefact("foreign-travel-advice/aruba")
      assert_requested(:get, "#{@base_api_url}/foreign-travel-advice%2Faruba.json")
      assert_equal "#{@base_api_url}/foreign-travel-advice%2Faruba.json", response["id"]
    end
  end

  describe "artefacts" do
    before :each do
      @artefacts_endpoint = "#{GdsApi::TestHelpers::ContentApi::CONTENT_API_ENDPOINT}/artefacts.json"
    end

    it "should return a listresponse for the artefacts" do
      WebMock.stub_request(:get, @artefacts_endpoint).
        to_return(:body => {
          "_response_info" => {"status" => "ok"},
          "total" => 4,
          "results" => [
            {"format" => "answer", "web_url" => "http://www.test.gov.uk/foo"},
            {"format" => "local_transaction", "web_url" => "http://www.test.gov.uk/bar/baz"},
            {"format" => "place", "web_url" => "http://www.test.gov.uk/somewhere"},
            {"format" => "guide", "web_url" => "http://www.test.gov.uk/vat"},
          ]
        }.to_json)

      response = @api.artefacts
      assert_equal 4, response.count
      assert_equal %w(answer local_transaction place guide), response.map(&:format)
    end

    it "should work with a paginated response" do
      WebMock.stub_request(:get, @artefacts_endpoint).
        to_return(
          :body => {
            "_response_info" => {"status" => "ok"},
            "total" => 4,
            "results" => [
              {"format" => "answer", "web_url" => "http://www.test.gov.uk/foo"},
              {"format" => "local_transaction", "web_url" => "http://www.test.gov.uk/bar/baz"},
              {"format" => "place", "web_url" => "http://www.test.gov.uk/somewhere"},
              {"format" => "guide", "web_url" => "http://www.test.gov.uk/vat"},
            ]
          }.to_json,
          :headers => {"Link" => "<#{@artefacts_endpoint}?page=2>; rel=\"next\""}
        )
      WebMock.stub_request(:get, "#{@artefacts_endpoint}?page=2").
        to_return(
          :body => {
            "_response_info" => {"status" => "ok"},
            "total" => 3,
            "results" => [
              {"format" => "answer", "web_url" => "http://www.test.gov.uk/foo2"},
              {"format" => "local_transaction", "web_url" => "http://www.test.gov.uk/bar/baz2"},
              {"format" => "guide", "web_url" => "http://www.test.gov.uk/vat2"},
            ]
          }.to_json
        )
      response = @api.artefacts
      assert_equal 7, response.with_subsequent_pages.count
      assert_equal "http://www.test.gov.uk/vat2", response.with_subsequent_pages.to_a.last.web_url
    end
  end

  describe "artefacts for need" do
    it "should fetch artefacts with a given need id" do
      content_api_has_artefacts_for_need_id(100123, [
        { "format" => "answer", "web_url" => "http://www.gov.uk/burrito" },
        { "format" => "guide", "web_url" => "http://www.gov.uk/burrito-standard" },
        { "format" => "transaction", "web_url" => "http://www.gov.uk/local-burrito-place" }
      ])

      response = @api.for_need(100123)

      assert_equal 3, response.count
      assert_equal ["http://www.gov.uk/burrito", "http://www.gov.uk/burrito-standard", "http://www.gov.uk/local-burrito-place" ], response.map(&:web_url)
      assert_equal ["answer", "guide", "transaction" ], response.map(&:format)
    end
  end

  describe "tags" do
    it "returns a list of tags of a given type" do
      content_api_has_tags("author", ["justin-thyme"])
      response = @api.tags("author")

      # Old-style dictionary access
      first_section = response["results"][0]
      assert_equal "#{@base_api_url}/tags/authors/justin-thyme.json", first_section["id"]

      # Also check attribute access
      first_section = response.first
      assert_equal "#{@base_api_url}/tags/authors/justin-thyme.json", first_section.id
    end

    it "returns a sorted list of tags of a given type" do
      content_api_has_sorted_tags("author", "alphabetical", ["justin-thyme"])
      response = @api.tags("author", sort: "alphabetical")

      first_section = response.first
      assert_equal "#{@base_api_url}/tags/authors/justin-thyme.json", first_section.id
    end

    it "returns draft tags if requested" do
      content_api_has_draft_and_live_tags(type: "specialist", draft: ["draft-tag-1"], live: ["live-tag-1"])

      all_tags = @api.tags("specialist", draft: true)
      assert_equal [["draft-tag-1", "draft"], ["live-tag-1", "live"]].to_set, all_tags.map {|t| [t.slug, t.state] }.to_set

      live_tags = @api.tags("specialist")
      assert_equal [["live-tag-1", "live"]], live_tags.map {|t| [t.slug, t.state] }
    end

    it "returns a list of root tags of a given type" do
      content_api_has_root_tags("author", ["oliver-sudden", "percy-vere"])
      response = @api.root_tags("author")

      # Old-style dictionary access
      first_section = response["results"][0]
      assert_equal "#{@base_api_url}/tags/authors/oliver-sudden.json", first_section["id"]

      # Also check attribute access
      first_section = response.first
      assert_equal "#{@base_api_url}/tags/authors/oliver-sudden.json", first_section.id
    end

    it "returns a list of child tags of a given type" do
      content_api_has_child_tags("genre", "indie", ["indie/indie-rock"])
      response = @api.child_tags("genre", "indie")

      # Old-style dictionary access
      first_section = response["results"][0]
      assert_equal "#{@base_api_url}/tags/genres/indie%2Findie-rock.json", first_section["id"]

      # Also check attribute access
      first_section = response.first
      assert_equal "#{@base_api_url}/tags/genres/indie%2Findie-rock.json", first_section.id
    end

    it "returns a sorted list of child tags of a given type" do
      content_api_has_sorted_child_tags("genre", "indie", "alphabetical", ["indie/indie-rock"])
      response = @api.child_tags("genre", "indie", sort: "alphabetical")

      first_section = response.first
      assert_equal "#{@base_api_url}/tags/genres/indie%2Findie-rock.json", first_section.id
    end

    it "returns artefacts given a section" do
      content_api_has_artefacts_in_a_section("crime-and-justice", ["complain-about-a-claims-company"])
      response = @api.with_tag("crime-and-justice")

      # Old dictionary-style access
      subsection = response["results"][0]
      assert_equal "Complain about a claims company", subsection["title"]

      # Attribute access
      assert_equal "Complain about a claims company", response.first.title
    end

    it "returns artefacts given a tag and tag type" do
      content_api_has_artefacts_with_a_tag("genre", "reggae", ["three-little-birds"])
      response = @api.with_tag("reggae", "genre")

      assert_equal "Three little birds", response.first.title
    end

    it "returns tag information for a section" do
      content_api_has_section("crime-and-justice")
      response = @api.tag("crime-and-justice")

      assert_equal "Crime and justice", response["title"]
    end

    it "returns tag information for a tag and tag type" do
      content_api_has_tag("genre", "reggae")
      response = @api.tag("reggae", "genre")

      assert_equal "Reggae", response['title']
    end

    it "returns artefacts in curated list order for a section" do
      content_api_has_artefacts_in_a_section("crime-and-justice", ["complain-about-a-claims-company"])
      response = @api.curated_list("crime-and-justice")

      assert_equal "Complain about a claims company", response.first.title
    end

    it "returns artefacts in curated list order for a tag and tag type" do
      content_api_has_artefacts_with_a_tag("genre", "reggae", ["buffalo-soldier"])
      response = @api.curated_list("reggae", "genre")

      assert_equal "Buffalo soldier", response.first.title
    end

    it "returns artefacts for a tag in a given sort order" do
      content_api_has_artefacts_in_a_section("crime-and-justice", ["complain-about-a-claims-company"])
      response = @api.sorted_by("crime-and-justice", "alphabetical")

      assert_equal "Complain about a claims company", response.first.title
    end

    it "returns artefacts in a given sort order for a tag and tag type" do
      content_api_has_sorted_artefacts_with_a_tag("genre", "reggae", "foo", ["is-this-love"])
      response = @api.sorted_by("reggae", "foo", "genre")

      assert_equal "Is this love", response.first.title
    end

    it "returns artefacts in groups for a tag and tag type" do
      content_api_has_grouped_artefacts_with_a_tag(
        "genre",
        "reggae",
        "format",
        {
          "Tracks" => ["is-this-love", "three-little-birds"],
          "Albums" => ["kaya", "exodus"],
        }
      )
      response = @api.with_tag("reggae", "genre", group_by: "format")

      # expect two groups to be returned
      assert_equal 2, response.results.size

      assert_equal 2, response.results[0].items.size
      assert_equal "Is this love", response.results[0].items[0].title
      assert_equal "Three little birds", response.results[0].items[1].title

      assert_equal 2, response.results[1].items.size
      assert_equal "Kaya", response.results[1].items[0].title
      assert_equal "Exodus", response.results[1].items[1].title
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
      response = @api.artefact('licence-example', snac: '1234')

      assert_equal "Licence Example", response["title"]
      assert_equal [ "England", "Wales" ], response["details"]["licence"]["availability"]
    end

    it "should escape snac code when searching for licence" do
      stub_request(:get, "#{@base_api_url}/licence-example.json?snac=snacks%21").
        to_return(:status => 200,
                  :body => {"test" => "ing"}.to_json,
                  :headers => {})

      @api.artefact("licence-example", snac: "snacks!")

      assert_requested :get, "#{@base_api_url}/licence-example.json?snac=snacks%21"
    end

    it "should return an unpublished artefact with a snac code" do
      body = artefact_for_slug('licence-example')
      url = "#{@base_api_url}/licence-example.json?snac=1234&edition=1"
      stub_request(:get, url).to_return(status: 200, body: body.to_json)

      api = GdsApi::ContentApi.new(@base_api_url, { bearer_token: 'MY_BEARER_TOKEN' })
      response = api.artefact('licence-example', snac: '1234', edition: '1')

      assert_equal "Licence example", response["title"]
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

      response = @api.business_support_schemes(:drink => "coffee")

      assert_equal({"foo" => "bar"}, response.to_hash)
      assert_requested :get, "#{@base_api_url}/business_support_schemes.json?drink=coffee", :times => 1
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

      assert_raises GdsApi::HTTPServerError do
        @api.business_support_schemes(['foo', 'bar'])
      end
    end

    describe "test helpers" do
      it "should have representative test helpers" do
        setup_content_api_business_support_schemes_stubs
        s1 = { "title" => "Scheme 1", "format" => "business_support" }
        content_api_has_business_support_scheme(s1, :locations => "england", :sectors => "farming")
        s2 = { "title" => "Scheme 2", "format" => "business_support" }
        content_api_has_business_support_scheme(s2, :sectors => "farming")
        s3 = { "title" => "Scheme 3", "format" => "business_support" }
        content_api_has_business_support_scheme(s3, :locations => "england", :sectors => "farming")

        response = @api.business_support_schemes(:locations => "england", :sectors => "farming").to_hash

        assert_equal 2, response["total"]
        assert_equal s1["title"], response["results"].first["title"]
        assert_equal s3["title"], response["results"].last["title"]
      end
    end
  end

  describe "getting licence details" do
    it "should get licence details" do
      setup_content_api_licences_stubs

      content_api_has_licence :licence_identifier => "1234", :title => 'Test Licence 1', :slug => 'test-licence-1',
        :licence_short_description => 'A short description'
      content_api_has_licence :licence_identifier => "1235", :title => 'Test Licence 2', :slug => 'test-licence-2',
        :licence_short_description => 'A short description'
      content_api_has_licence :licence_identifier => "AB1234", :title => 'Test Licence 3', :slug => 'test-licence-3',
        :licence_short_description => 'A short description'

      results = @api.licences_for_ids([1234, 'AB1234', 'something']).to_ostruct.results
      assert_equal 2, results.size
      assert_equal ['1234', 'AB1234'], results.map { |r| r.details.licence_identifier }
      assert_equal ['Test Licence 1', 'Test Licence 3'], results.map(&:title).sort
      assert_equal ['http://www.test.gov.uk/test-licence-1', 'http://www.test.gov.uk/test-licence-3'], results.map(&:web_url).sort
      assert_equal 'A short description', results[0].details.licence_short_description
      assert_equal 'A short description', results[1].details.licence_short_description
    end

    it "should return empty array with no licences" do
      setup_content_api_licences_stubs

      assert_equal [], @api.licences_for_ids([123,124]).to_ostruct.results
    end

    it "should raise an error if publisher returns an error" do
      stub_request(:get, %r[\A#{@base_api_url}/licences]).
        to_return(:status => [503, "Service temporarily unabailable"])

      assert_raises GdsApi::HTTPServerError do
        @api.licences_for_ids([123,124])
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
