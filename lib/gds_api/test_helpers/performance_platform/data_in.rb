module GdsApi
  module TestHelpers
    module PerformancePlatform
      module DataIn
        PP_DATA_IN_ENDPOINT = "http://www.performance.dev.gov.uk"

        def stub_service_feedback_day_aggregate_submission(slug, request_body = nil)
          post_stub = stub_http_request(:post, "#{PP_DATA_IN_ENDPOINT}/data/#{slug}/customer-satisfaction")
          post_stub.with(body: request_body) unless request_body.nil?
          post_stub.to_return(:status => 200)
        end

        def stub_corporate_content_problem_report_count_submission(submissions = nil)
          post_stub = stub_http_request(:post, "#{PP_DATA_IN_ENDPOINT}/data/gov-uk-content/feedback-count")
          post_stub.with(body: submissions.to_json) unless submissions.nil?
          post_stub.to_return(:status => 200)
        end

        def stub_corporate_content_urls_with_the_most_problem_reports_submission(submissions = nil)
          post_stub = stub_http_request(:post, "#{PP_DATA_IN_ENDPOINT}/data/gov-uk-content/top-urls")
          post_stub.with(body: submissions.to_json) unless submissions.nil?
          post_stub.to_return(:status => 200)
        end

        def stub_problem_report_daily_totals_submission(submissions = nil)
          post_stub = stub_http_request(:post, "#{PP_DATA_IN_ENDPOINT}/data/govuk-info/page-contacts")
          post_stub.with(body: submissions.to_json) unless submissions.nil?
          post_stub.to_return(:status => 200)
        end

        def stub_service_feedback_bucket_unavailable_for(slug)
          stub_request(:post, "#{PP_DATA_IN_ENDPOINT}/data/#{slug}/customer-satisfaction").to_return(:status => 404)
        end

        def stub_pp_isnt_available
          stub_request(:post, /#{PP_DATA_IN_ENDPOINT}\/.*/).to_return(:status => 503)
        end
      end
    end
  end
end
