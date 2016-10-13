require_relative '../base'

module GdsApi
  module PerformancePlatform
    class DataOut < GdsApi::Base
      # Fetch all service feedback from the performance platform for a given transaction
      # page slug.
      #
      # Makes a +GET+ request.
      #
      # The results are ordered date ascending.
      #
      # @param transaction_page_slug [String] The slug for which service feedback is
      # needed.
      #
      # # @example
      #
      #  performance_platform_data_out.service_feedback('register-to-vote')
      #
      #  #=> {
      #      "data": [
      #   {
      #     "_day_start_at": "2014-06-10T00:00:00+00:00",
      #     "_hour_start_at": "2014-06-10T00:00:00+00:00",
      #     "_id": "20140610_register-to-vote",
      #     "_month_start_at": "2014-06-01T00:00:00+00:00",
      #     "_quarter_start_at": "2014-04-01T00:00:00+00:00",
      #     "_timestamp": "2014-06-10T00:00:00+00:00",
      #     "_updated_at": "2014-06-11T00:30:50.901000+00:00",
      #     "_week_start_at": "2014-06-09T00:00:00+00:00",
      #     "comments": 217,
      #     "period": "day",
      #     "rating_1": 4,
      #     "rating_2": 6,
      #     "rating_3": 7,
      #     "rating_4": 74,
      #     "rating_5": 574,
      #     "slug": "register-to-vote",
      #     "total": 665
      #   },
      #   ...
      #  }
      def service_feedback(transaction_page_slug)
        get_json!("#{endpoint}/data/#{transaction_page_slug}/customer-satisfaction")
      end
    end
  end
end
