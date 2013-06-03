require 'gds_api/base'
require 'rack/utils'

module GdsApi
  class Rummager < Base

    def search(query)
      return [] if query.nil? || query == ""
      get_json!(search_url(:search, query))
    end

    def advanced_search(args)
      return [] if args.nil? || args.empty?
      request_path = "#{base_url}/advanced_search?#{Rack::Utils.build_nested_query(args)}"
      get_json!(request_path)
    end

  private

    def search_url(type, query)
      request_path = "#{base_url}/#{type}?q=#{CGI.escape(query)}"
      request_path
    end

    def base_url
      endpoint
    end
  end
end
