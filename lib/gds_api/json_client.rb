require_relative 'response'
require_relative 'exceptions'
require_relative 'version'
require_relative 'null_cache'
require_relative 'govuk_request_id'
require 'lrucache'
require 'rest-client'

module GdsApi
  class JsonClient

    include GdsApi::ExceptionHandling

    # Cache TTL will be overridden for a given request/response by the Expires
    # header if it is included in the response.
    #
    # LRUCache doesn't respect a cache size of 0, and instead effectively
    # creates a cache with a size of 1.
    def self.cache(size=DEFAULT_CACHE_SIZE, ttl=DEFAULT_CACHE_TTL)
      @cache ||= LRUCache.new(max_size: size, ttl: ttl)
    end

    def self.cache=(c)
      @cache = c
    end

    attr_accessor :logger, :options, :cache

    def initialize(options = {})
      if options[:disable_timeout] or options[:timeout].to_i < 0
        raise "It is no longer possible to disable the timeout."
      end

      @logger = options[:logger] || GdsApi::Base.logger

      if options[:disable_cache] || (options[:cache_size] == 0)
        @cache = NullCache.new
      else
        cache_size = options[:cache_size] || DEFAULT_CACHE_SIZE
        cache_ttl = options[:cache_ttl] || DEFAULT_CACHE_TTL
        @cache = JsonClient.cache(cache_size, cache_ttl)
      end
      @options = options
    end

    DEFAULT_REQUEST_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => "GDS Api Client v. #{GdsApi::VERSION}"
    }
    DEFAULT_TIMEOUT_IN_SECONDS = 4
    DEFAULT_CACHE_SIZE = 100
    DEFAULT_CACHE_TTL = 15 * 60 # 15 minutes

    def get_raw!(url)
      do_raw_request(:get, url)
    end

    def get_raw(url)
      ignoring_missing do
        get_raw!(url)
      end
    end

    # Define "safe" methods for each supported HTTP method
    #
    # Each "bang method" tries to make a request, but raises an exception if
    # the response is not successful. These methods discard the HTTPNotFound
    # exceptions (and return nil), and pass through all other exceptions.
    [:get, :post, :put, :delete].each do |http_method|
      method_name = "#{http_method}_json"
      define_method method_name do |url, *args, &block|
        ignoring_missing do
          send (method_name + "!"), url, *args, &block
        end
      end
    end

    def get_json!(url, additional_headers = {}, &create_response)
      do_json_request(:get, url, nil, additional_headers, &create_response)
    end

    def post_json!(url, params, additional_headers = {})
      do_json_request(:post, url, params, additional_headers)
    end

    def put_json!(url, params, additional_headers = {})
      do_json_request(:put, url, params, additional_headers)
    end

    def delete_json!(url, params = nil, additional_headers = {})
      do_json_request(:delete, url, params, additional_headers)
    end

    def post_multipart(url, params)
      r = do_raw_request(:post, url, params.merge({
        :multipart => true
      }))
      Response.new(r)
    end

    private
    def do_raw_request(method, url, params = nil)
      response = do_request(method, url, params)

    rescue RestClient::ResourceNotFound => e
      raise GdsApi::HTTPNotFound.new(e.http_code)

    rescue RestClient::Gone => e
      raise GdsApi::HTTPGone.new(e.http_code)

    rescue RestClient::Exception => e
      raise GdsApi::HTTPErrorResponse.new(e.response.code.to_i), e.response.body
    end

    # method: the symbolic name of the method to use, e.g. :get, :post
    # url:    the request URL
    # params: the data to send (JSON-serialised) in the request body
    # additional_headers: headers to set on the request (in addition to the default ones)
    # create_response: optional block to instantiate a custom response object
    #                  from the Net::HTTPResponse
    def do_json_request(method, url, params = nil, additional_headers = {}, &create_response)

      begin
        response = do_request_with_cache(method, url, (params.to_json if params), additional_headers)

      rescue RestClient::ResourceNotFound => e
        raise GdsApi::HTTPNotFound.new(e.http_code)

      rescue RestClient::Gone => e
        raise GdsApi::HTTPGone.new(e.http_code)

      rescue RestClient::Exception => e
        # Attempt to parse the body as JSON if possible
        error_details = begin
          e.http_body ? JSON.parse(e.http_body) : nil
        rescue JSON::ParserError
          nil
        end
        raise GdsApi::HTTPErrorResponse.new(e.http_code, error_details), e.http_body
      end

      # If no custom response is given, just instantiate Response
      create_response ||= Proc.new { |r| Response.new(r) }
      create_response.call(response)
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
      method_params.merge(
        timeout: options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS
      )
    end

    def with_headers(method_params, headers)
      headers = headers.merge(govuk_request_id: GdsApi::GovukRequestId.value) if GdsApi::GovukRequestId.set?
      method_params.merge(
        headers: method_params[:headers].merge(headers)
      )
    end

    def with_ssl_options(method_params)
      method_params.merge(
        # This is the default value anyway, but we should probably be explicit
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )
    end

    def do_request_with_cache(method, url, params = nil, additional_headers = {})
      # Only read GET requests from the cache: any other request methods should
      # always be passed through. Note that this means HEAD requests won't get
      # cached, but that would involve separating the cache by method and URL.
      # Also, we don't generally make HEAD requests.
      use_cache = (method == :get)

      if use_cache
        cached_response = @cache[url]
        return cached_response if cached_response
      end

      response = do_request(method, url, params, additional_headers)

      if use_cache
        cache_time = response_cache_time(response)
        # If cache_time is nil, this will fall back on @cache's default
        @cache.store(url, response, cache_time)
      end

      response
    end

    # Return either a Time object representing the expiry time of the response
    # or nil if no cache information is provided
    def response_cache_time(response)
      if response.headers[:cache_control]
        # The Cache-control header is composed of a comma-separated string
        # so split this apart before we look for particular values
        cache_parts = response.headers[:cache_control].split(',').map(&:strip)

        # If no-cache is present, this takes precedent over any other value
        # in this header
        return Time.now.utc if cache_parts.include?("no-cache")

        # Otherwise, look for a 'max-age=123' value, which is the number of
        # seconds for which to cache the response.
        max_age = cache_parts.map {|x| x.match(/max-age=(\d+)/) }.compact.first
        if max_age
          return Time.now.utc + max_age[1].to_i
        end
      end

      if response.headers[:expires]
        Time.httpdate response.headers[:expires]
      end
    end

    def do_request(method, url, params = nil, additional_headers = {})
      loggable = {request_uri: url, start_time: Time.now.to_f}
      start_logging = loggable.merge(action: 'start')
      logger.debug start_logging.to_json

      method_params = {
        method: method,
        url: url,
        headers: DEFAULT_REQUEST_HEADERS
      }
      method_params[:payload] = params
      method_params = with_auth_options(method_params)
      method_params = with_timeout(method_params)
      method_params = with_headers(method_params, additional_headers)
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

    rescue RestClient::MaxRedirectsReached => e
      raise GdsApi::TooManyRedirects

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
