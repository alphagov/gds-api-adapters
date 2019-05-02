require_relative 'json_client'
require 'cgi'
require 'null_logger'
require 'plek'
require_relative 'list_response'

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

  def_delegators :client,
                 :get_json,
                 :post_json,
                 :put_json,
                 :patch_json,
                 :delete_json,
                 :get_raw, :get_raw!,
                 :put_multipart,
                 :post_multipart

  attr_reader :options

  class << self
    attr_writer :logger
    attr_accessor :default_options
  end

  def self.logger
    @logger ||= NullLogger.instance
  end

  def initialize(endpoint_url, options = {})
    options[:endpoint_url] = endpoint_url
    raise InvalidAPIURL unless endpoint_url =~ URI::RFC3986_Parser::RFC3986_URI

    base_options = { logger: GdsApi::Base.logger }
    default_options = base_options.merge(GdsApi::Base.default_options || {})
    @options = default_options.merge(options)
    self.endpoint = options[:endpoint_url]
  end

  def url_for_slug(slug, options = {})
    "#{base_url}/#{slug}.json#{query_string(options)}"
  end

  def get_list(url)
    get_json(url) do |r|
      GdsApi::ListResponse.new(r, self)
    end
  end

private

  attr_accessor :endpoint

  def query_string(params)
    return "" if params.empty?

    param_pairs = params.sort.map { |key, value|
      case value
      when Array
        value.map { |v|
          "#{CGI.escape(key.to_s + '[]')}=#{CGI.escape(v.to_s)}"
        }
      else
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end
    }.flatten

    "?#{param_pairs.join('&')}"
  end
end
