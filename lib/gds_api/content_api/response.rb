module GdsApi
  class ContentApi < GdsApi::Base
    class Response < GdsApi::Response
      # Responses from the content API can be configured to use relative URLs
      # for `web_url` properties. This is useful on non-canonical frontends,
      # such as those in staging environments.
      #
      # Example:
      #
      #   r = Response.new(response, web_urls_relative_to: "https://www.gov.uk")
      #   r.results[0].web_url
      #   => "/bank-holidays"

      WEB_URL_KEYS = ["web_url"]

      def initialize(http_response, options = {})
        if options[:web_urls_relative_to]
          @web_urls_relative_to = URI.parse(options[:web_urls_relative_to])
        else
          @web_urls_relative_to = nil
        end

        super(http_response)
      end

      def to_hash
        @parsed ||= transform_parsed(JSON.parse(@http_response.body))
      end

    private
      def transform_parsed(value)
        case value
        when Hash
          Hash[value.map { |k, v|
            # NOTE: Don't bother transforming if the value is nil
            if @web_urls_relative_to && WEB_URL_KEYS.include?(k) && v
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
    end
  end
end
