require_relative 'base'
require_relative 'exceptions'

class GdsApi::CollectionsApi < GdsApi::Base

  def topic(base_path)
    get_json(collections_api_url(base_path))
  end

private

  def collections_api_url(base_path)
    "#{endpoint}/specialist-sectors#{base_path}"
  end
end
