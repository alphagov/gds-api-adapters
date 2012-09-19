require 'test_helper'
require 'gds_api/base'
require 'uri'

class GdsApiBaseTest < MiniTest::Unit::TestCase

  class ConcreteApi < GdsApi::Base
    def base_url
      endpoint
    end
  end

  def setup
    @orig_cache = GdsApi::JsonClient.cache
    @api = ConcreteApi.new('test')
  end

  def teardown
    GdsApi::JsonClient.cache = @orig_cache
  end

  def test_should_construct_escaped_query_string
    api = ConcreteApi.new('test')
    url = api.url_for_slug("slug", "a" => " ", "b" => "/")
    u = URI.parse(url)
    assert_equal "a=+&b=%2F", u.query
  end

  def test_should_not_add_a_question_mark_if_there_are_no_parameters
    api = ConcreteApi.new('test')
    url = api.url_for_slug("slug")
    refute_match /\?/, url
  end

  def test_should_use_platform_in_url
    api = ConcreteApi.new("test")
    url = api.url_for_slug("slug")
    u = URI.parse(url)
    assert_match /test\.alphagov\.co\.uk$/, u.host
  end

  def test_should_override_platform_with_endpoint_url
    api = ConcreteApi.new("test", "http://foo.bar")
    url = api.url_for_slug("slug")
    u = URI.parse(url)
    assert_equal "foo.bar", u.host
  end

  def test_should_use_dev_for_development_platform
    api = ConcreteApi.new("development")
    url = api.url_for_slug("slug")
    u = URI.parse(url)
    assert_match /dev\.gov\.uk$/, u.host
  end

  def test_should_derive_adapter_name_from_class
    api = ConcreteApi.new("test")
    url = api.url_for_slug("slug")
    u = URI.parse(url)
    assert_match /^concreteapi\.test/, u.host
  end

  def test_should_treat_second_positional_arg_as_endpoint_url_if_string
    api = ConcreteApi.new("test", "endpoint")
    assert_equal "endpoint", api.options[:endpoint_url]
  end

  def test_should_accept_options_as_second_arg
    api = ConcreteApi.new("test", {endpoint_url: "endpoint", foo: "bar"})
    assert_equal "endpoint", api.options[:endpoint_url]
    assert_equal "bar", api.options[:foo]
  end

  def test_setting_cache_size_from_options
    GdsApi::JsonClient.cache = false
    api = ConcreteApi.new("test", {endpoint_url: "endpoint", cache_size: 2})
    assert_equal 2, api.client.cache.max_size
  end

  def test_setting_cache_size_from_default_options
    GdsApi::JsonClient.cache = false
    GdsApi::Base.default_options = {cache_size: 4}
    api = ConcreteApi.new("test", {endpoint_url: "endpoint"})
    assert_equal 4, api.client.cache.max_size
  end


end
