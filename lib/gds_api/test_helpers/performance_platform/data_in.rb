module GdsApi
  module TestHelpers
    module PerformancePlatform
      module DataIn
        PP_DATA_IN_ENDPOINT = "http://www.performance.dev.gov.uk"

        def stub_service_feedback_day_aggregate_submission(slug, request_body = nil)
          post_stub = stub_http_request(:post, "#{PP_DATA_IN_ENDPOINT}/#{adjusted(slug)}_customer_satisfaction")
          post_stub.with(body: request_body) unless request_body.nil?
          post_stub.to_return(:status => 200)
        end

        def stub_service_feedback_bucket_unavailable_for(slug)
          stub_request(:post, "#{PP_DATA_IN_ENDPOINT}/#{adjusted(slug)}_customer_satisfaction").to_return(:status => 404)
        end

        def stub_pp_isnt_available
          stub_request(:post, /#{PP_DATA_IN_ENDPOINT}\/.*/).to_return(:status => 503)
        end

        private
        def adjusted(slug)
          slug.gsub("-", "_")
        end
      end
    end
  end
end
