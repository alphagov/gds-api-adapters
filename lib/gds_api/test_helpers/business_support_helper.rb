require 'gds_api/test_helpers/json_client_helper'
require 'cgi'
require 'gds_api/test_helpers/common_responses'


module GdsApi
  module TestHelpers
    module BusinessSupportHelper
      def setup_business_support_stubs(endpoint, path)
        @stubbed_business_supports = []
        stub_request(:get, %r{\A#{endpoint}/#{path}\.json}).to_return do |request|
          if request.uri.query_values
            facets = sanitise_facets(request.uri.query_values)
            results = stubs_for_facets(facets) || []
          else
            results = @stubbed_business_supports
          end
          { body: plural_response_base.merge("results" => results, "total" => results.size).to_json }
        end
      end

      def api_has_business_support(business_support, facets = {})
        facets = sanitise_facets(facets)

        if business_support.is_a?(Symbol)
          bs_with_facets = facets.merge(title: business_support)
        else
          bs_with_facets = facets.merge(business_support)
        end

        @stubbed_business_supports << bs_with_facets unless @stubbed_business_supports.include?(bs_with_facets)
      end

    private

      def stubs_for_facets(facets)
        @stubbed_business_supports.select do |bs|
          facet_matches = 0
          facets.each do |k, v|
            if bs[k] && (v & bs[k]).any?
              facet_matches += 1
            end
          end
          facet_matches == facets.keys.size
        end
      end

      def sanitise_facets(facets)
        Hash[facets.map { |k, v|
          v = v.split(',') if v.is_a?(String)
          [k.to_sym, v]
        }]
      end
    end
  end
end
