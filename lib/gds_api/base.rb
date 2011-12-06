require_relative 'json_utils'
require 'cgi'

class GdsApi::Base
  include GdsApi::JsonUtils

  def initialize(platform, endpoint_url = nil)
    adapter_name = self.class.to_s.split("::").last.downcase

    # This should get simpler if we can be more consistent with our domain names
    self.endpoint =
      if endpoint_url
        endpoint_url
      elsif platform == 'development'
        "http://#{adapter_name}.dev.gov.uk"
      else
        "http://#{adapter_name}.#{platform}.alphagov.co.uk"
      end
  end
  
  def url_for_slug(slug,options={})
    base = "#{base_url}/#{slug}.json"
    return base if options.empty?

    params = options.sort.map { |kv|
      kv.map { |a| CGI.escape(a) }.join("=")
    }.join("&")

    "#{base}?#{params}"
  end
  
  private
    attr_accessor :endpoint
end
