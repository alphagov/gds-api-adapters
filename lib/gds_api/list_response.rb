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
      # support group_by results from the content api by checking if there is a
      # grouped_results key present first. if it's not, then fallback to the
      # results key
      to_hash["grouped_results"] || to_hash["results"]
    end

    def has_next_page?
      ! page_link("next").nil?
    end

    def next_page
      # This shouldn't be a performance problem, since the cache will generally
      # avoid us making multiple requests for the same page, but we shouldn't
      # allow the data to change once it's already been loaded, so long as we
      # retain a reference to any one page in the sequence
      @next_page ||= if has_next_page?
                       @api_client.get_list! page_link("next").href
                     end
    end

    def has_previous_page?
      ! page_link("previous").nil?
    end

    def previous_page
      # See the note in `next_page` for why this is memoised
      @previous_page ||= begin
        if has_previous_page?
          @api_client.get_list!(page_link("previous").href)
        end
      end
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
      Enumerator.new { |yielder|
        self.each do |i| yielder << i end
        if has_next_page?
          next_page.with_subsequent_pages.each do |i| yielder << i end
        end
      }
    end

  private

    def link_header
      @link_header ||= LinkHeader.parse @http_response.headers[:link]
    end

    def page_link(rel)
      link_header.find_link(["rel", rel])
    end
  end
end
