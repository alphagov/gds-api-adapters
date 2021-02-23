require_relative "../base"

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
        get_json("#{endpoint}/data/#{transaction_page_slug}/customer-satisfaction")
      end

      # Fetching statistics data from the performance platform for a given page slug
      #
      # Makes a +GET+ request.
      #
      # @param slug [String] Points to the page for which we are requesting
      # statistics.
      # @param is_multipart [Boolean] Flag that marks whether the slug is multipart
      # or not:
      #
      # - simple: `/european-health-insurance-card`
      # - multipart: `/european-health-insurance-card/123`
      #
      # # @examples
      #
      #  1. Without multipart filtering:
      #
      #  performance_platform_data_out.search_terms('/european-health-insurance-card')
      #
      #  2. With multipart filtering:
      #
      #  performance_platform_data_out.searches('/european-health-insurance-card', true)
      #  performance_platform_data_out.page_views('/european-health-insurance-card', true)
      #  performance_platform_data_out.problem_reports('/european-health-insurance-card', true)

      def search_terms(slug)
        options = {
          slug: slug,
          transaction: "search-terms",
          group_by: "searchKeyword",
          collect: "searchUniques:sum",
        }
        statistics(options)
      end

      def searches(slug, is_multipart)
        options = {
          slug: slug,
          transaction: "search-terms",
          group_by: "pagePath",
          collect: "searchUniques:sum",
        }
        statistics(options, is_multipart)
      end

      def page_views(slug, is_multipart)
        options = {
          slug: slug,
          transaction: "page-statistics",
          group_by: "pagePath",
          collect: "uniquePageviews:sum",
        }
        statistics(options, is_multipart)
      end

      def problem_reports(slug, is_multipart)
        options = {
          slug: slug,
          transaction: "page-contacts",
          group_by: "pagePath",
          collect: "total:sum",
        }
        statistics(options, is_multipart)
      end

      # This can be used as a free form call to the performance platform.
      # The performance platform uses Backdrop and its query language for
      # storing and querying data.
      # Backdrop can be found here: https://github.com/alphagov/backdrop
      def statistics(options, is_multipart = false)
        params = {
          group_by: options[:group_by],
          collect: options[:collect],
          duration: 42,
          period: "day",
          end_at: Date.today.to_time.getutc.iso8601,
        }

        filter_param = is_multipart ? :filter_by_prefix : :filter_by
        params[filter_param] = "pagePath:#{options[:slug]}"

        get_json("#{endpoint}/data/govuk-info/#{options[:transaction]}#{query_string(params)}")
      end
    end
  end
end
