require_relative "base"
require_relative "exceptions"

class GdsApi::PublishingApi < GdsApi::Base
  # Create a publishing intent for a base_path.
  #
  # @param base_path [String]
  # @param payload [Hash]
  # @example
  #
  # publishing_api.put_intent(
  #   '/some/base_path',
  #   {
  #     publish_time: '2024-03-15T09:00:00.000+00:00',
  #     publishing_app: 'content-publisher',
  #     rendering_app: 'government-frontend',
  #   }
  #)
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/api.md#put-publish-intentbase_path
  def put_intent(base_path, payload)
    put_json(intent_url(base_path), payload)
  end

  # Delete a publishing intent for a base_path.
  #
  # @param base_path [String]
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/api.md#delete-publish-intentbase_path
  def destroy_intent(base_path)
    delete_json(intent_url(base_path))
  rescue GdsApi::HTTPNotFound => e
    e
  end

  def unreserve_path(base_path, publishing_app)
    payload = { publishing_app: publishing_app }
    delete_json(unreserve_url(base_path), payload)
  end

private

  def unreserve_url(base_path)
    "#{endpoint}/paths#{base_path}"
  end

  def intent_url(base_path)
    "#{endpoint}/publish-intent#{base_path}"
  end

  def paths_url(base_path)
    "#{endpoint}/paths#{base_path}"
  end
end
