require_relative 'response'
require_relative 'exceptions'
require_relative 'version'
require 'lrucache'
require 'rest-client'

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
      ignoring GdsApi::HTTPNotFound do
        do_raw_request(:get, url)
      end
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
      @cache[url] ||= do_json_request(:get, url, nil, &create_response)
    end

    def post_json!(url, params)
      do_json_request(:post, url, params)
    end

    def put_json!(url, params)
      do_json_request(:put, url, params)
    end

    def delete_json!(url, params = nil)
      do_request(:delete, url, params)
    end

    private
    def do_raw_request(method, url, params = nil)
      response = do_request(method, url, params)
      response.body

    rescue RestClient::ResourceNotFound => e
      raise GdsApi::HTTPNotFound.new(e.http_code)

    rescue RestClient::Exception => e
      raise GdsApi::HTTPErrorResponse.new(response.code.to_i), e.response.body
    end

    # method: the symbolic name of the method to use, e.g. :get, :post
    # url:    the request URL
    # params: the data to send (JSON-serialised) in the request body
    # create_response: optional block to instantiate a custom response object
    #                  from the Net::HTTPResponse
    def do_json_request(method, url, params = nil, &create_response)

      begin
        response = do_request(method, url, params)

      rescue RestClient::ResourceNotFound => e
        raise GdsApi::HTTPNotFound.new(e.http_code)

      rescue RestClient::Exception => e
        # Attempt to parse the body as JSON if possible
        body = begin
          JSON.parse(e.http_body)
        rescue JSON::ParserError
          e.response.body
        end
        raise GdsApi::HTTPErrorResponse.new(e.http_code), body
      end

      # If no custom response is given, just instantiate Response
      create_response ||= Proc.new { |r| Response.new(r) }
      create_response.call(response.net_http_res)
    end

    # Take a hash of parameters for Request#execute; return a hash of
    # parameters with authentication information included
    def with_auth_options(method_params)
      if @options[:bearer_token]
        headers = method_params[:headers] || {}
        method_params.merge(headers: headers.merge(
          {"Authorization" => "Bearer #{@options[:bearer_token]}"}
        ))
      elsif @options[:basic_auth]
        method_params.merge(
          user: @options[:basic_auth][:user],
          password: @options[:basic_auth][:password]
        )
      else
        method_params
      end
    end

    # Take a hash of parameters for Request#execute; return a hash of
    # parameters with timeouts included
    def with_timeout(method_params)
      if options[:disable_timeout]
        method_params.merge(timeout: -1)
      else
        method_params.merge(
          timeout: options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS
        )
      end
    end

    def with_ssl_options(method_params)
      method_params.merge(
        # This is the default value anyway, but we should probably be explicit
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )
    end

    def do_request(method, url, params = nil)
      loggable = {request_uri: url, start_time: Time.now.to_f}
      start_logging = loggable.merge(action: 'start')
      logger.debug start_logging.to_json

      method_params = {
        method: method,
        url: url,
        headers: DEFAULT_REQUEST_HEADERS
      }
      method_params[:payload] = params.to_json if params
      method_params = with_auth_options(method_params)
      method_params = with_timeout(method_params)
      if URI.parse(url).is_a? URI::HTTPS
        method_params = with_ssl_options(method_params)
      end

      return ::RestClient::Request.execute(method_params)

    rescue Errno::ECONNREFUSED => e
      logger.error loggable.merge(status: 'refused', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::EndpointNotFound.new("Could not connect to #{url}")

    rescue RestClient::RequestTimeout => e
      logger.error loggable.merge(status: 'timeout', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::TimedOutException.new

    rescue RestClient::Exception => e
      # Log the error here, since we have access to loggable, but raise the
      # exception up to the calling method to deal with
      loggable.merge!(status: e.http_code, end_time: Time.now.to_f, body: e.http_body)
      logger.warn loggable.to_json
      raise

    rescue Errno::ECONNRESET => e
      logger.error loggable.merge(status: 'connection_reset', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::TimedOutException.new
    end
  end
end
