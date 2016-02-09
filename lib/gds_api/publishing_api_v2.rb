require_relative 'base'

class GdsApi::PublishingApiV2 < GdsApi::Base
  def put_content(content_id, payload)
    put_json!(content_url(content_id), payload)
  end

  def get_content(content_id, options = {})
    params = {}
    params = params.merge(locale: options[:locale]) if options[:locale]

    get_json(content_url(content_id, params))
  end

  def publish(content_id, update_type, options = {})
    params = {
      update_type: update_type
    }

    optional_keys = [
      :locale,
      :previous_version,
    ]

    params = merge_optional_keys(params, options, optional_keys)

    post_json!(publish_url(content_id), params)
  end

  def discard_draft(content_id, options = {})
    optional_keys = [
      :locale,
      :previous_version,
    ]

    params = merge_optional_keys({}, options, optional_keys)

    post_json!(discard_url(content_id), params)
  end

  def get_links(content_id)
    get_json(links_url(content_id))
  end

  def put_links(content_id, payload)
    params = {
      links: payload.fetch(:links)
    }

    params = merge_optional_keys(params, payload, [:previous_version])

    put_json!(links_url(content_id), params)
  end

  def get_content_items(params)
    query = query_string(params)
    get_json("#{endpoint}/v2/content#{query}")
  end

  def get_linked_items(content_id, params = {})
    query = query_string(params)
    validate_content_id(content_id)
    get_json("#{endpoint}/v2/linked/#{content_id}#{query}")
  end

private

  def content_url(content_id, params = {})
    validate_content_id(content_id)
    query = query_string(params)
    "#{endpoint}/v2/content/#{content_id}#{query}"
  end

  def links_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/links/#{content_id}"
  end

  def publish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/publish"
  end

  def discard_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/discard-draft"
  end

  def merge_optional_keys(params, options, optional_keys)
    optional_keys.each_with_object(params) do |optional_key, hash|
      hash.merge!(optional_key => options[optional_key]) if options[optional_key]
    end
  end

  def validate_content_id(content_id)
    raise ArgumentError, "content_id cannot be nil" unless content_id
  end
end
