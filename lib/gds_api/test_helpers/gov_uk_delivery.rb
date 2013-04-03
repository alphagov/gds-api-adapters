require 'json'

module GdsApi
  module TestHelpers
    module GovUkDelivery

      GOVUK_DELIVERY_ENDPOINT = Plek.current.find('govuk-delivery')

      def stub_gov_uk_delivery_post_request(method, params_hash)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/#{method}").with(body: params_hash.to_json)
      end
    end
  end
end
