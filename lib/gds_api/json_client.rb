require_relative 'response'
require_relative 'exceptions'
require_relative 'version'
require 'net/http'
require 'lrucache'

module GdsApi
  class JsonClient

    include GdsApi::ExceptionHandling

    def self.cache(size=DEFAULT_CACHE_SIZE, ttl=DEFAULT_CACHE_TTL)
      @cache ||= LRUCache.new(max_size: size, ttl: ttl)
    end

    def self.cache=(c)
      @cache = c
    end

    attr_accessor :logger, :options, :cache

    def initialize(options = {})
      @logger = options[:logger] || GdsApi::Base.logger
      cache_size = options[:cache_size] || DEFAULT_CACHE_SIZE
      cache_ttl = options[:cache_ttl] || DEFAULT_CACHE_TTL
      @cache = JsonClient.cache(cache_size, cache_ttl)
      @options = options
    end

    DEFAULT_REQUEST_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "GDS Api Client v. #{GdsApi::VERSION}"
    }
    DEFAULT_TIMEOUT_IN_SECONDS = 4
    DEFAULT_CACHE_SIZE = 10
    DEFAULT_CACHE_TTL = 15 * 60 # 15 minutes

    def get_raw(url)
      do_raw_request(Net::HTTP::Get, url)
    end

    # Define "safe" methods for each supported HTTP method
    #
    # Each "bang method" tries to make a request, but raises an exception if
    # the response is not successful. These methods discard those exceptions
    # and return nil.
    [:get, :post, :put, :delete].each do |http_method|
      method_name = "#{http_method}_json"
      define_method method_name do |url, *args|
        ignoring GdsApi::HTTPNotFound do
          send (method_name + "!"), url, *args
        end
      end
    end

    def get_json!(url, &create_response)
      @cache[url] ||= do_json_request(Net::HTTP::Get, url, nil, &create_response)
    end

    def post_json!(url, params)
      do_json_request(Net::HTTP::Post, url, params)
    end

    def put_json!(url, params)
      do_json_request(Net::HTTP::Put, url, params)
    end

    def delete_json!(url, params = nil)
      do_request(Net::HTTP::Delete, url, params)
    end

    private
    def do_raw_request(method_class, url, params = nil)
      response, loggable = do_request(method_class, url, params)
      response.body
    end

    # method_class: the Net::HTTP class to use, e.g. Net::HTTP::Get
    # url:    the request URL
    # params: the data to send (JSON-serialised) in the request body
    # create_response: optional block to instantiate a custom response object
    #                  from the Net::HTTPResponse
    def do_json_request(method_class, url, params = nil, &create_response)

      response, loggable = do_request(method_class, url, params)

      # If no custom response is given, just instantiate Response
      create_response ||= Proc.new { |r| Response.new(r) }

      if response.is_a?(Net::HTTPSuccess)
        logger.info loggable.merge(status: 'success', end_time: Time.now.to_f).to_json
        create_response.call(response)
      elsif response.is_a?(Net::HTTPNotFound)
        raise GdsApi::HTTPNotFound.new(response.code.to_i)
      else
        body = begin
          JSON.parse(response.body.to_s)
        rescue JSON::ParserError
          response.body
        end
        loggable.merge!(status: response.code, end_time: Time.now.to_f, body: body)
        logger.warn loggable.to_json
        raise GdsApi::HTTPErrorResponse.new(response.code.to_i), body
      end
    end

    def extract_url_and_path(url)
      url = URI.parse(url)
      path = url.path
      path = path + "?" + url.query if url.query
      return url, path
    end

    def attach_auth_options(request)
      if @options[:bearer_token]
        request.add_field('Authorization', "Bearer #{@options[:bearer_token]}")
      elsif @options[:basic_auth]
        request.basic_auth(@options[:basic_auth][:user], @options[:basic_auth][:password])
      end
    end

    def set_timeout(http)
      unless options[:disable_timeout]
        http.read_timeout = options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS
      end
    end

    def ssl_options(port)
      if port == 443
        {use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE}
      else
        {}
      end
    end

    def do_request(method_class, url, params = nil)
      loggable = {request_uri: url, start_time: Time.now.to_f}
      start_logging = loggable.merge(action: 'start')
      logger.debug start_logging.to_json

      url, path = extract_url_and_path(url)

      response = Net::HTTP.start(url.host, url.port, nil, nil, nil, nil, ssl_options(url.port)) do |http|
        set_timeout(http)
        request = method_class.new(path, DEFAULT_REQUEST_HEADERS)
        attach_auth_options(request)
        request.body = params.to_json if params
        http.request(request)
      end

      return response, loggable

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
