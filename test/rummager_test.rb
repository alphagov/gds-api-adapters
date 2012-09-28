require "test_helper"
require "gds_api/rummager"

describe GdsApi::Rummager do
  before(:each) do
    stub_request(:get, /example.com\/search/).to_return(body: "[]")
    stub_request(:get, /example.com\/autocomplete/).to_return(body: "[]")
  end

  it "should raise an exception if the search service uri is not set" do
    assert_raises(GdsApi::Rummager::SearchUriNotSpecified) { GdsApi::Rummager.new(nil) }
  end

  it "should raise an exception if the service at the search URI returns a 500" do
    stub_request(:get, /example.com\/search/).to_return(status: [500, "Internal Server Error"])
    assert_raises(GdsApi::Rummager::SearchServiceError) do
      GdsApi::Rummager.new("http://example.com").search("query")
    end
  end

  it "should raise an exception if the service at the search URI returns a 404" do
    stub_request(:get, /example.com\/search/).to_return(status: [404, "Not Found"])
    assert_raises(GdsApi::Rummager::SearchServiceError) do
      GdsApi::Rummager.new("http://example.com").search("query")
    end
  end

  it "should raise an exception if the service at the search URI times out" do
    stub_request(:get, /example.com\/search/).to_timeout
    assert_raises(GdsApi::Rummager::SearchTimeout) do
      GdsApi::Rummager.new("http://example.com").search("query")
    end
  end

  it "should return the search deserialized from json" do
    search_results = [{"title" => "document-title"}]
    stub_request(:get, /example.com\/search/).to_return(body: search_results.to_json)
    results = GdsApi::Rummager.new("http://example.com").search("query")

    assert_equal search_results, results
  end

  it "should return an empty set of results without making request if query is empty" do
    results = GdsApi::Rummager.new("http://example.com").search("")

    assert_equal [], results
    assert_not_requested :get, /example.com/
  end

  it "should return an empty set of results without making request if query is nil" do
    results = GdsApi::Rummager.new("http://example.com").search(nil)

    assert_equal [], results
    assert_not_requested :get, /example.com/
  end

  it "should request the search results in JSON format" do
    GdsApi::Rummager.new("http://example.com").search("query")

    assert_requested :get, /.*/, headers: {"Accept" => "application/json"}
  end

  it "should issue a request for the search term specified" do
    GdsApi::Rummager.new("http://example.com").search "search-term"

    assert_requested :get, /\?q=search-term/
  end

  it "should add a format filter parameter to searches if provided" do
    GdsApi::Rummager.new("http://example.com").search "search-term", "specialist_guidance"

    assert_requested :get, /format_filter=specialist_guidance/
  end

  it "should not tell the http client to use ssl if we're connecting to an http host" do
    response = stub('response', code: '200', body: '[]')
    http = stub('http', get: response)
    Net::HTTP.stubs(:new).returns(http)

    http.expects(:use_ssl=).never

    client = GdsApi::Rummager.new("http://example.com").search "search-term"
  end

  it "should tell the http client to use ssl if we're connecting to an https host" do
    response = stub('response', code: '200', body: '[]')
    http = stub('http', get: response)
    Net::HTTP.stubs(:new).returns(http)

    http.expects(:use_ssl=).with(true)

    client = GdsApi::Rummager.new("https://example.com").search "search-term"
  end

  it "should add a format filter parameter to autocomplete if provided" do
    GdsApi::Rummager.new("http://example.com").autocomplete "search-term", "specialist_guidance"

    assert_requested :get, /format_filter=specialist_guidance/
  end

  it "should escape characters that would otherwise be invalid in a URI" do
    GdsApi::Rummager.new("http://example.com").search "search term with spaces"

    # FYI: the actual request is "?q=search+term+with+spaces", but Webmock appears to be re-escaping.
    assert_requested :get, /\?q=search%20term%20with%20spaces/
  end

  it "should pass autocomplete responses back as-is" do
    search_results_json = {"title" => "document-title"}.to_json
    stub_request(:get, /example.com\/autocomplete/).to_return(body: search_results_json)
    results = GdsApi::Rummager.new("http://example.com").autocomplete("test")

    assert_equal search_results_json, results
  end
end
