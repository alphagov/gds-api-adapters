require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentStore < GdsApi::ContentApi
  include GdsApi::ExceptionHandling

  def content_item(base_path)
    get_json(content_item_url(base_path))
  end

  def content_item!(base_path)
    get_json!(content_item_url(base_path))
  end

  private

  def content_item_url(base_path)
    "#{endpoint}/content#{base_path}"
  end
end
