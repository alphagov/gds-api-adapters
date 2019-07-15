require_relative 'base'

class GdsApi::WhitehallAdmin < GdsApi::Base
  def export_data(params)
    query_string = Rack::Utils.build_nested_query(params)
    get_json("#{endpoint}/export-data?#{query_string}")
  end
end
