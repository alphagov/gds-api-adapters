require_relative 'base'

class GdsApi::PublishingApiV2 < GdsApi::Base
  def put_content(content_id, payload)
    put_json!(content_url(content_id), payload)
  end

  # Return a content item
  #
  # Returns nil if the content item doesn't exist.
  #
  # @param content_id [UUID]
  # @param params [Hash]
  # @option params [String] locale The language, defaults to 'en' in publishing-api.
  #
  # @return [GdsApi::Response] a content item
  def get_content(content_id, params = {})
    get_json(content_url(content_id, params))
  end

  # Return a content item
  #
  # Raises exception if the item doesn't exist.
  #
  # @param content_id [UUID]
  # @param params [Hash]
  # @option params [String] locale The language, defaults to 'en' in publishing-api.
  #
  # @return [GdsApi::Response] a content item
  #
  # @raise [HTTPNotFound] when the content item is not found
  def get_content!(content_id, params = {})
    get_json!(content_url(content_id, params))
  end

  # Find the content_ids for a list of base_paths.
  #
  # @param base_paths [Array]
  # @return [Hash] a hash, keyed by `base_path` with `content_id` as value
  # @example
  #
  #   publishing_api.lookup_content_ids(base_paths: ['/foo', '/bar'])
  #   # => { "/foo" => "51ac4247-fd92-470a-a207-6b852a97f2db", "/bar" => "261bd281-f16c-48d5-82d2-9544019ad9ca" }
  #
  def lookup_content_ids(base_paths:)
    response = post_json!("#{endpoint}/lookup-by-base-path", base_paths: base_paths)
    response.to_hash
  end

  # Find the content_id for a base_path.
  #
  # Convenience method if you only need to look up one content_id for a
  # base_path. For multiple base_paths, use {GdsApi::PublishingApiV2#lookup_content_ids}.
  #
  # @param base_path [String]
  #
  # @return [UUID] the `content_id` for the `base_path`
  #
  # @example
  #
  #   publishing_api.lookup_content_id(base_path: '/foo')
  #   # => "51ac4247-fd92-470a-a207-6b852a97f2db"
  #
  def lookup_content_id(base_path:)
    lookups = lookup_content_ids(base_paths: [base_path])
    lookups[base_path]
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

  def patch_links(content_id, payload)
    params = {
      links: payload.fetch(:links)
    }

    params = merge_optional_keys(params, payload, [:previous_version])

    patch_json!(links_url(content_id), params)
  end

  def get_content_items(params)
    query = query_string(params)
    get_json("#{endpoint}/v2/content#{query}")
  end

  def get_linkables(document_type: nil, format: nil)
    if document_type.nil?
      if format.nil?
        raise ArgumentError.new("Please provide a `document_type`")
      else
        self.class.logger.warn(
          "Providing `format` to the `get_linkables` method is deprecated and will be removed in a " +
          "future release.  Please use `document_type` instead."
        )
        document_type = format
      end
    end

    get_json("#{endpoint}/v2/linkables?document_type=#{document_type}")
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
