require_relative 'base'
require_relative 'exceptions'

class GdsApi::CollectionsApi < GdsApi::Base

  def topic(base_path, options={})
    get_json(collections_api_url(base_path, options))
  end

private

  def collections_api_url(base_path, options={})
    "#{endpoint}/specialist-sectors#{base_path}#{query_string(options)}"
  end
end
