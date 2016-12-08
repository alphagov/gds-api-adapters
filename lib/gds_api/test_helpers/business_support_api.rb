require 'gds_api/test_helpers/business_support_helper'

module GdsApi
  module TestHelpers
    module BusinessSupportApi
      include GdsApi::TestHelpers::CommonResponses
      include GdsApi::TestHelpers::BusinessSupportHelper
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      BUSINESS_SUPPORT_API_ENDPOINT = Plek.current.find('business-support-api')

      def setup_business_support_api_schemes_stubs
        setup_business_support_stubs(BUSINESS_SUPPORT_API_ENDPOINT, 'business-support-schemes')
      end

      def business_support_api_has_scheme(scheme, facets = {})
        api_has_business_support(scheme, facets)
      end

      def business_support_api_has_schemes(schemes, facets = {})
        schemes.each do |scheme|
          business_support_api_has_scheme(scheme, facets)
        end
      end

      def business_support_api_has_a_scheme(slug, scheme)
        title = scheme.delete(:title)
        stub_request(:get, %r{\A#{BUSINESS_SUPPORT_API_ENDPOINT}/business-support-schemes/#{slug}\.json}).to_return do |_request|
          { body: response_base.merge(format: 'business_support', title: title, details: scheme).to_json }
        end
      end
    end
  end
end
