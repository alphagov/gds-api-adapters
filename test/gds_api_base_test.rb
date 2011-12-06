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
    @api = ConcreteApi.new('test')
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

end
