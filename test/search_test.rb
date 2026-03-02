require "test_helper"
require "gds_api/search"

describe GdsApi::Search do
  before(:each) do
    stub_request(:get, /example.com\/search/).to_return(body: "[]")
  end

  # tests for search

  it "#search should raise an exception if the service at the search URI returns a 500" do
    stub_request(:get, /example.com\/search.json/).to_return(status: [500, "Internal Server Error"])
    assert_raises(GdsApi::HTTPServerError) do
      GdsApi::Search.new("http://example.com").search(q: "query")
    end
  end

  it "#search should raise an exception if the service at the search URI returns a 404" do
    stub_request(:get, /example.com\/search/).to_return(status: [404, "Not Found"])
    assert_raises(GdsApi::HTTPNotFound) do
      GdsApi::Search.new("http://example.com").search(q: "query")
    end
  end

  it "#search should raise an exception if the service at the search URI returns a 400" do
    stub_request(:get, /example.com\/search/).to_return(
      status: [400, "Bad Request"],
      body: '"error":"Filtering by \"coffee\" is not allowed"',
    )
    assert_raises(GdsApi::HTTPClientError) do
      GdsApi::Search.new("http://example.com").search(q: "query", filter_coffee: "tea")
    end
  end

  it "#search should raise an exception if the service at the search URI returns a 422" do
    stub_request(:get, /example.com\/search/).to_return(
      status: [422, "Bad Request"],
      body: '"error":"Filtering by \"coffee\" is not allowed"',
    )
    assert_raises(GdsApi::HTTPUnprocessableEntity) do
      GdsApi::Search.new("http://example.com").search(q: "query", filter_coffee: "tea")
    end
  end

  it "#search should raise an exception if the service at the search URI times out" do
    stub_request(:get, /example.com\/search/).to_timeout
    assert_raises(GdsApi::TimedOutException) do
      GdsApi::Search.new("http://example.com").search(q: "query")
    end
  end

  it "#search should return the search deserialized from json" do
    search_results = [{ "title" => "document-title" }]
    stub_request(:get, /example.com\/search/).to_return(body: search_results.to_json)
    results = GdsApi::Search.new("http://example.com").search(q: "query")
    assert_equal search_results, results.to_hash
  end

  it "#search should request the search results in JSON format" do
    GdsApi::Search.new("http://example.com").search(q: "query")

    assert_requested :get, /.*/, headers: { "Accept" => "application/json" }
  end

  it "#search should issue a request for all the params supplied" do
    GdsApi::Search.new("http://example.com").search(
      q: "query & stuff",
      filter_topics: %w[1 2],
      order: "-public_timestamp",
    )

    assert_requested :get, /q=query%20%26%20stuff/
    assert_requested :get, /filter_topics\[\]=1&filter_topics\[\]=2/
    assert_requested :get, /order=-public_timestamp/
  end

  it "#search can pass additional headers" do
    GdsApi::Search.new("http://example.com").search({ q: "query" }, "authorization" => "token")

    assert_requested :get, /.*/, headers: { "authorization" => "token" }
  end

  # tests for search_enum
  it "#search_enum returns two pages - last page is half full" do
    stub_request(:get, /example.com\/search/)
      .with(query: hash_including(start: "0", count: "2"))
      .to_return(body: { "results" => [{ "title" => "t1" }, { "title" => "t2" }] }.to_json)

    stub_request(:get, /example.com\/search/)
      .with(query: hash_including(start: "2", count: "2"))
      .to_return(body: { "results" => [{ "title" => "t3" }] }.to_json)

    search_results = [{ "title" => "t1" }, { "title" => "t2" }, { "title" => "t3" }]
    results = GdsApi::Search.new("http://example.com").search_enum({}, page_size: 2)
    assert_equal search_results, results.to_a
  end

  it "#search_enum returns two pages - last page is full" do
    stub_request(:get, /example.com\/search/)
      .with(query: hash_including(start: "0", count: "2"))
      .to_return(body: { "results" => [{ "title" => "t1" }, { "title" => "t2" }] }.to_json)

    stub_request(:get, /example.com\/search/)
      .with(query: hash_including(start: "2", count: "2"))
      .to_return(body: { "results" => [{ "title" => "t3" }, { "title" => "t4" }] }.to_json)

    stub_request(:get, /example.com\/search/)
      .with(query: { start: "4", count: "2" })
      .to_return(body: { "results" => [] }.to_json)

    search_results = [{ "title" => "t1" }, { "title" => "t2" }, { "title" => "t3" }, { "title" => "t4" }]
    results = GdsApi::Search.new("http://example.com").search_enum({}, page_size: 2)
    assert_equal search_results, results.to_a
  end
end
