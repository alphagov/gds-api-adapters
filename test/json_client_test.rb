require_relative 'test_helper'
require 'gds_api/base'
require 'gds_api/json_client'
require 'base64'

class JsonClientTest < MiniTest::Spec
  def setup
    @json_client_cache = GdsApi::JsonClient.cache
    GdsApi::JsonClient.cache = {}
    @client = GdsApi::JsonClient.new
  end

  def teardown
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

  def test_should_fetch_and_parse_json_into_response
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 200)
    assert_equal GdsApi::Response, @client.get_json(url).class
  end

  def test_should_cache_multiple_requests_to_same_url_across_instances
    url = "http://some.endpoint/some.json"
    result = {"foo" => "bar"}
    stub_request(:get, url).to_return(:body => JSON.dump(result), :status => 200).times(1)
    response_a = GdsApi::JsonClient.new.get_json(url)
    response_b = GdsApi::JsonClient.new.get_json(url)
    assert_equal response_a.object_id, response_b.object_id
  end

  def test_should_return_nil_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 404)
    assert_nil @client.get_json(url)
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
end
