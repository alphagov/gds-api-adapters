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
    params = { update_type: update_type }
    params = params.merge(locale: options[:locale]) if options[:locale]

    post_json!(publish_url(content_id), params)
  end

  def get_links(content_id)
    get_json(links_url(content_id))
  end

  def put_links(content_id, payload)
    links = payload.fetch(:links)
    put_json!(links_url(content_id), links: links)
  end

private

  def content_url(content_id, params = {})
    query = query_string(params)
    "#{endpoint}/v2/content/#{content_id}#{query}"
  end

  def links_url(content_id)
    "#{endpoint}/v2/links/#{content_id}"
  end

  def publish_url(content_id)
    "#{endpoint}/v2/content/#{content_id}/publish"
  end
end
