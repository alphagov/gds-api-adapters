require_relative 'response'
require_relative 'exceptions'
require_relative 'version'
require_relative 'null_cache'
require_relative 'govuk_headers'
require 'lrucache'
require 'rest-client'
require 'null_logger'

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

    # Set the caching implementation. Default is LRUCache. Can be Anything
    # which responds to:
    #
    #   [](key)
    #   []=(key, value)
    #   store(key, value, expiry_time=nil) - or a Ruby Time object
    #
    def self.cache=(c)
      @cache = c
    end

    attr_accessor :logger, :options, :cache

    def initialize(options = {})
      if options[:disable_timeout] or options[:timeout].to_i < 0
        raise "It is no longer possible to disable the timeout."
      end

      @logger = options[:logger] || NullLogger.instance

      if options[:disable_cache] || (options[:cache_size] == 0)
        @cache = NullCache.new
      else
        cache_size = options[:cache_size] || DEFAULT_CACHE_SIZE
        cache_ttl = options[:cache_ttl] || DEFAULT_CACHE_TTL
        @cache = JsonClient.cache(cache_size, cache_ttl)
      end
      @options = options
    end

    def self.default_request_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        # GOVUK_APP_NAME is set for all apps by Puppet
        'User-Agent' => "gds-api-adapters/#{GdsApi::VERSION} (#{ENV["GOVUK_APP_NAME"]})"
      }
    end

    DEFAULT_TIMEOUT_IN_SECONDS = 4
    DEFAULT_CACHE_SIZE = 100
    DEFAULT_CACHE_TTL = 15 * 60 # 15 minutes

    def get_raw!(url)
      do_raw_request(:get, url)
    end

    def get_raw(url)
      if GdsApi.config.always_raise_for_not_found
        get_raw!(url)
      else
        warn <<-doc
          DEPRECATION NOTICE: You are making requests that will potentially
          return nil. Please set `GdsApi.config.always_raise_for_not_found = true`
          to make sure all responses with 404 or 410 raise an exception.

          Raising exceptions will be the default behaviour from October 1st, 2016.

          Called from: #{caller[2]}
        doc

        ignoring_missing do
          get_raw!(url)
        end
      end
    end

    # Define "safe" methods for each supported HTTP method
    #
    # Each "bang method" tries to make a request, but raises an exception if
    # the response is not successful. These methods discard the HTTPNotFound
    # exceptions (and return nil), and pass through all other exceptions.
    [:get, :post, :put, :patch, :delete].each do |http_method|
      method_name = "#{http_method}_json"
      define_method method_name do |url, *args, &block|
        if GdsApi.config.always_raise_for_not_found
          send (method_name + "!"), url, *args, &block
        else
          warn <<-doc
            DEPRECATION NOTICE: You are making requests that will potentially
            return nil. Please set `GdsApi.config.always_raise_for_not_found = true`
            to make sure all responses with 404 or 410 raise an exception.

            Raising exceptions will be the default behaviour from October 1st, 2016.

            Called from: #{caller[2]}
          doc

          ignoring_missing do
            send (method_name + "!"), url, *args, &block
          end
        end
      end
    end

    def get_json!(url, additional_headers = {}, &create_response)
      do_json_request(:get, url, nil, additional_headers, &create_response)
    end

    def post_json!(url, params = {}, additional_headers = {})
      do_json_request(:post, url, params, additional_headers)
    end

    def put_json!(url, params, additional_headers = {})
      do_json_request(:put, url, params, additional_headers)
    end

    def patch_json!(url, params, additional_headers = {})
      do_json_request(:patch, url, params, additional_headers)
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

    def put_multipart(url, params)
      r = do_raw_request(:put, url, params.merge({
        :multipart => true
      }))
      Response.new(r)
    end

    private
    def do_raw_request(method, url, params = nil)
      response = do_request(method, url, params)
    rescue RestClient::Exception => e
      raise build_specific_http_error(e, url, nil, params)
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
      rescue RestClient::Exception => e
        # Attempt to parse the body as JSON if possible
        error_details = begin
          e.http_body ? JSON.parse(e.http_body) : nil
        rescue JSON::ParserError
          nil
        end
        raise build_specific_http_error(e, url, error_details, params)
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
        timeout: options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS,
        open_timeout: options[:timeout] || DEFAULT_TIMEOUT_IN_SECONDS,
      )
    end

    def with_headers(method_params, headers)
      headers = headers.merge(GdsApi::GovukHeaders.headers)
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
        cache_control = Rack::Cache::CacheControl.new(response.headers[:cache_control])

        if cache_control.private? || cache_control.no_cache? || cache_control.no_store?
          Time.now.utc
        elsif cache_control.max_age
          Time.now.utc + cache_control.max_age
        end
      elsif response.headers[:expires]
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
        headers: self.class.default_request_headers
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

    rescue RestClient::Exceptions::Timeout => e
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
