require "test_helper"
require "gds_api/search_api_v2"

describe GdsApi::SearchApiV2 do
  describe "#search" do
    before(:each) do
      stub_request(:get, /example.com\/search/).to_return(body: "[]")
    end

    it "should raise an exception if the request is unsuccessful" do
      stub_request(:get, /example.com\/search.json/).to_return(status: [500, "Internal Server Error"])
      assert_raises(GdsApi::HTTPServerError) do
        GdsApi::SearchApiV2.new("http://example.com").search(q: "query")
      end
    end

    it "should return the search deserialized from json" do
      search_results = [{ "title" => "document-title" }]
      stub_request(:get, /example.com\/search/).to_return(body: search_results.to_json)
      results = GdsApi::SearchApiV2.new("http://example.com").search(q: "query")
      assert_equal search_results, results.to_hash
    end

    it "should request the search results in JSON format" do
      GdsApi::SearchApiV2.new("http://example.com").search(q: "query")

      assert_requested :get, /.*/, headers: { "Accept" => "application/json" }
    end

    it "should issue a request for all the params supplied" do
      GdsApi::SearchApiV2.new("http://example.com").search(
        q: "query & stuff",
        filter_topics: %w[1 2],
        order: "-public_timestamp",
      )

      assert_requested :get, /q=query%20%26%20stuff/
      assert_requested :get, /filter_topics\[\]=1&filter_topics\[\]=2/
      assert_requested :get, /order=-public_timestamp/
    end

    it "can pass additional headers" do
      GdsApi::SearchApiV2.new("http://example.com").search({ q: "query" }, "authorization" => "token")

      assert_requested :get, /.*/, headers: { "authorization" => "token" }
    end
  end

  describe "#autocomplete" do
    before(:each) do
      stub_request(:get, /example.com\/autocomplete/).to_return(body: "[]")
    end

    it "should raise an exception if the request is unsuccessful" do
      stub_request(:get, /example.com\/autocomplete.json/).to_return(
        status: [500, "Internal Server Error"],
      )
      assert_raises(GdsApi::HTTPServerError) do
        GdsApi::SearchApiV2.new("http://example.com").autocomplete("prime minis")
      end
    end

    it "should request the autocomplete results in JSON format" do
      GdsApi::SearchApiV2.new("http://example.com").autocomplete("prime minis")

      assert_requested :get, /.*/, headers: { "Accept" => "application/json" }
    end

    it "should issue a request for the correct query" do
      GdsApi::SearchApiV2.new("http://example.com").autocomplete("prime minis")

      assert_requested :get, /q=prime%20minis/
    end
  end
end
