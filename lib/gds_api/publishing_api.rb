require_relative 'base'
require_relative 'exceptions'

class GdsApi::PublishingApi < GdsApi::Base

  def put_draft_content_item(base_path, payload)
    put_json!(draft_content_item_url(base_path), payload)
  end

  def put_content_item(base_path, payload)
    put_json!(content_item_url(base_path), payload)
  end

  def put_intent(base_path, payload)
    put_json!(intent_url(base_path), payload)
  end

  def destroy_intent(base_path)
    delete_json(intent_url(base_path))
  end


  private

  def draft_content_item_url(base_path)
    "#{endpoint}/draft-content#{base_path}"
  end

  def content_item_url(base_path)
    "#{endpoint}/content#{base_path}"
  end

  def intent_url(base_path)
    "#{endpoint}/publish-intent#{base_path}"
  end
end
