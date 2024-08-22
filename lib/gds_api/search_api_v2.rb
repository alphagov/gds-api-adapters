module GdsApi
  class SearchApiV2 < Base
    def search(args, additional_headers = {})
      request_url = "#{endpoint}/search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json(request_url, additional_headers)
    end

    def autocomplete(query)
      args = { q: query }
      request_url = "#{endpoint}/autocomplete.json?#{Rack::Utils.build_nested_query(args)}"
      get_json(request_url)
    end
  end
end
