module GdsApi
  class SearchApiV2 < Base
    def search(args, additional_headers = {})
      request_url = "#{endpoint}/search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json(request_url, additional_headers)
    end
  end
end
