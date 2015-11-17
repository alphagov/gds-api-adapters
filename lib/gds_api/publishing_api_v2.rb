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


  # Returns content items by format.
  #
  # This includes draft content items. A special field +publication_state+ will
  # be returned indicating wheter the content item is live or draft.
  #
  # @param params [Hash]
  # @option params [String] content_format A GOV.UK content format, like +topic+
  #   or +mainstream_browse_page+.
  # @option params [Array] fields Attributes of the content item, like +title+,
  #   +description+ or +content_id+. You can request any valid content_item
  #   attribute (including +details+, which contains page data).
  #
  # @return [GdsApi::Response] a list of content items of the format.
  #
  # @example
  #  publishing_api.get_content_items(content_format: 'topic', fields: [:title, :base_path])
  #
  #  # will return a GdsApi::Response with the data:
  #
  #  [
  #    {"title" => "A", "base_path" => "/a-live-item", "publication_state" => "live"},
  #    {"title" => "B", "base_path" => "/a-draft-item", "publication_state" => "draft"}
  #  ]
  def get_content_items(params)
    query = query_string(params)
    get_json("#{endpoint}/v2/content#{query}")
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

  def merge_optional_keys(params, options, optional_keys)
    optional_keys.each_with_object(params) do |optional_key, hash|
      hash.merge!(optional_key => options[optional_key]) if options[optional_key]
    end
  end
end
