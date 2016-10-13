module GdsApi
  module TestHelpers
    module PerformancePlatform
      module DataOut
        PP_DATA_OUT_ENDPOINT = "http://www.performance.service.gov.uk".freeze

        def stub_service_feedback(slug, response_body = {})
          stub_http_request(:get, "#{PP_DATA_OUT_ENDPOINT}/data/#{slug}/customer-satisfaction").
            to_return(status: 200, body: response_body.to_json)
        end

        def stub_data_set_not_available(slug)
          stub_http_request(:get, "#{PP_DATA_OUT_ENDPOINT}/data/#{slug}/customer-satisfaction").
            to_return(status: 404)
        end

        def stub_service_not_available
          stub_request(:any, /#{PP_DATA_OUT_ENDPOINT}\/.*/).to_return(status: 503)
        end
      end
    end
  end
end
