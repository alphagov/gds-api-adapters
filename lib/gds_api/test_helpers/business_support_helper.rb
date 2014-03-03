require 'gds_api/test_helpers/json_client_helper'
require 'cgi'
require 'gds_api/test_helpers/common_responses'


module GdsApi
  module TestHelpers
    module BusinessSupportHelper
      def setup_business_support_stubs(endpoint, path)
        @stubbed_business_supports = {}
        stub_request(:get, %r{\A#{endpoint}/#{path}\.json}).to_return do |request|
          if request.uri.query_values
            key = facet_key(request.uri.query_values)
            results = @stubbed_business_supports[key] || []
          else
            results = @stubbed_business_supports['default']
          end
          {:body => plural_response_base.merge("results" => results, "total" => results.size).to_json}
        end

      end

      def api_has_business_support(business_support, facets={})
        key = facet_key(facets)
        unless @stubbed_business_supports.has_key?(key)
          @stubbed_business_supports[key] = []
        end
        @stubbed_business_supports[key] << business_support
      end

      private

      def facet_key(facets)
        key = 'default'
        key = facets.values.flatten.sort.hash.to_s if facets and !facets.empty?
        key
      end
    end
  end
end
