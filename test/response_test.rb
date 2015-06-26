require_relative 'test_helper'
require 'gds_api/response'

describe GdsApi::Response do

  describe "accessing HTTP response details" do
    before :each do
      @mock_http_response = stub(:body => "A Response body", :code => 200, :headers => {:cache_control => 'public'})
      @response = GdsApi::Response.new(@mock_http_response)
    end

    it "should return the raw response body" do
      assert_equal "A Response body", @response.raw_response_body
    end

    it "should return the status code" do
      assert_equal 200, @response.code
    end

    it "should pass-on the response headers" do
      assert_equal({:cache_control => 'public'}, @response.headers)
    end
  end

  describe ".cache_control_private?" do
    it "returns true if the response contains a cache-control private header" do
      headers = { :cache_control => 'max-age=5, private' }

      mock_http_response = stub(:body => "{}", :code => 200, :headers => headers)
      response = GdsApi::Response.new(mock_http_response)

      assert response.cache_control_private?
    end

    it "returns false if the response does not contain a cache-control private header" do
      headers = { :cache_control => 'max-age=5, public' }

      mock_http_response = stub(:body => "{}", :code => 200, :headers => headers)
      response = GdsApi::Response.new(mock_http_response)

      refute response.cache_control_private?
    end
  end

  describe ".expires_at" do
    it "should be calculated from cache-control max-age" do
      Timecop.freeze(Time.parse("15:00")) do
        cache_control_headers = { :cache_control => 'public, max-age=900' }
        headers = cache_control_headers.merge(date: Time.now.httpdate)

        mock_http_response = stub(:body => "A Response body", :code => 200, :headers => headers)
        response = GdsApi::Response.new(mock_http_response)

        assert_equal Time.parse("15:15"), response.expires_at
      end
    end

    it "should be same as the value of Expires header in absence of max-age" do
      Timecop.freeze(Time.parse("15:00")) do
        cache_headers = { :cache_control => 'public', :expires => (Time.now + 900).httpdate }
        headers = cache_headers.merge(date: Time.now.httpdate)

        mock_http_response = stub(:body => "A Response body", :code => 200, :headers => headers)
        response = GdsApi::Response.new(mock_http_response)

        assert_equal Time.parse("15:15"), response.expires_at
      end
    end

    it "should be nil in absence of Expires header and max-age" do
      mock_http_response = stub(:body => "A Response body", :code => 200, :headers => { :date => Time.now.httpdate })
      response = GdsApi::Response.new(mock_http_response)

      assert_nil response.expires_at
    end

    it "should be nil in absence of Date header and max-age" do
      mock_http_response = stub(:body => "A Response body", :code => 200, :headers => {})
      response = GdsApi::Response.new(mock_http_response)

      assert_nil response.expires_at
    end
  end

  describe ".expires_in" do
    it "should be seconds remaining from expiration time inferred from max-age" do
      cache_control_headers = { :cache_control => 'public, max-age=900' }
      headers = cache_control_headers.merge(date: Time.now.httpdate)
      mock_http_response = stub(:body => "A Response body", :code => 200, :headers => headers)

      Timecop.travel(12 * 60) do
        response = GdsApi::Response.new(mock_http_response)
        assert_equal 180, response.expires_in
      end
    end

    it "should be seconds remaining from expiration time inferred from Expires header" do
      cache_headers = { :cache_control => 'public', :expires => (Time.now + 900).httpdate }
      headers = cache_headers.merge(date: Time.now.httpdate)
      mock_http_response = stub(:body => "A Response body", :code => 200, :headers => headers)

      Timecop.travel(12 * 60) do
        response = GdsApi::Response.new(mock_http_response)
        assert_equal 180, response.expires_in
      end
    end

    it "should be nil in absence of Expires header and max-age" do
      mock_http_response = stub(:body => "A Response body", :code => 200, :headers => { :date => Time.now.httpdate })
      response = GdsApi::Response.new(mock_http_response)

      assert_nil response.expires_in
    end

    it "should be nil in absence of Date header" do
      cache_control_headers = { :cache_control => 'public, max-age=900' }
      mock_http_response = stub(:body => "A Response body", :code => 200, :headers => cache_control_headers)
      response = GdsApi::Response.new(mock_http_response)

      assert_nil response.expires_in
    end
  end

  describe "processing web_urls" do
    def build_response(body_string, relative_to = "https://www.gov.uk")
      GdsApi::Response.new(stub(:body => body_string), :web_urls_relative_to => relative_to)
    end

    it "should map web URLs" do
      body = {
        "web_url" => "https://www.gov.uk/test"
      }.to_json
      assert_equal "/test", build_response(body).web_url
    end

    it "should leave other properties alone" do
      body = {
        "title" => "Title",
        "description" => "Description"
      }.to_json
      response = build_response(body)
      assert_equal "Title", response.title
      assert_equal "Description", response.description
    end

    it "should traverse into hashes" do
      body = {
        "details" => {
          "chirality" => "widdershins",
          "web_url" => "https://www.gov.uk/left",
        }
      }.to_json

      response = build_response(body)
      assert_equal "/left", response.details.web_url
    end

    it "should traverse into arrays" do
      body = {
        "other_urls" => [
          { "title" => "Pies", "web_url" => "https://www.gov.uk/pies" },
          { "title" => "Cheese", "web_url" => "https://www.gov.uk/cheese" },
        ]
      }.to_json

      response = build_response(body)
      assert_equal "/pies", response.other_urls[0].web_url
      assert_equal "/cheese", response.other_urls[1].web_url
    end

    it "should handle nil values" do
      body = {"web_url" => nil}.to_json

      response = build_response(body)
      assert_nil response.web_url
    end

    it "should handle query parameters" do
      body = {
        "web_url" => "https://www.gov.uk/thing?does=stuff"
      }.to_json

      response = build_response(body)
      assert_equal "/thing?does=stuff", response.web_url
    end

    it "should handle fragments" do
      body = {
        "web_url" => "https://www.gov.uk/thing#part-2"
      }.to_json

      response = build_response(body)
      assert_equal "/thing#part-2", response.web_url
    end

    it "should keep URLs from other domains absolute" do
      body = {
        "web_url" => "https://www.example.com/example"
      }.to_json

      response = build_response(body)
      assert_equal "https://www.example.com/example", response.web_url
    end

    it "should keep URLs with other schemes absolute" do
      body = {
        "web_url" => "http://www.example.com/example"
      }.to_json

      response = build_response(body)
      assert_equal "http://www.example.com/example", response.web_url
    end
  end

  describe "hash and openstruct access" do
    before :each do
      @response_data = {
        "_response_info" => {
            "status" => "ok"
        },
        "id" => "https://www.gov.uk/api/vat-rates.json",
        "web_url" => "https://www.gov.uk/vat-rates",
        "title" => "VAT rates",
        "format" => "answer",
        "updated_at" => "2013-04-04T15:51:54+01:00",
        "details" => {
            "need_id" => "1870",
            "business_proposition" => false,
            "description" => "Current VAT rates - standard 20% and rates for reduced rate and zero-rated items",
            "language" => "en",
        },
        "tags" => [
          {"slug" => "foo"},
          {"slug" => "bar"},
          {"slug" => "baz"},
        ],
      }
      @response = GdsApi::Response.new(stub(:body => @response_data.to_json))
    end

    describe "behaving like a read-only hash" do
      it "should allow accessing members by key" do
        assert_equal "VAT rates", @response["title"]
      end

      it "should allow accessing nested keys" do
        assert_equal "1870", @response["details"]["need_id"]
      end

      it "should return nil for a non-existent key" do
        assert_equal nil, @response["foo"]
      end

      it "should memoize the parsed hash" do
        @response["id"]
        JSON.expects(:parse).never
        assert_equal "VAT rates", @response["title"]
      end
    end

    describe "behaving like a read-only openstruct" do
      it "should allow accessing members using methods" do
        assert_equal "VAT rates", @response.title
      end

      it "should allow accessing nested values" do
        assert_equal "1870", @response.details.need_id
      end

      it "should allow accessing values nested within arrays" do
        assert_equal "bar", @response.tags[1].slug
      end

      it "should return nil for a non-existent key" do
        assert_equal nil, @response.foo
      end

      it "should memoize the generated openstruct" do
        @response.id
        GdsApi::Response.expects(:build_ostruct_recursively).never
        assert_equal "VAT rates", @response.title
      end

      describe "handling respond_to?" do
        it "should respond_to methods for keys that exist" do
          assert @response.respond_to?(:title)
        end

        it "should not respond_to keys that don't exist" do
          assert ! @response.respond_to?(:foo)
        end
      end
    end
  end
end
