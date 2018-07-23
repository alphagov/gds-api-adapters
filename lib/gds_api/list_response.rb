require "json"
require "gds_api/response"
require "link_header"

module GdsApi
  # Response class for lists of multiple items.
  #
  # This expects responses to be in a common format, with the list of results
  # contained under the `results` key. The response may also have previous and
  # subsequent pages, indicated by entries in the response's `Link` header.
  class ListResponse < Response
    # The ListResponse is instantiated with a reference back to the API client,
    # so it can make requests for the subsequent pages
    def initialize(response, api_client, options = {})
      super(response, options)
      @api_client = api_client
    end

    # Pass calls to `self.each` to the `results` sub-object, so we can iterate
    # over the response directly
    def_delegators :results, :each, :to_ary

    def results
      to_hash["results"]
    end

    def has_next_page?
      to_hash["next_page_url"]
    end

    def has_previous_page?
      to_hash["previous_page_url"]
    end

    def next_page
      return unless to_hash["next_page_url"]
      @next_page ||= @api_client.get_list(to_hash["next_page_url"])
    end

    def previous_page
      return unless to_hash["previous_page_url"]
      @previous_page ||= @api_client.get_list(to_hash["previous_page_url"])
    end

    # Transparently get all results across all pages. Compare this with #each
    # or #results which only iterate over the current page.
    #
    # Example:
    #
    #   list_response.with_subsequent_pages.each do |result|
    #     ...
    #   end
    #
    # or:
    #
    #   list_response.with_subsequent_pages.count
    #
    # Pages of results are fetched on demand. When iterating, that means
    # fetching pages as results from the current page are exhausted. If you
    # invoke a method such as #count, this method will fetch all pages at that
    # point. Note that the responses are stored so subsequent pages will not be
    # loaded multiple times.
    def with_subsequent_pages
      Enumerator.new do |yielder|
        self.each { |i| yielder << i }

        if next_page
          next_page.with_subsequent_pages.each { |i| yielder << i }
        end
      end
    end
  end
end
