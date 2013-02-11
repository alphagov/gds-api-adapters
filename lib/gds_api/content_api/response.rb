module GdsApi
  class ContentApi < GdsApi::Base
    class Response < GdsApi::Response
      # Responses from the content API can be configured to use relative URLs
      # for `web_url` properties. This is useful on non-canonical frontends,
      # such as those in staging environments.
      #
      # Example:
      #
      #   r = Response.new(response, website_root: "https://www.gov.uk")
      #   r.results[0].web_url
      #   => "/bank-holidays"

      WEB_URL_KEYS = ["web_url"]

      def initialize(http_response, options = {})
        if options[:website_root]
          @website_root = URI.parse(options[:website_root])
        else
          @website_root = nil
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
            if @website_root && WEB_URL_KEYS.include?(k) && v
              # Use relative URLs to route when the web_url value is on the
              # same domain as the site root.
              [k, @website_root.route_to(v).to_s]
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
