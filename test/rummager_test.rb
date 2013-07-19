require "test_helper"
require "gds_api/rummager"

describe GdsApi::Rummager do
  before(:each) do
    stub_request(:get, /example.com\/search/).to_return(body: "[]")
    stub_request(:get, /example.com\/advanced_search/).to_return(body: "[]")
  end

  it "should raise an exception if the service at the search URI returns a 500" do
    stub_request(:get, /example.com\/search/).to_return(status: [500, "Internal Server Error"])
    assert_raises(GdsApi::HTTPErrorResponse) do
      GdsApi::Rummager.new("http://example.com").search("query")
    end
  end

  it "should raise an exception if the service at the search URI returns a 404" do
    stub_request(:get, /example.com\/search/).to_return(status: [404, "Not Found"])
    assert_raises(GdsApi::HTTPNotFound) do
      GdsApi::Rummager.new("http://example.com").search("query")
    end
  end

  it "should raise an exception if the service at the search URI times out" do
    stub_request(:get, /example.com\/search/).to_timeout
    assert_raises(GdsApi::TimedOutException) do
      GdsApi::Rummager.new("http://example.com").search("query")
    end
  end

  it "should return the search deserialized from json" do
    search_results = [{"title" => "document-title"}]
    stub_request(:get, /example.com\/search/).to_return(body: search_results.to_json)
    results = GdsApi::Rummager.new("http://example.com").search("query")

    assert_equal search_results, results.to_hash
  end

  it "should return an empty set of results without making request if query is empty" do
    assert_raises(ArgumentError) do
      GdsApi::Rummager.new("http://example.com").search("")
    end
  end

  it "should return an empty set of results without making request if query is nil" do
    assert_raises(ArgumentError) do
      GdsApi::Rummager.new("http://example.com").search(nil)
    end
  end

  it "should request the search results in JSON format" do
    GdsApi::Rummager.new("http://example.com").search("query")

    assert_requested :get, /.*/, headers: {"Accept" => "application/json"}
  end

  it "should issue a request for the search term specified" do
    GdsApi::Rummager.new("http://example.com").search "search-term"

    assert_requested :get, /\?q=search-term/
  end

  it "should escape characters that would otherwise be invalid in a URI" do
    GdsApi::Rummager.new("http://example.com").search "search term with spaces"

    #the actual request is "?q=search+term+with+spaces", but Webmock appears to be re-escaping.
    assert_requested :get, /\?q=search%20term%20with%20spaces/
  end

  it "should append arbitrary parameters when supplied" do
    GdsApi::Rummager.new("http://example.com").search("search-term", foo: "bar", zoo: "baz")

    assert_requested :get, /\?foo=bar&q=search-term&zoo=baz/
  end

  # tests for #organisations

  it "should request the list of organisations" do
    stub_request(:get, /example.com\/organisations/).to_return(body: "{}")
    GdsApi::Rummager.new("http://example.com").organisations

    assert_requested :get, /organisations/
  end

  # tests for #advanced_search

  it "#advanced_search should raise an exception if the service at the search URI returns a 500" do
    stub_request(:get, /example.com\/advanced_search/).to_return(status: [500, "Internal Server Error"])
    assert_raises(GdsApi::HTTPErrorResponse) do
      GdsApi::Rummager.new("http://example.com").advanced_search({keywords: "query"})
    end
  end

  it "#advanced_search should raise an exception if the service at the search URI returns a 404" do
    stub_request(:get, /example.com\/advanced_search/).to_return(status: [404, "Not Found"])
    assert_raises(GdsApi::HTTPNotFound) do
      GdsApi::Rummager.new("http://example.com").advanced_search({keywords: "query"})
    end
  end

  it "#advanced_search should raise an exception if the service at the search URI times out" do
    stub_request(:get, /example.com\/advanced_search/).to_timeout
    assert_raises(GdsApi::TimedOutException) do
      GdsApi::Rummager.new("http://example.com").advanced_search({keywords: "query"})
    end
  end

  it "#advanced_search should return the search deserialized from json" do
    search_results = [{"title" => "document-title"}]
    stub_request(:get, /example.com\/advanced_search/).to_return(body: search_results.to_json)
    results = GdsApi::Rummager.new("http://example.com").advanced_search({keywords: "query"})

    assert_equal search_results, results.to_hash
  end

  it "#advanced_search should return an empty set of results without making request if arguments are empty" do
    assert_raises(ArgumentError) do
      GdsApi::Rummager.new("http://example.com").advanced_search({})
    end
  end

  it "#advanced_search should return an empty set of results without making request if arguments is nil" do
    assert_raises(ArgumentError) do
      results = GdsApi::Rummager.new("http://example.com").advanced_search(nil)
    end
  end

  it "#advanced_search should request the search results in JSON format" do
    GdsApi::Rummager.new("http://example.com").advanced_search({keywords: "query"})

    assert_requested :get, /.*/, headers: {"Accept" => "application/json"}
  end

  it "#advanced_search should issue a request for all the params supplied" do
    GdsApi::Rummager.new("http://example.com").advanced_search({keywords: "query & stuff", topics: ["1","2"], order: {public_timestamp: "desc"}})

    #the actual request is "?keywords=query+%26+stuff&topic[0]=1&topic[1]=2&order[public_timestamp]=desc", but Webmock appears to be re-escaping.
    assert_requested :get, /keywords=query%20%26%20stuff/
    assert_requested :get, /topics%5B0%5D=1&topics%5B1%5D=2/
    assert_requested :get, /order%5Bpublic_timestamp%5D=desc/
  end

end
