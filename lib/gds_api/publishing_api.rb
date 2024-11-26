require_relative "base"
require_relative "exceptions"

# Adapter for the Publishing API.
#
# @see https://github.com/alphagov/publishing-api
# @see https://github.com/alphagov/publishing-api/blob/main/docs/publishing-application-examples.md
# @see https://github.com/alphagov/publishing-api/blob/main/docs/model.md
# @api documented
class GdsApi::PublishingApi < GdsApi::Base
  class NoLiveVersion < GdsApi::BaseError; end

  # Put a content item
  #
  # @param content_id [UUID]
  # @param payload [Hash] A valid content item
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#put-v2contentcontent_id
  def put_content(content_id, payload)
    put_json(content_url(content_id), payload)
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
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2contentcontent_id
  def get_content(content_id, params = {})
    get_json(content_url(content_id, params))
  end

  # Return a live content item, i.e. content that has a state of "published" or "unpublished"
  #
  # Raises exception if the item doesn't exist.
  #
  # @param content_id [UUID]
  # @option locale [String] locale The language, defaults to 'en' in publishing-api.
  #
  # @return [GdsApi::Response] a content item
  #
  # @raise [NoLiveVersion] when the content item is not found
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2contentcontent_id
  def get_live_content(content_id, locale = "en")
    content_item = get_content(content_id, locale:)

    live_states = %w[published unpublished]
    return content_item if live_states.include?(content_item.to_h["publication_state"])

    live_version_number = content_item["state_history"].find { |_, v| live_states.include?(v) }&.first
    raise NoLiveVersion, "No live version exists for content_id: #{content_id}" unless live_version_number

    get_content(content_id, locale:, version: live_version_number)
  end

  # Find the content_ids for a list of base_paths.
  #
  # @param base_paths [Array]
  # @param exclude_document_types [Array] (optional)
  # @param exclude_unpublishing_types [Array] (optional)
  # @param with_drafts [Boolean] (optional)
  # @return [Hash] a hash, keyed by `base_path` with `content_id` as value
  # @example
  #
  #   publishing_api.lookup_content_ids(base_paths: ['/foo', '/bar'])
  #   # => { "/foo" => "51ac4247-fd92-470a-a207-6b852a97f2db", "/bar" => "261bd281-f16c-48d5-82d2-9544019ad9ca" }
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#post-lookup-by-base-path
  def lookup_content_ids(base_paths:, exclude_document_types: nil, exclude_unpublishing_types: nil, with_drafts: false)
    options = { base_paths: }
    options[:exclude_document_types] = exclude_document_types if exclude_document_types
    options[:exclude_unpublishing_types] = exclude_unpublishing_types if exclude_unpublishing_types
    options[:with_drafts] = with_drafts if with_drafts
    response = post_json("#{endpoint}/lookup-by-base-path", options)
    response.to_hash
  end

  # Find the content_id for a base_path.
  #
  # Convenience method if you only need to look up one content_id for a
  # base_path. For multiple base_paths, use {GdsApi::PublishingApiV2#lookup_content_ids}.
  #
  # @param base_path [String]
  # @param exclude_document_types [Array] (optional)
  # @param exclude_unpublishing_types [Array] (optional)
  # @param with_drafts [Boolean] (optional)
  #
  # @return [UUID] the `content_id` for the `base_path`
  #
  # @example
  #
  #   publishing_api.lookup_content_id(base_path: '/foo')
  #   # => "51ac4247-fd92-470a-a207-6b852a97f2db"
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#post-lookup-by-base-path
  def lookup_content_id(base_path:, exclude_document_types: nil, exclude_unpublishing_types: nil, with_drafts: false)
    lookups = lookup_content_ids(
      base_paths: [base_path],
      exclude_document_types:,
      exclude_unpublishing_types:,
      with_drafts:,
    )
    lookups[base_path]
  end

  # Publish a content item
  #
  # The publishing-api will "publish" a draft item, so that it will be visible
  # on the public site.
  #
  # @param content_id [UUID]
  # @param update_type [String] Either 'major', 'minor' or 'republish'
  # @param options [Hash]
  # @option options [String] locale The language, defaults to 'en' in publishing-api.
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#post-v2contentcontent_idpublish
  def publish(content_id, update_type = nil, options = {})
    params = {
      update_type:,
    }

    optional_keys = %i[locale previous_version]

    params = merge_optional_keys(params, options, optional_keys)

    post_json(publish_url(content_id), params)
  end

  # Republish a content item
  #
  # The publishing-api will "republish" a live edition. This can be used to remove an unpublishing or to
  # re-send a published edition downstream
  #
  # @param content_id [UUID]
  # @param options [Hash]
  # @option options [String] locale The language, defaults to 'en' in publishing-api.
  #
  # @see ...
  def republish(content_id, options = {})
    optional_keys = %i[locale previous_version]

    params = merge_optional_keys({}, options, optional_keys)

    post_json(republish_url(content_id), params)
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
  # @param locale [String] (optional) The content item locale.
  # @param unpublished_at [Time] (optional) The time the content was withdrawn. Ignored for types other than withdrawn
  # @param redirects [Array] (optional) Required if no alternative_path is given. An array of redirect values, ie: { path:, type:, destination: }
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#post-v2contentcontent_idunpublish
  def unpublish(content_id, type:, explanation: nil, alternative_path: nil, discard_drafts: false, allow_draft: false, previous_version: nil, locale: nil, unpublished_at: nil, redirects: nil)
    params = {
      type:,
    }

    params[:explanation] = explanation if explanation
    params[:alternative_path] = alternative_path if alternative_path
    params[:previous_version] = previous_version if previous_version
    params[:discard_drafts] = discard_drafts if discard_drafts
    params[:allow_draft] = allow_draft if allow_draft
    params[:locale] = locale if locale
    params[:unpublished_at] = unpublished_at.utc.iso8601 if unpublished_at
    params[:redirects] = redirects if redirects

    post_json(unpublish_url(content_id), params)
  end

  # Discard a draft
  #
  # Deletes the draft content item.
  #
  # @param options [Hash]
  # @option options [String] locale The language, defaults to 'en' in publishing-api.
  # @option options [Integer] previous_version used to ensure the request is discarding the latest lock version of the draft
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#post-v2contentcontent_iddiscard-draft
  def discard_draft(content_id, options = {})
    optional_keys = %i[locale previous_version]

    params = merge_optional_keys({}, options, optional_keys)

    post_json(discard_url(content_id), params)
  end

  # Get the link set for the given content_id.
  #
  # Given a Content ID, it fetchs the existing link set and their version.
  #
  # @param content_id [String]
  #
  # @return [GdsApi::Response] A response containing `links` and `version`.
  #
  # @example
  #
  #   publishing_api.get_links("a-content-id")
  #   # => {
  #     "content_id" => "a-content-id",
  #     "links" => [
  #       "organisation" => "organisation-content-id",
  #       "document_collection" => "document-collection-content-id"
  #     ],
  #     "version" => 17
  #   }
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2linkscontent_id
  def get_links(content_id)
    get_json(links_url(content_id))
  end

  # Returns an array of changes to links.
  #
  # The link changes can be filtered by link_type, source content_id,
  # target content_id and user. A maximum of 250 changes will be
  # returned.
  #
  # @param link_types [Array] Array of link_types to filter by.
  # @param source_content_ids [Array] Array of source content ids to filter by.
  # @param target_content_ids [Array] Array of target content ids to filter by.
  # @param users [Array] User UIDs to filter by.
  # @example
  #
  #   publishing_api.get_links_changes(
  #     link_types: ['taxons'],
  #     target_content_ids: ['a544d48b-1e9e-47fb-b427-7a987c658c14']
  #   )
  #
  def get_links_changes(params)
    get_json(links_changes_url(params))
  end

  # Get expanded links
  #
  # Return the expanded links of the item.
  #
  # @param content_id [UUID]
  # @param locale [String] Locale with which to generate the expanded links. Unless this is specified, the default locale (`en`) in the Publishing API will be used.
  # @param with_drafts [Bool] Whether links to draft-only editions are returned, defaulting to `true`.
  # @param generate [Bool] Whether to require publishing-api to generate the expanded links, which may be slow. Defaults to `false`.
  #
  # @example
  #
  #   publishing_api.get_expanded_links("8157589b-65e2-4df6-92ba-2c91d80006c0", with_drafts: false).to_h
  #
  #   #=> {
  #     "generated" => "2017-08-01T10:42:49Z",
  #     "expanded_links" => {
  #       "organisations" => [
  #         {
  #           "content_id" => "21aa83a2-a47f-4189-a252-b02f8c322012",
  #           ... (and more attributes)
  #         }
  #       ]
  #     }
  #   }
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2expanded-linkscontent_id
  def get_expanded_links(content_id, locale: nil, with_drafts: true, generate: false)
    params = {}
    params[:with_drafts] = "false" unless with_drafts
    params[:generate] = "true" if generate
    params[:locale] = locale if locale
    query = query_string(params)
    validate_content_id(content_id)
    get_json("#{endpoint}/v2/expanded-links/#{content_id}#{query}")
  end

  # Patch the links of a content item
  #
  # @param content_id [UUID]
  # @param params [Hash]
  # @option params [Hash] links A "links hash"
  # @option params [Integer] previous_version The previous version (returned by `get_links`). If this version is not the current version, the publishing-api will reject the change and return 409 Conflict. (optional)
  # @option params [Boolean] bulk_publishing Set to true to indicate that this is part of a mass-republish. Allows the publishing-api to prioritise human-initiated publishing (optional, default false)
  # @example
  #
  #   publishing_api.patch_links(
  #     '86963c13-1f57-4005-b119-e7cf3cb92ecf',
  #     links: {
  #       topics: ['d6e1527d-d0c0-40d5-9603-b9f3e6866b8a'],
  #       mainstream_browse_pages: ['d6e1527d-d0c0-40d5-9603-b9f3e6866b8a'],
  #     },
  #     previous_version: 10,
  #     bulk_publishing: true
  #   )
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#patch-v2linkscontent_id
  def patch_links(content_id, params)
    payload = {
      links: params.fetch(:links),
    }

    payload = merge_optional_keys(payload, params, %i[previous_version bulk_publishing])

    patch_json(links_url(content_id), payload)
  end

  # Get a list of content items from the Publishing API.
  #
  # The only required key in the params hash is `document_type`. These will be used to filter down the content items being returned by the API. Other allowed options can be seen from the link below.
  #
  # @param params [Hash] At minimum, this hash has to include the `document_type` of the content items we wish to see. All other optional keys are documented above.
  #
  # @example
  #
  #   publishing_api.get_content_items(
  #     document_type: 'taxon',
  #     q: 'Driving',
  #     page: 1,
  #     per_page: 50,
  #     publishing_app: 'content-tagger',
  #     fields: ['title', 'description', 'public_updated_at'],
  #     locale: 'en',
  #     order: '-public_updated_at'
  #   )
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2content
  def get_content_items(params)
    query = query_string(params)
    get_json("#{endpoint}/v2/content#{query}")
  end

  # Get content items which embed a reusable content_id
  #
  # @param content_id [UUID]
  # @param params [Hash]
  #
  #   publishing_api.get_host_content_for_content_id(
  #     "4b148ebc-b2bb-40db-8e48-dd8cff363ff7",
  #     { page: 1, order: '-last_edited_at' }
  #   )
  #
  # @return [GdsApi::Response] A response containing a summarised list of the content items which embed the target.
  # The content items returned will be in either the draft of published state.
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2contentcontent_idhost-content
  def get_host_content_for_content_id(content_id, params = {})
    query = query_string(params)
    get_json("#{endpoint}/v2/content/#{content_id}/host-content#{query}")
  end

  def get_content_by_embedded_document(content_id, params = {})
    warn "GdsAPI::PublishingApi: #get_content_by_embedded_document deprecated (please use #get_host_content_for_content_id)"
    get_host_content_for_content_id(content_id, params)
  end

  # Returns an Enumerator of content items for the provided
  # query string parameters.
  #
  # @param params [Hash]
  #
  # @return [Enumerator] an enumerator of content items
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2content
  def get_content_items_enum(params)
    Enumerator.new do |yielder|
      (1..Float::INFINITY).each do |index|
        merged_params = params.merge(page: index)
        page = get_content_items(merged_params).to_h
        results = page.fetch("results", [])
        results.each do |result|
          yielder << result
        end
        break if page.fetch("pages") <= index
      end
    end
  end

  # FIXME: Add documentation
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2linkables
  def get_linkables(document_type: nil)
    if document_type.nil?
      raise ArgumentError, "Please provide a `document_type`"
    end

    get_json("#{endpoint}/v2/linkables?document_type=#{document_type}")
  end

  # FIXME: Add documentation
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2linkedcontent_id
  def get_linked_items(content_id, params = {})
    query = query_string(params)
    validate_content_id(content_id)
    get_json("#{endpoint}/v2/linked/#{content_id}#{query}")
  end

  # Returns a paginated list of editions for the provided query string
  # parameters.
  #
  # @param params [Hash]
  #
  # @return [GdsApi::Response] a paginated list of editions
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2editions
  def get_editions(params = {})
    get_json(get_editions_url(params))
  end

  # Returns an Enumerator of Response objects for each page of results of
  # editions for the provided query string parameters.
  #
  # @param params [Hash]
  #
  # @return [Enumerator] an enumerator of editions responses
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2editions
  def get_paged_editions(params = {})
    Enumerator.new do |yielder|
      next_link = get_editions_url(params)
      while next_link
        yielder.yield begin
          response = get_json(next_link)
        end
        next_link_info = response["links"].select { |link| link["rel"] == "next" }.first
        next_link = next_link_info && next_link_info["href"]
      end
    end
  end

  # Returns a mapping of content_ids => links hashes
  #
  # @param content_ids [Array]
  #
  # @return [Hash] a mapping of content_id => links
  #
  # @example
  #
  #   publishing_api.get_links_for_content_ids([
  #     "e1067450-7d13-45ff-ada4-5e3dd4025fb7",
  #     "72ed754c-4c82-415f-914a-ab6760454cb4"
  #   ])
  #
  #   #=> {
  #     "e1067450-7d13-45ff-ada4-5e3dd4025fb7" => {
  #       links: {
  #         taxons: ["13bba81c-b2b1-4b13-a3de-b24748977198"]},
  #         ... (and more attributes)
  #       version: 10},
  #     "72ed754c-4c82-415f-914a-ab6760454cb4" => { ..etc }
  #   }
  #
  def get_links_for_content_ids(content_ids)
    post_json("#{endpoint}/v2/links/by-content-id", content_ids:).to_hash
  end

  # Reserves a path for a publishing application
  #
  # Returns success or failure only.
  #
  # @param payload [Hash]
  # @option payload [Hash] publishing_app The publishing application, like `content-tagger`
  #
  # @see https://docs.publishing.service.gov.uk/apis/publishing-api/api.html#put-pathsbase_path
  def put_path(base_path, payload)
    url = "#{endpoint}/paths#{base_path}"
    put_json(url, payload)
  end

  def unreserve_path(base_path, publishing_app)
    payload = { publishing_app: }
    delete_json(unreserve_url(base_path), payload)
  end

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
  # )
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#put-publish-intentbase_path
  def put_intent(base_path, payload)
    put_json(intent_url(base_path), payload)
  end

  # Delete a publishing intent for a base_path.
  #
  # @param base_path [String]
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#delete-publish-intentbase_path
  def destroy_intent(base_path)
    delete_json(intent_url(base_path))
  rescue GdsApi::HTTPNotFound => e
    e
  end

  # Get all schemas
  #
  # @return [GdsApi::Response] A map of schema names with JSON schemas.
  #
  # @example
  #
  #   publishing_api.get_schemas()
  #     # => {
  #       "email_address" => {
  #           "type": "email_address",
  #           "required": ["email"],
  #           "properties": {
  #             "email": { "type" => "string" },
  #           },
  #         }
  #     }
  #
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2schemas
  def get_schemas
    get_json("#{endpoint}/v2/schemas").to_hash
  end

  # Get a content schema by name
  #
  # @param schema_name [String]
  #
  # @return [GdsApi::Response] A response mapping schema name with JSON schema.
  #
  # @example
  #
  #   publishing_api.get_schema("email_address")
  #     # => {
  #       "email_address" => {
  #           "type": "email_address",
  #           "required": ["email"],
  #           "properties": {
  #             "email": { "type" => "string" },
  #           },
  #         }
  #     }
  #
  # @raise [HTTPNotFound] when the schema is not found
  # @see https://github.com/alphagov/publishing-api/blob/main/docs/api.md#get-v2schemasschema_name
  def get_schema(schema_name)
    get_json("#{endpoint}/v2/schemas/#{schema_name}").to_hash
  end

  # Make a GraphQL query
  #
  # @param query [String]
  #
  # @return [Hash] A response with the result of the GraphQL query.
  def graphql_query(query)
    post_json("#{endpoint}/graphql", query:).to_hash
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

  def links_changes_url(params = {})
    query = query_string(params)
    "#{endpoint}/v2/links/changes#{query}"
  end

  def publish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/publish"
  end

  def republish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/republish"
  end

  def unpublish_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/unpublish"
  end

  def discard_url(content_id)
    validate_content_id(content_id)
    "#{endpoint}/v2/content/#{content_id}/discard-draft"
  end

  def get_editions_url(params)
    query = query_string(params)
    "#{endpoint}/v2/editions#{query}"
  end

  def unreserve_url(base_path)
    "#{endpoint}/paths#{base_path}"
  end

  def intent_url(base_path)
    "#{endpoint}/publish-intent#{base_path}"
  end

  def paths_url(base_path)
    "#{endpoint}/paths#{base_path}"
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
