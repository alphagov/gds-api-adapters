require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentStore < GdsApi::Base

  class ItemNotFound < GdsApi::HTTPNotFound
    def self.build_from(http_error)
      new(http_error.code, http_error.message, http_error.error_details)
    end
  end

  def content_item(base_path)
    get_json(content_item_url(base_path))
  end

  def incoming_links!(base_path, params = {})
    query = query_string(params)
    get_json!("#{endpoint}/incoming-links#{base_path}#{query}")
  rescue GdsApi::HTTPNotFound => e
    raise ItemNotFound.build_from(e)
  end

  def content_item!(base_path)
    get_json!(content_item_url(base_path))
  rescue GdsApi::HTTPNotFound => e
    raise ItemNotFound.build_from(e)
  end

  private

  def content_item_url(base_path)
    "#{endpoint}/content#{base_path}"
  end
end
