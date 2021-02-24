require_relative "test_helper"
require "gds_api/base"
require "gds_api/json_client"
require "base64"
require "null_logger"

class JsonClientTest < MiniTest::Spec
  def setup
    @client = GdsApi::JsonClient.new

    WebMock.disable_net_connect!
  end

  def options
    {}
  end

  def test_long_get_requests_timeout
    url = "http://www.example.com/timeout.json"
    stub_request(:get, url).to_timeout
    assert_raises GdsApi::TimedOutException do
      @client.get_json(url)
    end
  end

  def test_long_connections_timeout
    url = "http://www.example.com/timeout.json"
    exception = defined?(Net::OpenTimeout) ? Net::OpenTimeout : TimeoutError
    stub_request(:get, url).to_raise(exception)
    assert_raises GdsApi::TimedOutException do
      @client.get_json(url)
    end
  end

  def test_request_an_invalid_url
    url = "http://www.example.com/there-is-a-space-in-this-slug /"
    assert_raises GdsApi::InvalidUrl do
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

  def test_socket_error
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_raise(SocketError)
    assert_raises GdsApi::SocketErrorException do
      @client.get_json(url)
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
    stub_request(:get, url).to_return(body: "{}", status: 200)
    assert_equal GdsApi::Response, @client.get_json(url).class
  end

  def test_get_bang_should_raise_http_not_found_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 404)
    assert_raises GdsApi::HTTPNotFound do
      @client.get_json(url)
    end
  end

  def test_get_bang_should_raise_http_gone_if_410_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 410)
    assert_raises GdsApi::HTTPGone do
      @client.get_json(url)
    end
  end

  def test_get_bang_should_raise_http_forbidden_if_403_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 403)
    assert_raises GdsApi::HTTPForbidden do
      @client.get_json(url)
    end
  end

  def test_get_should_raise_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 404)
    assert_raises GdsApi::HTTPNotFound do
      @client.get_json(url)
    end
  end

  def test_get_should_raise_if_410_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 410)
    assert_raises GdsApi::HTTPGone do
      @client.get_json(url)
    end
  end

  def test_get_raw_should_raise_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 404)
    assert_raises GdsApi::HTTPNotFound do
      @client.get_raw(url)
    end
  end

  def test_get_raw_should_be_nil_if_410_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 410)
    assert_raises GdsApi::HTTPGone do
      @client.get_raw(url)
    end
  end

  def test_get_should_raise_error_if_non_404_non_410_error_code_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "{}", status: 500)
    assert_raises GdsApi::HTTPServerError do
      @client.get_json(url)
    end
  end

  def test_get_should_raise_conflict_for_409
    url = "http://some.endpoint/some.json"
    stub_request(:delete, url).to_return(body: "{}", status: 409)
    assert_raises GdsApi::HTTPConflict do
      @client.delete_json(url)
    end
  end

  def test_get_should_follow_permanent_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      body: "",
      status: 301,
      headers: { "Location" => new_url },
    )
    stub_request(:get, new_url).to_return(body: '{"a": 1}', status: 200)
    result = @client.get_json(url)
    assert_equal 1, result["a"]
  end

  def test_get_should_follow_found_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      body: "",
      status: 302,
      headers: { "Location" => new_url },
    )
    stub_request(:get, new_url).to_return(body: '{"a": 1}', status: 200)
    result = @client.get_json(url)
    assert_equal 1, result["a"]
  end

  def test_get_should_follow_see_other
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      body: "",
      status: 303,
      headers: { "Location" => new_url },
    )
    stub_request(:get, new_url).to_return(body: '{"a": 1}', status: 200)
    result = @client.get_json(url)
    assert_equal 1, result["a"]
  end

  def test_get_should_follow_temporary_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:get, url).to_return(
      body: "",
      status: 307,
      headers: { "Location" => new_url },
    )
    stub_request(:get, new_url).to_return(body: '{"a": 1}', status: 200)
    result = @client.get_json(url)
    assert_equal 1, result["a"]
  end

  def test_should_handle_infinite_redirects
    url = "http://some.endpoint/some.json"
    redirect = {
      body: "",
      status: 302,
      headers: { "Location" => url },
    }

    # Theoretically, we could set this up to mock out any number of requests
    # with a redirect to the same URL, but we'd risk getting the test code into
    # an infinite loop if the code didn't do what it was supposed to. The
    # failure response block aborts the test if we have too many requests.
    failure = ->(_request) { flunk("Request called too many times") }
    stub_request(:get, url).to_return(redirect).times(11).then.to_return(failure)

    assert_raises GdsApi::HTTPErrorResponse do
      @client.get_json(url)
    end
  end

  def test_should_handle_mutual_redirects
    first_url = "http://some.endpoint/some.json"
    second_url = "http://some.endpoint/some-other.json"

    first_redirect = {
      body: "",
      status: 302,
      headers: { "Location" => second_url },
    }
    second_redirect = {
      body: "",
      status: 302,
      headers: { "Location" => first_url },
    }

    # See the comment in the above test for an explanation of this
    failure = ->(_request) { flunk("Request called too many times") }
    stub_request(:get, first_url).to_return(first_redirect).times(6).then.to_return(failure)
    stub_request(:get, second_url).to_return(second_redirect).times(6).then.to_return(failure)

    assert_raises GdsApi::HTTPErrorResponse do
      @client.get_json(first_url)
    end
  end

  def test_post_should_be_raise_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "{}", status: 404)
    assert_raises(GdsApi::HTTPNotFound) do
      @client.post_json(url, {})
    end
  end

  def test_post_should_raise_error_if_non_404_error_code_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "{}", status: 500)
    assert_raises GdsApi::HTTPServerError do
      @client.post_json(url, {})
    end
  end

  def test_post_should_error_on_found_redirect
    url = "http://some.endpoint/some.json"
    new_url = "http://some.endpoint/other.json"
    stub_request(:post, url).to_return(
      body: "",
      status: 302,
      headers: { "Location" => new_url },
    )
    assert_raises GdsApi::HTTPErrorResponse do
      @client.post_json(url, {})
    end
  end

  def test_put_should_be_raise_if_404_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "{}", status: 404)

    assert_raises(GdsApi::HTTPNotFound) do
      @client.put_json(url, {})
    end
  end

  def test_put_should_raise_error_if_non_404_error_code_returned_from_endpoint
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "{}", status: 500)
    assert_raises GdsApi::HTTPServerError do
      @client.put_json(url, {})
    end
  end

  def empty_response
    net_http_response = stub(body: "{}")
    GdsApi::Response.new(net_http_response)
  end

  def test_put_json_does_put_with_json_encoded_packet
    url = "http://some.endpoint/some.json"
    payload = { a: 1 }
    stub_request(:put, url).with(body: payload.to_json).to_return(body: "{}", status: 200)
    assert_equal({}, @client.put_json(url, payload).to_hash)
  end

  def test_does_not_encode_json_if_payload_is_nil
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).with(body: nil).to_return(body: "{}", status: 200)
    assert_equal({}, @client.put_json(url, nil).to_hash)
  end

  def test_can_build_custom_response_object
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "Hello there!")

    response = @client.get_json(url, &:body)
    assert response.is_a? String
    assert_equal "Hello there!", response
  end

  def test_raises_on_custom_response_404
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "", status: 404)

    assert_raises(GdsApi::HTTPNotFound) do
      @client.get_json(url, &:body)
    end
  end

  def test_can_build_custom_response_object_in_bang_method
    url = "http://some.endpoint/some.json"
    stub_request(:get, url).to_return(body: "Hello there!")

    response = @client.get_json(url, &:body)
    assert response.is_a? String
    assert_equal "Hello there!", response
  end

  def test_can_access_attributes_of_response_directly
    url = "http://some.endpoint/some.json"
    payload = { a: 1 }
    stub_request(:put, url).with(body: payload.to_json).to_return(body: '{"a":{"b":2}}', status: 200)
    response = @client.put_json(url, payload)
    assert_equal 2, response["a"]["b"]
  end

  def test_a_response_is_always_considered_present_and_not_blank
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: '{"a":1}', status: 200)
    response = @client.put_json(url, {})
    assert !response.blank?
    assert response.present?
  end

  def test_client_can_use_basic_auth
    client = GdsApi::JsonClient.new(basic_auth: { user: "user", password: "password" })

    stub_request(:put, "http://some.endpoint/some.json")
      .with(basic_auth: %w[user password])
      .to_return(body: '{"a":1}', status: 200)

    response = client.put_json("http://some.endpoint/some.json", {})
    assert_equal 1, response["a"]
  end

  def test_client_can_use_bearer_token
    client = GdsApi::JsonClient.new(bearer_token: "SOME_BEARER_TOKEN")
    expected_headers = GdsApi::JsonClient.default_request_with_json_body_headers
      .merge("Authorization" => "Bearer SOME_BEARER_TOKEN")

    stub_request(:put, "http://some.other.endpoint/some.json")
      .with(headers: expected_headers)
      .to_return(body: '{"a":2}', status: 200)

    response = client.put_json("http://some.other.endpoint/some.json", {})
    assert_equal 2, response["a"]
  end

  def test_client_can_set_custom_headers_on_gets
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)

    GdsApi::JsonClient.new.get_json(
      "http://some.other.endpoint/some.json",
      "HEADER-A" => "B",
      "HEADER-C" => "D",
    )

    assert_requested(:get, %r{/some.json}) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_set_custom_headers_on_posts
    stub_request(:post, "http://some.other.endpoint/some.json").to_return(status: 200)

    GdsApi::JsonClient.new.post_json(
      "http://some.other.endpoint/some.json",
      {},
      "HEADER-A" => "B",
      "HEADER-C" => "D",
    )

    assert_requested(:post, %r{/some.json}) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_set_custom_headers_on_puts
    stub_request(:put, "http://some.other.endpoint/some.json").to_return(status: 200)

    GdsApi::JsonClient.new.put_json(
      "http://some.other.endpoint/some.json",
      {},
      "HEADER-A" => "B",
      "HEADER-C" => "D",
    )

    assert_requested(:put, %r{/some.json}) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_client_can_set_custom_headers_on_deletes
    stub_request(:delete, "http://some.other.endpoint/some.json").to_return(status: 200)

    GdsApi::JsonClient.new.delete_json(
      "http://some.other.endpoint/some.json",
      {},
      "HEADER-A" => "B",
      "HEADER-C" => "D",
    )

    assert_requested(:delete, %r{/some.json}) do |request|
      headers_with_uppercase_names = request.headers.transform_keys(&:upcase)
      headers_with_uppercase_names["HEADER-A"] == "B" && headers_with_uppercase_names["HEADER-C"] == "D"
    end
  end

  def test_govuk_headers_are_included_in_requests_if_present
    # set headers which would be set by middleware GovukHeaderSniffer
    GdsApi::GovukHeaders.set_header(:govuk_request_id, "12345")
    GdsApi::GovukHeaders.set_header(:govuk_original_url, "http://example.com")

    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)

    GdsApi::JsonClient.new.get_json("http://some.other.endpoint/some.json")

    assert_requested(:get, %r{/some.json}) do |request|
      request.headers["Govuk-Request-Id"] == "12345" &&
        request.headers["Govuk-Original-Url"] == "http://example.com"
    end
  end

  def test_govuk_headers_ignored_in_requests_if_not_present
    GdsApi::GovukHeaders.set_header(:x_govuk_authenticated_user, "")
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)

    GdsApi::JsonClient.new.get_json("http://some.other.endpoint/some.json")

    assert_requested(:get, %r{/some.json}) do |request|
      !request.headers.key?("X-Govuk-Authenticated-User")
    end
  end

  def test_additional_headers_passed_in_do_not_get_modified
    stub_request(:get, "http://some.other.endpoint/some.json").to_return(status: 200)

    headers = { "HEADER-A" => "A" }
    GdsApi::JsonClient.new.get_json("http://some.other.endpoint/some.json", headers)

    assert_equal({ "HEADER-A" => "A" }, headers)
  end

  # def test_client_can_decompress_gzip_responses
  #   url = "http://some.endpoint/some.json"
  #   # {"test": "hello"}
  #   stub_request(:get, url).to_return(
  #     body: "\u001F\x8B\b\u0000Q\u000F\u0019Q\u0000\u0003\xABVP*I-.Q\xB2RP\xCAH\xCD\xC9\xC9WR\xA8\u0005\u0000\xD1C\u0018\xFE\u0013\u0000\u0000\u0000",
  #     status: 200,
  #     headers: { 'Content-Encoding' => 'gzip' }
  #   )
  #   response = @client.get_json(url)
  #
  #   assert_equal "hello", response["test"]
  # end

  def test_client_does_not_send_content_type_header_for_multipart_post
    RestClient::Request.expects(:execute).with do |args|
      args[:headers]["Content-Type"].nil?
    end

    @client.post_multipart("http://example.com", {})
  end

  def test_client_does_not_send_content_type_header_for_multipart_put
    RestClient::Request.expects(:execute).with do |args|
      args[:headers]["Content-Type"].nil?
    end

    @client.put_multipart("http://example.com", {})
  end

  def test_client_can_post_multipart_responses
    url = "http://some.endpoint/some.json"
    stub_request(:post, url)
      .with(headers: { "Content-Type" => %r{multipart/form-data; boundary=----RubyFormBoundary\w+} }) { |request|
        request.body =~ %r{------RubyFormBoundary\w+\r\nContent-Disposition: form-data; name="a"\r\n\r\n123\r\n------RubyFormBoundary\w+--\r\n}
      }.to_return(body: '{"b": "1"}', status: 200)

    response = @client.post_multipart("http://some.endpoint/some.json", "a" => "123")
    assert_equal "1", response["b"]
  end

  def test_post_multipart_should_raise_exception_if_not_found
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "", status: 404)

    assert_raises GdsApi::HTTPNotFound do
      @client.post_multipart("http://some.endpoint/some.json", "a" => "123")
    end
  end

  def test_post_multipart_should_raise_error_responses
    url = "http://some.endpoint/some.json"
    stub_request(:post, url).to_return(body: "", status: 500)

    assert_raises GdsApi::HTTPServerError do
      @client.post_multipart("http://some.endpoint/some.json", "a" => "123")
    end
  end

  # EXACTLY the same as the post_multipart tests
  def test_client_can_put_multipart_responses
    url = "http://some.endpoint/some.json"
    stub_request(:put, url)
      .with(headers: { "Content-Type" => %r{multipart/form-data; boundary=----RubyFormBoundary\w+} }) { |request|
        request.body =~ %r{------RubyFormBoundary\w+\r\nContent-Disposition: form-data; name="a"\r\n\r\n123\r\n------RubyFormBoundary\w+--\r\n}
      }.to_return(body: '{"b": "1"}', status: 200)

    response = @client.put_multipart("http://some.endpoint/some.json", "a" => "123")
    assert_equal "1", response["b"]
  end

  def test_put_multipart_should_raise_exception_if_not_found
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "", status: 404)

    assert_raises GdsApi::HTTPNotFound do
      @client.put_multipart("http://some.endpoint/some.json", "a" => "123")
    end
  end

  def test_put_multipart_should_raise_error_responses
    url = "http://some.endpoint/some.json"
    stub_request(:put, url).to_return(body: "", status: 500)

    assert_raises GdsApi::HTTPServerError do
      @client.put_multipart("http://some.endpoint/some.json", "a" => "123")
    end
  end

  def test_should_raise_error_if_attempting_to_disable_timeout
    assert_raises RuntimeError do
      GdsApi::JsonClient.new(disable_timeout: true)
    end
    assert_raises RuntimeError do
      GdsApi::JsonClient.new(timeout: -1)
    end
  end

  def test_should_add_user_agent_using_env
    previous_govuk_app_name = ENV["GOVUK_APP_NAME"]
    ENV["GOVUK_APP_NAME"] = "api-tests"

    url = "http://some.other.endpoint/some.json"
    stub_request(:get, url).to_return(status: 200)

    GdsApi::JsonClient.new.get_json(url)

    assert_requested(:get, %r{/some.json}) do |request|
      request.headers["User-Agent"] == "gds-api-adapters/#{GdsApi::VERSION} (api-tests)"
    end
  ensure
    ENV["GOVUK_APP_NAME"] = previous_govuk_app_name
  end

  def test_should_default_to_using_null_logger
    assert_same @client.logger, NullLogger.instance
  end

  def test_should_use_custom_logger_specified_in_options
    custom_logger = stub("custom-logger")
    client = GdsApi::JsonClient.new(logger: custom_logger)
    assert_same client.logger, custom_logger
  end

  def test_should_avoid_content_type_header_on_get_without_body
    url = "http://some.endpoint/some.json"
    stub_request(:any, url)

    @client.get_json(url)
    assert_requested(:get, url, headers: GdsApi::JsonClient.default_request_headers)

    @client.delete_json(url)
    assert_requested(:delete, url, headers: GdsApi::JsonClient.default_request_headers)

    @client.post_json(url, test: "123")
    assert_requested(:post, url, headers: GdsApi::JsonClient.default_request_with_json_body_headers)

    @client.put_json(url, test: "123")
    assert_requested(:put, url, headers: GdsApi::JsonClient.default_request_with_json_body_headers)
  end
end
