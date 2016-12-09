require_relative '../base'

module GdsApi
  class PerformancePlatformDatasetNotConfigured < BaseError; end

  module PerformancePlatform
    class DataIn < GdsApi::Base
      def submit_service_feedback_day_aggregate(slug, request_details)
        post_json("#{endpoint}/data/#{slug}/customer-satisfaction", request_details)
      rescue GdsApi::HTTPNotFound
        raise PerformancePlatformDatasetNotConfigured, "Dataset for slug [#{slug}] not set up"
      end

      def corporate_content_problem_report_count(entries)
        post_json("#{endpoint}/data/gov-uk-content/feedback-count", entries)
      end

      def corporate_content_urls_with_the_most_problem_reports(entries)
        post_json("#{endpoint}/data/gov-uk-content/top-urls", entries)
      end

      def submit_problem_report_daily_totals(entries)
        post_json("#{endpoint}/data/govuk-info/page-contacts", entries)
      end
    end
  end
end
