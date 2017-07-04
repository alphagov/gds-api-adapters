module GdsApi
  module TestHelpers
    module PerformancePlatform
      module DataOut
        PP_DATA_OUT_ENDPOINT = "https://www.performance.service.gov.uk".freeze

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

        def stub_search_terms(slug, response_body = {})
          options = {
              slug: slug,
              transaction: 'search-terms',
              group_by: 'searchKeyword',
              collect: 'searchUniques:sum'
          }
          stub_statistics(options, false, response_body)
        end

        def stub_searches(slug, is_multipart, response_body = {})
          options = {
              slug: slug,
              transaction: 'search-terms',
              group_by: 'pagePath',
              collect: 'searchUniques:sum'
          }
          stub_statistics(options, is_multipart, response_body)
        end

        def stub_page_views(slug, is_multipart, response_body = {})
          options = {
              slug: slug,
              transaction: 'page-statistics',
              group_by: 'pagePath',
              collect: 'uniquePageviews:sum'
          }
          stub_statistics(options, is_multipart, response_body)
        end

        def stub_problem_reports(slug, is_multipart, response_body = {})
          options = {
              slug: slug,
              transaction: 'page-contacts',
              group_by: 'pagePath',
              collect: 'total:sum'
          }
          stub_statistics(options, is_multipart, response_body)
        end

        def stub_statistics(options, is_multipart, response_body = {})
          params = {
              group_by: options[:group_by],
              collect: options[:collect],
              duration: 42,
              period: "day",
              end_at: Date.today.to_time.getutc.iso8601
          }

          filter_param = is_multipart ? :filter_by_prefix : :filter_by
          params[filter_param] = "pagePath:" + options[:slug]

          stub_http_request(:get, "#{PP_DATA_OUT_ENDPOINT}/data/govuk-info/#{options[:transaction]}")
              .with(query: params)
              .to_return(status: 200, body: response_body.to_json)
        end

        def stub_search_404(slug)
          stub_request(:get, "#{PP_DATA_OUT_ENDPOINT}/data/govuk-info/search-terms").
              with(query: hash_including(filter_by: slug)).
              to_return(status: 404, headers: { content_type: "application/json" })
        end

        def stub_page_views_404(slug)
          stub_request(:get, "#{PP_DATA_OUT_ENDPOINT}/data/govuk-info/page-statistics").
              with(query: hash_including(filter_by: slug)).
              to_return(status: 404, headers: { content_type: "application/json" })
        end

        def stub_problem_reports_404(slug)
          stub_request(:get, "#{PP_DATA_OUT_ENDPOINT}/data/govuk-info/page-contacts").
              with(query: hash_including(filter_by: slug)).
              to_return(status: 404, headers: { content_type: "application/json" })
        end
      end
    end
  end
end
