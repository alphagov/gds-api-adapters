require_relative 'test_helper'
require 'gds_api/base'
require 'gds_api/json_client'
require 'rack'
require 'base64'

StubRackApp = lambda do |env|
  sleep(30)
  body = '{"some":"value"}'
  [200, {"Content-Type" => "text/plain", "Content-Length" => body.length.to_s}, [body]]
end

class JsonClientTest < MiniTest::Spec
  def setup
    @client = GdsApi::JsonClient.new
  end

  def options; {}; end
  def pending_test_long_requests_timeout
    url = "http://www.example.com/timeout.json"
    stub_request(:get, url).to_rack(StubRackApp)
    assert_raises GdsApi::TimedOut do
      @client.get_json(url)
    end
  end

  def test_get_returns_nil_on_timeout
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Timeout::Error)
    assert_nil @client.get_json(url)
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

  def test_post_returns_nil_on_timeout
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_raise(Timeout::Error)
    assert_nil @client.post_json(url, {})
  end

  def test_should_fetch_and_parse_json_into_response
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}",:status => 200)
    assert_equal GdsApi::Response, @client.get_json(url).class
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
    payload = {a:1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => "{}", :status => 200)
    assert_equal({}, @client.put_json(url, payload).to_hash)
  end
  
  def test_can_convert_response_to_ostruct
    url = "http://some.endpoint/some.json"
    payload = {a:1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => '{"a":1}', :status => 200)
    response = @client.put_json(url, payload)
    assert_equal(OpenStruct.new(a:1), response.to_ostruct)
  end
  
  def test_can_access_attributes_of_response_directly
    url = "http://some.endpoint/some.json"
    payload = {a:1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => '{"a":{"b":2}}', :status => 200)
    response = @client.put_json(url, payload)
    assert_equal 2, response.a.b
  end

  def test_client_can_use_basic_auth
    client = GdsApi::JsonClient.new(basic_auth: {user: 'user', password: 'password'})

    stub_request(:put, "http://user:password@some.endpoint/some.json")
      .to_return(:body => '{"a":1}', :status => 200)
    response = client.put_json("http://some.endpoint/some.json", {})
    assert_equal 1, response.a
  end
end
