require_relative 'base'
require_relative 'exceptions'

class GdsApi::PublishingApi < GdsApi::Base
  def put_intent(base_path, payload)
    put_json(intent_url(base_path), payload)
  end

  def destroy_intent(base_path)
    delete_json(intent_url(base_path))
  rescue GdsApi::HTTPNotFound => e
    e
  end

  # @deprecated Use GdsApi::PublishingApiV2
  def put_path(base_path, payload)
    put_json(paths_url(base_path), payload)
  end

private

  def intent_url(base_path)
    "#{endpoint}/publish-intent#{base_path}"
  end

  def paths_url(base_path)
    "#{endpoint}/paths#{base_path}"
  end
end
