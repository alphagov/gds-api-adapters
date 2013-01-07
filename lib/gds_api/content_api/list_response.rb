require "json"
require "gds_api/response"
require "link_header"

class GdsApi::ContentApi < GdsApi::Base

  # Response class for lists of multiple items from the content API.
  #
  # These responses are in a common format, with the list of results contained
  # under the `results` key. The response may also have previous and subsequent
  # pages, indicated by entries in the response's `Link` header.
  class ListResponse < GdsApi::Response

    # The ListResponse is instantiated with a reference back to the API client,
    # so it can make requests for the subsequent pages
    def initialize(response, api_client)
      super(response)
      @api_client = api_client
    end

    # Pass calls to `self.each` to the `results` sub-object, so we can iterate
    # over the response directly
    def_delegator :results, :each

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
      else
        nil
      end
    end

    def has_previous_page?
      ! page_link("previous").nil?
    end

    def previous_page
      # See the note in `next_page` for why this is memoised
      @previous_page ||= if has_previous_page?
        @api_client.get_list! page_link("previous").href
      else
        nil
      end
    end

    def with_subsequent_pages
      Enumerator.new { |yielder|
        each { |i| yielder << i }
        if has_next_page?
          next_page.with_subsequent_pages.each { |i| yielder << i }
        end
      }
    end

  private
    def link_header
      @link_header ||= LinkHeader.parse @net_http_response["Link"]
    end

    def page_link(rel)
      link_header.find_link(["rel", rel])
    end
  end
end
