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

    def_delegators :results, :each

    def has_next_page?
      ! page_link("next").nil?
    end

    def next_page
      if has_next_page?
        @api_client.get_list! page_link("next").href
      else
        nil
      end
    end

    def has_previous_page?
      ! page_link("previous").nil?
    end

    def previous_page
      if has_previous_page?
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
