require_relative 'base'
require_relative 'exceptions'

class GdsApi::PublishingApi < GdsApi::Base

  def put_content_item(base_path, payload)
    put_json!(content_item_url(base_path), payload)
  end

  private

  def content_item_url(base_path)
    "#{endpoint}/content#{base_path}"
  end
end
