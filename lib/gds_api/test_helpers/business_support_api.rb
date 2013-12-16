require 'gds_api/test_helpers/json_client_helper'
require 'cgi'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module BusinessSupportApi
      include GdsApi::TestHelpers::CommonResponses
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      BUSINESS_SUPPORT_API_ENDPOINT = Plek.current.find('business-support-api')

      def setup_business_support_api_schemes_stubs
        @stubbed_content_api_business_support_schemes = {}
        stub_request(:get, %r{\A#{BUSINESS_SUPPORT_API_ENDPOINT}/business-support-schemes\.json}).to_return do |request|
          if request.uri.query_values
            key = request.uri.query_values.values.sort.hash
            results = @stubbed_content_api_business_support_schemes[key] || []
          else
            results = @stubbed_content_api_business_support_schemes.values.flatten
          end
          {:body => plural_response_base.merge("results" => results, "total" => results.size).to_json}
        end

      end

      def business_support_api_has_scheme(scheme, facets={})
        key = facets.values.sort.hash
        unless @stubbed_content_api_business_support_schemes[key]
          @stubbed_content_api_business_support_schemes[key] = []
        end
        @stubbed_content_api_business_support_schemes[key] << scheme
      end

      def business_support_api_has_schemes(schemes, facets={})
        schemes.each do |scheme|
          business_support_api_has_scheme(scheme, facets)
        end
      end

      def business_support_api_has_a_scheme(slug, scheme)
        title = scheme.delete(:title)
        stub_request(:get, %r{\A#{BUSINESS_SUPPORT_API_ENDPOINT}/business-support-schemes/#{slug}\.json}).to_return do |request|
          {:body => response_base.merge(:format => 'business_support', :title => title, :details => scheme).to_json}
        end
      end
    end
  end
end
