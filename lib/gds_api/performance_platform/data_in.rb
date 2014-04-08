require_relative '../base'

module GdsApi
  class PerformancePlatformDatasetNotConfigured < BaseError; end

  module PerformancePlatform
    class DataIn < GdsApi::Base
      def submit_service_feedback_day_aggregate(slug, request_details)
        post_json!("#{endpoint}/data/#{slug}/customer-satisfaction", request_details)
      rescue GdsApi::HTTPNotFound
        raise PerformancePlatformDatasetNotConfigured, "Dataset for slug [#{slug}] not set up"
      end
    end
  end
end
