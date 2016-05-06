require_relative 'base'

# Adapter for the Publishing API.
#
# @see https://github.com/alphagov/publishing-api
# @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-application-examples.md
# @see https://github.com/alphagov/publishing-api/blob/master/doc/object-model-explanation.md
class GdsApi::PublishingApiV2 < GdsApi::Base
  # Put a content item
  #
  # @param content_id [UUID]
  # @param payload [Hash] A valid content item
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#put-v2contentcontent_id
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
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#get-v2contentcontent_id
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
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#get-v2contentcontent_id
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
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#post-lookup-by-base-path
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
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#post-lookup-by-base-path
  def lookup_content_id(base_path:)
    lookups = lookup_content_ids(base_paths: [base_path])
    lookups[base_path]
  end

  # Publish a content item
  #
  # The publishing-api will "publish" a draft item, so that it will be visible
  # on the public site.
  #
  # @param content_id [UUID]
  # @param update_type [String] Either 'major', 'minor' or 'republish'
  # @param params [Hash]
  # @option params [String] locale The language, defaults to 'en' in publishing-api.
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#post-v2contentcontent_idpublish
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

  # Unpublish a content item
  #
  # The publishing API will "unpublish" a live item, to remove it from the public
  # site, or update an existing unpublishing.
  #
  # @param content_id [UUID]
  # @param type [String] Either 'withdrawal', 'gone' or 'redirect'.
  # @param explanation [String] (optional) Text to show on the page.
  # @param alternative_path [String] (optional) Alternative path to show on the page or redirect to.
  # @param discard_drafts [Boolean] (optional) Whether to discard drafts on that item.  Defaults to false.
  # @param previous_version [Integer] (optional) A lock version number for optimistic locking.
  #
  # @see TODO
  def unpublish(content_id, type:, explanation: nil, alternative_path: nil, discard_drafts: false, previous_version: nil)
    params = {
      type: type
    }

    params.merge!(explanation: explanation) if explanation
    params.merge!(alternative_path: alternative_path) if alternative_path
    params.merge!(previous_version: previous_version) if previous_version
    params.merge!(discard_drafts: discard_drafts) if discard_drafts

    post_json!(unpublish_url(content_id), params)
  end

  # Discard a draft
  #
  # Deletes the draft content item.
  #
  # @param params [Hash]
  # @option params [String] locale The language, defaults to 'en' in publishing-api.
  # @option params [Integer] previous_version used to ensure the request is discarding the latest lock version of the draft
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#post-v2contentcontent_iddiscard-draft
  def discard_draft(content_id, options = {})
    optional_keys = [
      :locale,
      :previous_version,
    ]

    params = merge_optional_keys({}, options, optional_keys)

    post_json!(discard_url(content_id), params)
  end

  # FIXME: Add documentation
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#get-v2linkscontent_id
  def get_links(content_id)
    get_json(links_url(content_id))
  end

  # Patch the links of a content item
  #
  # @param content_id [UUID]
  # @param payload [Hash] A "links hash"
  # @example
  #
  #   publishing_api.patch_links(
  #     '86963c13-1f57-4005-b119-e7cf3cb92ecf',
  #     {
  #       topics: ['d6e1527d-d0c0-40d5-9603-b9f3e6866b8a'],
  #       mainstream_browse_pages: ['d6e1527d-d0c0-40d5-9603-b9f3e6866b8a'],
  #     }
  #   )
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#patch-v2linkscontent_id
  def patch_links(content_id, payload)
    params = {
      links: payload.fetch(:links)
    }

    params = merge_optional_keys(params, payload, [:previous_version])

    patch_json!(links_url(content_id), params)
  end

  # FIXME: Add documentation
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#get-v2content
  def get_content_items(params)
    query = query_string(params)
    get_json("#{endpoint}/v2/content#{query}")
  end

  # FIXME: Add documentation
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#get-v2linkables
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

  # FIXME: Add documentation
  #
  # @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-api-syntactic-usage.md#get-v2linkedcontent_id
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

  def unpublish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/unpublish"
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
