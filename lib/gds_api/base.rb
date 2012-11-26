require_relative 'json_client'
require 'cgi'
require 'null_logger'
require 'plek'

class GdsApi::Base
  class InvalidAPIURL < StandardError
  end

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
  end

  def self.logger
    @logger ||= NullLogger.instance
  end

  def initialize(endpoint_url, options={})
    options[:endpoint_url] = endpoint_url
    raise InvalidAPIURL unless endpoint_url =~ URI::regexp
    default_options = GdsApi::Base.default_options || {}
    @options = default_options.merge(options)
    self.endpoint = options[:endpoint_url]
  end

  def adapter_name
    self.class.to_s.split("::").last.downcase
  end

  def url_for_slug(slug, options={})
    base = "#{base_url}/#{slug}.json#{query_string(options)}"
  end

private
  attr_accessor :endpoint

  def query_string(params)
    return "" if params.empty?

    "?" << params.sort.map { |kv|
      kv.map { |a| CGI.escape(a.to_s) }.join("=")
    }.join("&")
  end
end
