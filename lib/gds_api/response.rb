require 'json'
require 'ostruct'
require 'forwardable'
require 'rack/cache'
require_relative 'core-ext/openstruct'

module GdsApi

  # This wraps an HTTP response with a JSON body, and presents this as
  # an object that has the read behaviour of both a Hash and an OpenStruct
  #
  # Responses can be configured to use relative URLs for `web_url` properties.
  # API endpoints should return absolute URLs so that they make sense outside of the
  # GOV.UK context.  However on internal systems we want to present relative URLs.
  # By specifying a base URI, this will convert all matching web_urls into relative URLs
  # This is useful on non-canonical frontends, such as those in staging environments.
  # See: https://github.com/alphagov/wiki/wiki/API-conventions for details on the API conventions
  #
  # Example:
  #
  #   r = Response.new(response, web_urls_relative_to: "https://www.gov.uk")
  #   r.results[0].web_url
  #   => "/bank-holidays"
  class Response
    extend Forwardable
    include Enumerable

    def_delegators :to_hash, :[], :"<=>", :each

    def initialize(http_response, options = {})
      @http_response = http_response
      @web_urls_relative_to = URI.parse(options[:web_urls_relative_to]) if options[:web_urls_relative_to]
    end

    def raw_response_body
      @http_response.body
    end

    def code
      # Return an integer code for consistency with HTTPErrorResponse
      @http_response.code
    end

    def headers
      @http_response.headers
    end

    def expires_at
      if headers[:date] && cache_control['max-age']
        response_date = Time.parse(headers[:date])
        response_date + cache_control['max-age'].to_i
      elsif headers[:expires]
        Time.parse(headers[:expires])
      end
    end

    def expires_in
      return unless headers[:date]

      age = Time.now.utc - Time.parse(headers[:date])

      if cache_control['max-age']
        cache_control['max-age'].to_i - age.to_i
      elsif headers[:expires]
        Time.parse(headers[:expires]).to_i - Time.now.utc.to_i
      end
    end

    def cache_control
      @cache_control ||= Rack::Cache::CacheControl.new(headers[:cache_control])
    end

    def cache_control_private?
      cache_control["private"]
    end

    def to_hash
      @parsed ||= transform_parsed(JSON.parse(@http_response.body))
    end

    def to_ostruct
      @ostruct ||= self.class.build_ostruct_recursively(to_hash)
    end

    def method_missing(method)
      to_ostruct.send(method)
    end

    def respond_to_missing?(method, include_private)
      to_ostruct.respond_to?(method, include_private)
    end

    def present?; true; end
    def blank?; false; end

  private

    def transform_parsed(value)
      return value if @web_urls_relative_to.nil?

      case value
      when Hash
        Hash[value.map { |k, v|
          # NOTE: Don't bother transforming if the value is nil
          if 'web_url' == k && v
            # Use relative URLs to route when the web_url value is on the
            # same domain as the site root. Note that we can't just use the
            # `route_to` method, as this would give us technically correct
            # but potentially confusing `//host/path` URLs for URLs with the
            # same scheme but different hosts.
            relative_url = @web_urls_relative_to.route_to(v)
            [k, relative_url.host ? v : relative_url.to_s]
          else
            [k, transform_parsed(v)]
          end
        }]
      when Array
        value.map { |v| transform_parsed(v) }
      else
        value
      end
    end

    def self.build_ostruct_recursively(value)
      case value
      when Hash
        OpenStruct.new(Hash[value.map { |k, v| [k, build_ostruct_recursively(v)] }])
      when Array
        value.map { |v| build_ostruct_recursively(v) }
      else
        value
      end
    end
  end
end
