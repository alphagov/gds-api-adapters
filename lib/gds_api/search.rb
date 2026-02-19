require "gds_api/base"
require "rack/utils"

module GdsApi
  # @api documented
  class Search < Base
    # Perform a search.
    #
    # @param args [Hash] A valid search query. See search-api documentation for options.
    #
    # @see https://github.com/alphagov/search-api/blob/master/docs/search-api.md
    def search(args, additional_headers = {})
      request_url = "#{base_url}/search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json(request_url, additional_headers)
    end

    # Perform a search, returning the results as an enumerator.
    #
    # The enumerator abstracts away search-api's pagination and fetches new pages when
    # necessary.
    #
    # @param args [Hash] A valid search query. See search-api documentation for options.
    # @param page_size [Integer] Number of results in each page.
    #
    # @see https://github.com/alphagov/search-api/blob/master/docs/search-api.md
    def search_enum(args, page_size: 100, additional_headers: {})
      Enumerator.new do |yielder|
        (0..Float::INFINITY).step(page_size).each do |index|
          search_params = args.merge(start: index.to_i, count: page_size)
          results = search(search_params, additional_headers).to_h.fetch("results", [])
          results.each do |result|
            yielder << result
          end
          if results.count < page_size
            break
          end
        end
      end
    end

    def base_url
      endpoint
    end
  end
end
