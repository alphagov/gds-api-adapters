require_relative 'json_utils'

class GdsApi::Base
  include GdsApi::JsonUtils

  def initialize(platform, endpoint_url = nil)
    adapter_name = self.class.to_s.split("::").last.downcase

    # This should get simpler if we can be more consistent with our domain names
    if endpoint_url
      self.endpoint = endpoint_url
    elsif platform == 'development'
      self.endpoint = "http://#{adapter_name}.dev.gov.uk"
    else
      self.endpoint = "http://#{adapter_name}.#{platform}.alphagov.co.uk"
    end
  end
  
  def url_for_slug(slug,options={})
    base = "#{base_url}/#{slug}.json"
    params = options.map { |k,v| "#{k}=#{v}" }
    base = base + "?#{params.join("&")}" unless options.empty? 
    base
  end
  
  private
    attr_accessor :endpoint
end