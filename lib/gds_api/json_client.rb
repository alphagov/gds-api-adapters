require_relative 'response'
require_relative 'exceptions'
require_relative 'version'
require_relative 'govuk_headers'
require 'rest-client'
require 'null_logger'

module GdsApi
  class JsonClient
    include GdsApi::ExceptionHandling

    attr_accessor :logger, :options

    def initialize(options = {})
      if options[:disable_timeout] || options[:timeout].to_i.negative?
        raise "It is no longer possible to disable the timeout."
      end

      @logger = options[:logger] || NullLogger.instance
      @options = options
    end

    def self.default_request_headers
      {
        'Accept' => 'application/json',
        # GOVUK_APP_NAME is set for all apps by Puppet
        'User-Agent' => "gds-api-adapters/#{GdsApi::VERSION} (#{ENV['GOVUK_APP_NAME']})"
      }
    end

    def self.default_request_with_json_body_headers
      self.default_request_headers.merge(self.json_body_headers)
    end

    def self.json_body_headers
      {
        'Content-Type' => 'application/json',
      }
    end

    DEFAULT_TIMEOUT_IN_SECONDS = 4

    def get_raw!(url)
      do_raw_request(:get, url)
    end

    def get_raw(url)
      get_raw!(url)
    end

    def get_json_with_retries(url, additional_headers = {}, retries: 3, &create_response)
      remaining_attempts = retries

      begin
        get_json(url, additional_headers, &create_response)
      rescue GdsApi::HTTPServerError => e
        if remaining_attempts.zero?
          raise e
        else
          remaining_attempts -= 1
          # Exponentially increasing sleep time, which doesn't exceed a set maximum
          # 0.5, 2, 4, 8, ... seconds delay
          seconds = (2**((retries - remaining_attempts) - 1))
          sleep_time = [seconds, MAX_BACKOFF].min
          sleep sleep_time
          retry
        end
      end
    end

    def get_json(url, additional_headers = {}, &create_response)
      do_json_request(:get, url, nil, additional_headers, &create_response)
    end

    def post_json(url, params = {}, additional_headers = {})
      do_json_request(:post, url, params, additional_headers)
    end

    def put_json(url, params, additional_headers = {})
      do_json_request(:put, url, params, additional_headers)
    end

    def patch_json(url, params, additional_headers = {})
      do_json_request(:patch, url, params, additional_headers)
    end

    def delete_json(url, params = {}, additional_headers = {})
      do_json_request(:delete, url, params, additional_headers)
    end

    def post_multipart(url, params)
      r = do_raw_request(:post, url, params.merge(multipart: true))
      Response.new(r)
    end

    def put_multipart(url, params)
      r = do_raw_request(:put, url, params.merge(multipart: true))
      Response.new(r)
    end

  private

    MAX_BACKOFF = 5

    def do_raw_request(method, url, params = nil)
      do_request(method, url, params)
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
        if params
          additional_headers.merge!(self.class.json_body_headers)
        end
        response = do_request(method, url, (params.to_json if params), additional_headers)
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
          "Authorization" => "Bearer #{@options[:bearer_token]}"
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

    def with_headers(method_params, default_headers, additional_headers)
      method_params.merge(
        headers: default_headers
          .merge(method_params[:headers] || {})
          .merge(GdsApi::GovukHeaders.headers)
          .merge(additional_headers)
      )
    end

    def with_ssl_options(method_params)
      method_params.merge(
        # This is the default value anyway, but we should probably be explicit
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )
    end

    def do_request(method, url, params = nil, additional_headers = {})
      loggable = { request_uri: url, start_time: Time.now.to_f }
      start_logging = loggable.merge(action: 'start')
      logger.debug start_logging.to_json

      method_params = {
        method: method,
        url: url,
      }

      method_params[:payload] = params
      method_params = with_timeout(method_params)
      method_params = with_headers(method_params, self.class.default_request_headers, additional_headers)
      method_params = with_auth_options(method_params)
      if URI.parse(url).is_a? URI::HTTPS
        method_params = with_ssl_options(method_params)
      end

      ::RestClient::Request.execute(method_params)
    rescue Errno::ECONNREFUSED => e
      logger.error loggable.merge(status: 'refused', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::EndpointNotFound.new("Could not connect to #{url}")
    rescue RestClient::Exceptions::Timeout => e
      logger.error loggable.merge(status: 'timeout', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::TimedOutException.new
    rescue URI::InvalidURIError => e
      logger.error loggable.merge(status: 'invalid_uri', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::InvalidUrl
    rescue RestClient::Exception => e
      # Log the error here, since we have access to loggable, but raise the
      # exception up to the calling method to deal with
      loggable.merge!(status: e.http_code, end_time: Time.now.to_f, body: e.http_body)
      logger.warn loggable.to_json
      raise
    rescue Errno::ECONNRESET => e
      logger.error loggable.merge(status: 'connection_reset', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::TimedOutException.new
    rescue SocketError => e
      logger.error loggable.merge(status: 'socket_error', error_message: e.message, error_class: e.class.name, end_time: Time.now.to_f).to_json
      raise GdsApi::SocketErrorException.new
    end
  end
end
