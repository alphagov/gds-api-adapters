require_relative '../base'

module GdsApi
  module PerformancePlatform
    class DataIn < GdsApi::Base
      def submit_service_feedback_day_aggregate(slug, request_details)
        post_json!("#{endpoint}/#{slug}_customer_satisfaction", request_details)
      end
    end
  end
end
