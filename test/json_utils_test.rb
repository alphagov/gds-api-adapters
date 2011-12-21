require_relative 'test_helper'
require 'gds_api/json_utils'
require 'rack'

StubRackApp = lambda do |env|
  sleep(30)
  body = '{"some":"value"}'
  [200, {"Content-Type" => "text/plain", "Content-Length" => body.length.to_s}, [body]]
end

class JsonUtilsTest < MiniTest::Unit::TestCase
  include GdsApi::JsonUtils

  def options; {}; end
  def pending_test_long_requests_timeout
    url = "http://www.example.com/timeout.json"
    stub_request(:get, url).to_rack(StubRackApp)
    assert_raises GdsApi::TimedOut do
      get_json(url)
    end
  end

  def test_get_returns_nil_on_timeout
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Timeout::Error)
    assert_nil get_json(url)
  end

  def test_get_should_raise_endpoint_not_found_if_connection_refused
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Errno::ECONNREFUSED)
    assert_raises GdsApi::EndpointNotFound do
      get_json(url)
    end
  end

  def test_post_should_raise_endpoint_not_found_if_connection_refused
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(Errno::ECONNREFUSED)
    assert_raises GdsApi::EndpointNotFound do
      get_json(url)
    end
  end

  def test_post_returns_nil_on_timeout
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_raise(Timeout::Error)
    assert_nil post_json(url, {})
  end
  
  def test_should_fetch_and_parse_json_into_hash
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}",:status => 200)
    assert_equal Hash, get_json(url).class
  end

  def test_should_return_nil_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(:body => "{}", :status => 404)
    assert_nil get_json(url)
  end
    
  def test_put_json_does_put_with_json_encoded_packet
    url = "http://some.endpoint/some.json"
    payload = {a:1}
    stub_request(:put, url).with(body: payload.to_json).to_return(:body => "{}", :status => 200)
    assert_equal({}, put_json(url, payload))
  end
end