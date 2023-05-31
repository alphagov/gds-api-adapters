require "json"
require "forwardable"

module GdsApi
  # This wraps an HTTP response with a JSON body.
  #
  # Responses can be configured to use relative URLs for `web_url` properties.
  # API endpoints should return absolute URLs so that they make sense outside of the
  # GOV.UK context.  However on internal systems we want to present relative URLs.
  # By specifying a base URI, this will convert all matching web_urls into relative URLs
  # This is useful on non-canonical frontends, such as those in staging environments.
  #
  # Example:
  #
  #   r = Response.new(response, web_urls_relative_to: "https://www.gov.uk")
  #   r['results'][0]['web_url']
  #   => "/bank-holidays"
  class Response
    extend Forwardable
    include Enumerable

    class CacheControl < Hash
      PATTERN = /([-a-z]+)(?:\s*=\s*([^,\s]+))?,?+/i

      def initialize(value = nil)
        super()
        parse(value)
      end

      def public?
        self["public"]
      end

      def private?
        self["private"]
      end

      def no_cache?
        self["no-cache"]
      end

      def no_store?
        self["no-store"]
      end

      def must_revalidate?
        self["must-revalidate"]
      end

      def proxy_revalidate?
        self["proxy-revalidate"]
      end

      def max_age
        self["max-age"].to_i if key?("max-age")
      end

      def reverse_max_age
        self["r-maxage"].to_i if key?("r-maxage")
      end
      alias_method :r_maxage, :reverse_max_age

      def shared_max_age
        self["s-maxage"].to_i if key?("r-maxage")
      end
      alias_method :s_maxage, :shared_max_age

      def to_s
        directives = []
        values = []

        each do |key, value|
          if value == true
            directives << key
          elsif value
            values << "#{key}=#{value}"
          end
        end

        (directives.sort + values.sort).join(", ")
      end

    private

      def parse(header)
        return if header.nil? || header.empty?

        header.scan(PATTERN).each do |name, value|
          self[name.downcase] = value || true
        end
      end
    end

    def_delegators :to_hash, :[], :"<=>", :each, :dig

    def initialize(http_response, options = {})
      @http_response = http_response
      @web_urls_relative_to = options[:web_urls_relative_to] ? URI.parse(options[:web_urls_relative_to]) : nil
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
      if headers[:date] && cache_control.max_age
        response_date = Time.parse(headers[:date])
        response_date + cache_control.max_age
      elsif headers[:expires]
        Time.parse(headers[:expires])
      end
    end

    def expires_in
      return unless headers[:date]

      age = Time.now.utc - Time.parse(headers[:date])

      if cache_control.max_age
        cache_control.max_age - age.to_i
      elsif headers[:expires]
        Time.parse(headers[:expires]).to_i - Time.now.utc.to_i
      end
    end

    def cache_control
      @cache_control ||= CacheControl.new(headers[:cache_control])
    end

    def to_hash
      parsed_content
    end

    def parsed_content
      @parsed_content ||= transform_parsed(JSON.parse(@http_response.body))
    end

    def present?
      true
    end

    def blank?
      false
    end

  private

    def transform_parsed(value)
      return value if @web_urls_relative_to.nil?

      case value
      when Hash
        Hash[value.map do |k, v|
          # NOTE: Don't bother transforming if the value is nil
          if k == "web_url" && v
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
        end]
      when Array
        value.map { |v| transform_parsed(v) }
      else
        value
      end
    end
  end
end
