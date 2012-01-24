require_relative 'response'
require_relative 'exceptions'
require_relative 'version'
require 'lrucache'

module GdsApi
  class JsonClient
    def self.cache
      @cache ||= LRUCache.new(max_size: 10)
    end

    def self.cache=(c)
      @cache = c
    end

    attr_accessor :logger, :options

    def initialize(options = {})
      @logger = options[:logger] || GdsApi::Base.logger
      @cache = options[:cache] || JsonClient.cache
      @options = options
    end

    REQUEST_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "GDS Api Client v. #{GdsApi::VERSION}"
    }
    DEFAULT_TIMEOUT_IN_SECONDS = 2

    def get_json(url)
      @cache[url] ||= do_request(Net::HTTP::Get, url)
    end

    def post_json(url, params)
      do_request(Net::HTTP::Post, url, params)
    end

    def put_json(url, params)
      do_request(Net::HTTP::Put, url, params)
    end

    private
    def do_request(method_class, url, params = nil)
      loggable = {request_uri: url, start_time: Time.now.to_f}
      start_logging = loggable.merge(action: 'start')
      logger.debug start_logging.to_json

      url = URI.parse(url)
      path = url.path
      path = path + "?" + url.query if url.query

      response = Net::HTTP.start(url.host, url.port, nil, nil, nil, nil, {use_ssl: url.port == 443, verify_mode: (OpenSSL::SSL::VERIFY_NONE if url.port == 443)}) do |http|
        unless options[:disable_timeout]
          http.read_timeout = options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS
        end
        request = method_class.new(path, REQUEST_HEADERS)
        request.basic_auth(@options[:basic_auth][:user], @options[:basic_auth][:password]) if @options[:basic_auth]
        request.body = params.to_json if params
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        logger.info loggable.merge(status: 'success', end_time: Time.now.to_f).to_json
        Response.new(response)
      else
        body = begin
          JSON.parse(response.body)
        rescue
          response.body
        end
        loggable.merge!(status: response.code, end_time: Time.now.to_f, body: body)
        logger.warn loggable.to_json
        nil
      end
    rescue Errno::ECONNREFUSED => e
      logger.error loggable.merge(status: 'refused', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::EndpointNotFound.new("Could not connect to #{url}")
    rescue Timeout::Error => e
      logger.error loggable.merge(status: 'timeout', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::TimedOutException.new
    rescue Errno::ECONNRESET => e
      logger.error loggable.merge(status: 'connection_reset', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::TimedOutException.new
    end
  end
end
