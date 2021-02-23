require_relative "test_helper"
require "gds_api/response"

describe GdsApi::Response::CacheControl do
  it "takes no args and initializes with an empty set of values" do
    cache_control = GdsApi::Response::CacheControl.new

    assert cache_control.empty?
    assert_equal "", cache_control.to_s
  end

  it "takes a String and parses it into a Hash when created" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600, foo")

    assert cache_control["foo"]
    assert_equal "600", cache_control["max-age"]
  end

  it "takes a String with a single name=value pair" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600")
    assert_equal "600", cache_control["max-age"]
  end

  it "takes a String with multiple name=value pairs" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600, max-stale=300, min-fresh=570")

    assert_equal "600", cache_control["max-age"]
    assert_equal "300", cache_control["max-stale"]
    assert_equal "570", cache_control["min-fresh"]
  end

  it "takes a String with a single flag value" do
    cache_control = GdsApi::Response::CacheControl.new("no-cache")

    assert cache_control.include?("no-cache")
    assert_equal true, cache_control["no-cache"]
  end

  it "takes a String with a bunch of all kinds of stuff" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600,must-revalidate,min-fresh=3000,foo=bar,baz")

    assert_equal "600", cache_control["max-age"]
    assert_equal true, cache_control["must-revalidate"]
    assert_equal "3000", cache_control["min-fresh"]
    assert_equal "bar", cache_control["foo"]
    assert_equal true, cache_control["baz"]
  end

  it "strips leading and trailing spaces from header value" do
    cache_control = GdsApi::Response::CacheControl.new("   public,   max-age =   600  ")

    assert cache_control.include?("public")
    assert cache_control.include?("max-age")
    assert_equal "600", cache_control["max-age"]
  end

  it "strips blank segments" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600,,max-stale=300")

    assert_equal 2, cache_control.size
    assert_equal "600", cache_control["max-age"]
    assert_equal "300", cache_control["max-stale"]
  end

  it "removes all directives with #clear" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600, must-revalidate")
    cache_control.clear

    assert cache_control.empty?
  end

  it "converts self into header String with #to_s" do
    cache_control = GdsApi::Response::CacheControl.new
    cache_control["public"] = true
    cache_control["max-age"] = "600"

    assert_equal ["max-age=600", "public"], cache_control.to_s.split(", ").sort
  end

  it "sorts alphabetically with boolean directives before value directives" do
    cache_control = GdsApi::Response::CacheControl.new("foo=bar, z, x, y, bling=baz, zoom=zib, b, a")
    assert_equal "a, b, x, y, z, bling=baz, foo=bar, zoom=zib", cache_control.to_s
  end

  it "responds to #max_age with an integer when max-age directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public, max-age=600")
    assert 600, cache_control.max_age
  end

  it "responds to #max_age with nil when no max-age directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public")
    assert cache_control.max_age.nil?
  end

  it "responds to #shared_max_age with an integer when s-maxage directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public, s-maxage=600")
    assert 600, cache_control.shared_max_age
  end

  it "responds to #shared_max_age with nil when no s-maxage directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public")
    assert cache_control.shared_max_age.nil?
  end

  it "responds to #reverse_max_age with an integer when r-maxage directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public, r-maxage=600")
    assert_equal 600, cache_control.reverse_max_age
  end

  it "responds to #reverse_max_age with nil when no r-maxage directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public")
    assert cache_control.reverse_max_age.nil?
  end

  it "responds to #public? truthfully when public directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public")
    assert cache_control.public?
  end

  it "responds to #public? non-truthfully when no public directive present" do
    cache_control = GdsApi::Response::CacheControl.new("private")
    refute cache_control.public?
  end

  it "responds to #private? truthfully when private directive present" do
    cache_control = GdsApi::Response::CacheControl.new("private")
    assert cache_control.private?
  end

  it "responds to #private? non-truthfully when no private directive present" do
    cache_control = GdsApi::Response::CacheControl.new("public")
    refute cache_control.private?
  end

  it "responds to #no_cache? truthfully when no-cache directive present" do
    cache_control = GdsApi::Response::CacheControl.new("no-cache")
    assert cache_control.no_cache?
  end

  it "responds to #no_cache? non-truthfully when no no-cache directive present" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600")
    refute cache_control.no_cache?
  end

  it "responds to #must_revalidate? truthfully when must-revalidate directive present" do
    cache_control = GdsApi::Response::CacheControl.new("must-revalidate")
    assert cache_control.must_revalidate?
  end

  it "responds to #must_revalidate? non-truthfully when no must-revalidate directive present" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600")
    refute cache_control.no_cache?
  end

  it "responds to #proxy_revalidate? truthfully when proxy-revalidate directive present" do
    cache_control = GdsApi::Response::CacheControl.new("proxy-revalidate")
    assert cache_control.proxy_revalidate?
  end

  it "responds to #proxy_revalidate? non-truthfully when no proxy-revalidate directive present" do
    cache_control = GdsApi::Response::CacheControl.new("max-age=600")
    refute cache_control.proxy_revalidate?
  end
end
