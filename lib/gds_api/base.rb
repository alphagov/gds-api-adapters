require_relative 'json_utils'
require 'cgi'

class GdsApi::Base
  include GdsApi::JsonUtils

  def initialize(platform, endpoint_url=nil)
    adapter_name = self.class.to_s.split("::").last.downcase

    self.endpoint = endpoint_url || endpoint_for_platform(adapter_name, platform)
  end

  def url_for_slug(slug, options={})
    base = "#{base_url}/#{slug}.json#{query_string(options)}"
  end

private
  attr_accessor :endpoint

  # This should get simpler if we can be more consistent with our domain names
  def endpoint_for_platform(adapter_name, platform)
    if platform == 'development'
      "http://#{adapter_name}.dev.gov.uk"
    else
      "http://#{adapter_name}.#{platform}.alphagov.co.uk"
    end
  end

  def query_string(params)
    return "" if params.empty?

    "?" << params.sort.map { |kv|
      kv.map { |a| CGI.escape(a.to_s) }.join("=")
    }.join("&")
  end
end
