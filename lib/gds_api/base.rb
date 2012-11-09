require_relative 'json_client'
require_relative 'core-ext/hash'
require 'cgi'
require 'null_logger'
require 'yaml'

class GdsApi::Base
  extend Forwardable

  def client
    @client ||= create_client
  end

  def create_client
    GdsApi::JsonClient.new(options)
  end

  def_delegators :client, :get_json, :get_json!,
                          :post_json, :post_json!,
                          :put_json, :put_json!,
                          :delete_json!,
                          :get_raw

  attr_reader :options

  class << self
    attr_writer :logger
    attr_accessor :default_options

    def platform_override_options(adapter)
      @platform_override_options ||= load_platform_override_config
      @platform_override_options[adapter.to_sym] || { }
    end

    def load_platform_override_config
      return { } if ENV['PLATFORM_OVERRIDE_CONFIG'].nil? or ENV['PLATFORM_OVERRIDE_CONFIG'].empty?

      config_file = File.expand_path(ENV['PLATFORM_OVERRIDE_CONFIG'], File.dirname(__FILE__))
      YAML.load(File.read(config_file)).symbolize_keys || { }
    end
  end

  def self.logger
    @logger ||= NullLogger.instance
  end

  def initialize(platform, options_or_endpoint_url=nil, maybe_options=nil)
    if options_or_endpoint_url.is_a?(String)
      options = maybe_options || {}
      options[:endpoint_url] = options_or_endpoint_url
    else
      options = options_or_endpoint_url || {}
    end
    default_options = GdsApi::Base.default_options || {}
    options_with_defaults = default_options.merge(options)
    @options = options_with_defaults.merge(GdsApi::Base.platform_override_options(adapter_name))

    self.endpoint = @options[:endpoint_url] || endpoint_for_platform(adapter_name, platform)
  end

  def adapter_name
    self.class.to_s.split("::").last.downcase
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
      "https://#{adapter_name}.#{platform}.alphagov.co.uk"
    end
  end

  def query_string(params)
    return "" if params.empty?

    "?" << params.sort.map { |kv|
      kv.map { |a| CGI.escape(a.to_s) }.join("=")
    }.join("&")
  end
end
