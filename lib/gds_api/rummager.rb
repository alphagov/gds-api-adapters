require 'gds_api/base'
require 'rack/utils'

module GdsApi
  class Rummager < Base

    def search(query, extra_params={})
      return [] if query.nil? || query == ""
      get_json!(search_url(:search, query, extra_params))
    end

    def advanced_search(args)
      return [] if args.nil? || args.empty?
      request_path = "#{base_url}/advanced_search?#{Rack::Utils.build_nested_query(args)}"
      get_json!(request_path)
    end

    def organisations
      get_json!("#{base_url}/organisations")
    end

  private

    def search_url(type, query, extra_params={})
      request_path = "#{base_url}/#{type}?q=#{CGI.escape(query)}"
      if extra_params
        request_path << "&"
        request_path << Rack::Utils.build_query(extra_params)
      end
      request_path
    end

    def base_url
      endpoint
    end
  end
end
