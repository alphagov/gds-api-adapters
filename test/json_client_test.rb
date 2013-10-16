require_relative 'test_helper'
require 'gds_api/base'
require 'gds_api/json_client'
require 'base64'

class JsonClientTest < MiniTest::Spec
  def setup
    @json_client_cache = GdsApi::JsonClient.cache

    # Set the cache to nil so the JsonClient recreates it on each test run
    # This used to initialise the cache to an empty Hash, eliminating the
    # potential problem of cache entries expiring during a test run, but that
    # no longer works now our code calls the `store` method with an expiry time
    GdsApi::JsonClient.cache = nil

    @client = GdsApi::JsonClient.new
  end

  def teardown
    super
    GdsApi::JsonClient.cache = @json_client_cache
  end

  def options;
    {}
  end

  def test_long_get_requests_timeout
    url = "http://www.example.com/timeout.json"
    stub_request(:get, url).to_timeout
    assert_raises GdsApi::TimedOutException do
      @client.get_json(url)
    end
  end

  def test_get_should_raise_endpoint_not_found_if_connection_refused
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Errno::ECONNREFUSED)
    assert_raises GdsApi::EndpointNotFound do
      @client.get_json(url)
    end
  end

  def test_post_should_raise_endpoint_not_found_if_connection_refused
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Errno::ECONNREFUSED)
    assert_raises GdsApi::EndpointNotFound do
      @client.get_json(url)
    end
  end

  def test_post_requests_timeout
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_timeout
    assert_raises GdsApi::TimedOutException do
      @client.post_json(url, {})
    end
  end

  def test_get_should_raise_error_on_restclient_error
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(RestClient::ServerBrokeConnection)
    assert_raises GdsApi::HTTPErrorResponse do
      @client.get_json(url)
    end
  end

  def test_should_fetch_and_parse_json_into_response
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 200)
    assert_equal GdsApi::Response, @client.get_json(url).class
  end

  def test_should_cache_multiple_requests_to_same_url_across_instances
    url = "http://some.endpoint/some.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(:body => JSON.dump(result), :status => 200)
    response_a = GdsApi::JsonClient.new.get_json(url)
    response_b = GdsApi::JsonClient.new.get_json(url)
    assert_equal response_a.to_hash, response_b.to_hash
    assert_requested :get, url, times: 1
  end

  def test_allow_overriding_the_number_of_cached_items
    # Clear out the default cache instance, because otherwise the customisation
    # doesn't take effect, due to some non-obvious behaviour in JsonClient.
    GdsApi::JsonClient.cache = nil

    url = "http://some.endpoint/"
    result = {"foo" => "bar"}
    stub_request(:get, %r{\A#{url}}).to_return do |request|
      {:body => {"url" => request.uri}.to_json, :status => 200}
    end

    response_a = GdsApi::JsonClient.new(:cache_size => 5).get_json("#{url}/first.json")
    response_b = GdsApi::JsonClient.new.get_json("#{url}/second.json")
    4.times { |n| GdsApi::JsonClient.new.get_json("#{url}/#{n}.json") }

    response_c = GdsApi::JsonClient.new.get_json("#{url}/second.json")
    response_d = GdsApi::JsonClient.new.get_json("#{url}/first.json")

    assert_requested :get, "#{url}/second.json", times: 1
    assert_requested :get, "#{url}/first.json", times: 2
    assert_equal response_b.to_hash, response_c.to_hash
    assert_equal response_a.to_hash, response_d.to_hash
  end

  def test_should_cache_requests_for_15_mins_by_default
    url = "http://some.endpoint/some.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(:body => JSON.dump(result), :status => 200)#.times(1)
    response_a = GdsApi::JsonClient.new.get_json(url)
    response_b = GdsApi::JsonClient.new.get_json(url)

    assert_requested :get, url, times: 1
    assert_equal response_a.to_hash, response_b.to_hash

    Timecop.travel( 15 * 60 - 30) do # now + 14 mins 30 secs
      response_c = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 1
      assert_equal response_a.to_hash, response_c.to_hash
    end

    Timecop.travel( 15 * 60 + 30) do # now + 15 mins 30 secs
      response_d = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_d.to_hash
    end
  end

  def test_should_allow_overriding_cache_ttl
    # Clear out the default cache instance, because otherwise the customisation
    # doesn't take effect, due to some non-obvious behaviour in JsonClient.
    GdsApi::JsonClient.cache = nil

    url = "http://some.endpoint/some.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(:body => JSON.dump(result), :status => 200)#.times(1)
    response_a = GdsApi::JsonClient.new(:cache_ttl => 5 * 60).get_json(url)
    response_b = GdsApi::JsonClient.new.get_json(url)

    assert_requested :get, url, times: 1
    assert_equal response_a.to_hash, response_b.to_hash

    Timecop.travel( 5 * 60 - 30) do # now + 4 mins 30 secs
      response_c = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 1
      assert_equal response_a.to_hash, response_c.to_hash
    end

    Timecop.travel( 5 * 60 + 30) do # now + 5 mins 30 secs
      response_d = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_d.to_hash
    end
  end

  def test_should_allow_disabling_caching
    url = "http://some.endpoint/some.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(:body => JSON.dump(result), :status => 200)

    client = GdsApi::JsonClient.new(disable_cache: true)

    response_a = client.get_json(url)
    response_b = client.get_json(url)

    assert_requested :get, url, times: 2

    [response_a, response_b].each do |r|
      assert_equal result, r.to_hash
    end
  end

  def test_should_respect_expiry_headers
    url = "http://some.endpoint/some.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(
      :body => JSON.dump(result),
      :status => 200,
      :headers => { "Expires" => (Time.now + 7 * 60).utc.httpdate }
    )

    response_a = GdsApi::JsonClient.new.get_json(url)

    Timecop.travel( 7 * 60 - 30) do # now + 6 mins 30 secs
      response_b = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 1
      assert_equal response_a.to_hash, response_b.to_hash
    end

    Timecop.travel( 7 * 60 + 30) do # now + 7 mins 30 secs
      response_c = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_c.to_hash
    end
  end

  def test_should_respect_cache_control_headers_with_max_age
    url = "http://some.endpoint/max_age.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(
      :body => JSON.dump(result),
      :status => 200,
      :headers => { "Cache-Control" => "max-age=420, public" } # 6 minutes
    )

    response_a = GdsApi::JsonClient.new.get_json(url)

    Timecop.travel( 7 * 60 - 30) do # now + 6 mins 30 secs
      response_b = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 1
      assert_equal response_a.to_hash, response_b.to_hash
    end

    Timecop.travel( 7 * 60 + 30) do # now + 7 mins 30 secs
      response_c = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_c.to_hash
    end
  end

  def test_should_respect_cache_control_headers_with_no_cache
    url = "http://some.endpoint/no_cache.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(
      :body => JSON.dump(result),
      :status => 200,
      :headers => { "Cache-Control" => "no-cache, public" }
    )

    response_a = GdsApi::JsonClient.new.get_json(url)

    Timecop.travel( 7 * 60 - 30) do # now + 6 mins 30 secs
      response_b = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_b.to_hash
    end
  end

  def test_should_respect_cache_control_headers_with_no_cache_and_max_age
    url = "http://some.endpoint/no_cache_and_max_age.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(
      :body => JSON.dump(result),
      :status => 200,
      :headers => { "Cache-Control" => "max-age=600, no-cache, public" }
    )

    response_a = GdsApi::JsonClient.new.get_json(url)

    Timecop.travel( 7 * 60 - 30) do # now + 6 mins 30 secs
      response_b = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_b.to_hash
    end
  end

  def test_should_use_cache_control_headers_over_expires_headers
    url = "http://some.endpoint/url.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(
      :body => JSON.dump(result),
      :status => 200,
      :headers => {
        "Cache-Control" => "no-cache",
        "Expires" => (Time.now + 7 * 60).utc.httpdate
      }
    )

    response_a = GdsApi::JsonClient.new.get_json(url)

    Timecop.travel( 7 * 60 - 30) do # now + 6 mins 30 secs
      response_b = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 2
      assert_equal response_a.to_hash, response_b.to_hash
    end
  end

  def test_should_fallback_to_expires_headers_if_cache_control_is_malformed
    url = "http://some.endpoint/url.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(
      :body => JSON.dump(result),
      :status => 200,
      :headers => {
        "Cache-Control" => "foo, bar, baz",
        "Expires" => (Time.now + 7 * 60).utc.httpdate
      }
    )

    response_a = GdsApi::JsonClient.new.get_json(url)

    Timecop.travel( 7 * 60 - 30) do # now + 6 mins 30 secs
      response_b = GdsApi::JsonClient.new.get_json(url)

      assert_requested :get, url, times: 1
      assert_equal response_a.to_hash, response_b.to_hash
    end
  end

  def test_should_raise_http_not_found_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 404)
    assert_raises GdsApi::HTTPNotFound do
      @client.get_json!(url)
    end
  end

  def test_get_should_be_nil_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 404)
    assert_nil @client.get_json(url)
  end

  def test_get_should_raise_error_if_non_404_error_code_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 500)
    assert_raises GdsApi::HTTPErrorResponse do
      @client.get_json(url)
    end
  end

  def test_get_should_follow_permanent_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      :body => "",
      :status => 301,
      :headers => {"Location" => new_url}
    )
    stub_request(:get, new_url).to_return(:body => '{"a": 1}', :status => 200)
    result = @client.get_json(url)
    assert_equal 1, result.a
  end

  def test_get_should_follow_found_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      :body => "",
      :status => 302,
      :headers => {"Location" => new_url}
    )
    stub_request(:get, new_url).to_return(:body => '{"a": 1}', :status => 200)
    result = @client.get_json(url)
    assert_equal 1, result.a
  end

  def test_get_should_follow_see_other
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      :body => "",
      :status => 303,
      :headers => {"Location" => new_url}
    )
    stub_request(:get, new_url).to_return(:body => '{"a": 1}', :status => 200)
    result = @client.get_json(url)
    assert_equal 1, result.a
  end

  def test_get_should_follow_temporary_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      :body => "",
      :status => 307,
      :headers => {"Location" => new_url}
    )
    stub_request(:get, new_url).to_return(:body => '{"a": 1}', :status => 200)
    result = @client.get_json(url)
    assert_equal 1, result.a
  end

  def test_should_handle_infinite_redirects
    url = "http://some.endpoint/some.json"
    redirect = {
      :body => "",
      :status => 302,
      :headers => {"Location" => url}
    }

    # Theoretically, we could set this up to mock out any number of requests
    # with a redirect to the same URL, but we'd risk getting the test code into
    # an infinite loop if the code didn't do what it was supposed to. The
    # failure response block aborts the test if we have too many requests.
    failure = lambda { |request| flunk("Request called too many times") }
    stub_request(:get, url).to_return(redirect).times(11).then.to_return(failure)

    assert_raises GdsApi::TooManyRedirects do
      @client.get_json(url)
    end
  end

  def test_should_handle_mutual_redirects
    first_url = "http://some.endpoint/some.json"
    second_url = "http://some.endpoint/some-other.json"

    first_redirect = {
      :body => "",
      :status => 302,
      :headers => {"Location" => second_url}
    }
    second_redirect = {
      :body => "",
      :status => 302,
      :headers => {"Location" => first_url}
    }

    # See the comment in the above test for an explanation of this
    failure = lambda { |request| flunk("Request called too many times") }
    stub_request(:get, first_url).to_return(first_redirect).times(6).then.to_return(failure)
    stub_request(:get, second_url).to_return(second_redirect).times(6).then.to_return(failure)

    assert_raises GdsApi::TooManyRedirects do
      @client.get_json(first_url)
    end
  end

  def test_post_should_be_nil_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(:body => "{}", :status => 404)
    assert_nil @client.post_json(url, {})
  end

  def test_post_should_raise_error_if_non_404_error_code_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(:body => "{}", :status => 500)
    assert_raises GdsApi::HTTPErrorResponse do
      @client.post_json(url, {})
    end
  end

  def test_post_should_error_on_found_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:post, url).to_return(
      :body => "",
      :status => 302,
      :headers => {"Location" => new_url}
    )
    assert_raises GdsApi::HTTPErrorResponse do
      @client.post_json(url, {})
    end
  end

  def test_put_should_be_nil_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(:body => "{}", :status => 404)
    assert_nil @client.put_json(url, {})
  end

  def test_put_should_raise_error_if_non_404_error_code_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(:body => "{}", :status => 500)
    assert_raises GdsApi::HTTPErrorResponse do
      @client.put_json(url, {})
    end
  end

  def empty_response
    net_http_response = stub(:body => '{}')
    GdsApi::Response.new(net_http_response)
  end

  def test_put_json_does_put_with_json_encoded_packet
    url = "http://some.endpoint/some.json"
    payload = {a: 1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => "{}", :status => 200)
    assert_equal({}, @client.put_json(url, payload).to_hash)
  end

  def test_does_not_encode_json_if_payload_is_nil
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).with(body: nil).to_return(:body => "{}", :status => 200)
    assert_equal({}, @client.put_json(url, nil).to_hash)
  end

  def test_can_build_custom_response_object
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "Hello there!")

    response = @client.get_json(url) { |http_response| http_response.body }
    assert response.is_a? String
    assert_equal "Hello there!", response
  end

  def test_responds_with_nil_on_custom_response_404
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "", :status => 404)

    response = @client.get_json(url) { |http_response| http_response.body }
    assert_nil response
  end

  def test_can_build_custom_response_object_in_bang_method
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "Hello there!")

    response = @client.get_json!(url) { |http_response| http_response.body }
    assert response.is_a? String
    assert_equal "Hello there!", response
  end

  def test_can_convert_response_to_ostruct
    url = "http://some.endpoint/some.json"
    payload = {a: 1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => '{"a":1}', :status => 200)
    response = @client.put_json(url, payload)
    assert_equal(OpenStruct.new(a: 1), response.to_ostruct)
  end

  def test_can_access_attributes_of_response_directly
    url = "http://some.endpoint/some.json"
    payload = {a: 1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => '{"a":{"b":2}}', :status => 200)
    response = @client.put_json(url, payload)
    assert_equal 2, response.a.b
  end

  def test_accessing_non_existent_attribute_of_response_returns_nil
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(:body => '{"a":1}', :status => 200)
    response = @client.put_json(url, {})
    assert_equal nil, response.does_not_exist
  end

  def test_response_does_not_claim_to_respond_to_methods_corresponding_to_non_existent_attributes
    # This mimics the behaviour of OpenStruct
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(:body => '{"a":1}', :status => 200)
    response = @client.put_json(url, {})
    assert ! response.respond_to?(:does_not_exist)
  end

  def test_a_response_is_always_considered_present_and_not_blank
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(:body => '{"a":1}', :status => 200)
    response = @client.put_json(url, {})
    assert ! response.blank?
    assert response.present?
  end

  def test_client_can_use_basic_auth
    client = GdsApi::JsonClient.new(basic_auth: {user: 'user', password: 'password'})

    stub_request(:put, "http://user:password@some.endpoint/some.json").
      to_return(:body => '{"a":1}', :status => 200)

    response = client.put_json("http://some.endpoint/some.json", {})
    assert_equal 1, response.a
  end

  def test_client_can_use_bearer_token
    client = GdsApi::JsonClient.new(bearer_token: 'SOME_BEARER_TOKEN')
    expected_headers = GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS.
      merge('Authorization' => 'Bearer SOME_BEARER_TOKEN')

    stub_request(:put, "http://some.other.endpoint/some.json").
      with(:headers => expected_headers).
      to_return(:body => '{"a":2}', :status => 200)

    response = client.put_json("http://some.other.endpoint/some.json", {})
    assert_equal 2, response.a
  end

  def test_client_can_set_custom_headers_on_gets
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(:status => 200)

    response = GdsApi::JsonClient.new.get_json("http://some.other.endpoint/some.json", 
                                               { "HEADER-A" => "B", "HEADER-C" => "D" })

    assert_requested(:get, %r{/some.json}) do |request|
      headers_with_uppercase_names = Hash[request.headers.collect {|key, value| [key.upcase, value] }]
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_set_custom_headers_on_posts
    stub_request(:post, "http://some.other.endpoint/some.json").to_return(:status => 200)

    response = GdsApi::JsonClient.new.post_json("http://some.other.endpoint/some.json", {}, 
                                                { "HEADER-A" => "B", "HEADER-C" => "D" })

    assert_requested(:post, %r{/some.json}) do |request|
      headers_with_uppercase_names = Hash[request.headers.collect {|key, value| [key.upcase, value] }]
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_set_custom_headers_on_puts
    stub_request(:put, "http://some.other.endpoint/some.json").to_return(:status => 200)

    response = GdsApi::JsonClient.new.put_json("http://some.other.endpoint/some.json", {}, 
                                               { "HEADER-A" => "B", "HEADER-C" => "D" })

    assert_requested(:put, %r{/some.json}) do |request|
      headers_with_uppercase_names = Hash[request.headers.collect {|key, value| [key.upcase, value] }]
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_set_custom_headers_on_deletes
    stub_request(:delete, "http://some.other.endpoint/some.json").to_return(:status => 200)

    response = GdsApi::JsonClient.new.delete_json("http://some.other.endpoint/some.json", {}, 
                                                  { "HEADER-A" => "B", "HEADER-C" => "D" })

    assert_requested(:delete, %r{/some.json}) do |request|
      headers_with_uppercase_names = Hash[request.headers.collect {|key, value| [key.upcase, value] }]
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_decompress_gzip_responses
    url = "http://some.endpoint/some.json"
    # {"test": "hello"}
    stub_request(:get, url).to_return(:body => "\u001F\x8B\b\u0000Q\u000F\u0019Q\u0000\u0003\xABVP*I-.Q\xB2RP\xCAH\xCD\xC9\xC9WR\xA8\u0005\u0000\xD1C\u0018\xFE\u0013\u0000\u0000\u0000", :status => 200, :headers => { 'Content-Encoding' => 'gzip' })
    response = @client.get_json(url)

    assert_equal "hello", response["test"]
  end

  def test_client_can_post_multipart_responses
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).
      with(:body => %r{Content\-Disposition: form\-data; name="a"\r\n\r\n123}, :headers => {'Content-Type' => %r{multipart/form-data; boundary=\d+}}).
      to_return(:body => '{"b": "1"}', :status => 200)

    response = @client.post_multipart("http://some.endpoint/some.json", {"a" => "123"})
    assert_equal "1", response["b"]
  end

  def test_post_multipart_should_raise_exception_if_not_found
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(:body => '', :status => 404)

    assert_raises GdsApi::HTTPNotFound do
      @client.post_multipart("http://some.endpoint/some.json", {"a" => "123"})
    end
  end

  def test_post_multipart_should_raise_error_responses
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(:body => '', :status => 500)

    assert_raises GdsApi::HTTPErrorResponse do
      @client.post_multipart("http://some.endpoint/some.json", {"a" => "123"})
    end
  end

  def test_should_raise_error_if_attempting_to_disable_timeout
    assert_raises RuntimeError do
      GdsApi::JsonClient.new(:disable_timeout => true)
    end
    assert_raises RuntimeError do
      GdsApi::JsonClient.new(:timeout => -1)
    end
  end
end
