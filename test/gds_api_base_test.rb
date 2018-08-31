require 'test_helper'
require 'gds_api/base'
require 'uri'

class GdsApiBaseTest < Minitest::Test
  class ConcreteApi < GdsApi::Base
    def base_url
      endpoint
    end
  end

  def teardown
    GdsApi::Base.default_options = nil
  end

  def test_should_construct_escaped_query_string
    api = ConcreteApi.new('http://foo')
    url = api.url_for_slug("slug", "a" => " ", "b" => "/")
    u = URI.parse(url)
    assert_equal "a=+&b=%2F", u.query
  end

  def test_should_construct_escaped_query_string_for_rails
    api = ConcreteApi.new('http://foo')

    url = api.url_for_slug("slug", "b" => ['123'])
    u = URI.parse(url)
    assert_equal "b%5B%5D=123", u.query

    url = api.url_for_slug("slug", "b" => %w(123 456))
    u = URI.parse(url)
    assert_equal "b%5B%5D=123&b%5B%5D=456", u.query
  end

  def test_should_not_add_a_question_mark_if_there_are_no_parameters
    api = ConcreteApi.new('http://foo')
    url = api.url_for_slug("slug")
    refute_match(/\?/, url)
  end

  def test_should_use_endpoint_in_url
    api = ConcreteApi.new("http://foobarbaz")
    url = api.url_for_slug("slug")
    u = URI.parse(url)
    assert_match(/foobarbaz$/, u.host)
  end

  def test_should_accept_options_as_second_arg
    api = ConcreteApi.new("http://foo", foo: "bar")
    assert_equal "bar", api.options[:foo]
  end

  def test_should_barf_if_not_given_valid_url
    assert_raises GdsApi::Base::InvalidAPIURL do
      ConcreteApi.new('invalid-url')
    end
  end

  def test_should_set_json_client_logger_to_own_logger_by_default
    api = ConcreteApi.new("http://bar")
    assert_same GdsApi::Base.logger, api.client.logger
  end

  def test_should_set_json_client_logger_to_logger_in_default_options
    custom_logger = stub('custom-logger')
    GdsApi::Base.default_options = { logger: custom_logger }
    api = ConcreteApi.new("http://bar")
    assert_same custom_logger, api.client.logger
  end

  def test_should_set_json_client_logger_to_logger_in_options
    custom_logger = stub('custom-logger')
    GdsApi::Base.default_options = { logger: custom_logger }
    another_logger = stub('another-logger')
    api = ConcreteApi.new("http://bar", logger: another_logger)
    assert_same another_logger, api.client.logger
  end
end
